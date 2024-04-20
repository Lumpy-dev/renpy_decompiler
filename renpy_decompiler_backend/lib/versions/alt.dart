import 'dart:io';

import 'package:renpy_decompiler_backend/tree_creator.dart';

class ALT1 extends RPAVersion {
  @override
  (int offset, int? key) findOffsetAndKey(
      String header, List<int> rawHeader, RandomAccessFile file) {
    List<String> parts = header.split(' ');
    return (
      int.parse(parts[2], radix: 16),
      int.parse(parts[1], radix: 16) ^ 0xDABE8DF0
    );
  }

  @override
  String get version => 'ALT-1.0';
}
