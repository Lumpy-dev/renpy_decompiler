// This file is made to emulate the testing process of the project UnRPYC made by CensoredUsername and other contributors

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/hash.dart';
import 'package:path/path.dart';
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/rpyc_parser.dart';
import 'package:renpy_decompiler_backend/tree_creator.dart';

int totalAttemptedFilesAmount = 0;
int totalDecompiledFilesAmount = 0;

void main() {
  String unrpycPath =
      const String.fromEnvironment('UNRPYC_PATH', defaultValue: 'test/unrpyc');

  Directory unrpycHome = Directory(unrpycPath);

  File unrpycDotPy = File(join(unrpycHome.path, 'unrpyc.py'));

  final cipher = SHA256();

  Map<String, Uint8List> filesToHash = {};

  Directory rpaDir = Directory('test/rpa');

  Directory testcaseDir = Directory('test/testcases');
  Directory testcaseCompiledDir = Directory(join(testcaseDir.path, 'compiled'));

  group('RPA extraction', () {
    setUpAll(() async {
      // if (testcaseCompiledDir.existsSync()) {
      //   print(
      //       'Testcases\'s compile directory already exists, skipping extraction');
      //   return;
      // }

      if (!unrpycDotPy.existsSync()) {
        print('UnRPYC not found, skipping extraction');
        return;
      }

      testcaseCompiledDir.createSync();
    });

    for (var archive in rpaDir.listSync(recursive: true)) {
      if (archive is! File || !archive.path.endsWith('.rpa')) {
        continue;
      }

      test('${basename(archive.absolute.path)} extraction', () async {
        if (!(await isRPAFile(archive))) {
          return;
        }

        var createdTree = await createTree(archive, false);

        List<TreeNodeFile> files = listFiles(createdTree, []);

        for (TreeNodeFile file in files) {
          if (file.path.endsWith('.rpyc')) {
            StreamController<List<int>> controller = StreamController();

            file.postProcess(controller.sink);
            controller.sink.close();

            List<int> data = (await controller.stream.toList())
                .reduce((value, element) => value + element);

            File extractedFile = File(join(testcaseCompiledDir.path,
                basename(archive.path), (file as RPATreeNodeFile).fullPath));
            extractedFile.createSync(recursive: true);
            extractedFile.writeAsBytesSync(data);
          }
        }
      });
    }
  });

  group('Dart rpyc decryption', () {
    if (!rpaDir.existsSync()) {
      print('RPA directory not found, skipping tests');
      return;
    }

    for (var archive in rpaDir.listSync(recursive: true)) {
      if (archive is! File || !archive.path.endsWith('.rpa')) {
        continue;
      }

      test('${basename(archive.absolute.path)} Dart decryption', () async {
        if (!(await isRPAFile(archive))) {
          return;
        }

        var createdTree = await createTree(archive, false);

        List<TreeNodeFile> files = listFiles(createdTree, []);

        int attemptedFilesAmount = 0;
        int decompiledFilesAmount = 0;

        for (TreeNodeFile file in files) {
          if (extension(file.path) != '.rpyc') continue;

          attemptedFilesAmount++;

          StreamController<List<int>> controller = StreamController();

          file.postProcess(controller.sink);
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
            List<dynamic> compiled = loads(Uint8List.fromList(data),
                recognizedDescriptors: descriptors,
                swappers: swappers,
                silent: false);

            String out = parseFile(compiled);
            out += // To match accurately with the unrpyc output, not actually decompiled via unrpyc
                '\n# Decompiled by unrpyc: https://github.com/CensoredUsername/unrpyc\n';
            filesToHash[join(basename(archive.path),
                    (file as RPATreeNodeFile).fullPath)] =
                cipher.update(Uint8List.fromList(out.codeUnits)).digest();
            cipher.reset();
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

  test('Compare', () async {
    if (testcaseCompiledDir
        .listSync(recursive: true)
        .any((element) => extension(element.path) == '.rpy')) {
      print('Already ran unrpyc, skipping');
    } else {
      var result = Process.runSync(
          'python', [unrpycDotPy.path, testcaseCompiledDir.path, '-c']);
      if (result.exitCode != 0) {
        fail('Couldn\'t make unrpyc decompile files');
      }
    }

    for (var file in filesToHash.entries) {
      var unrpycFile =
          File(join(testcaseCompiledDir.path, setExtension(file.key, '.rpy')));
      if (!unrpycFile.existsSync()) {
        fail('File ${file.key} not found in unrpyc output');
      }

      var unrpycHash = cipher.update(unrpycFile.readAsBytesSync()).digest();
      cipher.reset();
      if (!listEquals(unrpycHash, file.value)) {
        // Re-decompile the file in dart and compare both
        File fileToDecompile = File(join(testcaseCompiledDir.path, file.key));
        List<int> data = fileToDecompile.readAsBytesSync();

        if (listEquals(data.sublist(0, 10), 'RENPY RPC2'.codeUnits)) {
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

        List<dynamic> compiled = loads(Uint8List.fromList(data),
            recognizedDescriptors: descriptors,
            swappers: swappers,
            silent: false);

        String out = parseFile(compiled);
        out += // To match accurately with the unrpyc output, not actually decompiled via unrpyc
            '\n# Decompiled by unrpyc: https://github.com/CensoredUsername/unrpyc\n';

        expect(out.trim(), unrpycFile.readAsStringSync().trim());
      } else {
        print('Hashes of ${file.key} match');
      }
    }
  });
}
