// Converted/modified from Python's pickle.py: https://github.com/python/cpython/blob/main/Lib/pickle.py

import 'dart:convert';
import 'dart:typed_data';

import 'package:pickle_decompiler/src/args.dart';
import 'package:pickle_decompiler/src/consts.dart';
import 'package:pickle_decompiler/src/pickle_decompiler_base.dart';
import 'package:pickle_decompiler/src/python_types.dart';

typedef Loader = void Function(Unpickler unpickler);

int highestProtocol = 5;

List<dynamic> popMark(Unpickler unpickler) {
  var items = unpickler.stack;
  unpickler.stack = unpickler.metastack.removeLast();
  unpickler.add = unpickler.stack.add;

  return items;
}

void persistentLoad(int pid) {
  throw Exception('unsupported persistent id encountered');
}

void loadGlobal(Unpickler unpickler) {
  String module = utf8.decode(unpickler.readline!()..removeLast());
  String name = utf8.decode(unpickler.readline!()..removeLast());
  PythonClass klass = PythonClass(name, module: module);

  if (unpickler.recognizedDescriptors
      .any((element) => element.klass == klass)) {
    klass.descriptor = unpickler.recognizedDescriptors
        .firstWhere((element) => element.klass == klass);
  } else {
    print('WARNING! Class $klass not recognized');
  }

  if (unpickler.swappers.any((element) => element.klass == klass)) {
    unpickler.add!(unpickler.swappers
        .firstWhere((element) => element.klass == klass)
        .getReplacementOnInit([]));
    return;
  }

  unpickler.add!(klass);
}

void loadProto(Unpickler unpickler) {
  int proto = unpickler.read!(1).first;
  if (!(0 <= proto && proto <= highestProtocol)) {
    throw UnsupportedError('unsupported pickle protocol: $proto');
  }
  unpickler.proto = proto;
}

void newObj(Unpickler unpickler) {
  var args = unpickler.stack.removeLast();
  var cls = unpickler.stack.removeLast();

  if (unpickler.swappers.any((element) => element.klass == cls)) {
    unpickler.add!(unpickler.swappers
        .firstWhere((element) => element.klass == cls)
        .getReplacementOnInit(args));
    return;
  }

  if (cls is Map || cls is List) {
    unpickler.add!(cls);
    return;
  }

  var instance = PythonClassInstance(cls);
  instance.setState(args);
  unpickler.add!(instance);
}

void loadFrame(Unpickler unpickler) {
  final reader = Uint8List.fromList(unpickler.read!(8)).buffer.asByteData();
  final frameSize = reader.getUint64(0, Endian.little);

  if (frameSize > 9223372036854775807) {
    // 9223372036854775807 is the maximum value for int in Dart
    throw Exception('frame size > sys.maxsize: $frameSize');
  }

  unpickler.unframer.loadFrame(frameSize);
}

// What does persistent do ???
void loadPersId(Unpickler unpickler) {
  try {
    //var pid = ascii.decode(unpickler.readline!()..removeLast());
    persistentLoad(0);
  } catch (e) {
    throw Exception('persistent IDs in protocol 0 must be ASCII strings');
  }
}

void loadBinPersId(Unpickler unpickler) {
  var pid = unpickler.stack.removeLast();
  persistentLoad(pid);
}

void loadReduce(Unpickler unpickler) {
  var args = unpickler.stack.isEmpty ? null : unpickler.stack.removeLast();

  PythonClass? func = unpickler.stack.lastOrNull;

  if (func == PythonClass('list', module: '__builtin__')) {
    unpickler.stack.last = args.first.toList();
    return;
  }

  if (func == PythonClass('set', module: '__builtin__') && args.first is List) {
    unpickler.stack.last = args.first.toSet();
    return;
  }

  if (func == PythonClass('OrderedDict', module: 'collections') &&
      (args.isEmpty || args.first is List)) {
    if (args.isEmpty) {
      unpickler.stack.last = <MapEntry<dynamic, dynamic>>[];
      return;
    }
    // TODO: Check if this is the correct implementation
    List<MapEntry<dynamic, dynamic>> orderedDict = [];

    for (int i = 0; i < args.first.length; i++) {
      orderedDict.add(MapEntry(args.first[i].first, args.first[i].last));
    }

    unpickler.stack.last = orderedDict;
    return;
  }

  if (func != null) {
    // Somewhere we don't add the descriptor to the class, TODO: find this place
    if (func.descriptor == null &&
        unpickler.recognizedDescriptors
            .any((element) => element.klass == func)) {
      func.descriptor = unpickler.recognizedDescriptors
          .firstWhere((element) => element.klass == func);
    }

    if (func.descriptor != null) {
      unpickler.stack.last = func.descriptor!.construct(args) ??
          (PythonClassInstance(func)..setState(args));
      return;
    }

    print(
        'WARNING! Calling $func with args $args (First element in args is ${(args?.isEmpty ?? true) ? 'null' : args.first.runtimeType}) but no implementation was defined');
  }

  //stack.last = func.call(args.first);
}

