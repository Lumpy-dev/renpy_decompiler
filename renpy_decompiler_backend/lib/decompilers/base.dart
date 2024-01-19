import 'package:pickle_decompiler/pickle_decompiler.dart';

typedef BlankLineCallback = bool Function(int? lineNumber);

typedef BaseDecompilerState = ({
  List<String> outSink,
  bool skipIndentUntilWrite,
  int lineNumber,
  List<dynamic> blockStack,
  List<dynamic> indexStack,
  int indentLevel,
  List<BlankLineCallback> blankLineQueue
});

class DecompilerBase {
  List<String> outSink;
  String indentation;
  bool skipIndentUntilWrite = false;

  int lineNumber = 0;

  List<dynamic> blockStack = [];
  List<dynamic> indexStack = [];
  List<BlankLineCallback> blankLineQueue = [];

  int indentLevel = 0;

  DecompilerBase({this.outSink = const [], this.indentation = '    '});

  /// Write the decompiled representation of `ast` into the opened file given in the
  /// constructor
  (int, List<String>) dump(dynamic ast,
      [int indentLevel = 0,
      int lineNumber = 1,
      bool skipIndentUntilWrite = false]) {
    this.indentLevel = indentLevel;
    this.lineNumber = lineNumber;
    this.skipIndentUntilWrite = skipIndentUntilWrite;
    if (ast is! List) {
      ast = [ast];
    }
    printNodes(ast);
    return (this.lineNumber, outSink);
  }

  void increaseIndent(void Function() code, [int amount = 1]) {
    indentLevel += amount;
    try {
      code();
    } finally {
      indentLevel -= amount;
    }
  }

  /// Shorthand method for writing `string` to the file
  void write(String string) {
    lineNumber += '\n'.allMatches(string).length;
    skipIndentUntilWrite = false;
    if (string.contains('renpy.ast.PyExpr')) {
      print('Outputted a raw renpy.ast.PyExpr');
    }
    outSink.add(string);
  }

  /// Write each line in lines to the file without writing whitespace-only lines
  void writeLines(List<String> lines) {
    for (String line in lines) {
      if (line == '') {
        write('\n');
      } else {
        indent();
        write(line);
      }
    }
  }

  /// Save our current state
  dynamic saveState() {
    BaseDecompilerState state = (
      outSink: outSink,
      skipIndentUntilWrite: skipIndentUntilWrite,
      lineNumber: lineNumber,
      blockStack: blockStack,
      indexStack: indexStack,
      indentLevel: indentLevel,
      blankLineQueue: blankLineQueue
    );
    outSink = [];
    return state;
  }

  /// Commit changes since a saved state
  void commitState(dynamic state) {
    var stateOutSink = state.outSink;
    stateOutSink.addAll(outSink);
    outSink = stateOutSink;
  }

  /// Roll back to a saved state
  void rollbackState(dynamic state) {
    outSink = state.outSink;
    skipIndentUntilWrite = state.skipIndentUntilWrite;
    lineNumber = state.lineNumber;
    blockStack = state.blockStack;
    indexStack = state.indexStack;
    indentLevel = state.indentLevel;
    blankLineQueue = state.blankLineQueue;
  }

  void advanceToLine(int lineNumber) {
    blankLineQueue = blankLineQueue.where((m) => m(lineNumber)).toList();
    if (this.lineNumber < lineNumber) {
      write('\n' * (lineNumber - this.lineNumber - 1));
    }
  }

  /// Do something the next time we find a blank line. m should be a method that takes
  /// one parameter (the line we're advancing to), and returns whether or not it needs
  /// to run again.
  void doWhenBlankLine(BlankLineCallback m) {
    blankLineQueue.add(m);
  }

  /// Shorthand method for pushing a newline and indenting to the proper indent level
  /// Setting skip_indent_until_write causes calls to this method to be ignored until
  /// something calls the write method
  void indent() {
    if (!skipIndentUntilWrite) {
      write('\n${indentation * indentLevel}');
    }
  }

  void printNodes(List<dynamic> ast, [int extraIndent = 0]) {
    ast = List<PythonClassInstance>.from(ast);

    increaseIndent(() {
      blockStack.add(ast);
      indexStack.add(0);

      for (int i = 0; i < ast.length; i++) {
        PythonClassInstance node = ast[i];
        indexStack.last = i;
        printNode(node);
      }

      blockStack.removeLast();
      indexStack.removeLast();
    }, extraIndent);
  }

