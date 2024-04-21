import 'dart:io';

import 'package:renpy_decompiler_backend/tree_creator.dart';
import 'package:renpy_decompiler_backend/versions/official_rpa.dart';

/// Ported from https://github.com/einstein95/unrpa/commit/b93302ee695c19d70ac410eafed31b95f61436d3
class RPAVersionNinePointTwo extends RPAVersionThree {
  @override
  String get version => 'RPA-9.1';

  int mainKey = 0x126E6680;
  int extraKey = 0x46D96FA8FAD5262B;

  // Is not formatted well by `dart format`
  List<int> xorpad = [
    0xF6,
    0x02,
    0x3F,
    0x76,
    0x4D,
    0x0B,
    0x80,
    0x1B,
    0x29,
    0x10,
    0xDF,
    0xDD,
    0x74,
    0x85,
    0xDE,
    0xA6,
    0xDB,
    0x7D,
    0xC8,
    0x19,
    0xBA,
    0xE3,
    0xD0,
    0x63,
    0x2F,
    0x50,
    0xE7,
    0x55,
    0xB4,
    0x67,
    0x0B,
    0xFB,
  ];

  @override
  (int, int?) findOffsetAndKey(
      String header, List<int> rawHeader, RandomAccessFile file) {
    List<String> parts = header.split(' ');
    int offset = int.parse(parts[1], radix: 16) ^ extraKey;
    return (offset, mainKey);
  }

  @override
  void postProcess(RPATreeNodeFile source, Sink<List<int>> sink) {
    List<int> segment = source.read1();
    while (segment.isNotEmpty) {
      segment = [
        for (int i = 0; i < segment.length; i++) segment[i] ^ xorpad[i % 32]
      ];
      sink.add(segment);

      segment = source.read1();
    }
  }
}