void loadNone(Unpickler unpickler) {
  unpickler.add!(null);
}

void loadFalse(Unpickler unpickler) {
  unpickler.add!(false);
}

void loadTrue(Unpickler unpickler) {
  unpickler.add!(true);
}

final trueAbr = 'I01\n'.codeUnits;
final falseAbr = 'I00\n'.codeUnits;

void loadInt(Unpickler unpickler) {
  List<int> data = unpickler.readline!();
  dynamic val;
  if (data == trueAbr.sublist(1)) {
    val = true;
  } else if (data == falseAbr.sublist(1)) {
    val = false;
  } else {
    val = int.parse(ascii.decode(data));
  }
  unpickler.add!(val);
}

void loadBinInt(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(4)).buffer.asByteData();
  var val = reader.getInt32(0, Endian.little);
  unpickler.add!(val);
}

void loadBinInt1(Unpickler unpickler) {
  var val = unpickler.read!(1).first;
  unpickler.add!(val);
}

void loadBinInt2(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(2)).buffer.asByteData();
  var val = reader.getUint16(0, Endian.little);
  unpickler.add!(val);
}

void loadLong(Unpickler unpickler) {
  var val = unpickler.readline!()..removeLast();
  if (val.isNotEmpty && val.last == 'L'.codeUnits.single) {
    val.removeLast();
  }

  var finalVal = int.parse(ascii.decode(val));

  unpickler.add!(finalVal);
}

void loadLong1(Unpickler unpickler) {
  var n = unpickler.read!(1).first;
  var data = unpickler.read!(n);
  var val = decodeLong(data);
  unpickler.add!(val);
}

void loadLong4(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(4)).buffer.asByteData();
  var n = reader.getUint32(0, Endian.little);

  if (n < 0) {
    throw Exception('LONG pickle has negative byte count');
  }
  var data = unpickler.read!(n);
  var val = decodeLong(data);
  unpickler.add!(val);
}

void loadFloat(Unpickler unpickler) {
  var val = double.parse(ascii.decode(unpickler.readline!()..removeLast()));
  unpickler.add!(val);
}

void loadBinFloat(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(8)).buffer.asByteData();
  var val = reader.getFloat64(0, Endian.big);
  unpickler.add!(val);
}

dynamic _decodeString(Unpickler unpickler, List<int> data) {
  if (unpickler.encoding == 'bytes') {
    return data;
  } else {
    return Encoding.getByName(unpickler.encoding)!.decode(data);
  }
}

void loadString(Unpickler unpickler) {
  var data = unpickler.readline!()..removeLast();
  if (data.length >= 2 &&
      data.first == data.last &&
      ['"'.codeUnits.single, "'".codeUnits.single].contains(data.first)) {
    data = data.sublist(1);
    data.removeLast();
  } else {
    throw Exception('the STRING opcode argument must be quoted');
  }
  unpickler.add!(_decodeString(unpickler, data));
}

void loadBinString(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(8)).buffer.asByteData();
  var len = reader.getInt32(0, Endian.little);

  if (len < 0) {
    throw Exception('BINSTRING pickle has negative byte count');
  }

  var data = unpickler.read!(len);
  unpickler.add!(_decodeString(unpickler, data));
}

void loadBinBytes(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(8)).buffer.asByteData();
  var len = reader.getInt32(0, Endian.little);

  if (len > 9223372036854775807) {
    throw Exception('BINBYTES exceeds system\'s maximum size');
  }

  var data = unpickler.read!(len);
  unpickler.add!(data);
}

void loadUnicode(Unpickler unpickler) {
  var data = unpickler.readline!()..removeLast();

  unpickler.add!(Encoding.getByName('utf-8')!.decode(data));
}

