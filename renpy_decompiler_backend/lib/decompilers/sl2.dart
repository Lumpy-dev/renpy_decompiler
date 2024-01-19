import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/decompilers/base.dart';

typedef PrintATLCallback = int Function(
    int lineNumber, int indentLevel, PythonClassInstance atl);

class SL2Decompiler extends DecompilerBase {
  static (int, List<String>) pprint(List<String> outSink,
      List<PythonClassInstance> ast, PrintATLCallback callback,
      {int indentLevel = 0,
      int lineNumber = 0,
      bool skipIndentUntilWrite = false,
      bool tagOutsideBlock = false}) {
    return SL2Decompiler(
            outSink: outSink,
            tagOutsideBlock: tagOutsideBlock,
            printATLCallback: callback)
        .dump(ast, indentLevel, lineNumber, skipIndentUntilWrite);
  }

  PrintATLCallback printATLCallback;
  bool tagOutsideBlock;

  SL2Decompiler(
      {super.outSink,
      super.indentation,
      this.tagOutsideBlock = false,
      required this.printATLCallback});

  Map<PythonClass,
          void Function(SL2Decompiler builder, PythonClassInstance ast)>
      dispatch = {
    PythonClass('SLScreen', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write('screen ${ast.namedArgs['name']}');

      if (ast.namedArgs['parameters'] != null) {
        builder.write(reconstructParaminfo(ast.namedArgs['parameters']));
      }

      builder.printKeywordsAndChildren(ast.namedArgs['keyword'],
          ast.namedArgs['children'], ast.namedArgs['location'][1],
          tag: ast.namedArgs['tag'],
          atlTransform: ast.namedArgs.containsKey('atl_transform')
              ? ast.namedArgs['atl_transform']
              : null);
    },
    PythonClass('SLIf', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.printIf(ast, 'if');
    },
    PythonClass('SLShowIf', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.printIf(ast, 'showif');
    },
    PythonClass('SLBlock', module: 'renpy.sl2.slast'): (builder, ast) =>
        builder.printBlock(ast),
    PythonClass('SLFor', module: 'renpy.sl2.slast'): (builder, ast) {
      String variable;
      List<dynamic> children;
      if (ast.namedArgs['variable'] == '_sl2_i') {
        variable = ast
            .namedArgs['children'].first.namedArgs['code'].namedArgs['source'];
        variable = variable.substring(0, variable.length - 9);
        children = ast.namedArgs['children'].sublist(1);
      } else {
        variable = ast.namedArgs['variable'].trim() + ' ';
        children = ast.namedArgs['children'];
      }

      builder.indent();
      if (ast.namedArgs.containsKey('index_expression') &&
          ast.namedArgs['index_expression'] != null) {
        builder.write(
            'for ${variable}index ${ast.namedArgs['index_expression']} in ${ast.namedArgs['expression'].namedArgs['value']}:');
      } else {
        builder.write(
            'for ${variable}in ${ast.namedArgs['expression'].namedArgs['value']}:');
      }

      builder.printNodes(children, 1);
    },
    PythonClass('SLPython', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();

      dynamic code = ast.namedArgs['code'].namedArgs['source'];
      if (code is PythonClassInstance) {
        code = code.namedArgs['value'];
      }
      if (code.startsWith('\n')) {
        code = code.substring(1);
        builder.write('python:');
        builder.increaseIndent(() {
          builder.writeLines(splitLogicalLines(code));
        });
      } else {
        builder.write('\$ $code');
      }
    },
    PythonClass('Pass', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write('pass');
    },
    PythonClass('SLUse', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write('use ');
      String args = reconstructArginfo(ast.namedArgs['args']);
      if (ast.namedArgs['target'] is PythonClassInstance &&
          ast.namedArgs['target'].klass ==
              PythonClass('PyExpr', module: 'renpy.ast')) {
        builder
            .write('expression ${ast.namedArgs['target'].namedArgs['value']}');
        if (args.isNotEmpty) {
          builder.write(' pass ');
        }
      } else {
        builder.write(ast.namedArgs['target']);
      }

      builder.write(args);
      if (ast.namedArgs.containsKey('id') && ast.namedArgs['id'] != null) {
        builder.write(' id ${ast.namedArgs['id']}');
      }

      if (ast.namedArgs.containsKey('block') &&
          ast.namedArgs['block'] != null) {
        builder.write(':');
        builder.printBlock(ast.namedArgs['block']);
      }
    },
    PythonClass('SLTransclude', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write('transclude');
    },
    PythonClass('SLDefault', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write(
          'default ${ast.namedArgs['variable']} = ${ast.namedArgs['expression'].namedArgs['value']}');
    },
    PythonClass('SLDisplayable', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.printDisplayable(ast);
    },
  };

