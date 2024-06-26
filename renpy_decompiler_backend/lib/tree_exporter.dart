import 'dart:async';
import 'dart:io';

import 'package:glob/glob.dart';
import 'package:path/path.dart';
import 'package:renpy_decompiler_backend/tree_creator.dart';

Future<int> exportTree(TreeNode tree, Directory output,
    [bool overwrite = true,
    Glob? filter,
    String currentPath = '',
    int currentFileAmount = 0,
    int? totalFileAmount,
    Sink<({int amount, int max})>? sink]) async {
  if (tree is TreeNodeFile) {
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
  } else {
    // Would be unfortunate...
    if (tree.path == '/') {
      tree.path = '';
    }
    Directory directoryToExportTo =
        Directory(join(output.path, currentPath, tree.path));
    if (filter == null || filter.matches(directoryToExportTo.path)) {
      await directoryToExportTo.create(recursive: true);
    }
    for (TreeNode child in tree.childNodes) {
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
  }

  return currentFileAmount;
}

Future<void> exportFile(TreeNodeFile file, File output) async {
  IOSink sink = output.openWrite();

  file.postProcess(sink);
  await sink.flush();
  await sink.close();
}