void loadBinUnicode(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(4)).buffer.asByteData();
  var len = reader.getUint32(0, Endian.little);

  if (len > 9223372036854775807) {
    throw Exception('BINUNICODE exceeds system\'s maximum size');
  }

  var data = Encoding.getByName('utf-8')!.decode(unpickler.read!(len));
  unpickler.add!(data);
}

void loadBinUnicode8(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(8)).buffer.asByteData();
  var len = reader.getUint64(0, Endian.little);

  if (len > 9223372036854775807) {
    throw Exception('BINUNICODE8 exceeds system\'s maximum size');
  }

  var data = unpickler.read!(len);
  unpickler.add!(Encoding.getByName('utf-8')!.decode(data));
}

void loadBinBytes8(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(8)).buffer.asByteData();
  var len = reader.getUint64(0, Endian.little);

  if (len > 9223372036854775807) {
    throw Exception('BINBYTES8 exceeds system\'s maximum size');
  }

  var data = unpickler.read!(len);
  unpickler.add!(data);
}

void loadByteArray8(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(8)).buffer.asByteData();
  var len = reader.getUint64(0, Endian.little);

  if (len > 9223372036854775807) {
    throw Exception('BYTEARRAY8 exceeds system\'s maximum size');
  }

  Uint8List b = Uint8List(len);
  unpickler.readinto!(b);
  unpickler.add!(b);
}

void loadNextBuffer(Unpickler unpickler) {
  if (unpickler.buffers == null) {
    throw Exception(
        'pickle stream refers to out-of-band data but no *buffers* argument was given');
  }
  if (!unpickler.buffers!.moveNext()) {
    throw Exception('not enough out-of-band buffers');
  }

  unpickler.add!(unpickler.buffers!.current);
}

void loadReadonlyBuffer(Unpickler unpickler) {
  // No need for the buffer to become read-only in Dart.
}

void loadShortBinString(Unpickler unpickler) {
  var len = unpickler.read!(1).first;
  var data = unpickler.read!(len);
  unpickler.add!(_decodeString(unpickler, data));
}

void loadShortBinBytes(Unpickler unpickler) {
  var len = unpickler.read!(1).first;
  var data = unpickler.read!(len);
  unpickler.add!(data);
}

void loadShortBinUnicode(Unpickler unpickler) {
  var len = unpickler.read!(1).first;
  var data = unpickler.read!(len);
  unpickler.add!(Encoding.getByName('utf-8')!.decode(data));
}

void loadTuple(Unpickler unpickler) {
  var items = popMark(unpickler);
  unpickler.add!(List.unmodifiable(items));
}

void loadEmptyTuple(Unpickler unpickler) {
  unpickler.add!(List.unmodifiable([]));
}

void loadTuple1(Unpickler unpickler) {
  unpickler.stack.last = List.unmodifiable([unpickler.stack.last]);
}

void loadTuple2(Unpickler unpickler) {
  var items = unpickler.stack.removeLast();
  unpickler.stack.last = List.unmodifiable([unpickler.stack.last, items]);
}

void loadTuple3(Unpickler unpickler) {
  var items = unpickler.stack.removeLast();
  var items2 = unpickler.stack.removeLast();
  unpickler.stack.last =
      List.unmodifiable([unpickler.stack.last, items2, items]);
}

void loadEmptyList(Unpickler unpickler) {
  unpickler.add!([]);
}

void loadEmptyDictionary(Unpickler unpickler) {
  unpickler.add!(<dynamic, dynamic>{});
}

void loadEmptySet(Unpickler unpickler) {
  unpickler.add!(<dynamic>{});
}

void loadFrozenSet(Unpickler unpickler) {
  var items = popMark(unpickler);
  unpickler.add!(items.toSet());
}

void loadList(Unpickler unpickler) {
  var items = popMark(unpickler);
  unpickler.add!(items);
}

void loadDict(Unpickler unpickler) {
  var items = popMark(unpickler);
  var dict = <dynamic, dynamic>{};
  for (var i = 0; i < items.length; i += 2) {
    dict[items[i]] = items[i + 1];
  }
  unpickler.add!(dict);
}

