import 'dart:math';

import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/decompilers/atl.dart';
import 'package:renpy_decompiler_backend/decompilers/base.dart';
import 'package:renpy_decompiler_backend/decompilers/sl2.dart';
import 'package:renpy_decompiler_backend/decompilers/testcase.dart';
import 'package:renpy_decompiler_backend/decompilers/translate.dart';

typedef RPYCDecompilerState = ({
  BaseDecompilerState baseState,
  dynamic pairedWith,
  PythonClassInstance? sayInsideMenu,
  PythonClassInstance? labelInsideMenu,
  bool inInit,
  bool missingInit,
  int mostLinesBehind,
  int lastLinesBehind,
});

typedef BlankLineCallback = bool Function(int? lineNumber);

class Options extends OptionBase {
  Translator? translator;
  bool initOffset;
  Map<String, (String, dynamic)>? slCustomNames;

  Options(
      {super.indentation = '    ',
      super.printLock,
      this.translator,
      this.initOffset = true,
      this.slCustomNames});
}

class RPYCDecompiler extends DecompilerBase<Options> {
  static List<String> pprint(
      List<String> outSink, List<PythonClassInstance> ast, Options options) {
    RPYCDecompiler builder = RPYCDecompiler(outSink: outSink, options: options);
    builder.dump(ast);
    outSink = builder.outSink;

    return outSink;
  }

