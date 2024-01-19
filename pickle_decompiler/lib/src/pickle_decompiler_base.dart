import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:pickle_decompiler/src/opcode_actions.dart';
import 'package:pickle_decompiler/src/opcodes.dart';
import 'package:pickle_decompiler/src/pickle_reader.dart';
import 'package:pickle_decompiler/src/python_types.dart';
import 'package:pickle_decompiler/src/stack_objects.dart';

class Unpickler {
  late Unframer unframer;
  List<int> Function()? _fileReadline;
  List<int> Function(int? n)? _fileRead;
  Map<dynamic, dynamic> memo = {};
  final String encoding;
  String errors;
  int proto = 0;

  Uint8List file;

  List<int> Function(int? n)? read;
  int Function(Uint8List buf)? readinto;
  List<int> Function()? readline;
  List<dynamic> metastack = [];
  List<dynamic> stack = [];

  Iterator<dynamic>? buffers;

  void Function(dynamic value)? add;

  List<PythonClassDescriptor> recognizedDescriptors;
  List<PythonClassSwapper> recognizedSwappers;

  Unpickler(
      {required this.file,
      this.encoding = 'ascii',
      this.errors = 'strict',
      List<dynamic>? buffers,
      this.recognizedDescriptors = const [],
      this.recognizedSwappers = const []})
      : buffers = (buffers?.isEmpty ?? true) ? null : buffers!.iterator {
    RawFrame rawFrame = RawFrame(data: file);
    _fileReadline = rawFrame.readline;
    _fileRead = rawFrame.read;
  }

  dynamic load() {
    if (_fileRead == null) {
      throw Exception('Unpickler was not called.');
    }

    unframer = Unframer(fileRead: _fileRead, fileReadline: _fileReadline);
    read = unframer.read;
    readinto = unframer.readInto;
    readline = unframer.readline;
    metastack = [];
    stack = [];
    add = stack.add;
    proto = 0;

    try {
      while (true) {
        var data = read!(1);

        if (data.isEmpty) {
          throw Exception('EOF while reading bytes');
        }
        var opcode = data[0];

        if (!opcodeMap.containsKey(opcode)) {
          throw Exception('Invalid opcode: $opcode (${utf8.decode([
                opcode
              ], allowMalformed: true)})');
        }

        if (opcodeMap[opcode] == null) {
          throw Exception('Opcode ${utf8.decode([
                opcode
              ], allowMalformed: true)} ($opcode) isn\'t defined');
        }

        opcodeMap[opcode]!(this);

        // if (opcode == '.'.codeUnitAt(0)) {
        //   break;
        // }
      }
    } on Stop catch (e) {
      return e.value;
    }
  }
}

dynamic loads(Uint8List file,
    {String encoding = 'ascii',
    String errors = 'strict',
    List<dynamic>? buffers,
    List<PythonClassDescriptor> recognizedDescriptors = const [],
    List<PythonClassSwapper> recognizedSwappers = const []}) {
  return Unpickler(
          file: file,
          encoding: encoding,
          errors: errors,
          buffers: buffers,
          recognizedDescriptors: recognizedDescriptors,
          recognizedSwappers: recognizedSwappers)
      .load();
}