  void printIf(PythonClassInstance ast, String keyword) {
    First<String> keywordFirst =
        First<String>(yesValue: keyword, noValue: 'elif');

    for (var i in ast.namedArgs['entries']) {
      var condition = i[0];
      PythonClassInstance block = i[1];

      advanceToLine(block.namedArgs['location'][1]);
      indent();

      if (condition == null || condition == 'True') {
        write('else:');
      } else {
        if (condition is PythonClassInstance) {
          condition = condition.namedArgs['value'];
        }

        write('${keywordFirst.call()} $condition:');
      }

      if (block.namedArgs['keyword'].isNotEmpty ||
          block.namedArgs['children'].isNotEmpty ||
          (block.namedArgs.containsKey('atl_transform') &&
              block.namedArgs['atl_transform'].isNotEmpty)) {
        printBlock(block);
      } else {
        increaseIndent(() {
          indent();
          write('pass');
        });
      }
    }
  }

  void printBlock(PythonClassInstance ast) {
    printKeywordsAndChildren(
        ast.namedArgs['keyword'], ast.namedArgs['children'], null,
        atlTransform: ast.namedArgs.containsKey('atl_transform')
            ? ast.namedArgs['atl_transform']
            : null);
  }

  void printDisplayable(PythonClassInstance ast, {bool hasBlock = false}) {
    var key = (ast.namedArgs['displayable'].name, ast.namedArgs['style']);
    var nameAndChildren =
        displayableNames.containsKey(key) ? displayableNames[key] : null;
    if (nameAndChildren == null) {
      nameAndChildren = (ast.namedArgs['style'], 'many');
      printDebug('''
      Warning: We encountered a user-defined displayable of type
      '{ast.displayable}'.
      Unfortunately, the name of user-defined displayables is not recorded in
      the compiled file. For now the style name '${ast.namedArgs['style']}' will be
      substituted.
      To check if this is correct, find the corresponding
      renpy.register_sl_displayable call.\n
      ''');
    }
    var name = nameAndChildren.$1;
    var children = nameAndChildren.$2;
    indent();
    write(name);
    if (ast.namedArgs['positional'].isNotEmpty) {
      List<dynamic> rawPositions = ast.namedArgs['positional'];
      List<String> positions = [];

      for (var i in rawPositions) {
        if (i is PythonClassInstance) {
          if (i.klass == PythonClass('PyExpr', module: 'renpy.ast')) {
            positions.add(i.namedArgs['value']);
          } else {
            positions.add(i.namedArgs['name']);
          }
        } else {
          positions.add(i);
        }
      }

      write(' ${positions.join(' ')}');
    }
    String? variable;

    if (ast.namedArgs.containsKey('variable')) {
      variable = ast.namedArgs['variable'];
    }
    var atlTransform = ast.namedArgs.containsKey('atl_transform')
        ? ast.namedArgs['atl_transform']
        : null;

    if (!hasBlock &&
        children == 1 &&
        ast.namedArgs['children'].length == 1 &&
        ast.namedArgs['children'].first.klass ==
            PythonClass('SLDisplayable', module: 'renpy.sl2.slast') &&
        ast.namedArgs['children'].first.namedArgs['children'].isNotEmpty &&
        (ast.namedArgs['keyword'].isEmpty ||
            ast.namedArgs['children'].first.namedArgs['location'][1] >
                ast.namedArgs['keyword'].last[1].namedArgs['linenumber']) &&
        (atlTransform == null ||
            ast.namedArgs['children'].first.namedArgs['location'][1] >
                atlTransform.namedArgs['loc'][1])) {
      printKeywordsAndChildren(
          ast.namedArgs['keyword'], [], ast.namedArgs['location'][1],
          needsColon: true, variable: variable, atlTransform: atlTransform);
      advanceToLine(ast.namedArgs['children'].first.namedArgs['location'][1]);
      increaseIndent(() {
        indent();
        write('has ');
        skipIndentUntilWrite = true;
        printDisplayable(ast.namedArgs['children'].first, hasBlock: true);
      });
    } else {
      printKeywordsAndChildren(ast.namedArgs['keyword'],
          ast.namedArgs['children'], ast.namedArgs['location'][1],
          hasBlock: hasBlock, variable: variable, atlTransform: atlTransform);
    }
  }

