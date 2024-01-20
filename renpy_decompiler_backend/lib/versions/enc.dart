import 'dart:io';

import 'package:renpy_decompiler_backend/tree_creator.dart';

/// Ported from https://github.com/varieget/unrpa/commit/dfad951d6911575cd1f5ac6e37662c0336c9170d
class ENC1 extends RPAVersion {
  @override
  (int offset, int? key) findOffsetAndKey(String header, List<int> rawHeader, File file) {
    Map<String, String> caesar = {
            "0": "a",
            "5": "b",
            "b": "c",
            "2": "d",
            "a": "e",
            "4": "f",
            "c": "0",
            "8": "1",
            "e": "2",
            "3": "3",
            "d": "4",
            "6": "5",
            "f": "6",
            "7": "7",
            "1": "8",
            "9": "9",
            "g": " ",
    };

    String offsetAndKey = header.substring(8, 33);
    offsetAndKey = [
      for(var c in offsetAndKey.split(''))
        caesar[c]!
    ].join();

    header = header.substring(0, 8) + offsetAndKey;

    List<String> parts = header.split(' ');
    return (int.parse(parts[1], radix: 16), int.parse(parts[2], radix: 16));
  }

  @override
  String get version => 'ENC-1.0';
}