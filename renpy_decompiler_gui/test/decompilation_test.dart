import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/rpyc_parser.dart';
import 'package:renpy_decompiler_backend/tree_creator.dart';

int totalAttemptedFilesAmount = 0;
int totalDecompiledFilesAmount = 0;

void main() {
  // We cannot compare our decompiled files against UnRPYC decompiled files because we made edits to the decompiler output
  // Example: In menus, if there's no condition in the original script, UnRPYC adds a useless "if True" which we deleted.
  // We're only going to see if there are any errors thrown by the decompiler or in the descriptors.

  group('Dart rpyc decryption', () {
    Directory rpaDir = Directory('test/rpa');

    if (!rpaDir.existsSync()) {
      print('RPA directory not found, skipping tests');
      return;
    }

    for (var archive in rpaDir.listSync(recursive: true)) {
      if (archive is! File || extension(archive.absolute.path) != '.rpa') {
        continue;
      }

      test('${basename(archive.absolute.path)} .RPYC files decryption',
          () async {
        var createdTree = await createTree(archive);

        List<RPATreeNodeFile> files = listFiles(createdTree.tree, []);

        int attemptedFilesAmount = 0;
        int decompiledFilesAmount = 0;

        for (RPATreeNodeFile file in files) {
          if (extension(file.path) != '.rpyc') continue;

          attemptedFilesAmount++;

          StreamController<List<int>> controller = StreamController();

          file.version.postProcess(file, controller.sink);
          controller.sink.close();

          List<int> data = (await controller.stream.toList())
              .reduce((value, element) => value + element);

          if (listEquals(data.sublist(0, 10), 'RENPY RPC2'.codeUnits)) {
            int position = 10;
            Map<int, dynamic> chunks = {};
            while (true) {
              int slot =
                  Uint8List.fromList(data.sublist(position, position + 4))
                      .buffer
                      .asByteData()
                      .getUint32(0, Endian.little);
              position += 4;
              int start =
                  Uint8List.fromList(data.sublist(position, position + 4))
                      .buffer
                      .asByteData()
                      .getUint32(0, Endian.little);
              position += 4;
              int length =
                  Uint8List.fromList(data.sublist(position, position + 4))
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

          try {
            List<dynamic> compiled = loads(
              Uint8List.fromList(data),
              recognizedDescriptors: descriptors,
              swappers: swappers,
            );

            parseFile(compiled);
          } on UnimplementedError {
            print('Unimplemented error in ${file.path}, skipping...');
            continue;
          }

          decompiledFilesAmount++;
        }

        totalAttemptedFilesAmount += attemptedFilesAmount;
        totalDecompiledFilesAmount += decompiledFilesAmount;

        if (attemptedFilesAmount == 0) {
          print('No .RPYC files found in ${archive.path}');
        } else {
          print(
              'Decompiled $decompiledFilesAmount/$attemptedFilesAmount .RPYC files (${(decompiledFilesAmount / attemptedFilesAmount * 100).toStringAsFixed(2)}%)');
        }

        if (totalAttemptedFilesAmount != 0) {
          print(
              'Decompiled $totalDecompiledFilesAmount/$totalAttemptedFilesAmount .RPYC files so far (${(totalDecompiledFilesAmount / totalAttemptedFilesAmount * 100).toStringAsFixed(2)}%)');
        }
      });
    }
  });
}
