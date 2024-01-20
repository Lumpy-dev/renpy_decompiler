import 'dart:convert';
import 'dart:io';

import 'package:renpy_decompiler_backend/tree_creator.dart';

//String getLoader()
// TODO: find a workaround for the Python decompiler
// https://gist.github.com/Lattyware/c7ae85998f62a5d1a985de6bfc662048

int obfuscationOffset(List<int> value) {
  String a = utf8.decode(value.sublist(6, 8).reversed.toList());
  String b = utf8.decode(value.sublist(0, 3));
  String c = utf8.decode(value.sublist(3, 6).reversed.toList());
  return int.parse(a + b + c, radix: 16);
}

class ZiX12A extends RPAVersion {
  @override
  (int offset, int? key) findOffsetAndKey(String header, List<int> rawHeader, File file) {
    return (obfuscationOffset(utf8.encode(header.split(' ').last)), null);
  }

  @override
  String get version => 'ZiX-12A';
}

class ZiX12B extends RPAVersion {
  @override
  (int offset, int? key) findOffsetAndKey(String header, List<int> rawHeader, File file) {
    return (obfuscationOffset(utf8.encode(header.split(' ').last)), null);
  }

  @override
  String get version => 'ZiX-12B';
}
