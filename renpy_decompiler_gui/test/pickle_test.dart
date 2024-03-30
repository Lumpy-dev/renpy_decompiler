import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hash/hash.dart';
import 'package:path/path.dart';
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/tree_creator.dart';

void main() {
  // Performance between Python and Dart here is not comparable, most of the compute time in Dart is flushing all the data to stdout or a file.
  group('Dart pickle dis against Python pickle dis', () {
    Directory rpaDir = Directory('test/rpa');
    print(rpaDir.absolute.path);

    if (!rpaDir.existsSync()) {
      print('RPA directory not found, skipping tests');
      return;
    }

    for (var file in rpaDir.listSync()) {
      test('test ${basename(file.path)}\'s dis', () async {
        if (file is File) {
          print('Testing ${file.path}');
          List<int> decompressed =
              (await findIndexAndVersion(file)).decompressedIndex;

          File tempObj = File('in.pickle');
          tempObj.writeAsBytesSync(decompressed);

          print('Running Python');
          var result = await Process.run(
              'python', ['test/pickle_dis.py', tempObj.absolute.path],
              runInShell: true);
          print('Python dis finished, exit code: ${result.exitCode}');

          print('Running Dart');
          await dis(decompressed, out: File('out_dis_dart.txt').openWrite());
          print('Dart dis finished');

          expect(
              MD5().update(File('out_dis_dart.txt').readAsBytesSync()).digest(),
              MD5()
                  .update(File('out_dis_python.txt').readAsBytesSync())
                  .digest());
        }
      });
    }
  });

  // Here the performance is comparable, but Dart is still slower because of its flush, if all was kept in memory the results would be the same.
  group('Dart pickle load against Python pickle load', () {
    Directory rpaDir = Directory('test/rpa');

    if (!rpaDir.existsSync()) {
      print('RPA directory not found, skipping tests');
      return;
    }

    for (var file in rpaDir.listSync()) {
      test('test ${basename(file.path)}\'s load', () async {
        if (file is File) {
          print('Testing ${file.path}');
          var indexAndVersion = await findIndexAndVersion(file);

          File tempObj = File('in.pickle');
          tempObj.writeAsBytesSync(indexAndVersion.decompressedIndex);

          print('Running Python');
          var result = await Process.run(
              'python', ['test/pickle_load.py', tempObj.absolute.path],
              runInShell: true);
          print('Python load finished, exit code: ${result.exitCode}');
          if (result.exitCode != 0) {
            print(result.stdout);
            print(result.stderr);
          }

          print('Running Dart');
          Map<dynamic, dynamic> outIndex =
              loads(Uint8List.fromList(indexAndVersion.decompressedIndex));
          print('Dart load finished');

          print('Writing Dart output to file');
          var out = File('out_load_dart.txt').openWrite();
          for (var entry in outIndex.entries) {
            out.writeln(
                '${entry.key} ${entry.value[0][0]}-${entry.value[0][1]}');
          }
          await out.flush();
          await out.close();
          print('Dart output written to file');

          expect(
              MD5()
                  .update(File('out_load_dart.txt').readAsBytesSync())
                  .digest(),
              MD5()
                  .update(File('out_load_python.txt').readAsBytesSync())
                  .digest());
        }
      });
    }
  });
}
