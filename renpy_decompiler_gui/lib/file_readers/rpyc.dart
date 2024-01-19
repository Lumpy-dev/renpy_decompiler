import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/bridges/renpy/ast.dart';
import 'package:renpy_decompiler_backend/bridges/renpy/python.dart';
import 'package:renpy_decompiler_backend/bridges/renpy/revertable.dart';
import 'package:renpy_decompiler_backend/bridges/renpy/sl2/slast.dart';
import 'package:renpy_decompiler_backend/rpyc_parser.dart';

class RPYCReader extends StatefulWidget {
  final List<int> bytes;
  const RPYCReader({super.key, required this.bytes});

  @override
  State<RPYCReader> createState() => _RPYCReaderState();
}

class _RPYCReaderState extends State<RPYCReader> {
  late String parsedOut;

  @override
  void initState() {
    super.initState();

    List<int> fileBytes = List.from(widget.bytes);

    if (listEquals(fileBytes.sublist(0, 10), 'RENPY RPC2'.codeUnits)) {
      int position = 10;
      Map<int, dynamic> chunks = {};
      while (true) {
        int slot = Uint8List.fromList(fileBytes.sublist(position, position + 4))
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

    try {
      var out = Unpickler(
              file: Uint8List.fromList(fileBytes),
              recognizedDescriptors: [...astDescriptors, ...slastDescriptors],
              recognizedSwappers: [...revertableSwappers, ...pythonSwappers])
          .load();
      parsedOut = parseFile(out);
    } catch (e) {
      if (e is UnimplementedError) {
        parsedOut =
            'Your file does uses a feature we haven\'t implemented yet, please report this.';
      } else {
        parsedOut = 'Error while decompiling file, please report this:\n$e';
      }
    }
  }

  void printInfoDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Decompiled file'),
            content: const Text('This file was decompiled.\n\n'
                'RPYC files are compiled Ren\'Py script files who tells the engine what to do.\n'
                'As this is not the original script file, it may defer from what the artist originally wrote.\n'
                'If you see any obvious issues with this code please report this.\n'
                'This decompiler was made possible with the UnRPYC Python project which was then ported to Dart.\n'
                'We have not yet achieved feature parity, the only missing feature are: screens and testcases.\n\n' // TODO: Remove this note once we have feature parity
                'If you find many empty lines, those are usually comments that were removed by the compiler.'),
            actions: [
              TextButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          bottom: 0,
          left: 0,
          right: 0,
          child: SelectableText(parsedOut,
              scrollPhysics: const AlwaysScrollableScrollPhysics()),
        ),
        Positioned.directional(
            top: 6,
            end: 18,
            textDirection: TextDirection.ltr,
            child: TextButton(
              onPressed: printInfoDialog,
              child: Row(
                children: [
                  if (!Platform.isAndroid && !Platform.isIOS) ...[
                    Text('Decompiled file',
                        style: Theme.of(context)
                            .textTheme
                            .labelMedium
                            ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.secondary)),
                    const SizedBox(width: 8),
                  ],
                  Icon(Icons.info,
                      color: Theme.of(context).colorScheme.secondary, size: 24)
                ],
              ),
            )),
      ],
    );
  }
}
