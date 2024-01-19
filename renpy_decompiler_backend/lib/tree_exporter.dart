import 'dart:async';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart';
import 'package:renpy_decompiler_backend/tree_creator.dart';

Future<int> exportTree(RPATreeNode tree, Directory output,
    [bool overwrite = true,
    Glob? filter,
    String currentPath = '',
    int currentFileAmount = 0,
    int? totalFileAmount,
    Sink<({int amount, int max})>? sink]) async {
  if (tree is RPATreeNodeDirectory) {
    // Would be unfortunate...
    if (tree.path == '/') {
      tree.path = '';
    }
    Directory directoryToExportTo =
        Directory(join(output.path, currentPath, tree.path));
    if (filter == null || filter.matches(directoryToExportTo.path)) {
      await directoryToExportTo.create(recursive: true);
    }
    for (RPATreeNode child in tree.childNodes) {
      currentFileAmount = await exportTree(
          child,
          output,
          overwrite,
          filter,
          join(currentPath, tree.path),
          currentFileAmount,
          totalFileAmount,
          sink);
    }
  } else if (tree is RPATreeNodeFile) {
    File fileToExportTo = File(join(output.path, currentPath, tree.path));

    if ((overwrite || !(await fileToExportTo.exists())) &&
        (filter == null || filter.matches(fileToExportTo.path))) {
      await fileToExportTo.create(recursive: true);
      await exportFile(tree, fileToExportTo);

      totalFileAmount ??= 0;
      currentFileAmount++;

      if (sink != null) {
        sink.add((amount: currentFileAmount, max: totalFileAmount));
      }
    }
  }

  return currentFileAmount;
}

Future<void> exportFile(RPATreeNodeFile file, File output) async {
  IOSink sink = output.openWrite();

  file.version.postProcess(file, sink);
  await sink.flush();
  await sink.close();
}
