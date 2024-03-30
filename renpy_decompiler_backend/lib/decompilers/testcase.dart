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
import 'package:renpy_decompiler_backend/decompilers/base.dart';
import 'package:renpy_decompiler_backend/decompilers/rpyc.dart';

class TestcaseDecompiler extends DecompilerBase {
  static (int, List<String>) pprint(
      List<String> outSink, List<PythonClassInstance> ast, OptionBase options,
      {int indentLevel = 0,
      int lineNumber = 1,
      bool skipIndentUntilWrite = false}) {
    TestcaseDecompiler builder =
        TestcaseDecompiler(outSink: outSink, options: options);
    return builder.dump(ast, indentLevel, lineNumber, skipIndentUntilWrite);
  }

  TestcaseDecompiler({required super.outSink, required super.options});

  @override
  void printNode(PythonClassInstance ast) {
    if (ast.vars.containsKey('linenumber')) {
      advanceToLine(ast.vars['linenumber']);
    }
    (dispatch[ast.klass] ?? printUnknown)(this, ast);
  }

  static final Map<PythonClass,
          void Function(TestcaseDecompiler builder, PythonClassInstance ast)>
      dispatch = {
    PythonClass('Python', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      String code = ast.vars['code'].vars['source'].vars['value'];
      if (code[0] == '\n') {
        builder.write('python:');
        builder.increaseIndent(() {
          builder.writeLines(splitLogicalLines(code.substring(1)));
        });
      } else {
        builder.write('\$ $code');
      }
    },
    PythonClass('If', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write('if ${ast.vars['condition']}:');
      builder.printNodes(ast.vars['block'], 1);
    },
    PythonClass('Assert', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write('assert ${ast.vars['expr'].vars['value']}');
    },
    PythonClass('Jump', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write('jump ${ast.vars['target']}');
    },
    PythonClass('Call', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write('call ${ast.vars['target']}');
    },
    PythonClass('Action', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write('run ${ast.vars['expr'].vars['value']}');
    },
    PythonClass('Pause', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write('pause ${ast.vars['expr'].vars['value']}');
    },
    PythonClass('Label', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write('label ${ast.vars['name']}');
    },
    PythonClass('Type', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      if (ast.vars['keys'].first.length == 1) {
        builder.write(
            'type "${RPYCDecompiler.stringEscape(ast.vars['keys'].join(''))}"');
      } else {
        builder.write('type ${ast.vars['keys'].first}');
      }
      if (ast.vars['pattern'] != null) {
        builder.write(
            ' pattern "${RPYCDecompiler.stringEscape(ast.vars['pattern'])}"');
      }
      if (ast.vars.containsKey('position') && ast.vars['position'] != null) {
        builder.write(' pos ${ast.vars['position']}');
      }
    },
    PythonClass('Drag', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write('drag ${ast.vars['points']}');
      if (ast.vars['button'] != 1) {
        builder.write(' button ${ast.vars['button']}');
      }
      if (ast.vars['pattern'] != null) {
        builder.write(
            ' pattern "${RPYCDecompiler.stringEscape(ast.vars['pattern'])}"');
      }
      if (ast.vars['steps'] != 10) {
        builder.write(' steps ${ast.vars['steps']}');
      }
    },
    PythonClass('Move', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write('move ${ast.vars['position']}');
      if (ast.vars['pattern'] != null) {
        builder.write(
            ' pattern "${RPYCDecompiler.stringEscape(ast.vars['pattern'])}"');
      }
    },
    PythonClass('Click', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      if (ast.vars['pattern'] != null) {
        builder.write('"${RPYCDecompiler.stringEscape(ast.vars['pattern'])}"');
      } else {
        builder.write('click');
      }
      if (ast.vars.containsKey('button') && ast.vars['button'] != 1) {
        builder.write(' button ${ast.vars['button']}');
      }
      if (ast.vars.containsKey('position') && ast.vars['position'] != null) {
        builder.write(' pos ${ast.vars['position']}');
      }
      if (ast.vars.containsKey('always') && ast.vars['always'] == true) {
        builder.write(' always');
      }
    },
    PythonClass('Scroll', module: 'renpy.test.testast'): (builder, ast) {
      builder.indent();
      builder.write(
          'scroll "${RPYCDecompiler.stringEscape(ast.vars['pattern'])}"');
    },
    PythonClass('Until', module: 'renpy.test.testast'): (builder, ast) {
      if (ast.vars['right'].vars.containsKey('linenumber')) {
        builder.advanceToLine(ast.vars['right'].vars['linenumber']);
      }
      builder.printNode(ast.vars['left']);
      builder.write(' until ');
      builder.skipIndentUntilWrite = true;
      builder.printNode(ast.vars['right']);
    },
  };
}
