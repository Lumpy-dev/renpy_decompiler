import 'dart:math';

import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/decompilers/base.dart';
import 'package:renpy_decompiler_backend/decompilers/sl2.dart';
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

const String tab = '    ';

typedef BlankLineCallback = bool Function(int? lineNumber);

class RPYCDecompiler extends DecompilerBase {
  static List<String> pprint(
      List<String> outSink, List<PythonClassInstance> ast,
      {int indentLevel = 0,
      bool decompilePython = false,
      Translator? translator,
      bool initOffset = false,
      bool tagOutsideBlock = false}) {
    RPYCDecompiler builder =
        RPYCDecompiler(outSink: outSink, decompilePython: decompilePython);
    builder.dumpFile(ast, indentLevel, initOffset, tagOutsideBlock);
    outSink = builder.outSink;

    return outSink;
  }

  Map<PythonClass,
          void Function(RPYCDecompiler builder, PythonClassInstance ast)>
      dispatch = {
    PythonClass(module: 'renpy.atl', 'RawMultipurpose'): (builder, ast) {
      WordConcatenator warpWords = WordConcatenator(false);

      if (ast.state!.containsKey('warp_function') &&
          ast.state!['warp_function'] != null) {
        warpWords.append('warp');
        warpWords.append(ast.state!['warp_function']);
        warpWords.append(ast.state!['duration']);
      } else if (ast.state!.containsKey('warper') &&
          ast.state!['warper'] != null) {
        warpWords.append(ast.state!['warper']);
        warpWords.append(ast.state!['duration'].namedArgs['value']);
      } else if (ast.state!.containsKey('duration') &&
          ast.state!['duration'] != '0') {
        warpWords.append(ast.state!['pause']);
      }

      String warp = warpWords.join();
      WordConcatenator words = WordConcatenator(
          warp.isNotEmpty && warp.substring(warp.length - 1) != ' ', true);

      if (ast.state!.containsKey('revolution') &&
          ast.state!['revolution'] != null) {
        words.append(ast.state!['revolution']);
      }

      if (ast.state!.containsKey('circles') && ast.state!['circles'] != '0') {
        words.append('circles ${ast.state!['circles']}');
      }

      WordConcatenator splineWords = WordConcatenator(false);
      for (var entry in ast.state!['splines']) {
        List<dynamic> expressions = entry[1];

        splineWords.append('knot');
        for (var expression in expressions..removeLast()) {
          splineWords.append(expression);
        }
        words.append(splineWords.join());

        WordConcatenator propertyWords = WordConcatenator(false);
        for (var property in ast.state!['properties']) {
          dynamic key = property[0];
          dynamic value = property[1];

          propertyWords.append(key);
          propertyWords.append(value);
        }
        words.append(propertyWords.join());

        WordConcatenator expressionWords = WordConcatenator(false);
        // TODO: There's a lot of cases where pass isn't needed,
        // since we could reorder stuff so there's never 2 expressions in a row.
        // (And it's never necessary for the last one,
        // but we don't know what the last one is since it could get reordered.)
        bool needsPass = ast.state!['expressions'].length > 1;
        for (var entry in ast.state!['expressions']) {
          dynamic expression = entry[0];
          dynamic withExpression = entry[1];

          expressionWords.append(expression);

          if (withExpression != null) {
            expressionWords.append('with');
            expressionWords.append(withExpression);
          }

          if (needsPass) {
            expressionWords.append('pass');
          }
        }
        words.append(expressionWords.join());

        String toWrite = warp + words.join();

        if (toWrite.isNotEmpty) {
          builder.indent();
          builder.write(toWrite);
        } else {
          builder.write(',');
        }
      }
    },
    PythonClass(module: 'renpy.atl', 'RawBlock'): (builder, ast) {
      builder.indent();
      builder.write('block:');
      builder.printAtl(ast);
    },
    PythonClass(module: 'renpy.atl', 'RawChild'): (builder, ast) {
      builder.indent();
      builder.write('contains:');
      builder.printAtl(ast);
    },
    PythonClass(module: 'renpy.atl', 'RawChoice'): (builder, ast) {
      for (var entry in ast.state!['choices']) {
        String chance = entry[0];
        PythonClassInstance block = entry[1];

        builder.indent();
        builder.write('choice');
        if (chance != '1.0') {
          builder.write(' $chance');
        }
        builder.write(':');
        builder.printAtl(block);
      }
      if (builder.index + 1 < builder.block.length &&
          builder.block[builder.index + 1].klass ==
              PythonClass(module: 'renpy.atl', 'RawChoice')) {
        builder.indent();
        builder.write('pass');
      }
    },
    PythonClass(module: 'renpy.atl', 'RawContainsExpr'): (builder, ast) {
      builder.indent();
      builder.write('contains ${ast.state!['expression'].namedArgs['value']}');
    },
    PythonClass(module: 'renpy.atl', 'RawEvent'): (builder, ast) {
      builder.indent();
      builder.write('event ${ast.state!['name']}');
    },
    PythonClass(module: 'renpy.atl', 'RawFunction'): (builder, ast) {
      builder.indent();
      builder.write('function ${ast.state!['expr'].namedArgs['value']}');
    },
    PythonClass(module: 'renpy.atl', 'RawOn'): (builder, ast) {
      for (var entry in (Map.from(ast.state!['handlers']).entries.toList())
        ..sort((a, b) => a.value.namedArgs['loc'][1]
            .compareTo(b.value.namedArgs['loc'][1]))) {
        String name = entry.key;
        PythonClassInstance block = entry.value;

        builder.indent();
        builder.write('on $name:');
        builder.printAtl(block);
      }
    },
    PythonClass(module: 'renpy.atl', 'RawParallel'): (builder, ast) {
      for (var block in ast.state!['blocks']) {
        builder.indent();
        builder.write('parallel:');
        builder.printAtl(block);
      }
      if (builder.index + 1 < builder.block.length &&
          builder.block[builder.index + 1].klass ==
              PythonClass(module: 'renpy.atl', 'RawParallel')) {
        builder.indent();
        builder.write('pass');
      }
    },
    PythonClass(module: 'renpy.atl', 'RawRepeat'): (builder, ast) {
      builder.indent();
      builder.write('repeat');
      if (ast.state!['repeat'] != null) {
        builder.write(
            ' ${ast.state!['repeat']}'); // Not sure if this is even a string, to monitor/test
      }
    },
    PythonClass(module: 'renpy.atl', 'RawTime'): (builder, ast) {
      builder.indent();
      builder.write(
          'time ${ast.state!['time'] is PythonClassInstance ? ast.state!['time'].namedArgs['value'] : ast.state!['time']}');
    },

    // AST
    PythonClass(module: 'renpy.ast', 'Image'): (builder, ast) {
      builder.requireInit();
      builder.indent();
      builder.write('image ${ast.namedArgs['imgname'].join(' ')}');
      if (ast.namedArgs['code'] != null) {
        dynamic val = ast.namedArgs['code'].namedArgs['source'];

        if (val is PythonClassInstance &&
            val.klass == PythonClass(module: 'renpy.ast', 'PyExpr')) {
          val = val.namedArgs['value'];
        }

        builder.write(' = $val');
      } else {
        if (ast.namedArgs.containsKey('atl') && ast.namedArgs['atl'] != null) {
          builder.write(':');
          builder.printAtl(ast.namedArgs['atl']);
        }
      }
    },
    PythonClass(module: 'renpy.ast', 'Transform'): (builder, ast) {
      builder.requireInit();
      builder.indent();

      String priority = '';
      if (builder.parent?.klass == PythonClass(module: 'renpy.ast', 'Init')) {
        PythonClassInstance init = builder.parent!;
        if (init.namedArgs['priority'] != builder.initOffset &&
            init.namedArgs['block'].length != 1 &&
            !builder.shouldComeBefore(init, ast)) {
          priority = ' ${init.namedArgs['priority'] - builder.initOffset}';
        }
      }
      builder.write('transform$priority ${ast.namedArgs['varname']}');
    },
    PythonClass(module: 'renpy.ast', 'Show'): (builder, ast) {
      builder.indent();
      builder.write('show ');
      bool needsSpace = builder.printImspec(ast.namedArgs['imspec']);

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

      if (ast.namedArgs.containsKey('atl') && ast.namedArgs['atl'] != null) {
        builder.write(':');
        builder.printAtl(ast.namedArgs['atl']);
      }
    },
    PythonClass(module: 'renpy.ast', 'ShowLayer'): (builder, ast) {
      builder.indent();
      builder.write('show layer ${ast.namedArgs['layer']}');

      if (ast.namedArgs.containsKey('at_list') &&
          ast.namedArgs['at_list'] != null &&
          ast.namedArgs['at_list'].isNotEmpty) {
        List<dynamic> rawATList = ast.namedArgs['at_list'];
        List<String> atList = [];

        for (var entry in rawATList) {
          if (entry is PythonClassInstance &&
              entry.klass == PythonClass(module: 'renpy.ast', 'PyExpr')) {
            atList.add(entry.namedArgs['value']);
          } else {
            atList.add(entry);
          }
        }

        builder.write(' at ${atList.join(', ')}');
      }

      if (ast.namedArgs.containsKey('atl') && ast.namedArgs['atl'] != null) {
        builder.write(':');
        builder.printAtl(ast.namedArgs['atl']);
      }
    },
    PythonClass(module: 'renpy.ast', 'Scene'): (builder, ast) {
      builder.indent();
      builder.write('scene');

      late bool needsSpace;

      if (!ast.namedArgs.containsKey('imspec') ||
          ast.namedArgs['imspec'] == null) {
        if (ast.namedArgs['layer'] is String) {
          builder.write(' onlayer ${ast.namedArgs['layer']}');
        }
        needsSpace = true;
      } else {
        builder.write(' ');
        needsSpace = builder.printImspec(ast.namedArgs['imspec']);
      }

      if (builder.pairedWith != null && builder.pairedWith != false) {
        if (needsSpace) {
          builder.write(' ');
        }
        builder
            .write('with ${builder.pairedWith}'); // possibly different output.
        builder.pairedWith = true;
      }

      if (ast.namedArgs.containsKey('atl') && ast.namedArgs['atl'] != null) {
        builder.write(':');
        builder.printAtl(ast.namedArgs['atl']);
      }
    },
    PythonClass(module: 'renpy.ast', 'Hide'): (builder, ast) {
      builder.indent();
      builder.write('hide ');
      bool needsSpace = builder.printImspec(ast.namedArgs['imspec']);
      if (builder.pairedWith != null && builder.pairedWith != false) {
        if (needsSpace) {
          builder.write(' ');
        }
        builder.write('with ${builder.pairedWith}');
        builder.pairedWith = true;
      }
    },
    PythonClass(module: 'renpy.ast', 'With'): (builder, ast) {
      if (ast.namedArgs.containsKey('paired') &&
          ast.namedArgs['paired'] != null) {
        if (!(builder.block[builder.index + 2].klass ==
                PythonClass(module: 'renpy.ast', 'With') &&
            builder.block[builder.index + 2].namedArgs['expr'] ==
                ast.namedArgs['paired'])) {
          throw Exception(
              'Unmateched paired with ${builder.pairedWith} != ${ast.namedArgs['expr']}');
        }

        builder.pairedWith = ast.namedArgs['paired'].namedArgs['value'];
      } else if (builder.pairedWith != null) {
        if (builder.pairedWith != true) {
          builder.write(' with ${ast.namedArgs['expr'].namedArgs['value']}');
        }
        builder.pairedWith = false;
      } else {
        builder.advanceToLine(ast.namedArgs['linenumber']);
        builder.indent();
        builder.write('with ${ast.namedArgs['expr']}');
        builder.pairedWith = false;
      }
    },
    PythonClass(module: 'renpy.ast', 'Label'): (builder, ast) {
      if (builder.index != 0 &&
          builder.block[builder.index - 1].klass ==
              PythonClass(module: 'renpy.ast', 'Call')) {
        return;
      }
      int remainingBlocks = builder.block.length - builder.index;
      if (remainingBlocks > 1) {
        PythonClassInstance nextAst = builder.block[builder.index + 1];
        if (ast.namedArgs['block'].isEmpty &&
            (!ast.namedArgs.containsKey('parameters') ||
                ast.namedArgs['parameters'] == null) &&
            (nextAst.klass == PythonClass(module: 'renpy.ast', 'Menu') ||
                (remainingBlocks > 2 &&
                    nextAst.klass == PythonClass(module: 'renpy.ast', 'Say') &&
                    builder.sayBelongsToMenu(
                        nextAst, builder.block[builder.index + 2])))) {
          builder.labelInsideMenu = ast;
          return;
        }
      }

      builder.advanceToLine(ast.namedArgs['linenumber']);
      builder.indent();

      List<String> outSink = builder.outSink;
      builder.outSink = [];
      bool missingInit = builder.missingInit;
      builder.missingInit = false;
      try {
        builder.write(
            'label ${ast.namedArgs['name']}${ast.namedArgs.containsKey('parameters') ? reconstructParaminfo(ast.namedArgs['parameters']) : ''}${ast.namedArgs.containsKey('hide') && ast.namedArgs['hide'] ? ' hide:' : ':'}');
        builder.printNodes(ast.namedArgs['block'], 1);
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
          'jump ${ast.namedArgs.containsKey('expression') && ast.namedArgs['expression'] != null ? 'expression ' : ''}${ast.namedArgs['target'] is PythonClassInstance ? ast.namedArgs['target'].namedArgs['value'] : ast.namedArgs['target']}');
    },
    PythonClass(module: 'renpy.ast', 'Call'): (builder, ast) {
      builder.indent();
      WordConcatenator words = WordConcatenator(false);
      words.append('call');
      if (ast.namedArgs.containsKey('expression') &&
          ast.namedArgs['expression'] == true) {
        words.append('expression');
      }
      if (ast.namedArgs['label'] is PythonClassInstance) {
        words.append(ast.namedArgs['label'].namedArgs['value']);
      } else {
        words.append(ast.namedArgs['label']);
      }

      if (ast.namedArgs.containsKey('arguments') &&
          ast.namedArgs['arguments'] != null) {
        if (ast.namedArgs.containsKey('expression') &&
            ast.namedArgs['expression'] == true) {
          words.append('pass');
        }
        words.append(reconstructArginfo(ast.namedArgs['arguments']));
      }

      PythonClassInstance nextBlock = builder.block[builder.index + 1];

      if (nextBlock.klass == PythonClass(module: 'renpy.ast', 'Label')) {
        words.append('from ${nextBlock.namedArgs['name']}');
      }

      builder.write(words.join());
    },
    PythonClass(module: 'renpy.ast', 'Return'): (builder, ast) {
      if ((!ast.namedArgs.containsKey('expression') ||
              ast.namedArgs['expression'] == null) &&
          builder.parent == null &&
          builder.index + 1 == builder.block.length &&
          builder.index != 0 &&
          ast.namedArgs['linenumber'] ==
              builder.block[builder.index - 1].namedArgs['linenumber']) {
        return;
      }

      builder.advanceToLine(ast.namedArgs['linenumber']);
      builder.indent();
      builder.write('return');

      if (ast.namedArgs.containsKey('expression') &&
          ast.namedArgs['expression'] != null) {
        builder.write(' ${ast.namedArgs['expression'].namedArgs['value']}');
      }
    },
    PythonClass(module: 'renpy.ast', 'If'): (builder, ast) {
      First statement = First(yesValue: 'if', noValue: 'elif');

      for (int i = 0; i < ast.namedArgs['entries'].length; i++) {
        dynamic condition = ast.namedArgs['entries'][i][0];
        List<PythonClassInstance> block =
            List<PythonClassInstance>.from(ast.namedArgs['entries'][i][1]);

        if (i + 1 == ast.namedArgs['entries'].length && condition is! String) {
          builder.indent();
          builder.write('else:');
        } else {
          if (condition is PythonClassInstance &&
              condition.namedArgs.containsKey('linenumber')) {
            builder.advanceToLine(condition.namedArgs['linenumber']);
          }
          builder.indent();
          String call = statement.call();
          if (call == 'elif' && condition == 'True') {
            call = 'else';
          }

          if (condition is PythonClassInstance &&
              condition.klass == PythonClass(module: 'renpy.ast', 'PyExpr')) {
            condition = condition.namedArgs['value'];
          }

          if (call != 'else') {
            builder.write('$call $condition:');
          } else {
            builder.write('$call:');
          }
        }
        builder.printNodes(block, 1);
      }
    },
    PythonClass(module: 'renpy.ast', 'While'): (builder, ast) {
      builder.indent();
      builder.write('while ${ast.namedArgs['condition'].namedArgs['value']}');
      builder.printNodes(ast.namedArgs['block'], 1);
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
          builder.block[builder.index - 2].namedArgs['linenumber'] ==
              ast.namedArgs['linenumber']) {
        return;
      }

      builder.advanceToLine(ast.namedArgs['linenumber']);
      builder.indent();
      builder.write('pass');
    },
    PythonClass(module: 'renpy.ast', 'Init'): (builder, ast) {
      bool inInit = builder.inInit;
      builder.inInit = true;
      try {
        if (ast.namedArgs['block'].length == 1 &&
            ([
                  PythonClass(module: 'renpy.ast', 'Define'),
                  PythonClass(module: 'renpy.ast', 'Default'),
                  PythonClass(module: 'renpy.ast', 'Transform')
                ].contains(ast.namedArgs['block'].first.klass) ||
                (ast.namedArgs['priority'] == -500 + builder.initOffset &&
                    ast.namedArgs['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'Screen')) ||
                (ast.namedArgs['priority'] == builder.initOffset &&
                    ast.namedArgs['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'Style')) ||
                (ast.namedArgs['priority'] == 500 + builder.initOffset &&
                    ast.namedArgs['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'Testcase')) ||
                (ast.namedArgs['priority'] == 0 + builder.initOffset &&
                    ast.namedArgs['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'UserStatement') &&
                    ast.namedArgs['block'].first.namedArgs['line']
                        .startsWith('layeredimage ')) ||
                (ast.namedArgs['priority'] ==
                        (builder.is356c6e34OrLater ? 500 : 990) +
                            builder.initOffset &&
                    ast.namedArgs['block'].first.klass ==
                        PythonClass(module: 'renpy.ast', 'Image'))) &&
            !builder.shouldComeBefore(ast, ast.namedArgs['block'].first)) {
          builder.printNodes(ast.namedArgs['block']);
        } else if (ast.namedArgs['block'].length == 0 &&
            ast.namedArgs['priority'] == builder.initOffset &&
            (ast.namedArgs['block'] as List<PythonClassInstance>).every(
                (element) =>
                    element.klass ==
                    PythonClass(module: 'renpy.ast', 'TranslateString')) &&
            (ast.namedArgs['block'] as List<PythonClassInstance>)
                .sublist(1)
                .every((element) =>
                    element.namedArgs['language'] ==
                    ast.namedArgs['block'].first.namedArgs['language'])) {
          builder.printNodes(ast.namedArgs['block']);
        } else {
          builder.indent();
          builder.write('init');
          if (ast.namedArgs['priority'] != builder.initOffset) {
            builder.write(' ${ast.namedArgs['priority'] - builder.initOffset}');
          }

          if (ast.namedArgs['block'].length == 1 &&
              !builder.shouldComeBefore(ast, ast.namedArgs['block'].first)) {
            builder.write(' ');
            builder.skipIndentUntilWrite = true;
            builder.printNodes(ast.namedArgs['block']);
          } else {
            builder.write(':');
            builder.printNodes(ast.namedArgs['block'], 1);
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
        builder.write(' ${builder.labelInsideMenu!.namedArgs['name']}');
        builder.labelInsideMenu = null;
      }

      if (ast.namedArgs.containsKey('arguments') &&
          ast.namedArgs['arguments'] != null) {
        builder.write(reconstructArginfo(ast.namedArgs['arguments']));
      }

      builder.write(':');

      builder.increaseIndent(() {
        if (ast.namedArgs['with_'] != null) {
          builder.indent();
          builder.write('with ${ast.namedArgs['with_']}');
        }

        if (ast.namedArgs['set'] != null) {
          builder.indent();
          builder.write('set ${ast.namedArgs['set']}');
        }

        List<dynamic> itemArguments;

        if (ast.namedArgs.containsKey('item_arguments')) {
          itemArguments = ast.namedArgs['item_arguments'];
        } else {
          itemArguments =
              List.generate(ast.namedArgs['items'].length, (index) => null);
        }

        for (int i = 0; i < ast.namedArgs['items'].length; i++) {
          String label = ast.namedArgs['items'][i][0];
          dynamic condition = ast.namedArgs['items'][i][1];
          List<PythonClassInstance> block = List<PythonClassInstance>.from(
              ast.namedArgs['items'][i][2] ?? []);

          dynamic arguments = itemArguments[i];
          if (builder.translator != null) {
            label = builder.translator!.strings[label] ?? label;
          }

          RPYCDecompilerState? state;

          if (condition is PythonClassInstance &&
              condition.namedArgs.containsKey('linenumber')) {
            if (builder.sayInsideMenu != null &&
                condition.namedArgs['linenumber'] > builder.lineNumber + 1) {
              builder.printSayInsideMenu();
            }
            builder.advanceToLine(condition.namedArgs['linenumber']);
          } else if (builder.sayInsideMenu != null) {
            state = builder.saveState();
            builder.mostLinesBehind = builder.lastLinesBehind;
            builder.printSayInsideMenu();
          }

          builder.printMenuItem(label, condition, block, arguments);

          if (state != null) {
            if (builder.lastLinesBehind > state.lastLinesBehind) {
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
    PythonClass('Default', module: 'renpy.ast'): (builder, ast) =>
        builder.printDefine(ast),
    PythonClass('Say', module: 'renpy.ast'): (builder, ast) =>
        builder.printSay(ast),
    PythonClass('UserStatement', module: 'renpy.ast'): (builder, ast) {
      builder.indent();
      builder.write(ast.namedArgs['line']);

      if (ast.namedArgs.containsKey('block') &&
          ast.namedArgs['block'].isNotEmpty) {
        builder.increaseIndent(() {
          builder.printLex(ast.namedArgs['block']);
        });
      }
    },
    PythonClass('PostUserStatement', module: 'renpy.ast'): (builder, ast) {},
    PythonClass('Style', module: 'renpy.ast'): (builder, ast) {
      builder.requireInit();
      Map<int, WordConcatenator> keywords = {
        ast.namedArgs['linenumber']: WordConcatenator(false, true)
      };

      if (ast.namedArgs['parent'] != null) {
        keywords[ast.namedArgs['linenumber']]!
            .append('is ${ast.namedArgs['parent']}');
      }
      if (ast.namedArgs['clear']) {
        keywords[ast.namedArgs['linenumber']]!.append('clear');
      }
      if (ast.namedArgs['take'] != null) {
        keywords[ast.namedArgs['linenumber']]!
            .append('take ${ast.namedArgs['take']}');
      }
      for (String delName in ast.namedArgs['delattr']) {
        keywords[ast.namedArgs['linenumber']]!.append('del $delName');
      }

      if (ast.namedArgs['variant'] != null) {
        if (!keywords
            .containsKey(ast.namedArgs['variant'].namedArgs['linenumber'])) {
          keywords[ast.namedArgs['variant'].namedArgs['linenumber']] =
              WordConcatenator(false);
        }
        if (ast.namedArgs['variant'] is PythonClassInstance) {
          keywords[ast.namedArgs['variant'].namedArgs['linenumber']]!
              .append('variant ${ast.namedArgs['variant'].namedArgs['value']}');
        } else {
          keywords[ast.namedArgs['variant'].namedArgs['linenumber']]!
              .append('variant ${ast.namedArgs['variant']}');
        }
      }
      for (var entry in Map.from(ast.namedArgs['properties']).entries) {
        if (!keywords.containsKey(entry.value.namedArgs['linenumber'])) {
          keywords[entry.value.namedArgs['linenumber']] =
              WordConcatenator(false);
        }
        if (entry.value is PythonClassInstance) {
          keywords[entry.value.namedArgs['linenumber']]!
              .append('${entry.key} ${entry.value.namedArgs['value']}');
        } else {
          keywords[entry.value.namedArgs['linenumber']]!
              .append('${entry.key} ${entry.value}');
        }
      }

      List<(int, String)> finalKeywords = [
        for (var entry in keywords.entries) (entry.key, entry.value.join())
      ];

      finalKeywords.sort((a, b) => a.$1.compareTo(b.$1));

      builder.indent();
      builder.write('style ${ast.namedArgs['style_name']}');

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
          'translate to ${ast.namedArgs.containsKey('language') ? (ast.namedArgs['language'] ?? 'None') : 'None'} ${ast.namedArgs['identifier']}');

      builder.printNodes(ast.namedArgs['block'], 1);
    },
    PythonClass('EndTranslate', module: 'renpy.ast'): (builder, ast) {},
    PythonClass('TranslateString', module: 'renpy.ast'): (builder, ast) {
      builder.requireInit();

      if (!(builder.index > 0 &&
          builder.block[builder.index - 1].klass ==
              PythonClass(module: 'renpy.ast', 'TranslateString') &&
          builder.block[builder.index - 1].namedArgs['language'] ==
              ast.namedArgs['language'])) {
        builder.indent();
        builder
            .write('translate ${ast.namedArgs['language'] ?? 'None'} strings:');
      }

      builder.increaseIndent(() {
        builder.advanceToLine(ast.namedArgs['linenumber']);
        builder.indent();
        builder.write('old "${stringEscape(ast.namedArgs['old'])}"');
        if (ast.namedArgs.containsKey('newloc')) {
          builder.advanceToLine(ast.namedArgs['newloc'][1]);
        }
        builder.indent();
        builder.write('new "${stringEscape(ast.namedArgs['new'])}"');
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
      PythonClassInstance screen = ast.namedArgs['screen'];
      if (screen.klass ==
          PythonClass(module: 'renpy.screenlang', 'ScreenLangScreen')) {
        // TODO: Port screen decompiler
        builder.skipIndentUntilWrite = true;

        throw UnimplementedError('screen decompiler not ported yet');
      } else if (screen.klass ==
          PythonClass(module: 'renpy.sl2.slast', 'SLScreen')) {
        // ignore: unused_element
        int printAtlCallback(
            int linenumber, int indentLevel, PythonClassInstance atl) {
          builder.skipIndentUntilWrite = false;

          int oldLineNumber = builder.lineNumber;
          builder.lineNumber = linenumber;
          builder.increaseIndent(() {
            builder.printAtl(atl);
          }, indentLevel - builder.indentLevel);
          int newLineNumber = builder.lineNumber;
          builder.lineNumber = oldLineNumber;
          return newLineNumber;
        }

        var out = SL2Decompiler.pprint(
            builder.outSink, [screen], printAtlCallback,
            indentLevel: builder.indentLevel,
            lineNumber: builder.lineNumber,
            skipIndentUntilWrite: builder.skipIndentUntilWrite,
            tagOutsideBlock: builder.tagOutsideBlock);

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
      builder.write('testcase ${ast.namedArgs['label']}:');
      // TODO: Port testcase decompiler
      builder.skipIndentUntilWrite = false;
      throw UnimplementedError();
    },
  };

  dynamic pairedWith = false;
  PythonClassInstance? sayInsideMenu;
  PythonClassInstance? labelInsideMenu;
  bool inInit = false;
  bool missingInit = false;
  int initOffset = 0;
  bool is356c6e34OrLater = false;
  int mostLinesBehind = 0;
  int lastLinesBehind = 0;
  bool tagOutsideBlock = false;
  bool decompilePython;
  Translator? translator;

  RPYCDecompiler(
      {super.outSink,
      super.indentation,
      this.decompilePython = false,
      this.translator});

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

    if (ast.namedArgs['who'] != null) {
      rv.add(ast.namedArgs['who']);
    }

    if (ast.namedArgs.containsKey('attributes') &&
        ast.namedArgs['attributes'] != null) {
      rv.addAll(List<String>.from(ast.namedArgs['attributes']));
    }

    if (ast.namedArgs.containsKey('temporary_attributes') &&
        ast.namedArgs['temporary_attributes'] != null) {
      rv.add('@');
      rv.addAll(List.from(ast.namedArgs['temporary_attributes']));
    }

    rv.add(encodeSayString(ast.namedArgs['what']));

    if (!ast.namedArgs['interact'] && !inMenu) {
      rv.add('nointeract');
    }

    if (ast.namedArgs['with_'] != null) {
      rv.add('with');
      if (ast.namedArgs['with_'] is PythonClassInstance) {
        rv.add(ast.namedArgs['with_'].namedArgs['value']);
      } else {
        rv.add(ast.namedArgs['with_']);
      }
    }

    if (ast.namedArgs.containsKey('arguments') &&
        ast.namedArgs['arguments'] != null) {
      rv.add(reconstructArginfo(ast.namedArgs['arguments']));
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
    if (ast.namedArgs['code'].namedArgs['source'] is String) {
      code = ast.namedArgs['code'].namedArgs['source'];
    } else {
      code = ast.namedArgs['code'].namedArgs['source'].namedArgs['value'];
    }

    if (code[0] == '\n') {
      code = code.substring(1);
      write('python');
      if (early) {
        write(' early');
      }
      if (ast.namedArgs['hide']) {
        write(' hide');
      }
      if (ast.namedArgs.containsKey('store') &&
          ast.namedArgs['store'] != 'store') {
        write(' in ');
        write(ast.namedArgs['store'].substring(6));
      }
      write(':');

      increaseIndent(() {
        writeLines(splitLogicalLines(code));
      });
    } else {
      write('\$ $code');
    }
  }

  void printDefine(PythonClassInstance ast) {
    requireInit();
    indent();
    String name;
    if (ast.klass == PythonClass(module: 'renpy.ast', 'Default')) {
      name = 'default';
    } else {
      name = 'define';
    }

    String priority = '';
    if (parent?.klass == PythonClass(module: 'renpy.ast', 'Init')) {
      PythonClassInstance init = parent!;
      if (init.namedArgs['priority'] != initOffset &&
          init.namedArgs['block'].length == 1 &&
          !shouldComeBefore(init, ast)) {
        priority = ' ${init.namedArgs['priority'] - initOffset}';
      }
    }
    String index = '';
    if (ast.namedArgs.containsKey('index') && ast.namedArgs['index'] != null) {
      index = ' [${ast.namedArgs['index'].namedArgs['source']}]';
    }
    dynamic val = ast.namedArgs['code'].namedArgs['source'];

    if (val is PythonClassInstance &&
        val.klass == PythonClass(module: 'renpy.ast', 'PyExpr')) {
      val = val.namedArgs['value'];
    }

    if (!ast.namedArgs.containsKey('store') ||
        ast.namedArgs['store'] == 'store') {
      write('$name$priority ${ast.namedArgs['varname']}$index = $val');
    } else {
      write(
          '$name$priority ${ast.namedArgs['store'].substring(6)}.${ast.namedArgs['varname']}$index = $val');
    }
  }

  void printLex(List lex) {
    for (List val in lex) {
      int lineNumber = val[1];
      String content = val[2];
      List<dynamic> block = val[3];

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
    write('translate ${ast.namedArgs['language'] ?? 'None'} ');

    skipIndentUntilWrite = true;

    bool inInit = this.inInit;
    if (ast.namedArgs['block'].length == 1 &&
        [
          PythonClass('Python', module: 'renpy.ast'),
          PythonClass('Style', module: 'renpy.ast')
        ].contains(ast.namedArgs['block'].first.klass)) {
      this.inInit = true;
    }
    try {
      printNodes(ast.namedArgs['block']);
    } finally {
      this.inInit = inInit;
    }
  }

  void dumpFile(dynamic ast,
      [int indentLevel = 0,
      bool initOffset = false,
      bool tagOutsideBlock = false]) {
    if (ast is List &&
        ast.length > 1 &&
        ast.last.klass == PythonClass('Return', module: 'renpy.ast') &&
        (!ast.last.namedArgs.containsKey('expression') ||
            ast.last.namedArgs['expression'] == null) &&
        ast.last.namedArgs['linenumber'] ==
            ast[ast.length - 2].namedArgs['linenumber']) {
      /// Investigate those commits to try to find a workaround
      is356c6e34OrLater = true;
    }

    this.tagOutsideBlock = tagOutsideBlock;

    if (translator != null) {
      translator!.translateDialogue(ast);
    }

    if (initOffset && ast is List) {
      setBestInitOffset(List<PythonClassInstance>.from(ast));
    }

    super.dump(ast, indentLevel, 1, true);

    for (var m in blankLineQueue) {
      m(null);
    }

    assert(!missingInit);
  }

  bool shouldComeBefore(PythonClassInstance a, PythonClassInstance b) {
    return a.namedArgs['linenumber'] < b.namedArgs['linenumber'];
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

      int offset = ast.namedArgs['priority'];
      if (ast.namedArgs['block'].length == 1 &&
          !shouldComeBefore(ast, ast.namedArgs['block'].first)) {
        PythonClassInstance block = ast.namedArgs['block'].first;

        if (block.klass == PythonClass(module: 'renpy.ast', 'Screen')) {
          offset += 500;
        } else if (block.klass ==
            PythonClass(module: 'renpy.ast', 'Testcase')) {
          offset -= 500;
        } else if (block.klass == PythonClass(module: 'renpy.ast', 'Image')) {
          offset -= is356c6e34OrLater ? 500 : 990;
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
    if (ast.namedArgs.containsKey('linenumber') &&
        ![
          PythonClass(module: 'renpy.ast', 'TranslateString'),
          PythonClass(module: 'renpy.ast', 'With'),
          PythonClass(module: 'renpy.ast', 'Label'),
          PythonClass(module: 'renpy.ast', 'Pass'),
          PythonClass(module: 'renpy.ast', 'Return'),
        ].contains(ast.klass)) {
      advanceToLine(ast.namedArgs['linenumber']);
    } else if (ast.namedArgs.containsKey('loc') &&
        ast.klass != PythonClass(module: 'renpy.ast', 'RawBlock')) {
      advanceToLine(ast.namedArgs['loc'][1]);
    }

    dispatch[ast.klass]!(this, ast);
  }

  void printAtl(PythonClassInstance ast) {
    increaseIndent(() {
      advanceToLine(ast.state!['loc'][1]);
      if (ast.state!.containsKey('statements') &&
          ast.state!['statements'] != null) {
        printNodes(ast.state!['statements']);
      } else if (ast.state!['loc'] != ['', 0]) {
        indent();
        write('pass');
      }
    });
  }

  bool printImspec(List<dynamic> imspec) {
    String begin = '';
    if (imspec[1] != null) {
      begin = 'expression ${imspec[1].namedArgs['value']}';
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
        words.append('zorder ${imspec[5].namedArgs['value']}');
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
          positions.add(rawPosition.namedArgs['value']);
        } else {
          throw Exception('Unknown position type');
        }
      }
      words.append('at ${positions.join(', ')}');
    }

    write(begin + words.join());
    return words.needsSpace;
  }

  bool sayBelongsToMenu(PythonClassInstance say, PythonClassInstance menu) {
    return ((!say.namedArgs.containsKey('interact') ||
            !say.namedArgs['interact']) &&
        (say.namedArgs.containsKey('who') &&
            say.namedArgs['who'] != null &&
            say.namedArgs['who'].isNotEmpty) &&
        (!say.namedArgs.containsKey('with_') ||
            say.namedArgs['with_'] != null) &&
        (!say.namedArgs.containsKey('attributes') ||
            say.namedArgs['attributes'] == null) &&
        (menu.klass == PythonClass('Menu', module: 'renpy.ast')) &&
        (menu.namedArgs['items'][0][2] != null) &&
        (!shouldComeBefore(say, menu)));
  }

  void printSayInsideMenu() {
    dispatch[PythonClass(module: 'renpy.ast', 'Say')]!(this, sayInsideMenu!);
  }

  void printMenuItem(String label, dynamic condition,
      List<PythonClassInstance>? block, dynamic arguments) {
    indent();
    write('"${stringEscape(label)}"');

    if (arguments != null) {
      write(reconstructArginfo(arguments));
    }

    if (block != null) {
      if (condition is String && condition != 'True') {
        write(' if $condition');
      }

      write(':');
      printNodes(block, 1);
    }
  }
}
