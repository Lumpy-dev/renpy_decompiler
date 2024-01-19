// Cannot find an example of screen to decompile.

/*
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/decompilers/base.dart';

typedef SLDecompilerState = ({
  BaseDecompilerState baseState,
  bool shouldAdvanceToLine,
  bool isRoot,
});

class SLDecompiler extends DecompilerBase {
  static (int, List<String>) pprint(List<String> outSink, List<PythonClassInstance> ast,
      {int indentLevel = 0,
      int lineNumber = 0,
      bool skipIndentUntilWrite = false,
      bool decompilePython = false}) {
    return SLDecompiler(
            outSink: outSink)
        .dump(ast, indentLevel, lineNumber, skipIndentUntilWrite);
  }
  
  bool decompilePython;
  bool shouldAdvanceToLine = true;
  bool isRoot = true;
  
  SLDecompiler(
      {super.outSink,
      super.indentation,
      this.decompilePython = false,
      });
  
  Map<PythonClass,
          void Function(SLDecompiler builder, PythonClassInstance ast)>
      dispatch = {};

  @override
  (int, List<String>) dump(ast, [int indentLevel = 0, int lineNumber = 1, bool skipIndentUntilWrite = false]) {
    this.indentLevel = indentLevel;
    this.lineNumber = lineNumber;
    this.skipIndentUntilWrite = skipIndentUntilWrite;
    printScreen(ast);

    return (this.lineNumber, outSink);
  }

  @override
  void advanceToLine(int lineNumber) {
    if(shouldAdvanceToLine) {
      super.advanceToLine(lineNumber);
    }
  }

  @override
  SLDecompilerState saveState() {
    return (baseState: super.saveState(), shouldAdvanceToLine: shouldAdvanceToLine, isRoot: isRoot);
  }

  @override
  void commitState(state) {
    super.commitState(state.baseState);
  }

  @override
  void rollbackState(state) {
    shouldAdvanceToLine = state.shouldAdvanceToLine;
    isRoot = state.isRoot;
    super.rollbackState(state.baseState);
  }

  String toSource(PythonClassInstance node) {
    throw UnimplementedError('codegen has not been ported yet');
  }

  void notRoot(void Function() callback) {
    bool isRoot = this.isRoot;
    this.isRoot = false;
    try {
      callback();
    } finally {
      this.isRoot = isRoot;
    }
  }

  void printScreen(PythonClassInstance ast) {
    indent();
    write('screen ${ast.namedArgs['name']}');

    if(ast.namedArgs.containsKey('parameters') && ast.namedArgs['parameters'] != null) {
      write(reconstructParaminfo(ast.namedArgs['parameters']));
    }

    if(ast.namedArgs['tag'] != null) {
      write(' tag ${ast.namedArgs['tag']}');
    }

    Map<int, WordConcatenator> keywords = {ast.namedArgs['code'].namedArgs['location'][1]: WordConcatenator(false, true)};
    for(String key in ['modal', 'zorder', 'variant', 'predict']) {
      var value = ast.namedArgs[key];

      if(value is PythonClassInstance && value.klass == PythonClass('PyExpr', module: 'renpy.ast')) {
        if(!keywords.containsKey(value.namedArgs['linenumber'])) {
          keywords[value.namedArgs['linenumber']] = WordConcatenator(false, true);
        }
        keywords[value.namedArgs['linenumber']]!.append('$key ${value.namedArgs['value']}');
      }
    }
    List<(int, String)> newKeywords = [
      for(var entry in keywords.entries)
        (entry.key, entry.value.join())
    ];
    newKeywords.sort((a, b) => a.$1.compareTo(b.$1));
    if(decompilePython) {
      printKeywordsAndNodes(keywords, null, true);
      increaseIndent(() {
        indent();
        write('python:');
        increaseIndent(() {
          writeLines(toSource(ast.namedArgs['code'].namedArgs['source']).split('\n').sublist(1));
        });
      });
    } else {
      printKeywordsAndNodes(keywords, null, true);
    }
  }

  List<List<PythonClassInstance>> splitNodesAtHeaders(List<PythonClassInstance> nodes) {
    if(nodes.isEmpty) {
      return [];
    }
    List<List<PythonClassInstance>> rv = [nodes.sublist(0, 1)];
    int? parentId = parseHeader(nodes.first);
    if(parentId == null) {
      throw Exception("First node passed to split_nodes_at_headers was not a header");
    }
    for(PythonClassInstance i in nodes.sublist(1)) {
      if(parseHeader(i) == parentId) {
        rv.add([i]);
      } else {
        rv.last.add(i);
      }
    }
    return rv;
  }

  @override
  void printNodes(List ast, [int extraIndent = 0, bool hasBlock = false]) {
    if(hasBlock && ast.isEmpty) {
      // BadHasBlockException
      return;
    }
    var split = splitNodesAtHeaders(List<PythonClassInstance>.from(ast));
    increaseIndent(() {
      for(var i in split) {
        printNode(i[0], i.sublist(1), hasBlock);
      }
    }, extraIndent);
  }

  int getFirstLine(List<PythonClassInstance> nodes) {
    if(getDispatchKey(nodes.first)) {
      return nodes.first.namedArgs['value'].namedArgs['lineno'];
    } else if (isRenpyFor(nodes)) {
      return nodes[1].namedArgs['target'].namedArgs['lineno'];
    } else if(isRenpyIf(nodes)) {
      return nodes.first.namedArgs['test'].namedArgs['lineno'];
    } else {
      return nodes.first.namedArgs['lineno'];
    }
  }


}
*/