/*
All of those actions could be possible to implement but the objects won't have their attached methods,
I've already implemented newObj and some others to see if it works and I succeeded,
but no more implementations are required for the time being
because RPA and RPYC files are already supported with this incomplete implementation.

Implementing those methods is the first step that should be taken if you want to support the full protocols.

void instantiate(Unpickler unpickler, Type klass, List<dynamic> args) {
  print('Trying to instantiate $klass with args $args');
  switch(klass) {
    default:
      print('couldn\'t instantiate $klass');
  }
  //unpickler.add!(klass(*args));
}

void loadInst(Unpickler unpickler) {
  ...
}

void loadNewObjEx(Unpickler unpickler) {
  ...
}

void loadStackGlobal(Unpickler unpickler) {
  ...
}

void loadExt1(Unpickler unpickler) {
  ...
}

void loadExt2(Unpickler unpickler) {
  ...
}

void loadExt4(Unpickler unpickler) {
  ...
}

void getExtension(Unpickler unpickler, int code) {
  ...
}

void findClass(Unpickler unpickler, String module, String name) {
  ...
}
*/

void loadPop(Unpickler unpickler) {
  if (unpickler.stack.isNotEmpty) {
    unpickler.stack.removeLast();
  } else {
    popMark(unpickler);
  }
}

void loadPopMark(Unpickler unpickler) {
  popMark(unpickler);
}

void loadDup(Unpickler unpickler) {
  unpickler.add!(unpickler.stack.last);
}

void loadGet(Unpickler unpickler) {
  var i = int.parse(ascii.decode(unpickler.readline!()..removeLast()));
  try {
    unpickler.add!(unpickler.stack[i]);
  } catch (e) {
    throw Exception('Memo value not found at index $i');
  }
}

void loadBinGet(Unpickler unpickler) {
  var i = unpickler.read!(1).first;
  try {
    unpickler.add!(unpickler.memo[i]);
  } catch (e) {
    throw Exception('Memo value not found at index $i');
  }
}

void loadLongBinGet(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(4)).buffer.asByteData();
  var i = reader.getUint32(0, Endian.little);
  try {
    unpickler.add!(unpickler.memo[i]);
  } catch (e) {
    throw Exception('Memo value not found at index $i');
  }
}

void loadPut(Unpickler unpickler) {
  var i = int.parse(ascii.decode(unpickler.readline!()..removeLast()));
  if (i < 0) {
    throw Exception('negative PUT argument');
  }
  unpickler.memo[i] = unpickler.stack.last;
}

void loadBinPut(Unpickler unpickler) {
  var i = unpickler.read!(1).first;
  if (i < 0) {
    throw Exception('negative BINPUT argument');
  }
  unpickler.memo[i] = unpickler.stack.last;
}

void loadLongBinPut(Unpickler unpickler) {
  var reader = Uint8List.fromList(unpickler.read!(4)).buffer.asByteData();
  var i = reader.getUint32(0, Endian.little);
  if (i < 0) {
    throw Exception('negative LONG_BINPUT argument');
  }
  unpickler.memo[i] = unpickler.stack.last;
}

void loadMemoize(Unpickler unpickler) {
  unpickler.memo[unpickler.memo.length] = unpickler.stack.last;
}

void loadAppend(Unpickler unpickler) {
  var value = unpickler.stack.removeLast();
  if (unpickler.stack.last is PythonClassInstance) {
    throw UnsupportedError('tried to add $value to ${unpickler.stack.last}');
  }
  unpickler.stack.last.add(value);
}

// Relies on the append method, to monitor
void loadAppends(Unpickler unpickler) {
  var items = popMark(unpickler);
  var listObj = unpickler.stack.last;

  try {
    if (listObj is PythonClassInstance) {
      listObj.state ??= {};
      listObj.state!['items'] = items;
      return;
    }
    var extend = listObj.extend;
    extend(items);
  } on NoSuchMethodError {
    var append = listObj.add;
    for (var item in items) {
      append(item);
    }
  }
}

void loadSetItem(Unpickler unpickler) {
  var value = unpickler.stack.removeLast();
  var key = unpickler.stack.removeLast();
  var dict = unpickler.stack.last;

  if (dict is! Map) {
    // The object to set items to isn't a dict. Defaulting to {}
    dict = {};
  }

  dict[key] = value;

  unpickler.stack.last = dict;
}

void loadSetItems(Unpickler unpickler) {
  var items = popMark(unpickler);
  var dict = unpickler.stack.last;

  if (dict is! Map) {
    if (dict is List) {
      Map<dynamic, dynamic> newDict = {};
      for (var i = 0; i < dict.length; i += 2) {
        newDict[dict[i]] = dict[i + 1];
      }
      dict = newDict;
    } else if (dict is PythonClassInstance) {
      dict.state ??= {};
      dict.state!['items'] = items;
      return;
    } else {
      throw UnsupportedError('The object to set items to isn\'t a dict.');
    }
  }

  for (var i = 0; i < items.length; i += 2) {
    dict[items[i]] = items[i + 1];
  }

  unpickler.stack.last = dict;
}