  Map<(String, dynamic), (String, dynamic)> displayableNames = {
    ('AreaPicker', "default"): ("areapicker", 1),
    ('Button', "button"): ("button", 1),
    ('DismissBehavior', "default"): ("dismiss", 0),
    ('Input', "input"): ("input", 0),
    ('MouseArea', null): ("mousearea", 0),
    ('MouseArea', 0): ("mousearea", 0),
    ('OnEvent', null): ("on", 0),
    ('OnEvent', 0): ("on", 0),
    ('Timer', "default"): ("timer", 0),
    ('Drag', null): ("drag", 1),
    ('Drag', "drag"): ("drag", 1),
    ('DragGroup', null): ("draggroup", 'many'),
    ('image', "default"): ("image", 0),
    ('Grid', "grid"): ("grid", 'many'),
    ('MultiBox', "fixed"): ("fixed", 'many'),
    ('MultiBox', "hbox"): ("hbox", 'many'),
    ('MultiBox', "vbox"): ("vbox", 'many'),
    ('NearRect', "default"): ("nearrect", 0),
    ('Null', "default"): ("null", 0),
    ('Side', "side"): ("side", 'many'),
    ('Window', "frame"): ("frame", 1),
    ('Window', "window"): ("window", 1),
    ('Transform', "transform"): ("transform", 1),
    ('Text', "text"): ("text", 0),
    ('sl2add', null): ("add", 0),
    ('sl2bar', null): ("bar", 0),
    ('sl2vbar', null): ("vbar", 0),
    ('sl2viewport', "viewport"): ("viewport", 1),
    ('sl2vpgrid', "vpgrid"): ("vpgrid", 'many'),
    ('_add', null): ("add", 0),
    ('_hotbar', "hotbar"): ("hotbar", 0),
    ('_hotspot', "hotspot"): ("hotspot", 1),
    ('_key', null): ("key", 0),
    ('_imagebutton', "image_button"): ("imagebutton", 0),
    ('_imagemap', "imagemap"): ("imagemap", 'many'),
    ('_label', "label"): ("label", 0),
    ('_textbutton', 0): ("textbutton", 0),
    ('_textbutton', "button"): ("textbutton", 0)
  };

  @override
  void printNode(PythonClassInstance ast) {
    advanceToLine(ast.namedArgs['location'][1]);
    dispatch[ast.klass]!(this, ast);
  }