  List<PythonClassInstance> get block => blockStack.last;
  int get index => indexStack.last;
  PythonClassInstance? get parent {
    if (blockStack.length < 2) {
      return null;
    } else {
      return blockStack[blockStack.length - 2]
          [indexStack[indexStack.length - 2]];
    }
  }

  void printDebug(String message) {
    print(message);
  }

  void writeFailure(String message) {
    print(message);
    indent();
    write('pass # <<<COULD NOT DECOMPILE: $message>>>');
  }

  void printUnknownNode(PythonClassInstance ast) {
    writeFailure('Unknown AST node: ${ast.klass}');
  }

  void printNode(PythonClassInstance ast) {
    throw UnimplementedError();
  }
}

class WordConcatenator {
  bool needsSpace;
  bool reorderable;
  List<String> words = [];

  WordConcatenator(this.needsSpace, [this.reorderable = false]);

  void append(String word) {
    words.add(word);
  }

  String join() {
    if (words.isEmpty) {
      return '';
    }
    if (reorderable && words.last[words.last.length - 1] == ' ') {
      for (int i = words.length - 1; i >= 0; i--) {
        if (words[i][words[i].length - 1] != ' ') {
          words.add(words.removeLast());
          break;
        }
      }
    }
    String lastWord = words.last;
    words = [
      for (String x in words.sublist(0, words.length - 1))
        if (x[x.length - 1] == ' ') x.substring(0, x.length - 1) else x
    ];
    words.add(lastWord);
    String rv = (needsSpace ? ' ' : '') + words.join(' ');
    needsSpace = rv[rv.length - 1] != ' ';
    return rv;
  }
}

class First<T> {
  final T yesValue;
  final T noValue;
  bool first = true;

  First({required this.yesValue, required this.noValue});

  T call() {
    if (this.first) {
      this.first = false;
      return this.yesValue;
    } else {
      return this.noValue;
    }
  }
}

String reconstructParaminfo(PythonClassInstance? paraminfo) {
  if (paraminfo == null || (paraminfo.state ?? {}).isEmpty) {
    return '';
  }

  List<String> rv = ['('];

  First sep = First<String>(yesValue: '', noValue: ', ');
  List<dynamic> positional = [
    for (var i in paraminfo.state!['parameters'])
      if (paraminfo.state!['positional'].contains(i[0])) i
  ];
  List<dynamic> nameOnly = [
    for (var i in paraminfo.state!['parameters'])
      if (!positional.contains(i)) i
  ];

  for (var parameter in positional) {
    rv.add(sep.call());
    rv.add(parameter[0]);
    if (parameter[1] != null) {
      rv.add('=${paraminfo.state!['extrapos']}');
    }
  }
  if (paraminfo.state!.containsKey('extrapos') &&
      paraminfo.state!['extrapos'] != null) {
    rv.add(sep.call());
    rv.add('*${paraminfo.state!['extrapos']}');
  }
  if (nameOnly.isNotEmpty) {
    if (!paraminfo.state!.containsKey('extrapos') ||
        paraminfo.state!['extrapos'] == null) {
      rv.add(sep.call());
      rv.add('*');
    }
    for (var parameter in nameOnly) {
      rv.add(sep.call());
      rv.add(parameter[0]);
      if (parameter[1] != null) {
        rv.add('=${parameter[1]}');
      }
    }
  }
  if (paraminfo.state!.containsKey('extrakw') &&
      paraminfo.state!['extrakw'] != null) {
    rv.add(sep.call());
    rv.add('**${paraminfo.state!['extrakw']}');
  }
  rv.add(')');

  return rv.join();
}

String reconstructArginfo(PythonClassInstance? arginfo) {
  if (arginfo == null) {
    return '';
  }

  List<String> rv = ['('];

  First sep = First<String>(yesValue: '', noValue: ', ');

  List arguments;
  if ((arginfo.state ?? {}).containsKey('named_args') &&
      arginfo.namedArgs.containsKey('arguments')) {
    arguments = arginfo.namedArgs['arguments'];
  } else {
    arguments = [];
  }

  for (var entry in arguments) {
    String? name = entry[0];
    dynamic val = entry[1];

    rv.add(sep.call());
    if (name != null) {
      rv.add('$name=');
    }
    rv.add(val);
  }
  if (arginfo.namedArgs.containsKey('extrapos') &&
      arginfo.namedArgs['extrapos'] != null) {
    rv.add(sep.call());
    rv.add('*${arginfo.namedArgs['extrapos']}');
  }
  if (arginfo.namedArgs.containsKey('extrakw') &&
      arginfo.namedArgs['extrakw'] != null) {
    rv.add(sep.call());
    rv.add('**${arginfo.namedArgs['extrakw']}');
  }

  rv.add(')');

  return rv.join();
}

