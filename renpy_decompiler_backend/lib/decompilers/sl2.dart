// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// The license of codegen.py is included in the file itself.
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/decompilers/atl.dart';
import 'package:renpy_decompiler_backend/decompilers/base.dart';
import 'package:renpy_decompiler_backend/decompilers/rpyc.dart';

class SL2Decompiler extends DecompilerBase<Options> {
  static (int, List<String>) pprint(
      List<String> outSink, PythonClassInstance ast, Options options,
      {int indentLevel = 0,
      int lineNumber = 1,
      bool skipIndentUntilWrite = false}) {
    return SL2Decompiler(outSink: outSink, options: options)
        .dump(ast, indentLevel, lineNumber, skipIndentUntilWrite);
  }

  SL2Decompiler({super.outSink, required super.options});

  static final Map<PythonClass,
          void Function(SL2Decompiler builder, PythonClassInstance ast)>
      dispatch = {
    PythonClass('SLScreen', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write('screen ${ast.vars['name']}');

      if (ast.vars['parameters'] != null) {
        builder.write(reconstructParaminfo(ast.vars['parameters']));
      }

      var (first: firstLine, others: otherLines) =
          builder.sortKeywordsAndChildren(ast);

      builder.printKeywordOrChild(firstLine, true, otherLines.isNotEmpty);

      if (otherLines.isNotEmpty) {
        builder.increaseIndent(() {
          for (var line in otherLines) {
            builder.printKeywordOrChild(line);
          }
        });
      }
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
      if (ast.vars['variable'] == '_sl2_i') {
        variable = ast.vars['children'].first.vars['code'].vars['source'];
        variable = variable.substring(0, variable.length - 9);
        children = ast.vars['children'].sublist(1);
      } else {
        variable = ast.vars['variable'].trim() + ' ';
        children = ast.vars['children'];
      }

      builder.indent();
      if (ast.vars.containsKey('index_expression') &&
          ast.vars['index_expression'] != null) {
        builder.write(
            'for ${variable}index ${ast.vars['index_expression']} in ${ast.vars['expression'].vars['value']}:');
      } else {
        builder.write(
            'for ${variable}in ${ast.vars['expression'].vars['value']}:');
      }

      builder.printNodes(children, 1);
    },
    PythonClass('SLContinue', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write('continue');
    },
    PythonClass('SLBreak', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write('break');
    },
    PythonClass('SLPython', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();

      dynamic code = ast.vars['code'].vars['source'];
      if (code is PythonClassInstance) {
        code = code.vars['value'];
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
      String args = reconstructArginfo(ast.vars['args']);
      if (ast.vars['target'] is PythonClassInstance &&
          ast.vars['target'].klass ==
              PythonClass('PyExpr', module: 'renpy.ast')) {
        builder.write('expression ${ast.vars['target'].vars['value']}');
        if (args.isNotEmpty) {
          builder.write(' pass ');
        }
      } else {
        builder.write(ast.vars['target']);
      }

      builder.write(args);
      if (ast.vars.containsKey('id') && ast.vars['id'] != null) {
        builder.write(' id ${ast.vars['id']}');
      }

      if (ast.vars.containsKey('block') && ast.vars['block'] != null) {
        builder.printBlock(ast.vars['block']);
      }
    },
    PythonClass('SLTransclude', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write('transclude');
    },
    PythonClass('SLDefault', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.indent();
      builder.write(
          'default ${ast.vars['variable']} = ${ast.vars['expression'].vars['value']}');
    },
    PythonClass('SLDisplayable', module: 'renpy.sl2.slast'): (builder, ast) {
      builder.printDisplayable(ast);
    },
  };

  void printIf(PythonClassInstance ast, String keyword) {
    First<String> keywordFirst =
        First<String>(yesValue: keyword, noValue: 'elif');

    for (var [condition, block] in ast.vars['entries']) {
      advanceToLine(block.vars['location'][1]);
      indent();

      if (condition == null) {
        write('else');
      } else {
        if (condition is PythonClassInstance) {
          condition = condition.vars['value'];
        }

        write('${keywordFirst.call()} $condition');
      }

      printBlock(block, true);
    }
  }

  void printBlock(PythonClassInstance ast, [bool immediateBlock = false]) {
    var (first: firstLine, others: otherLines) =
        sortKeywordsAndChildren(ast, true);
    bool hasBlock = immediateBlock || otherLines.isNotEmpty;

    printKeywordOrChild(firstLine, true, hasBlock);

    if (otherLines.isNotEmpty) {
      increaseIndent(() {
        for (var line in otherLines) {
          printKeywordOrChild(line, false, hasBlock);
        }
      });
    } else if (immediateBlock) {
      increaseIndent(() {
        indent();
        write('pass');
      });
    }
  }

  void printDisplayable(PythonClassInstance ast, {bool hasBlock = false}) {
    var key = (ast.vars['displayable'], ast.vars['style']);
    var nameAndChildren =
        displayableNames.containsKey(key) ? displayableNames[key] : null;

    if (nameAndChildren == null && options.slCustomNames != null) {
      nameAndChildren = options.slCustomNames![ast.vars['displayable']];
    }

    if (nameAndChildren == null) {
      nameAndChildren = (ast.vars['style'], 'many');
      printDebug('''
      Warning: We encountered a user-defined displayable of type
      '${ast.vars['displayable']}'.
      Unfortunately, the name of user-defined displayables is not recorded in
      the compiled file. For now the style name '${ast.vars['style']}' will be
      substituted.
      To check if this is correct, find the corresponding
      renpy.register_sl_displayable call.\n
      ''');
    }

    var (name, children) = nameAndChildren;
    indent();
    write(name);
    if (ast.vars['positional'].isNotEmpty) {
      List<dynamic> rawPositions = ast.vars['positional'];
      List<String> positions = [];

      for (var i in rawPositions) {
        if (i is PythonClassInstance) {
          if (i.klass == PythonClass('PyExpr', module: 'renpy.ast')) {
            positions.add(i.vars['value']);
          } else {
            positions.add(i.vars['name']);
          }
        } else {
          positions.add(i);
        }
      }

      write(' ${positions.join(' ')}');
    }

    var atlTransform = ast.vars.containsKey('atl_transform')
        ? ast.vars['atl_transform']
        : null;

    if (!hasBlock &&
        children == 1 &&
        ast.vars['children'].length == 1 &&
        ast.vars['children'].first.klass ==
            PythonClass('SLDisplayable', module: 'renpy.sl2.slast') &&
        ast.vars['children'].first.vars['children'].isNotEmpty &&
        (ast.vars['keyword'].isEmpty ||
            ast.vars['children'].first.vars['location'][1] >
                ast.vars['keyword'].last[1].vars['linenumber']) &&
        (atlTransform == null ||
            ast.vars['children'].first.vars['location'][1] >
                atlTransform.vars['loc'][1])) {
      var (first: firstLine, others: otherLines) =
          sortKeywordsAndChildren(ast, false, true);
      printKeywordOrChild(firstLine, true, true);

      increaseIndent(() {
        for (var line in otherLines) {
          printKeywordOrChild(line);
        }

        advanceToLine(ast.vars['children'].first.vars['location'][1]);
        indent();
        write('has ');
        skipIndentUntilWrite = true;
        printDisplayable(ast.vars['children'].first, hasBlock: true);
      });
    } else if (hasBlock) {
      var (first: firstLine, others: otherLines) = sortKeywordsAndChildren(ast);
      printKeywordOrChild(firstLine, true, false);
      for (var line in otherLines) {
        printKeywordOrChild(line);
      }
    } else {
      var (first: firstLine, others: otherLines) = sortKeywordsAndChildren(ast);
      printKeywordOrChild(firstLine, true, otherLines.isNotEmpty);

      increaseIndent(() {
        for (var line in otherLines) {
          printKeywordOrChild(line);
        }
      });
    }
  }

  /// When updating this map, please swap the modules to their full form (in the imports)
  Map<(PythonClass, dynamic), (String, dynamic)> displayableNames = {
    (PythonClass('AreaPicker', module: 'renpy.display.behavior'), "default"): (
      "areapicker",
      1
    ),
    (PythonClass('Button', module: 'renpy.display.behavior'), "button"): (
      "button",
      1
    ),
    (
      PythonClass('DismissBehavior', module: 'renpy.display.behavior'),
      "default"
    ): ("dismiss", 0),
    (PythonClass('Input', module: 'renpy.display.behavior'), "input"): (
      "input",
      0
    ),
    (PythonClass('MouseArea', module: 'renpy.display.behavior'), 0): (
      "mousearea",
      0
    ),
    (PythonClass('MouseArea', module: 'renpy.display.behavior'), null): (
      "mousearea",
      0
    ),
    (PythonClass('OnEvent', module: 'renpy.display.behavior'), 0): ("on", 0),
    (PythonClass('OnEvent', module: 'renpy.display.behavior'), null): ("on", 0),
    (PythonClass('Timer', module: 'renpy.display.behavior'), "default"): (
      "timer",
      0
    ),
    (PythonClass('Drag', module: 'renpy.display.dragdrop'), "drag"): (
      "drag",
      1
    ),
    (PythonClass('Drag', module: 'renpy.display.dragdrop'), null): ("drag", 1),
    (PythonClass('DragGroup', module: 'renpy.display.dragdrop'), null): (
      "draggroup",
      'many'
    ),
    (PythonClass('image', module: 'renpy.display.im'), "default"): ("image", 0),
    (PythonClass('Grid', module: 'renpy.display.layout'), "grid"): (
      "grid",
      'many'
    ),
    (PythonClass('MultiBox', module: 'renpy.display.layout'), "fixed"): (
      "fixed",
      'many'
    ),
    (PythonClass('MultiBox', module: 'renpy.display.layout'), "hbox"): (
      "hbox",
      'many'
    ),
    (PythonClass('MultiBox', module: 'renpy.display.layout'), "vbox"): (
      "vbox",
      'many'
    ),
    (PythonClass('NearRect', module: 'renpy.display.layout'), "default"): (
      "nearrect",
      1
    ),
    (PythonClass('Null', module: 'renpy.display.layout'), "default"): (
      "null",
      0
    ),
    (PythonClass('Side', module: 'renpy.display.layout'), "side"): (
      "side",
      'many'
    ),
    (PythonClass('Window', module: 'renpy.display.layout'), "frame"): (
      "frame",
      1
    ),
    (PythonClass('Window', module: 'renpy.display.layout'), "window"): (
      "window",
      1
    ),
    (PythonClass('Transform', module: 'renpy.display.motion'), "transform"): (
      "transform",
      1
    ),
    (PythonClass('sl2add', module: 'renpy.sl2.sldisplayables'), null): (
      "add",
      0
    ),
    (PythonClass('sl2bar', module: 'renpy.sl2.sldisplayables'), null): (
      "bar",
      0
    ),
    (PythonClass('sl2vbar', module: 'renpy.sl2.sldisplayables'), null): (
      "vbar",
      0
    ),
    (
      PythonClass('sl2viewport', module: 'renpy.sl2.sldisplayables'),
      "viewport"
    ): ("viewport", 1),
    (PythonClass('sl2vpgrid', module: 'renpy.sl2.sldisplayables'), "vpgrid"): (
      "vpgrid",
      'many'
    ),
    (PythonClass('Text', module: 'renpy.text.text'), "text"): ("text", 0),
    (PythonClass('Transform', module: 'renpy.display.transform'), "transform"):
        ("transform", 1),
    (PythonClass('_add', module: 'renpy.ui'), null): ("add", 0),
    (PythonClass('_hotbar', module: 'renpy.ui'), "hotbar"): ("hotbar", 0),
    (PythonClass('_hotspot', module: 'renpy.ui'), "hotspot"): ("hotspot", 1),
    (PythonClass('_imagebutton', module: 'renpy.ui'), "image_button"): (
      "imagebutton",
      0
    ),
    (PythonClass('_imagemap', module: 'renpy.ui'), "imagemap"): (
      "imagemap",
      'many'
    ),
    (PythonClass('_key', module: 'renpy.ui'), null): ("key", 0),
    (PythonClass('_label', module: 'renpy.ui'), "label"): ("label", 0),
    (PythonClass('_textbutton', module: 'renpy.ui'), "button"): (
      "textbutton",
      0
    ),
    (PythonClass('_textbutton', module: 'renpy.ui'), 0): ("textbutton", 0),
  };

  @override
  void printNode(PythonClassInstance ast) {
    advanceToLine(ast.vars['location'][1]);
    (dispatch[ast.klass] ?? printUnknown)(this, ast);
  }

  ({dynamic first, List others}) sortKeywordsAndChildren(
      PythonClassInstance node,
      [bool immediateBlock = false,
      bool ignoreChildren = false]) {
    List keywords = node.vars['keyword'];
    List children = ignoreChildren ? [] : node.vars['children'];

    int blockLineno = node.vars['location'][1];
    int startLineno = immediateBlock ? (blockLineno + 1) : blockLineno;

    String? keywordTag = node.vars['tag'];
    String? keywordAs = node.vars['variable'];
    PythonClassInstance? atlTransform = node.vars['atl_transform'];

    List<(int?, String, (String?, PythonClassInstance?))> keywordsByLine = [
      for (var [name, value] in keywords)
        (
          value?.vars['linenumber'],
          value != null && value.vars['value'].isNotEmpty
              ? 'keyword'
              : 'broken',
          (name, value)
        )
    ];

    List<(int, String, PythonClassInstance)> childrenByLine = [
      for (PythonClassInstance entry in children)
        (entry.vars['location'][1], 'child', entry)
    ];

    List contentsInOrder = [];
    keywordsByLine = List.from(keywordsByLine.reversed);
    childrenByLine = List.from(childrenByLine.reversed);
    while (keywordsByLine.isNotEmpty && childrenByLine.isNotEmpty) {
      if (keywordsByLine.last.$1 == null) {
        contentsInOrder.add(keywordsByLine.removeLast());
      } else if ((keywordsByLine.last.$1 ?? -1) < childrenByLine.last.$1) {
        contentsInOrder.add(keywordsByLine.removeLast());
      } else {
        contentsInOrder.add(childrenByLine.removeLast());
      }
    }

    while (keywordsByLine.isNotEmpty) {
      contentsInOrder.add(keywordsByLine.removeLast());
    }

    while (childrenByLine.isNotEmpty) {
      contentsInOrder.add(childrenByLine.removeLast());
    }

    if (atlTransform != null) {
      int atlLineno = atlTransform.vars['loc'][1];

      int? index;

      for (int i = 0; i < contentsInOrder.length; i++) {
        int? lineno = contentsInOrder[i].$1;

        if (lineno != null && atlLineno < lineno) {
          index = i;
          break;
        }
      }

      index ??= contentsInOrder.length;

      contentsInOrder.insert(index, (atlLineno, 'atl', atlTransform));
    }

    (int?, String, List)? currentKeywordLine;

    List contentsGrouped = [];

    for (var currentContents in contentsInOrder) {
      int? lineno = currentContents.$1;
      String ty = currentContents.$2;
      dynamic content = currentContents.$3;
      if (currentKeywordLine == null) {
        if (ty == 'child') {
          contentsGrouped.add((lineno, 'child', content));
        } else if (ty == 'keyword') {
          currentKeywordLine = (lineno, 'keywords', [content]);
        } else if (ty == 'broken') {
          contentsGrouped.add((lineno, 'keywords_broken', [], content));
        } else if (ty == 'atl') {
          contentsGrouped.add((lineno, 'keywords_atl', [], content));
        }
      } else {
        if (ty == 'child') {
          contentsGrouped.add(currentKeywordLine);
          currentKeywordLine = null;
          contentsGrouped.add((lineno, 'child', content));
        } else if (ty == 'keyword') {
          if (currentKeywordLine.$1 == lineno) {
            currentKeywordLine.$3.add(content);
          } else {
            contentsGrouped.add(currentKeywordLine);
            currentKeywordLine = (lineno, 'keywords', [content]);
          }
        } else if (ty == 'broken') {
          contentsGrouped.add((
            currentKeywordLine.$1,
            'keywords_broken',
            currentKeywordLine.$3,
            content
          ));
        } else if (ty == 'atl') {
          if (currentKeywordLine.$1 == lineno) {
            contentsGrouped
                .add((lineno, 'keywords_atl', currentKeywordLine.$3, content));
            currentKeywordLine = null;
          } else {
            contentsGrouped.add(currentKeywordLine);
            currentKeywordLine = null;
            contentsGrouped.add((lineno, 'keywords_atl', [], content));
          }
        }
      }
    }

    if (currentKeywordLine != null) {
      contentsGrouped.add(currentKeywordLine);
    }

    for (int i = 0; i < contentsGrouped.length; i++) {
      int? lineno = contentsGrouped[i].$1;
      String ty = contentsGrouped[i].$2;
      if (ty == 'keywords_broken' && lineno == null) {
        List contents = contentsGrouped[i].$4;

        if (i != 0) {
          lineno = contentsGrouped[i - 1].$1 + 1;
        } else {
          lineno = startLineno;
        }

        contentsGrouped[i] = (lineno, 'keywords_broken', [], contents);
      }
    }

    if (keywordTag != null && keywordTag.isNotEmpty) {
      if (contentsGrouped.isEmpty) {
        contentsGrouped
            .add((blockLineno + 1, 'keywords', [('tag', keywordTag)]));
      } else if ((contentsGrouped.first.$1 ?? -1) > blockLineno + 1) {
        contentsGrouped
            .insert(0, (blockLineno + 1, 'keywords', [('tag', keywordTag)]));
      } else {
        bool addedTag = false;

        for (var entry in contentsGrouped) {
          if (entry.$2.startsWith('keywords')) {
            addedTag = true;
            entry.$3.add(('tag', keywordTag));
            break;
          }
        }

        if (!addedTag) {
          contentsGrouped
              .insert(0, (blockLineno + 1, 'keywords', [('tag', keywordTag)]));
        }
      }
    }

    if (keywordAs != null && keywordAs.isNotEmpty) {
      if (contentsGrouped.isEmpty) {
        contentsGrouped.add((blockLineno + 1, 'keywords', [('as', keywordAs)]));
      } else if ((contentsGrouped.first.$1 ?? -1) > blockLineno + 1) {
        contentsGrouped
            .insert(0, (blockLineno + 1, 'keywords', [('as', keywordAs)]));
      } else if (contentsGrouped.first.$1 ?? -1 > startLineno) {
        contentsGrouped
            .insert(0, (startLineno, 'keywords', [('as', keywordAs)]));
      } else {
        bool addedAs = false;

        for (var entry in contentsGrouped) {
          if (entry.$2.startsWith('keywords')) {
            addedAs = true;
            entry.$3.add(('as', keywordAs));
            break;
          }
        }

        if (!addedAs) {
          contentsGrouped
              .insert(0, (startLineno, 'keywords', [('as', keywordAs)]));
        }
      }
    }

    if (immediateBlock ||
        contentsGrouped.isEmpty ||
        contentsGrouped.first.$1 != blockLineno) {
      contentsGrouped.insert(0, (blockLineno, 'keywords', []));
    }

    return (first: contentsGrouped.first, others: contentsGrouped.sublist(1));
  }

  void printKeywordOrChild(dynamic item,
      [bool firstLine = false, bool hasBlock = false]) {
    First sep = First(yesValue: firstLine ? ' ' : '', noValue: ' ');

    int lineno = item.$1;
    String ty = item.$2;

    if (ty == 'child') {
      printNode(item.$3);
      return;
    }

    if (!firstLine) {
      advanceToLine(lineno);
      indent();
    }

    for (var (String key, dynamic value) in item.$3) {
      write(sep.call());
      write('$key ${value is String ? value : value.vars['value']}');
    }

    if (ty == 'keyboards_atl') {
      assert(!hasBlock,
          'cannot start a block on the same line as an at transform block');
      write(sep.call());
      write('at transform:');

      var out = ATLDecompiler.pprint(outSink, item.$4, options,
          indentLevel: indentLevel,
          lineNumber: lineNumber,
          skipIndentUntilWrite: skipIndentUntilWrite);

      lineNumber = out.$1;
      outSink = out.$2;
      skipIndentUntilWrite = false;
      return;
    }

    if (ty == 'keywords_broken') {
      write(sep.call());
      write(item.$4.$1);
    }

    if (firstLine && hasBlock) {
      write(':');
    }
  }
}