void loadAdditions(Unpickler unpickler) {
  var items = popMark(unpickler);
  var setObj = unpickler.stack.last;

  if (setObj is Set) {
    setObj.addAll(items);
  } else {
    var add = setObj.add;
    for (var item in items) {
      add(item);
    }
  }
}

void loadBuild(Unpickler unpickler) {
  var state = unpickler.stack.removeLast();
  var inst = unpickler.stack.last;
  try {
    inst.setState(state);

    unpickler.stack.last = inst;
  } catch (e) {
    if (inst is List) {
      inst = state;
      return;
    }

    if (inst is Map && state is List && state.length % 2 == 0) {
      inst = {};

      for (var i = 0; i < state.length; i += 2) {
        inst[state[i]] = state[i + 1];
      }

      unpickler.stack.last = inst;

      return;
    }

    if (inst is Map && state is Map) {
      unpickler.stack.last = state;

      return;
    }

    rethrow;
  }
}

void loadMark(Unpickler unpickler) {
  unpickler.metastack.add(unpickler.stack);
  unpickler.stack = [];
  unpickler.add = unpickler.stack.add;
}

class Stop implements Exception {
  dynamic value;
  Stop(this.value);
}

void loadStop(Unpickler unpickler) {
  throw Stop(unpickler.stack.removeLast());
}

Map<int, Loader?> opcodeMap = {
  MARK: loadMark,
  STOP: loadStop,
  POP: loadPop,
  POP_MARK: loadPopMark,
  DUP: loadDup,
  FLOAT: loadFloat,
  INT: loadInt,
  BININT: loadBinInt,
  BININT1: loadBinInt1,
  LONG: loadLong,
  BININT2: loadBinInt2,
  NONE: loadNone,
  PERSID: loadPersId,
  BINPERSID: loadBinPersId,
  REDUCE: loadReduce,
  STRING: loadString,
  BINSTRING: loadBinString,
  SHORT_BINSTRING: loadShortBinString,
  UNICODE: loadUnicode,
  BINUNICODE: loadBinUnicode,
  APPEND: loadAppend,
  BUILD: loadBuild,
  GLOBAL: loadGlobal,
  DICT: loadDict,
  EMPTY_DICT: loadEmptyDictionary,
  APPENDS: loadAppends,
  GET: loadGet,
  BINGET: loadBinGet,
  INST: null,
  LONG_BINGET: loadLongBinGet,
  LIST: loadList,
  EMPTY_LIST: loadEmptyList,
  OBJ: null,
  PUT: loadPut,
  BINPUT: loadBinPut,
  LONG_BINPUT: loadLongBinPut,
  SETITEM: loadSetItem,
  TUPLE: loadTuple,
  EMPTY_TUPLE: loadEmptyTuple,
  SETITEMS: loadSetItems,
  BINFLOAT: loadBinFloat,

  // Protocol 2
  PROTO: loadProto,
  NEWOBJ: newObj,
  EXT1: null,
  EXT2: null,
  EXT4: null,
  TUPLE1: loadTuple1,
  TUPLE2: loadTuple2,
  TUPLE3: loadTuple3,
  NEWTRUE: loadTrue,
  NEWFALSE: loadFalse,
  LONG1: loadLong1,
  LONG4: loadLong4,

  // Protocol 3 (Python 3.x)
  BINBYTES: loadBinBytes,
  SHORT_BINBYTES: loadShortBinBytes,

  // Protocol 4
  SHORT_BINUNICODE: loadShortBinUnicode,
  BINUNICODE8: loadBinUnicode8,
  BINBYTES8: loadBinBytes8,
  EMPTY_SET: loadEmptySet,
  ADDITEMS: loadAdditions,
  FROZENSET: loadFrozenSet,
  NEWOBJ_EX: null,
  STACK_GLOBAL: null,
  MEMOIZE: loadMemoize,
  FRAME: loadFrame,

  // Protocol 5
  BYTEARRAY8: loadByteArray8,
  NEXT_BUFFER: loadNextBuffer,
  READONLY_BUFFER: loadReadonlyBuffer,
};
