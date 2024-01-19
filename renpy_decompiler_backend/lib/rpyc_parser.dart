import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/bridges/renpy/ast.dart';
import 'package:renpy_decompiler_backend/bridges/renpy/python.dart';
import 'package:renpy_decompiler_backend/bridges/renpy/revertable.dart';
import 'package:renpy_decompiler_backend/bridges/renpy/sl2/slast.dart';
import 'package:renpy_decompiler_backend/decompilers/rpyc.dart';

bool isRPYCFile(File file) {
  return file.statSync().size >= 3 &&
      ListEquality()
          .equals(file.openSync().readSync(10), utf8.encode('RENPY RPC2'));
}

String decompileRPYC(File file) {
  List<int> data = file.readAsBytesSync();

  if (isRPYCFile(file)) {
    int position = 10;
    Map<int, dynamic> chunks = {};
    while (true) {
      int slot = Uint8List.fromList(data.sublist(position, position + 4))
          .buffer
          .asByteData()
          .getUint32(0, Endian.little);
      position += 4;
      int start = Uint8List.fromList(data.sublist(position, position + 4))
          .buffer
          .asByteData()
          .getUint32(0, Endian.little);
      position += 4;
      int length = Uint8List.fromList(data.sublist(position, position + 4))
          .buffer
          .asByteData()
          .getUint32(0, Endian.little);
      position += 4;

      if (slot == 0) break;

      chunks[slot] = data.sublist(start, start + length);
    }

    data = chunks[1];
  }

  data = zlib.decode(data);

  List<dynamic> compiled = Unpickler(
      file: Uint8List.fromList(data),
      recognizedDescriptors: [...astDescriptors, ...slastDescriptors],
      recognizedSwappers: [...revertableSwappers, ...pythonSwappers]).load();

  return parseFile(compiled);
}

String parseFile(List<dynamic> file) {
  dynamic version = file.removeAt(0);

  if (version['version'] != 5003000) {
    print('WARNING! Unsupported .RPYC version: ${version['version']}');
  }

  if (file.first.isEmpty) {
    return '';
  }

  return RPYCDecompiler.pprint([], List<PythonClassInstance>.from(file.first))
      .join('');
}