  static final Map<PythonClass,
          void Function(RPYCDecompiler builder, PythonClassInstance ast)>
      dispatch = {
    PythonClass(module: 'renpy.ast', 'Image'): (builder, ast) {
      builder.requireInit();
      builder.indent();
      builder.write('image ${ast.vars['imgname'].join(' ')}');
      if (ast.vars['code'] != null) {
        builder.write(' = ${ast.vars['code'].vars['source'].vars['value']}');
      } else {
        if (ast.vars['atl'] != null) {
          builder.write(':');
          builder.printAtl(ast.vars['atl']);
        }
      }
    },
    PythonClass(module: 'renpy.ast', 'Transform'): (builder, ast) {
      builder.requireInit();
      builder.indent();

      String priority = '';
      if (builder.parent?.klass == PythonClass(module: 'renpy.ast', 'Init')) {
        PythonClassInstance init = builder.parent!;
        if (init.vars['priority'] != builder.initOffset &&
            init.vars['block'].length != 1 &&
            !builder.shouldComeBefore(init, ast)) {
          priority = ' ${init.vars['priority'] - builder.initOffset}';
        }
      }
      builder.write('transform$priority ${ast.vars['varname']}');
      if (ast.vars['parameters'] != null) {
        builder.write(reconstructParaminfo(ast.vars['parameters']));
      }

      if (ast.vars.containsKey('atl') && ast.vars['atl'] != null) {
        builder.write(':');
        builder.printAtl(ast.vars['atl']);
      }
    },
    PythonClass(module: 'renpy.ast', 'Show'): (builder, ast) {
      builder.indent();
      builder.write('show ');
      bool needsSpace = builder.printImspec(ast.vars['imspec']);

      if (builder.pairedWith != null &&
          (builder.pairedWith == true ||
              (builder.pairedWith is String &&
                  builder.pairedWith.isNotEmpty))) {
        if (needsSpace) {
          builder.write(' ');
        }
        builder.write('with ${builder.pairedWith}');
        builder.pairedWith = true;
      }

      if (ast.vars.containsKey('atl') && ast.vars['atl'] != null) {
        builder.write(':');
        builder.printAtl(ast.vars['atl']);
      }
    },
    PythonClass(module: 'renpy.ast', 'ShowLayer'): (builder, ast) {
      builder.indent();
      builder.write('show layer ${ast.vars['layer']}');

      if (ast.vars['at_list'] != null && ast.vars['at_list'].isNotEmpty) {
        List<dynamic> rawATList = ast.vars['at_list'];
        List<String> atList = [];

        for (var entry in rawATList) {
          if (entry is PythonClassInstance &&
              entry.klass == PythonClass(module: 'renpy.ast', 'PyExpr')) {
            atList.add(entry.vars['value']);
          } else {
            atList.add(entry);
          }
        }

        builder.write(' at ${atList.join(', ')}');
      }

      if (ast.vars.containsKey('atl') && ast.vars['atl'] != null) {
        builder.write(':');
        builder.printAtl(ast.vars['atl']);
      }
    },
    PythonClass(module: 'renpy.ast', 'Scene'): (builder, ast) {
      builder.indent();
      builder.write('scene');

      bool needsSpace;

      if (ast.vars['imspec'] == null) {
        if (ast.vars['layer'] is String) {
          builder.write(' onlayer ${ast.vars['layer']}');
        }
        needsSpace = true;
      } else {
        builder.write(' ');
        needsSpace = builder.printImspec(ast.vars['imspec']);
      }

      if (builder.pairedWith != null && builder.pairedWith != false) {
        if (needsSpace) {
          builder.write(' ');
        }
        builder
            .write('with ${builder.pairedWith}'); // possibly different output.
        builder.pairedWith = true;
      }

      if (ast.vars.containsKey('atl') && ast.vars['atl'] != null) {
        builder.write(':');
        builder.printAtl(ast.vars['atl']);
      }
    },
    PythonClass(module: 'renpy.ast', 'Hide'): (builder, ast) {
      builder.indent();
      builder.write('hide ');
      bool needsSpace = builder.printImspec(ast.vars['imspec']);
      if (builder.pairedWith != null && builder.pairedWith != false) {
        if (needsSpace) {
          builder.write(' ');
        }
        builder.write('with ${builder.pairedWith}');
        builder.pairedWith = true;
      }
    },
    PythonClass(module: 'renpy.ast', 'With'): (builder, ast) {
      if (ast.vars['paired'] != null) {
        if (!(builder.block[builder.index + 2].klass ==
                PythonClass(module: 'renpy.ast', 'With') &&
            builder.block[builder.index + 2].vars['expr'].vars['value'] ==
                ast.vars['paired'].vars['value'])) {
          throw Exception(
              'Unmateched paired with ${builder.pairedWith} != ${ast.vars['expr']}');
        }

        builder.pairedWith = ast.vars['paired'].vars['value'];
      } else if (builder.pairedWith != false) {
        if (builder.pairedWith != true) {
          builder.write(' with ${ast.vars['expr'].vars['value']}');
        }
        builder.pairedWith = false;
      } else {
        builder.advanceToLine(ast.vars['linenumber']);
        builder.indent();
        builder.write('with ${ast.vars['expr'].vars['value']}');
        builder.pairedWith = false;
      }
    },
    PythonClass(module: 'renpy.ast', 'Camera'): (builder, ast) {
      builder.indent();
      builder.write('camera');

      if (ast.vars['layer'] != 'master') {
        builder.write(' ${ast.vars['name']}');
      }

      if (ast.vars['at_list'].isNotEmpty) {
        builder.write(' at ${ast.vars['at_list'].join(', ')}');
      }

      if (ast.vars['atl'] != null) {
        builder.write(':');
        builder.printAtl(ast.vars['atl']);
      }
    },
    PythonClass(module: 'renpy.ast', 'Label'): (builder, ast) {
      if (builder.index != 0 &&
          builder.block[builder.index - 1].klass ==
              PythonClass(module: 'renpy.ast', 'Call')) {
        return;
      }
      if ((ast.vars['blocks'] == null || ast.vars['blocks'].isEmpty) &&
          ast.vars['parameters'] == null) {
        int remainingBlocks = builder.block.length - builder.index;
        PythonClassInstance? nextAst;
        if (remainingBlocks > 1) {
          nextAst = builder.block[builder.index + 1];
          if (nextAst.klass == PythonClass(module: 'renpy.ast', 'Menu') &&
              nextAst.vars['linenumber'] == ast.vars['linenumber']) {
            builder.labelInsideMenu = ast;
            return;
          }
        }

        if (remainingBlocks > 2) {
          PythonClassInstance nextNextAst = builder.block[builder.index + 2];
          if (nextAst!.klass == PythonClass(module: 'renpy.ast', 'Say') &&
              nextNextAst.klass == PythonClass(module: 'renpy.ast', 'Menu') &&
              nextNextAst.vars['linenumber'] == ast.vars['linenumber'] &&
              builder.sayBelongsToMenu(nextAst, nextNextAst)) {
            builder.labelInsideMenu = ast;
            return;
          }
        }
      }

      builder.advanceToLine(ast.vars['linenumber']);
      builder.indent();

      List<String> outSink = List.from(builder.outSink);
      builder.outSink = [];
      bool missingInit = builder.missingInit;
      builder.missingInit = false;
      try {
        builder.write(
            'label ${ast.vars['name']}${reconstructParaminfo(ast.vars['parameters'])}${ast.vars.containsKey('hide') && ast.vars['hide'] == true ? ' hide:' : ''}:');
        builder.printNodes(ast.vars['block'], 1);
      } finally {
        if (builder.missingInit) {
          outSink.add('init ');
        }
        builder.missingInit = missingInit;
        outSink.addAll(builder.outSink);
        builder.outSink = outSink;
      }
    },
    PythonClass(module: 'renpy.ast', 'Jump'): (builder, ast) {
      builder.indent();
      builder.write(
          'jump ${ast.vars.containsKey('expression') && ast.vars['expression'] == true ? 'expression ' : ''}${ast.vars['target'] is PythonClassInstance ? ast.vars['target'].vars['value'] : ast.vars['target']}');
    },
    PythonClass(module: 'renpy.ast', 'Call'): (builder, ast) {
      builder.indent();
      WordConcatenator words = WordConcatenator(false);
      words.append('call');
      if (ast.vars.containsKey('expression') &&
          ast.vars['expression'] == true) {
        words.append('expression');
      }
      if (ast.vars['label'] is PythonClassInstance) {
        words.append(ast.vars['label'].vars['value']);
      } else {
        words.append(ast.vars['label']);
      }

      if (ast.vars['arguments'] != null) {
        if (ast.vars['expression']) {
          words.append('pass');
        }
        words.append(reconstructArginfo(ast.vars['arguments']));
      }

      PythonClassInstance nextBlock = builder.block[builder.index + 1];

      if (nextBlock.klass == PythonClass(module: 'renpy.ast', 'Label')) {
        words.append('from ${nextBlock.vars['name']}');
      }

      builder.write(words.join());
    },
    PythonClass(module: 'renpy.ast', 'Return'): (builder, ast) {
      if (ast.vars['expression'] == null &&
          builder.parent == null &&
          builder.index + 1 == builder.block.length &&
          builder.index > 0 &&
          ast.vars['linenumber'] ==
              builder.block[builder.index - 1].vars['linenumber']) {
        return;
      }

      builder.advanceToLine(ast.vars['linenumber']);
      builder.indent();
      builder.write('return');

      if (ast.vars['expression'] != null) {
        builder.write(' ${ast.vars['expression'].vars['value']}');
      }
    },
    PythonClass(module: 'renpy.ast', 'If'): (builder, ast) {
      First statement = First(yesValue: 'if', noValue: 'elif');

      for (int i = 0; i < ast.vars['entries'].length; i++) {
        dynamic condition = ast.vars['entries'][i][0];
        List<PythonClassInstance> block =
            List<PythonClassInstance>.from(ast.vars['entries'][i][1]);

        if (i + 1 == ast.vars['entries'].length &&
            condition is PythonClassInstance &&
            condition.klass != PythonClass(module: 'renpy.ast', 'PyExpr')) {
          builder.indent();
          builder.write('else:');
        } else {
          if (condition is PythonClassInstance &&
              condition.vars.containsKey('linenumber')) {
            builder.advanceToLine(condition.vars['linenumber']);
          }
          builder.indent();
          String call = statement.call();

          if (call != 'else') {
            if (call == 'elif' &&
                (condition == 'True' ||
                    (condition is PythonClassInstance &&
                        condition.vars['value'] == 'True'))) {
              builder.write('else:');
            } else {
              builder.write(
                  '$call ${condition is PythonClassInstance ? condition.vars['value'] : condition}:');
            }
          } else {
            builder.write('$call:');
          }
        }
        builder.printNodes(block, 1);
      }
    },
    PythonClass(module: 'renpy.ast', 'While'): (builder, ast) {
      builder.indent();
      builder.write('while ${ast.vars['condition'].vars['value']}');
      builder.printNodes(ast.vars['block'], 1);
    },
    PythonClass(module: 'renpy.ast', 'Pass'): (builder, ast) {
      if (builder.index != 0 &&
          builder.block[builder.index - 1].klass ==
              PythonClass(module: 'renpy.ast', 'Call')) {
        return;
      }

      if (builder.index > 1 &&
          builder.block[builder.index - 2].klass ==
              PythonClass(module: 'renpy.ast', 'Call') &&
          builder.block[builder.index - 1].klass ==
              PythonClass(module: 'renpy.ast', 'Label') &&
          builder.block[builder.index - 2].vars['linenumber'] ==
              ast.vars['linenumber']) {
        return;
      }

      builder.advanceToLine(ast.vars['linenumber']);
      builder.indent();
      builder.write('pass');
    },
    PythonClass(module: 'renpy.ast', 'Init'): (builder, ast) {
      bool inInit = builder.inInit;
      builder.inInit = true;
      try {
        if (ast.vars['block'].length == 1 &&
            ([
                  PythonClass(module: 'renpy.ast', 'Define'),
                  PythonClass(module: 'renpy.ast', 'Default'),
                  PythonClass(module: 'renpy.ast', 'Transform')
                ].contains(ast.vars['block'].first.klass) ||
                (ast.vars['priority'] == -500 + builder.initOffset &&
                    ast.vars['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'Screen')) ||
                (ast.vars['priority'] == builder.initOffset &&
                    ast.vars['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'Style')) ||
                (ast.vars['priority'] == 500 + builder.initOffset &&
                    ast.vars['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'Testcase')) ||
                (ast.vars['priority'] == 0 + builder.initOffset &&
                    ast.vars['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'UserStatement') &&
                    ast.vars['block'].first.vars['line']
                        .startsWith('layeredimage ')) ||
                (ast.vars['priority'] == 500 + builder.initOffset &&
                    ast.vars['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'Image'))) &&
            !builder.shouldComeBefore(ast, ast.vars['block'].first)) {
          builder.printNodes(ast.vars['block']);
        } else if (ast.vars['block'].length == 0 &&
            ast.vars['priority'] == builder.initOffset &&
            (ast.vars['block'] as List<PythonClassInstance>).every((element) =>
                element.klass ==
                PythonClass(module: 'renpy.ast', 'TranslateString')) &&
            (ast.vars['block'] as List<PythonClassInstance>).sublist(1).every(
                (element) =>
                    element.vars['language'] ==
                    ast.vars['block'].first.vars['language'])) {
          builder.printNodes(ast.vars['block']);
        } else {
          builder.indent();
          builder.write('init');
          if (ast.vars['priority'] != builder.initOffset) {
            builder.write(' ${ast.vars['priority'] - builder.initOffset}');
          }

          if (ast.vars['block'].length == 1 &&
              !builder.shouldComeBefore(ast, ast.vars['block'].first)) {
            builder.write(' ');
            builder.skipIndentUntilWrite = true;
            builder.printNodes(ast.vars['block']);
          } else {
            builder.write(':');
            builder.printNodes(ast.vars['block'], 1);
          }
        }
      } finally {
        builder.inInit = inInit;
      }
    },
    PythonClass(module: 'renpy.ast', 'Menu'): (builder, ast) {
      builder.indent();
      builder.write('menu');
      if (builder.labelInsideMenu != null) {
        builder.write(' ${builder.labelInsideMenu!.vars['name']}');
        builder.labelInsideMenu = null;
      }

      if (ast.vars.containsKey('arguments') && ast.vars['arguments'] != null) {
        builder.write(reconstructArginfo(ast.vars['arguments']));
      }

      builder.write(':');

      builder.increaseIndent(() {
        if (ast.vars['with_'] != null) {
          builder.indent();
          builder.write('with ${ast.vars['with_']}');
        }

        if (ast.vars['set'] != null) {
          builder.indent();
          builder.write('set ${ast.vars['set']}');
        }

        List<dynamic> itemArguments;

        if (ast.vars.containsKey('item_arguments')) {
          itemArguments = ast.vars['item_arguments'];
        } else {
          itemArguments =
              List.generate(ast.vars['items'].length, (index) => null);
        }

        for (int i = 0; i < ast.vars['items'].length; i++) {
          var [label, condition, rawBlock] = ast.vars['items'][i];
          var block = rawBlock == null
              ? null
              : List<PythonClassInstance>.from(rawBlock);
          dynamic arguments = itemArguments[i];

          if (builder.options.translator != null) {
            label = builder.options.translator!.strings[label] ?? label;
          }

          RPYCDecompilerState? state;

          if (condition is PythonClassInstance &&
              condition.vars.containsKey('linenumber')) {
            if (builder.sayInsideMenu != null &&
                condition.vars['linenumber'] > builder.lineNumber + 1) {
              builder.printSayInsideMenu();
            }
            builder.advanceToLine(condition.vars['linenumber']);
          } else if (builder.sayInsideMenu != null) {
            state = builder.saveState();
            builder.mostLinesBehind = builder.lastLinesBehind;
            builder.printSayInsideMenu();
          }

          builder.printMenuItem(label, condition, block, arguments);

          if (state != null) {
            if (builder.mostLinesBehind > state.lastLinesBehind) {
              builder.rollbackState(state);
              builder.printMenuItem(label, condition, block, arguments);
            } else {
              builder.mostLinesBehind =
                  max(state.mostLinesBehind, builder.mostLinesBehind);
              builder.commitState(state);
            }
          }
        }

        if (builder.sayInsideMenu != null) {
          builder.printSayInsideMenu();
        }
      });
    },
    PythonClass('Python', module: 'renpy.ast'): (builder, ast) =>
        builder.printPython(ast),
    PythonClass('EarlyPython', module: 'renpy.ast'): (builder, ast) =>
        builder.printPython(ast, true),
    PythonClass('Define', module: 'renpy.ast'): (builder, ast) =>
        builder.printDefine(ast),
    PythonClass('Default', module: 'renpy.ast'): (builder, ast) {
      builder.requireInit();
      builder.indent();

      String priority = '';
      if (builder.parent?.klass == PythonClass(module: 'renpy.ast', 'Init')) {
        PythonClassInstance init = builder.parent!;
        if (init.vars['priority'] != builder.initOffset &&
            init.vars['block'].length == 1 &&
            !builder.shouldComeBefore(init, ast)) {
          priority = ' ${init.vars['priority'] - builder.initOffset}';
        }
      }

      if (ast.vars['store'] == 'store') {
        builder.write(
            'default$priority ${ast.vars['varname']} = ${ast.vars['code'].vars['source'].vars['value']}');
      } else {
        builder.write(
            'default$priority ${ast.vars['store'].substring(6)}.${ast.vars['varname']} = ${ast.vars['code'].vars['source'].vars['value']}');
      }
    },
    PythonClass('Say', module: 'renpy.ast'): (builder, ast) =>
        builder.printSay(ast),
    PythonClass('UserStatement', module: 'renpy.ast'): (builder, ast) {
      builder.indent();
      builder.write(ast.vars['line']);

      if (ast.vars.containsKey('block') &&
          ast.vars['block'] != null &&
          ast.vars['block'].isNotEmpty) {
        builder.increaseIndent(() {
          builder.printLex(ast.vars['block']);
        });
      }
    },
    PythonClass('Style', module: 'renpy.ast'): (builder, ast) {
      builder.requireInit();
      Map<int, WordConcatenator> keywords = {
        ast.vars['linenumber']: WordConcatenator(false, true)
      };

      if (ast.vars['parent'] != null) {
        keywords[ast.vars['linenumber']]!.append('is ${ast.vars['parent']}');
      }
      if (ast.vars['clear']) {
        keywords[ast.vars['linenumber']]!.append('clear');
      }
      if (ast.vars['take'] != null) {
        keywords[ast.vars['linenumber']]!.append('take ${ast.vars['take']}');
      }
      for (String delName in ast.vars['delattr']) {
        keywords[ast.vars['linenumber']]!.append('del $delName');
      }

      if (ast.vars['variant'] != null) {
        if (!keywords.containsKey(ast.vars['variant'].vars['linenumber'])) {
          keywords[ast.vars['variant'].vars['linenumber']] =
              WordConcatenator(false);
        }
        if (ast.vars['variant'] is PythonClassInstance) {
          keywords[ast.vars['variant'].vars['linenumber']]!
              .append('variant ${ast.vars['variant'].vars['value']}');
        } else {
          keywords[ast.vars['variant'].vars['linenumber']]!
              .append('variant ${ast.vars['variant']}');
        }
      }
      for (var entry in Map.from(ast.vars['properties']).entries) {
        if (!keywords.containsKey(entry.value.vars['linenumber'])) {
          keywords[entry.value.vars['linenumber']] = WordConcatenator(false);
        }
        if (entry.value is PythonClassInstance) {
          keywords[entry.value.vars['linenumber']]!
              .append('${entry.key} ${entry.value.vars['value']}');
        } else {
          keywords[entry.value.vars['linenumber']]!
              .append('${entry.key} ${entry.value}');
        }
      }

      List<(int, String)> finalKeywords = [
        for (var entry in keywords.entries) (entry.key, entry.value.join())
      ];

      finalKeywords.sort((a, b) => a.$1.compareTo(b.$1));

      builder.indent();
      builder.write('style ${ast.vars['style_name']}');

      if (finalKeywords[0].$2.isNotEmpty) {
        builder.write(' ${finalKeywords[0].$2}');
      }
      if (finalKeywords.length > 1) {
        builder.write(':');
        builder.increaseIndent(() {
          for (int i = 1; i < finalKeywords.length; i++) {
            builder.advanceToLine(finalKeywords[i].$1);
            builder.indent();
            builder.write(finalKeywords[i].$2);
          }
        });
      }
    },
    PythonClass('Translate', module: 'renpy.ast'): (builder, ast) {
      builder.indent();
      builder.write(
          'translate to ${ast.vars.containsKey('language') ? (ast.vars['language'] ?? 'None') : 'None'} ${ast.vars['identifier']}');

      builder.printNodes(ast.vars['block'], 1);
    },
    PythonClass('EndTranslate', module: 'renpy.ast'): (builder, ast) {},
    PythonClass('TranslateString', module: 'renpy.ast'): (builder, ast) {
      builder.requireInit();

      if (!(builder.index > 0 &&
          builder.block[builder.index - 1].klass ==
              PythonClass(module: 'renpy.ast', 'TranslateString') &&
          builder.block[builder.index - 1].vars['language'] ==
              ast.vars['language'])) {
        builder.indent();
        builder.write('translate ${ast.vars['language'] ?? 'None'} strings:');
      }

      builder.increaseIndent(() {
        builder.advanceToLine(ast.vars['linenumber']);
        builder.indent();
        builder.write('old "${stringEscape(ast.vars['old'])}"');
        if (ast.vars.containsKey('newloc')) {
          builder.advanceToLine(ast.vars['newloc'][1]);
        }
        builder.indent();
        builder.write('new "${stringEscape(ast.vars['new'])}"');
      });
    },
    PythonClass('TranslateBlock', module: 'renpy.ast'): (builder, ast) {
      builder.printTranslateBlock(ast);
    },
    PythonClass('TranslateEarlyBlock', module: 'renpy.ast'): (builder, ast) {
      builder.printTranslateBlock(ast);
    },
    PythonClass('Screen', module: 'renpy.ast'): (builder, ast) {
      builder.requireInit();
      PythonClassInstance screen = ast.vars['screen'];
      if (screen.klass ==
          PythonClass(module: 'renpy.screenlang', 'ScreenLangScreen')) {
        throw UnimplementedError(
            'Decompiling screen language version 1 screens is no longer supported. Use the legacy branch of Unrpyc (by CensoredUsername on Github) if this is required');
      } else if (screen.klass ==
          PythonClass(module: 'renpy.sl2.slast', 'SLScreen')) {
        var out = SL2Decompiler.pprint(
          builder.outSink,
          screen,
          builder.options,
          indentLevel: builder.indentLevel,
          lineNumber: builder.lineNumber,
          skipIndentUntilWrite: builder.skipIndentUntilWrite,
        );

        builder.lineNumber = out.$1;
        builder.outSink = out.$2;

        builder.skipIndentUntilWrite = false;
      } else {
        throw Exception('Unknown screen type ${screen.klass}');
      }
    },
    PythonClass('Testcase', module: 'renpy.ast'): (builder, ast) {
      builder.requireInit();
      builder.indent();
      builder.write('testcase ${ast.vars['label']}:');
      var out = TestcaseDecompiler.pprint(
          builder.outSink,
          List<PythonClassInstance>.from(ast.vars['test'].vars['block']),
          builder.options,
          indentLevel: builder.indentLevel + 1,
          lineNumber: builder.lineNumber,
          skipIndentUntilWrite: builder.skipIndentUntilWrite);
      builder.lineNumber = out.$1;
      builder.outSink = out.$2;
      builder.skipIndentUntilWrite = false;
    },
    PythonClass('RPY', module: 'renpy.ast'): (builder, ast) {
      builder.indent();
      builder.write('rpy python ${ast.vars['rest']}');
    },
  };

  dynamic pairedWith = false;
  PythonClassInstance? sayInsideMenu;
  PythonClassInstance? labelInsideMenu;
  bool inInit = false;
  bool missingInit = false;
  int initOffset = 0;
  int mostLinesBehind = 0;
  int lastLinesBehind = 0;

  RPYCDecompiler({
    super.outSink,
    required super.options,
  });

  @override
  (int, List<String>) dump(ast,
      [int indentLevel = 0,
      int lineNumber = 1,
      bool skipIndentUntilWrite = false]) {
    if (options.translator != null) {
      options.translator!.translateDialogue(ast);
    }

    if (options.initOffset && ast is List) {
      setBestInitOffset(List<PythonClassInstance>.from(ast));
    }

    super.dump(ast, indentLevel, lineNumber, true);

    for (var m in blankLineQueue) {
      m(null);
    }

    assert(!missingInit,
        'A required init, init label, or translate block was missing');

    return (this.lineNumber, outSink);
  }

  static String encodeSayString(String s) {
    return '"${s.replaceAll('\\', '\\\\').replaceAll('\n', '\\n').replaceAll('"', '\\"').replaceAll(RegExp(r'(?<= ) '), '\\ ')}"';
  }

  static String stringEscape(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\t', '\\t');
  }

  static String sayGetCode(PythonClassInstance ast, [bool inMenu = false]) {
    List<String> rv = [];

    if (ast.vars['who'] != null) {
      if (ast.vars['who'] is PythonClassInstance) {
        rv.add(ast.vars['who'].vars['value']);
      } else {
        rv.add(ast.vars['who']);
      }
    }

    if (ast.vars.containsKey('attributes') && ast.vars['attributes'] != null) {
      rv.addAll(List<String>.from(ast.vars['attributes']));
    }

    if (ast.vars.containsKey('temporary_attributes') &&
        ast.vars['temporary_attributes'] != null) {
      rv.add('@');
      rv.addAll(List<String>.from(ast.vars['temporary_attributes']));
    }

    rv.add(encodeSayString(ast.vars['what']));

    if (!ast.vars['interact'] && !inMenu) {
      rv.add('nointeract');
    }

    if (ast.vars.containsKey('explicit_identifier') &&
        ast.vars['explicit_identifier'] == true) {
      rv.add('id');
      rv.add(ast.vars['identifier']);
    } else if (ast.vars.containsKey('identifier') &&
        ast.vars['identifier'] != null) {
      rv.add('id');
      rv.add(ast.vars['identifier']);
    }

    if (ast.vars.containsKey('arguments') && ast.vars['arguments'] != null) {
      rv.add(reconstructArginfo(ast.vars['arguments']));
    }

    if (ast.vars['with_'] != null) {
      rv.add('with');
      if (ast.vars['with_'] is PythonClassInstance) {
        rv.add(ast.vars['with_'].vars['value']);
      } else {
        rv.add(ast.vars['with_']);
      }
    }

    return rv.join(' ');
  }

  void printSay(PythonClassInstance ast, [bool inMenu = false]) {
    if (!inMenu &&
        index + 1 < block.length &&
        sayBelongsToMenu(ast, block[index + 1])) {
      sayInsideMenu = ast;
      return;
    }

    indent();
    write(sayGetCode(ast, inMenu));
  }

  void printPython(PythonClassInstance ast, [bool early = false]) {
    indent();

    String code;
    if (ast.vars['code'].vars['source'] is String) {
      code = ast.vars['code'].vars['source'];
    } else {
      code = ast.vars['code'].vars['source'].vars['value'];
    }

    if (code[0] == '\n') {
      code = code.substring(1);
      write('python');
      if (early) {
        write(' early');
      }
      if (ast.vars['hide']) {
        write(' hide');
      }
      if (ast.vars.containsKey('store') &&
          (ast.vars['store'] ?? 'store') != 'store') {
        write(' in ');
        write(ast.vars['store'].substring(6));
      }
      write(':');

      increaseIndent(() {
        var result = splitLogicalLines(code);
        writeLines(result);
      });
    } else {
      write('\$ $code');
    }
  }

  void printDefine(PythonClassInstance ast) {
    requireInit();
    indent();

    String priority = '';
    if (parent != null &&
        parent!.klass == PythonClass(module: 'renpy.ast', 'Init')) {
      PythonClassInstance init = parent!;
      if (init.vars['priority'] != initOffset &&
          init.vars['block'].length == 1 &&
          !shouldComeBefore(init, ast)) {
        priority = ' ${init.vars['priority'] - initOffset}';
      }
    }

    String index = '';
    if (ast.vars.containsKey('index') && ast.vars['index'] != null) {
      index = '[${ast.vars['index'].vars['source']}]';
    }

    String operator =
        ast.vars.containsKey('operator') ? (ast.vars['operator'] ?? '=') : '=';
    String store = ast.vars.containsKey('store')
        ? (ast.vars['store'] ?? 'store')
        : 'store';

    if (store == 'store') {
      write(
          'define$priority ${ast.vars['varname']}$index $operator ${ast.vars['code'].vars['source'].vars['value']}');
    } else {
      write(
          'define$priority ${store.substring(6)}.${ast.vars['varname']}$index $operator ${ast.vars['code'].vars['source'].vars['value']}');
    }
  }

  void printLex(List lex) {
    for (var [_, lineNumber, content, block] in lex) {
      advanceToLine(lineNumber);
      indent();
      write(content);
      if (block.isNotEmpty) {
        increaseIndent(() {
          printLex(block);
        });
      }
    }
  }

  void printTranslateBlock(PythonClassInstance ast) {
    indent();
    write('translate ${ast.vars['language'] ?? 'None'} ');

    skipIndentUntilWrite = true;

    bool inInit = this.inInit;
    if (ast.vars['block'].length == 1 &&
        [
          PythonClass('Python', module: 'renpy.ast'),
          PythonClass('Style', module: 'renpy.ast')
        ].contains(ast.vars['block'].first.klass)) {
      this.inInit = true;
    }
    try {
      printNodes(ast.vars['block']);
    } finally {
      this.inInit = inInit;
    }
  }

  bool shouldComeBefore(PythonClassInstance a, PythonClassInstance b) {
    return a.vars['linenumber'] < b.vars['linenumber'];
  }

  void requireInit() {
    if (!inInit) {
      missingInit = true;
    }
  }

  void setBestInitOffset(List<PythonClassInstance> nodes) {
    Map<int, int> votes = {};
    for (PythonClassInstance ast in nodes) {
      if (ast.klass != PythonClass(module: 'renpy.ast', 'Init')) {
        continue;
      }

      int offset = ast.vars['priority'];
      if (ast.vars['block'].length == 1 &&
          !shouldComeBefore(ast, ast.vars['block'].first)) {
        PythonClassInstance block = ast.vars['block'].first;

        if (block.klass == PythonClass(module: 'renpy.ast', 'Screen')) {
          offset -= -500;
        } else if (block.klass ==
            PythonClass(module: 'renpy.ast', 'Testcase')) {
          offset -= 500;
        } else if (block.klass == PythonClass(module: 'renpy.ast', 'Image')) {
          offset -= 500;
        }
      }
      votes[offset] = (votes[offset] ?? 0) + 1;
    }
    if (votes.isNotEmpty) {
      int winner =
          votes.entries.reduce((a, b) => a.value > b.value ? a : b).key;

      if ((votes[0] ?? 0) + 1 < votes[winner]!) {
        setInitOffset(winner);
      }
    }
  }

  void setInitOffset(int offset) {
    doWhenBlankLine((lineNumber) {
      if (lineNumber == null ||
          lineNumber - this.lineNumber <= 1 ||
          indentLevel > 0) {
        return true;
      }

      if (offset != initOffset) {
        indent();
        write('init offset = $offset');
        initOffset = offset;
      }

      return false;
    });
  }

  @override
  void advanceToLine(int lineNumber) {
    lastLinesBehind =
        max(this.lineNumber + (skipIndentUntilWrite ? 0 : 1) - lineNumber, 0);
    mostLinesBehind = max(lastLinesBehind, mostLinesBehind);

    blankLineQueue = blankLineQueue.where((m) => m(lineNumber)).toList();
    if (this.lineNumber < lineNumber) {
      write('\n' * (lineNumber - this.lineNumber - 1));
    }
  }

  @override
  RPYCDecompilerState saveState() {
    return (
      baseState: super.saveState(),
      pairedWith: pairedWith,
      sayInsideMenu: sayInsideMenu,
      labelInsideMenu: labelInsideMenu,
      inInit: inInit,
      missingInit: missingInit,
      mostLinesBehind: mostLinesBehind,
      lastLinesBehind: lastLinesBehind,
    );
  }

  @override
  void commitState(dynamic state) {
    super.commitState(state.baseState);
  }

  @override
  void rollbackState(dynamic state) {
    pairedWith = state.pairedWith;
    sayInsideMenu = state.sayInsideMenu;
    labelInsideMenu = state.labelInsideMenu;
    inInit = state.inInit;
    missingInit = state.missingInit;
    mostLinesBehind = state.mostLinesBehind;
    lastLinesBehind = state.lastLinesBehind;
    super.rollbackState(state.baseState);
  }

  @override
  void printNode(PythonClassInstance ast) {
    if (ast.vars.containsKey('linenumber') &&
        ![
          PythonClass(module: 'renpy.ast', 'TranslateString'),
          PythonClass(module: 'renpy.ast', 'With'),
          PythonClass(module: 'renpy.ast', 'Label'),
          PythonClass(module: 'renpy.ast', 'Pass'),
          PythonClass(module: 'renpy.ast', 'Return'),
        ].contains(ast.klass)) {
      advanceToLine(ast.vars['linenumber']);
    }

    (dispatch[ast.klass] ?? printUnknown)(this, ast);
  }

  void printAtl(PythonClassInstance ast) {
    var out = ATLDecompiler.pprint(
      outSink,
      ast,
      options,
      indentLevel: indentLevel,
      lineNumber: lineNumber,
      skipIndentUntilWrite: skipIndentUntilWrite,
    );

    lineNumber = out.$1;
    outSink = out.$2;
    skipIndentUntilWrite = false;
  }

  bool printImspec(List<dynamic> imspec) {
    String begin = '';
    if (imspec[1] != null) {
      begin = 'expression ${imspec[1].vars['value']}';
    } else {
      begin = imspec[0].join(' ');
    }

    WordConcatenator words = WordConcatenator(
        begin.isNotEmpty && begin.substring(begin.length - 1) != ' ', true);
    if (imspec[2] != null) {
      words.append('as ${imspec[2]}');
    }

    if (imspec[6].length > 0) {
      words.append('behind ${imspec[6].join(', ')}');
    }

    if (imspec[4] is String) {
      words.append('onlayer ${imspec[4]}');
    }

    if (imspec[5] != null) {
      if (imspec[5] is PythonClassInstance) {
        words.append('zorder ${imspec[5].vars['value']}');
      } else {
        words.append('zorder ${imspec[5]}');
      }
    }

    if (imspec[3].length > 0) {
      List<dynamic> rawPositions = imspec[3];
      List<String> positions = [];
      for (dynamic rawPosition in rawPositions) {
        if (rawPosition is String) {
          positions.add(rawPosition);
        } else if (rawPosition is PythonClassInstance) {
          positions.add(rawPosition.vars['value']);
        } else {
          positions.add(rawPosition.toString());
        }
      }

      words.append('at ${positions.join(', ')}');
    }

    write(begin + words.join());
    return words.needsSpace;
  }

  bool sayBelongsToMenu(PythonClassInstance say, PythonClassInstance menu) {
    return ((!say.vars.containsKey('interact') ||
            say.vars['interact'] == false) &&
        (say.vars.containsKey('who') && say.vars['who'] != null) &&
        (!say.vars.containsKey('with_') || say.vars['with_'] == null) &&
        (!say.vars.containsKey('attributes') ||
            say.vars['attributes'] == null) &&
        (menu.klass == PythonClass('Menu', module: 'renpy.ast')) &&
        (menu.vars['items'][0][2] != null) &&
        (!shouldComeBefore(say, menu)));
  }

  void printSayInsideMenu() {
    printSay(sayInsideMenu!, true);
    sayInsideMenu = null;
  }

  void printMenuItem(String label, dynamic condition,
      List<PythonClassInstance>? block, dynamic arguments) {
    indent();
    write('"${stringEscape(label)}"');

    if (arguments != null) {
      write(reconstructArginfo(arguments));
    }

    if (block != null) {
      if (condition is PythonClassInstance &&
          condition.klass == PythonClass('PyExpr', module: 'renpy.ast') &&
          condition.vars['value'] != 'True') {
        condition = condition.vars['value'];
      }

      if (condition != 'True') {
        write(' if $condition');
      }

      write(':');
      printNodes(block, 1);
    }
  }
}
