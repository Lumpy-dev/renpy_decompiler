import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/decompilers/base.dart';

class ATLDecompiler extends DecompilerBase<OptionBase> {
  static (int, List<String>) pprint(
      List<String> outSink, PythonClassInstance ast, OptionBase options,
      {int indentLevel = 0,
      int lineNumber = 1,
      bool skipIndentUntilWrite = false}) {
    return ATLDecompiler(outSink: outSink, options: options)
        .dump(ast, indentLevel, lineNumber, skipIndentUntilWrite);
  }

  ATLDecompiler({required super.outSink, required super.options});

  static final Map<PythonClass,
          void Function(ATLDecompiler builder, PythonClassInstance ast)>
      dispatch = {
    PythonClass(module: 'renpy.atl', 'RawMultipurpose'): (builder, ast) {
      WordConcatenator warpWords = WordConcatenator(false);

      if (ast.vars.containsKey('warp_function') &&
          ast.vars['warp_function'] != null) {
        warpWords.append('warp');
        warpWords.append(ast.vars['warp_function']);
        warpWords.append(ast.vars['duration'].vars['value']);
      } else if (ast.vars.containsKey('warper') && ast.vars['warper'] != null) {
        warpWords.append(ast.vars['warper']);
        warpWords.append(ast.vars['duration'].vars['value']);
      } else if (ast.vars.containsKey('duration') &&
          ast.vars['duration'] != '0') {
        warpWords.append('pause');
        warpWords.append(ast.vars['duration'].vars['value']);
      }

      String warp = warpWords.join();
      WordConcatenator words =
          WordConcatenator(warp.isNotEmpty && !warp.endsWith(' '), true);

      if (ast.vars.containsKey('revolution') &&
          ast.vars['revolution'] != null) {
        words.append(ast.vars['revolution']);
      }

      if (ast.vars.containsKey('circles') && ast.vars['circles'] != '0') {
        words.append('circles ${ast.vars['circles'].vars['value']}');
      }

      WordConcatenator splineWords = WordConcatenator(false);
      for (var [name, expressions] in ast.vars['splines']) {
        splineWords.append(name);
        splineWords.append(expressions.removeLast());
        for (var expression in expressions) {
          splineWords.append('knot');
          splineWords.append(expression);
        }
      }
      words.append(splineWords.join());

      WordConcatenator propertyWords = WordConcatenator(false);
      for (var [key, value] in ast.vars['properties']) {
        propertyWords.append(key);
        propertyWords.append(value.vars['value']);
      }
      words.append(propertyWords.join());

      WordConcatenator expressionWords = WordConcatenator(false);
      // TODO: There's a lot of cases where pass isn't needed,
      // since we could reorder stuff so there's never 2 expressions in a row.
      // (And it's never necessary for the last one,
      // but we don't know what the last one is since it could get reordered.)
      bool needsPass = ast.vars['expressions'].length > 1;
      for (var [expression, withExpression] in ast.vars['expressions']) {
        expressionWords.append(expression.vars['value']);

        if (withExpression != null) {
          expressionWords.append('with');
          expressionWords.append(withExpression.vars['value']);
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
    },
    PythonClass(module: 'renpy.atl', 'RawBlock'): (builder, ast) {
      builder.indent();
      builder.write('block:');
      builder.printBlock(ast);
    },
    PythonClass(module: 'renpy.atl', 'RawChild'): (builder, ast) {
      for (var child in ast.vars['children']) {
        builder.advanceToBlock(child);
        builder.indent();
        builder.write('contains:');
        builder.printBlock(ast);
      }
    },
    PythonClass(module: 'renpy.atl', 'RawChoice'): (builder, ast) {
      for (var entry in ast.vars['choices']) {
        String chance = entry[0];
        PythonClassInstance block = entry[1];

        builder.advanceToBlock(block);
        builder.indent();
        builder.write('choice');
        if (chance != '1.0') {
          builder.write(' $chance');
        }
        builder.write(':');
        builder.printBlock(block);
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
      builder.write('contains ${ast.vars['expression'].vars['value']}');
    },
    PythonClass(module: 'renpy.atl', 'RawEvent'): (builder, ast) {
      builder.indent();
      builder.write('event ${ast.vars['name']}');
    },
    PythonClass(module: 'renpy.atl', 'RawFunction'): (builder, ast) {
      builder.indent();
      builder.write('function ${ast.vars['expr'].vars['value']}');
    },
    PythonClass(module: 'renpy.atl', 'RawOn'): (builder, ast) {
      for (var entry in (Map.from(ast.vars['handlers']).entries.toList())
        ..sort((a, b) =>
            a.value.vars['loc'][1].compareTo(b.value.vars['loc'][1]))) {
        String name = entry.key;
        PythonClassInstance block = entry.value;

        builder.advanceToBlock(block);
        builder.indent();
        builder.write('on $name:');
        builder.printBlock(block);
      }
    },
    PythonClass(module: 'renpy.atl', 'RawParallel'): (builder, ast) {
      for (var block in ast.vars['blocks']) {
        builder.advanceToBlock(block);
        builder.indent();
        builder.write('parallel:');
        builder.printBlock(block);
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
      if (ast.vars['repeat'] != null) {
        builder.write(
            ' ${ast.vars['repeat']}'); // Not sure if this is even a string, to monitor/test
      }
    },
    PythonClass(module: 'renpy.atl', 'RawTime'): (builder, ast) {
      builder.indent();
      builder.write(
          'time ${ast.vars['time'] is PythonClassInstance ? ast.vars['time'].vars['value'] : ast.vars['time']}');
    },
  };

  @override
  (int, List<String>) dump(ast,
      [int indentLevel = 0,
      int lineNumber = 1,
      bool skipIndentUntilWrite = false]) {
    this.indentLevel = indentLevel;
    this.lineNumber = lineNumber;
    this.skipIndentUntilWrite = skipIndentUntilWrite;

    printBlock(ast);
    return (this.lineNumber, outSink);
  }

  @override
  void printNode(PythonClassInstance ast) {
    if (ast.vars.containsKey('loc')) {
      if (ast.klass == PythonClass(module: 'renpy.atl', 'RawBlock')) {
        advanceToBlock(ast);
      } else {
        advanceToLine(ast.vars['loc'][1]);
      }
    }

    (dispatch[ast.klass] ?? printUnknown)(this, ast);
  }

  void printBlock(PythonClassInstance block) {
    increaseIndent(() {
      if (block.vars['statements'] != null &&
          block.vars['statements'].isNotEmpty) {
        printNodes(block.vars['statements']);
      } else if (block.vars['loc'] != ['', 0]) {
        indent();
        write('pass');
      }
    });
  }

  void advanceToBlock(PythonClassInstance block) {
    if (block.vars['loc'] != ['', 0]) {
      advanceToLine(block.vars['loc'][1] - 1);
    }
  }
}