  void printKeywordsAndChildren(
      List<dynamic> keywords, List<dynamic> children, int? lineNo,
      {bool needsColon = false,
      bool hasBlock = false,
      String? tag,
      String? variable,
      PythonClassInstance? atlTransform}) {
    bool wroteColon = false;
    List<(int?, dynamic)> keywordsByLine = [];
    (int?, List) currentLine = (lineNo, []);
    List<String> keywordsSomewhere = [];
    if (variable != null) {
      if (currentLine.$1 == null) {
        keywordsSomewhere.addAll(['as', variable]);
      } else {
        currentLine = (currentLine.$1, [...currentLine.$2, 'as', variable]);
      }
    }
    if (tag != null) {
      if (currentLine.$1 == null || !tagOutsideBlock) {
        keywordsSomewhere.addAll(['tag', tag]);
      } else {
        currentLine = (currentLine.$1, [...currentLine.$2, 'tag', tag]);
      }
    }

    bool forceNewline = false;
    for (var i in keywords) {
      String key = i[0];
      PythonClassInstance? value = i[1];
      if (variable == null) {
        if (currentLine.$1 == null || forceNewline) {
          forceNewline = false;
          keywordsByLine.add(currentLine);
          currentLine = (0, []);
        }

        forceNewline = true;

        currentLine = (currentLine.$1, [...currentLine.$2, key]);
      } else {
        if (currentLine.$1 == null ||
            value?.namedArgs['linenumber'] > currentLine.$1 ||
            forceNewline) {
          forceNewline = false;
          keywordsByLine.add(currentLine);
          currentLine = (value?.namedArgs['linenumber'], []);
        }

        currentLine = (currentLine.$1, [...currentLine.$2, key, value]);
      }
    }

    if (keywordsByLine.isNotEmpty) {
      if (forceNewline) {
        keywordsByLine.add(currentLine);
        currentLine = (0, []);
      }

      currentLine = (currentLine.$1, [...currentLine.$2, ...keywordsSomewhere]);
      keywordsSomewhere.clear();
    }

    keywordsByLine.add(currentLine);
    var lastKeywordLine = keywordsByLine.last.$1;
    List<(int?, dynamic)> childrenWithKeywords = [];
    List childrenAfterKeywords = [];

    for (PythonClassInstance i in children) {
      if (lastKeywordLine == null ||
          i.namedArgs['location'][1] > lastKeywordLine) {
        childrenAfterKeywords.add(i);
      } else {
        childrenWithKeywords.add((i.namedArgs['location'][1], i));
      }
    }

    var blockContents = (keywordsByLine.sublist(1) + childrenWithKeywords)
      ..sort((a, b) => a.$1!.compareTo(b.$1!));
    if (keywordsByLine.first.$2.isNotEmpty) {
      write(' ${keywordsByLine.first.$2.join(' ')}');
    }
    if (keywordsSomewhere.isNotEmpty) {
      if (lineNo != null) {
        write(':');
        wroteColon = true;
      }
      bool completed = true;
      for (int index = 0; index < childrenAfterKeywords.length; index++) {
        var child = childrenAfterKeywords[index];
        if (child.namedArgs['location'][1] > lineNumber + 1) {
          increaseIndent(() {
            indent();
            write(keywordsSomewhere.join(' '));
          });
          printNodes(childrenAfterKeywords.sublist(index), hasBlock ? 0 : 1);
          completed = false;
          break;
        }
        increaseIndent(() {
          printNode(child);
        });
      }
      if (completed) {
        increaseIndent(() {
          indent();
          write(keywordsSomewhere.join(' '));
        });
      }
    } else {
      if (blockContents.isNotEmpty ||
          (!hasBlock && childrenAfterKeywords.isNotEmpty)) {
        if (lineNo != null) {
          write(':');
          wroteColon = true;
        }
        increaseIndent(() {
          for (var i in blockContents) {
            if (i.$2 is List) {
              advanceToLine(i.$1!);
              indent();
              write(i.$2.join(' '));
            } else {
              printNode(i.$2);
            }
          }
        });
      } else if (needsColon) {
        write(':');
        wroteColon = true;
      }
      printNodes(childrenAfterKeywords, hasBlock ? 0 : 1);
    }

    if (atlTransform != null) {
      if (!wroteColon && lineNo != null) {
        write(':');
      }
      increaseIndent(() {
        indent();
        write('at transform:');
        lineNumber = printATLCallback(lineNumber, indentLevel, atlTransform);
      });
    }
  }
}