List<String> splitLogicalLines(String s) {
  return Lexer(s).splitLogicalLines();
}

final wordRegexp = RegExp(r'[a-zA-Z_\u00a0-\ufffd][0-9a-zA-Z_\u00a0-\ufffd]*');
final keywords = {
  '\$',
  'as',
  'at',
  'behind',
  'call',
  'expression',
  'hide',
  'if',
  'in',
  'image',
  'init',
  'jump',
  'menu',
  'onlayer',
  'python',
  'return',
  'scene',
  'set',
  'show',
  'with',
  'while',
  'zorder',
  'transform'
};

class Lexer {
  int pos = 0;
  late int length;
  String string;

  Lexer(this.string) {
    length = string.length;
  }

  String? re(RegExp reexp) {
    if (length == pos) {
      return null;
    }

    reexp = RegExp(reexp.pattern, dotAll: true);

    Match? match = reexp.matchAsPrefix(string, pos);
    if (match == null) {
      return null;
    }

    pos = match.end;
    return match.group(0);
  }

  bool eol() {
    re(RegExp(r'(\s+|\\\n)+'));
    return pos >= length;
  }

  String? match(RegExp reexp) {
    re(RegExp(r'(\s+|\\\n)+'));
    return re(reexp);
  }

  String? pythonString([bool clearWhitespace = true]) {
    final regex = RegExp(
      r'u?' // optional unicode prefix (u)
      r'(?<a>' // capture beginning quote
      r'"("")?|' // double quotes
      r"'('')?" // or single quotes
      r')' // end quote capture
      r'.*?' // any string content
      r'(?<=[^\ ])(\\)*' // ensure end quote is not escaped
      r'\k<a>', // double or single quote, matching beginning
      multiLine: true,
    );
    if (clearWhitespace) {
      return match(regex);
    } else {
      return re(regex);
    }
  }

  bool? container() {
    Map<String, String> containers = {'{': '}', '[': ']', '(': ')'};
    if (eol()) {
      return null;
    }

    String c = string[pos];
    if (!containers.containsKey(c)) {
      return null;
    }
    pos++;

    c = containers[c]!;

    while (!eol()) {
      if (c == string[pos]) {
        pos++;
        return true;
      }

      if ((pythonString() ?? '').isNotEmpty || (container() ?? false)) {
        continue;
      }

      pos++;
    }

    return null;
  }

  String? number() {
    return match(RegExp(r'([+\-])?(\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?'));
  }

  String? word() {
    return match(wordRegexp)!;
  }

  String? name() {
    int pos = this.pos;
    String? word = this.word();

    if (keywords.contains(word)) {
      this.pos = pos;
      return null;
    }

    return word;
  }

  bool singleExpression() {
    if (eol()) {
      return false;
    }

    if (!(pythonString() != null ||
        number() != null ||
        (container() ?? false) ||
        name() != null)) {
      return false;
    }

    while (!eol()) {
      if (match(RegExp(r'\.')) != null) {
        if (name() == null) {
          return false;
        }

        continue;
      }

      if (container() ?? false) {
        continue;
      }

      break;
    }

    return eol();
  }

  List<String> splitLogicalLines() {
    List<String> lines = [];

    int contained = 0;

    int startPos = pos;

    while (pos < length) {
      String c = string[pos];

      if (c == '\n' &&
          contained == 0 &&
          (pos == 0 || string[pos - 1] != '\\')) {
        lines.add(string.substring(startPos, pos));
        pos++;
        startPos = pos;
        continue;
      }

      if ({'(', '[', '{'}.contains(c)) {
        contained++;
        pos++;
        continue;
      }

      if ({')', ']', '}'}.contains(c) && contained > 0) {
        contained--;
        pos++;
        continue;
      }

      if (c == '#') {
        re(RegExp(r'[^\n]*'));
        continue;
      }

      if (pythonString(false) != null) {
        continue;
      }

      re(RegExp(r'\w+| +|.'));
    }

    if (pos != startPos) {
      lines.add(string.substring(startPos));
    }
    return lines;
  }
}
