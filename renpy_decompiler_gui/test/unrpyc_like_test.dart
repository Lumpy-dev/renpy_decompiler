// This file is made to emulate the testing process of the project UnRPYC made by CensoredUsername and other contributors

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/rpyc_parser.dart';

void main() {
  String unrpycPath =
      const String.fromEnvironment('UNRPYC_PATH', defaultValue: 'test/unrpyc');

  Directory unrpycHome = Directory(unrpycPath);

  Directory testFilesDir =
      Directory(join(unrpycHome.absolute.path, 'testcases'));

  Directory compiledFilesDir =
      Directory(join(testFilesDir.absolute.path, 'compiled'));
  Directory expectedFilesDir =
      Directory(join(testFilesDir.absolute.path, 'expected'));

  List<File> filesToTest = compiledFilesDir
      .listSync(recursive: true)
      .where((element) => element is File && extension(element.path) == '.rpyc')
      .cast<File>()
      .toList();

  group('Decompile files', () {
    for (var file in filesToTest) {
      test('Test ${basename(file.path)}', () {
        print('Testing ${file.path}');
        List<int> fileBytes = file.readAsBytesSync();

        if (listEquals(fileBytes.sublist(0, 10), 'RENPY RPC2'.codeUnits)) {
          int position = 10;
          Map<int, dynamic> chunks = {};
          while (true) {
            int slot =
                Uint8List.fromList(fileBytes.sublist(position, position + 4))
                    .buffer
                    .asByteData()
                    .getUint32(0, Endian.little);
            position += 4;
            int start =
                Uint8List.fromList(fileBytes.sublist(position, position + 4))
                    .buffer
                    .asByteData()
                    .getUint32(0, Endian.little);
            position += 4;
            int length =
                Uint8List.fromList(fileBytes.sublist(position, position + 4))
                    .buffer
                    .asByteData()
                    .getUint32(0, Endian.little);
            position += 4;

            if (slot == 0) break;

            chunks[slot] = fileBytes.sublist(start, start + length);
          }

          fileBytes = chunks[1];
        }

        fileBytes = zlib.decode(fileBytes);

        var out = loads(
          Uint8List.fromList(fileBytes),
          recognizedDescriptors: descriptors,
          swappers: swappers,
          silent: false,
        );

        String result = parseFile(out);

        print('Testing against precompiled file');

        String expected = join(expectedFilesDir.path,
            relative(file.path, from: compiledFilesDir.path));
        String fileContent =
            File(expected.substring(0, expected.length - 1)).readAsStringSync();
        expect(
          result.trim(),
          fileContent.substring(0, fileContent.length - 68).trim(),
        );
      });
    }
  });
}
