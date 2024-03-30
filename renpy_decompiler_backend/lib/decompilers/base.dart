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

class OptionBase {
  String indentation;

  /// TODO: Find the type for [printLock]
  dynamic printLock;

  OptionBase({this.indentation = '    ', this.printLock});
}

class DecompilerBase<O extends OptionBase> {
  List<String> outSink;
  bool skipIndentUntilWrite = false;

  int lineNumber = 0;

  List<dynamic> blockStack = [];
  List<dynamic> indexStack = [];
  List<BlankLineCallback> blankLineQueue = [];

  int indentLevel = 0;

  O options;

  DecompilerBase({this.outSink = const [], required this.options});

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

  /// Shorthand method for writing [string] to the file
  void write(dynamic string) {
    string = string.toString();
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
      write('\n${options.indentation * indentLevel}');
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

  void printUnknown(PythonClassInstance ast) {
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
    if (word.isNotEmpty) {
      words.add(word);
    }
  }

  String join() {
    if (words.isEmpty) {
      return '';
    }
    if (reorderable &&
        words.last.isNotEmpty &&
        words.last[words.last.length - 1] == ' ') {
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
        if (x.isNotEmpty && x[x.length - 1] == ' ')
          x.substring(0, x.length - 1)
        else
          x
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
  if (paraminfo == null || paraminfo.vars.isEmpty) {
    return '';
  }

  List<String> rv = ['('];

  First sep = First<String>(yesValue: '', noValue: ', ');

  if (paraminfo.vars.containsKey('positional_only')) {
    Set<String> alreadyAccounted = {
      for (var (name, _) in paraminfo.vars['positional_only']) name,
      for (var (name, _) in paraminfo.vars['keyword_only']) name
    };
    List<({String name, String? defaultVal})> other = [
      for (var [name, defaultVal] in paraminfo.vars['parameters'])
        if (!alreadyAccounted.contains(name))
          (name: name, defaultVal: defaultVal)
    ];

    for (var [name, defaultVal] in paraminfo.vars['positional_only']) {
      rv.add(sep.call());
      rv.add(name);
      if (defaultVal != null) {
        rv.add('=');
        rv.add(defaultVal);
      }
    }

    if (paraminfo.vars['positional_only']?.isNotEmpty ?? false) {
      rv.add(sep.call());
      rv.add('/');
    }

    for (var (name: name, defaultVal: defaultVal) in other) {
      rv.add(sep.call());
      rv.add(name);
      if (defaultVal != null) {
        rv.add('=');
        rv.add(defaultVal);
      }
    }

    if (paraminfo.vars['extrapos'] != null) {
      rv.add(sep.call());
      rv.add('*');
      rv.add(paraminfo.vars['extrapos']);
    } else if (paraminfo.vars['keyword_only'].isNotEmpty) {
      rv.add(sep.call());
      rv.add('*');
    }

    for (var (name, defaultVal) in paraminfo.vars['keyword_only']) {
      rv.add(sep.call());
      rv.add(name);
      if (defaultVal != null) {
        rv.add('=');
        rv.add(defaultVal);
      }
    }

    if (paraminfo.vars['extrakw'] != null) {
      rv.add(sep.call());
      rv.add('**');
      rv.add(paraminfo.vars['extrakw']);
    }
  } else if (paraminfo.vars.containsKey('extrapos')) {
    List<dynamic> positional = [
      for (var param in paraminfo.vars['parameters'])
        if (paraminfo.vars['positional'].contains(param[0])) param
    ];
    List<dynamic> nameonly = [
      for (var param in paraminfo.vars['parameters'])
        if (!positional.contains(param)) param
    ];
    for (var parameter in positional) {
      rv.add(sep.call());
      rv.add(parameter[0]);
      if (parameter[1] != null) {
        rv.add('=');
        rv.add(parameter[1].vars['value']);
      }
    }
    if (paraminfo.vars['extrapos'] != null) {
      rv.add(sep.call());
      rv.add('*');
      rv.add(paraminfo.vars['extrapos']);
    }
    if (nameonly.isNotEmpty) {
      if (!paraminfo.vars['extrapos']) {
        rv.add(sep.call());
        rv.add('*');
      }
      for (var parameter in nameonly) {
        rv.add(sep.call());
        rv.add(parameter[0]);
        if (parameter[1] != null) {
          rv.add('=');
          rv.add(parameter[1]);
        }
      }
    }
    if (paraminfo.vars['extrakw'] != null) {
      rv.add(sep.call());
      rv.add('**');
      rv.add(paraminfo.vars['extrakw']);
    }
  } else {
    int state = 1;

    Iterable<dynamic> values = paraminfo.vars['parameters'] is Map
        ? paraminfo.vars['parameters'].values
        : [for (var parameter in paraminfo.vars['parameters']) parameter.value];

    for (var parameter in values) {
      rv.add(sep.call());
      if (parameter.vars['kind'] == 0) {
        state = 0;

        rv.add(parameter.vars['name']);
        if (parameter.vars['default'] != null) {
          rv.add('=');
          rv.add(parameter.vars['default']);
        }
      } else {
        if (state == 0) {
          state = 1;
          rv.add('/');
          rv.add(sep.call());
        }

        if (parameter.vars['kind'] == 1) {
          rv.add(parameter.vars['name']);
          if (parameter.vars['default'] != null) {
            rv.add('=');
            rv.add(parameter.vars['default']);
          }
        } else if (parameter.vars['kind'] == 2) {
          state = 2;
          rv.add('*');
          rv.add(parameter.vars['name']);
        } else if (parameter.vars['kind'] == 3) {
          if (state == 1) {
            state = 2;
            rv.add('*');
            rv.add(sep.call());
          }

          rv.add(parameter.vars['name']);
          if (parameter.vars['default'] != null) {
            rv.add('=');
            rv.add(parameter.vars['default']);
          }
        }
      }
    }
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
  if (arginfo.vars.containsKey('arguments')) {
    arguments = arginfo.vars['arguments'];
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

    if (val is PythonClassInstance) {
      val = val.vars['value'];
    }

    rv.add(val);
  }
  if (arginfo.vars.containsKey('extrapos') &&
      arginfo.vars['extrapos'] != null) {
    rv.add(sep.call());
    rv.add('*${arginfo.vars['extrapos']}');
  }
  if (arginfo.vars.containsKey('extrakw') && arginfo.vars['extrakw'] != null) {
    rv.add(sep.call());
    rv.add('**${arginfo.vars['extrakw']}');
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
  final int length;
  String string;

  Lexer(this.string) : length = string.length;

  Match? re(RegExp reexp) {
    if (length == pos) {
      return null;
    }

    reexp = RegExp(reexp.pattern,
        multiLine: false, caseSensitive: false, dotAll: true, unicode: true);

    Match? match = reexp.matchAsPrefix(string, pos);
    if (match == null) {
      return null;
    }

    pos = match.end;
    return match;
  }

  bool eol() {
    re(RegExp(r'(\s+|\\\n)+'));
    return pos >= length;
  }

  void skipWhitespace() {
    re(RegExp(r'(\s+|\\\n)+'));
  }

  Match? match(RegExp reexp, [bool clearWhitespace = true]) {
    if (clearWhitespace) {
      skipWhitespace();
    }
    return re(reexp);
  }

  String? pythonString([bool clearWhitespace = true]) {
    int oldPos = pos;

    if (eol()) {
      return null;
    }

    RegExp exp = RegExp(r'[urfURF]*("""|'
        r"'''|"
        r'"|'
        r"')");

    var start = match(exp, clearWhitespace);

    if (start == null) {
      pos = oldPos;

      return null;
    }

    var delim = start.group(1)!;

    final sb = StringBuffer(start.group(0)!);

    while (true) {
      if (eol()) {
        throw Exception('End of line reached while parsing string.');
      }

      if (match(RegExp(delim), clearWhitespace) != null) {
        sb.write(delim);
        return sb.toString();
      }

      if (match(RegExp(r'\\'), clearWhitespace) != null) {
        pos++;
        continue;
      }

      final contentMatch = re(RegExp(r".[^'"
          r'"\\]*'));
      if (contentMatch != null) {
        sb.write(contentMatch.group(0));
      } else {
        throw Exception('Unexpected character in Python string.');
      }
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
    return match(RegExp(r'([+\-])?(\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?'))
        ?.group(0);
  }

  String? word() {
    return match(wordRegexp)?.group(0);
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
        container() != null ||
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

      if ({')', ']', '}'}.contains(c) && contained != 0) {
        contained--;
        pos++;
        continue;
      }

      if (c == '#') {
        re(RegExp(r'[^\n]*'));
        continue;
      }

      if ((pythonString(false) ?? '').isNotEmpty) {
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

String ltrim(String x, String characters) {
  var start = 0;
  while (characters.contains(x[start])) {
    start += 1;
  }
  return x.substring(start);
}
