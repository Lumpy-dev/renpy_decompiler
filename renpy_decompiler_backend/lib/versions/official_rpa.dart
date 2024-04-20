import 'dart:io';

import 'package:renpy_decompiler_backend/tree_creator.dart';

class RPAVersionOne extends RPAVersion {
  @override
  (int offset, int? key) findOffsetAndKey(
      String header, List<int> rawHeader, RandomAccessFile file) {
    return (0, null);
  }

  @override
  String get version => 'RPA-1.0';
}

class RPAVersionTwo extends RPAVersion {
  @override
  (int offset, int? key) findOffsetAndKey(
      String header, List<int> rawHeader, RandomAccessFile file) {
    return (int.parse(header.substring(8), radix: 16), null);
  }

  @override
  String get version => 'RPA-2.0';
}

class RPAVersionThree extends RPAVersion {
  @override
  (int offset, int? key) findOffsetAndKey(
      String header, List<int> rawHeader, RandomAccessFile file) {
    List<String> splitHeader = header.split(' ');
    return (
      int.parse(splitHeader[1], radix: 16),
      int.parse(splitHeader[2], radix: 16)
    );
  }

  @override
  String get version => 'RPA-3.0';
}