Future<int> dis(List<int> data,
    {IOSink? out,
    Map<dynamic, dynamic> memo = const {},
    int indentLevel = 4,
    int annotate = 0}) async {
  List<StackObject> stack = [];
  Map<dynamic, dynamic> memo = {};
  int maxProto = -1;
  List<int?> markStack = [];
  String indentChunk = ' ' * indentLevel;
  String? errormsg;
  out ??= stdout;
  int annocol = annotate;

  int lineAmount = 0;

  await for (var entry in genops(data)) {
    lineAmount++;
    out.write('${entry.pos.toString().padLeft(5, ' ')}: ');

    String line =
        '${reprByte(entry.opcode.code.codeUnits.single).padRight(4, ' ')} ${indentChunk * markStack.length}${entry.opcode.name}';

    maxProto = max(maxProto, entry.opcode.proto);
    var before = entry.opcode.stackBefore;
    var after = entry.opcode.stackAfter;
    int numToPop = before.length;

    String markMsg = '';
    if (before.contains(markobject) ||
        (entry.opcode.name == 'POP' &&
            stack.isNotEmpty &&
            stack.last == markobject)) {
      assert(!after.contains(markobject));

      if (markStack.isNotEmpty) {
        int? markPos = markStack.removeLast();
        if (markPos == null) {
          markMsg = '(MARK at unknown opcode offset)';
        } else {
          markMsg = '(MARK at $markPos)';
        }

        while (stack.last != markobject) {
          stack.removeLast();
        }
        stack.removeLast();
        numToPop = before.indexOf(markobject);
        if (numToPop == -1) {
          assert(entry.opcode.name == 'POP');
          numToPop = 0;
        }
      } else {
        errormsg = markMsg = 'No MARK exists on stack';
      }
    }

    if (['PUT', 'BINPUT', 'LONG_BINPUT', 'MEMOIZE']
        .contains(entry.opcode.name)) {
      dynamic memoIdx;
      if (entry.opcode.name == 'MEMOIZE') {
        memoIdx = memo.length;
        markMsg = '(as $memoIdx)';
      } else {
        assert(entry.arg != null);
        memoIdx = entry.arg;
      }

      if (memo.containsKey(memoIdx)) {
        errormsg = 'memo key ${entry.arg} already defined';
      } else if (stack.isEmpty) {
        errormsg = 'stack is empty -- can\'t store into memo';
      } else if (stack.last == markobject) {
        errormsg = 'can\'t store markobject in the memo';
      } else {
        memo[memoIdx] = stack.last;
      }
    } else if (['GET', 'BINGET', 'LONG_BINGET'].contains(entry.opcode.name)) {
      if (memo.containsKey(entry.arg)) {
        assert(after.length == 1);
        after = [memo[entry.arg]];
      } else {
        errormsg = 'memo key ${entry.arg} has never been stored into';
      }
    }

    if (entry.arg != null || markMsg.isNotEmpty) {
      line += ' ' * (10 - entry.opcode.name.length);
      if (entry.arg != null) {
        if (['BINUNICODE', 'SHORT_BINSTRING'].contains(entry.opcode.name)) {
          // To keep the two dis the same between Python and Dart
          line += " '${entry.arg}'";
        } else {
          line += ' ${entry.arg}';
        }
      }
      if (markMsg.isNotEmpty) {
        line += ' $markMsg';
      }
    }
    if (annotate != 0) {
      line += ' ' * (annocol - line.length);
      annocol = line.length;
      if (annocol > 50) {
        annocol = annotate;
      }
      line += ' ${entry.opcode.doc.split('\n').first}';
    }

    out.writeln(line);

    if (errormsg != null) {
      throw Exception(errormsg);
    }

    if (stack.length < numToPop) {
      throw Exception(
          'tries to pop $numToPop items from stack with only ${stack.length} items');
    }

    if (numToPop > 0) {
      stack.removeRange(stack.length - numToPop, stack.length);
    }

    if (after.contains(markobject)) {
      assert(!before.contains(markobject));
      markStack.add(entry.pos);
    }

    stack.addAll(after);
  }

  out.writeln('highest protocol among opcodes = $maxProto');
  lineAmount++;

  await out.flush();
  await out.close();

  if (stack.isNotEmpty) {
    throw Exception('stack not empty after STOP: $stack');
  }

  return lineAmount;
}

Stream<({OpCodeInfo opcode, dynamic arg, int pos})> genops(
    List<int> data) async* {
  Map<String, OpCodeInfo> codeToOp = {};

  for (var d in opcodes) {
    codeToOp[d.code] = d;
  }

  int pos = 0;
  while (true) {
    int code = data[pos];
    OpCodeInfo? opcode = codeToOp[latin1.decode([code])];

    if (opcode == null) {
      throw Exception('Unknown opcode: $code at $pos');
    }

    ({int n, dynamic result})? arg;

    if (opcode.arg == null) {
      arg = null;
    } else {
      var result = opcode.arg!.reader(data, pos + 1);
      arg = result;
    }

    yield (opcode: opcode, arg: arg?.result, pos: pos);

    if (code == '.'.codeUnitAt(0)) {
      break;
    }

    pos += 1 + (arg?.n ?? 0);
  }
}
