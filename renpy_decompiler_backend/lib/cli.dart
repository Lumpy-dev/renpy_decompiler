import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart';
import 'package:renpy_decompiler_backend/rpyc_parser.dart';
import 'package:renpy_decompiler_backend/tree_creator.dart';
import 'package:renpy_decompiler_backend/tree_exporter.dart';

void main(List<String> args) async {
  await loadCLI(args);
}

Future<void> loadCLI(List<String> args) async {
  CommandRunner runner = CommandRunner(
      'renpy_decompiler_backend', 'A tool to decompile .rpa and .rpyc files')
    ..addCommand(DecompileCommand());

  try {
    await runner.run(args);
  } catch (e) {
    print(e);
    if (e is UsageException) {
      exit(64);
    }
    exit(1);
  } finally {
    exit(0);
  }
}

class DecompileCommand extends Command {
  @override
  String get description => 'Decompile .rpa and .rpyc files';

  @override
  String get name => 'decompile';

  DecompileCommand() {
    addSubcommand(RpaCommand());
    addSubcommand(RpycCommand());
  }
}

class RpaCommand extends Command {
  @override
  String get description => 'Decompile RPAs (.rpa and .rpi files)';

  @override
  String get name => 'rpa';

  @override
  String get invocation =>
      'decompile rpa -i <input> -o <output> [-m] [-f] [-n] [--overwrite] [-f] [-n] [--filter <glob>]';

  @override
  Future<void> run() async {
    Set<File> filesToDecompile = {};

    Set<File> toAdd = {};

    if (input is File) {
      toAdd.add(input as File);
    } else if (input is Directory) {
      toAdd.addAll((input as Directory)
          .listSync(recursive: true, followLinks: true)
          .whereType<File>());
    }

    filesToDecompile.addAll(toAdd);

    if (filesToDecompile.isEmpty) {
      print('Did not found files to decompile.');
    } else {
      print(
          'Found ${filesToDecompile.length} files to decompile, some of them may not be RPAs.');
    }

    int attemptedAmount = 0;
    int successAmount = 0;

    for (File archive in filesToDecompile) {
      bool isRPAArchive = await isRPAFile(archive);
      if (!isRPAArchive) {
        continue;
      } else {
        attemptedAmount++;
        Directory outputFolder = Directory(output.path);

        if (!merge) {
          outputFolder = Directory(join(
              outputFolder.path,
              File(relative(archive.absolute.path, from: input.path))
                  .parent
                  .path,
              basenameWithoutExtension(archive.path)));
        }

        print('Decompiling ${basename(archive.path)}...');

        if (outputFolder.existsSync()) {
          if (outputFolder.listSync().isNotEmpty && !force && !merge) {
            throw FileSystemException(
                'Output folder is not empty and force is not enabled.');
          }
        } else {
          outputFolder.createSync(recursive: true);
        }

        var out = await createTree(archive);

        try {
          int fileAmount =
              await exportTree(out.tree, outputFolder, overwrite, filter);
          if (fileAmount == 0) {
            print('No files were exported.');
          } else {
            print('Exported $fileAmount file(s).');
          }
        } catch (e) {
          if (noFail) {
            print('Failed to decompile ${archive.path}: $e');
            continue;
          } else {
            rethrow;
          }
        }

        successAmount++;
      }
    }

    print(
        'Successfully decompiled $successAmount out of $attemptedAmount archive(s).');
  }

  late FileSystemEntity input;
  late Directory output;
  late bool merge;
  late bool force;
  late bool overwrite;
  late bool noFail;
  late Glob filter;

  RpaCommand() {
    argParser.addOption('input',
        abbr: 'i',
        help:
            'Input file(s)/folder(s), if a folder is specified, all .rpa files in the folder will be decompiled',
        mandatory: true, callback: (value) {
      if (FileSystemEntity.isDirectorySync(value!)) {
        input = Directory(value).absolute;
      } else if (FileSystemEntity.isFileSync(value)) {
        input = File(value).absolute;
      } else if (FileSystemEntity.isLinkSync(value)) {
        String path = Link(value).resolveSymbolicLinksSync();
        if (FileSystemEntity.isDirectorySync(path)) {
          input = Directory(path).absolute;
        } else if (FileSystemEntity.isFileSync(path)) {
          input = File(path).absolute;
        } else {
          throw ArgumentError('Invalid input: $value');
        }
      } else {
        throw ArgumentError('Invalid input: $value');
      }
    });
    argParser.addOption('output',
        abbr: 'o', help: 'Output folder', mandatory: true, callback: (value) {
      if (FileSystemEntity.isDirectorySync(value!)) {
        output = Directory(value).absolute;
      } else if (FileSystemEntity.isLinkSync(value)) {
        String path = Link(value).resolveSymbolicLinksSync();
        if (FileSystemEntity.isDirectorySync(path)) {
          output = Directory(path).absolute;
        } else {
          throw ArgumentError('$path must be a folder or a link to one.');
        }
      } else {
        throw ArgumentError('$value must be a folder or a link to one.');
      }
    });
    argParser.addFlag('merge',
        abbr: 'm',
        help:
            'Merge all of the RPAs in one folder, could lead to merge conflicts if all of the .RPAs do not come from the same game',
        negatable: false, callback: (value) {
      merge = value;
    });
    argParser.addFlag('force',
        abbr: 'f',
        help: 'Can write in an non-empty folder',
        negatable: false, callback: (value) {
      force = value;
    });
    argParser.addFlag('overwrite',
        help: 'Can write on top of existing files',
        negatable: false, callback: (value) {
      overwrite = value;
    });
    argParser.addFlag('no-fail',
        abbr: 'n',
        help:
            'Continues to decompile even if the file before wasn\'t decompiled correctly',
        negatable: false, callback: (value) {
      noFail = value;
    });
    argParser.addOption('filter',
        help: 'Only exports files whose file name match the provided glob',
        defaultsTo: '**', callback: (value) {
      if (value == null) {
        throw ArgumentError('Provided empty filter.');
      }
      try {
        filter = Glob(value);
      } on FormatException catch (e) {
        throw ArgumentError('Invalid glob: ${e.message}');
      }
    });
  }
}

class RpycCommand extends Command {
  @override
  String get description => 'Decompile RPYC files';

  @override
  String get name => 'rpyc';

  @override
  String get invocation =>
      'decompile rpyc -i <input> -o <output> [-m] [-f] [-n] [--overwrite] [-f] [-p <prefix>] [-s <suffix>]';

  @override
  Future<void> run() async {
    Set<File> filesToDecompile = {};

    Set<File> toAdd = {};

    if (input is File) {
      toAdd.add(input as File);
    } else if (input is Directory) {
      toAdd.addAll((input as Directory)
          .listSync(recursive: true, followLinks: true)
          .whereType<File>());
    }

    filesToDecompile.addAll(toAdd);

    if (filesToDecompile.isEmpty) {
      print('Did not found files to decompile.');
    } else {
      print(
          'Found ${filesToDecompile.length} files to decompile, some of them may not be RPYC files.');
    }

    int attemptedAmount = 0;
    int successAmount = 0;

    for (File file in filesToDecompile) {
      bool isARPYCFile = isRPYCFile(file);
      if (!isARPYCFile) {
        continue;
      } else {
        attemptedAmount++;
        Directory outputFolder = Directory(output.path);

        if (!merge) {
          outputFolder = Directory(join(
              outputFolder.path,
              File(relative(file.absolute.path, from: input.path)).parent.path,
              basenameWithoutExtension(file.path)));
        }

        File outputFile = File(
            join(outputFolder.path, prefix + basename(file.path) + suffix));

        print('Decompiling ${basename(file.path)}...');

        if (outputFile.existsSync()) {
          if (!force && !merge) {
            throw FileSystemException(
                'Output file is not empty and force is not enabled.');
          }
        } else {
          outputFile.createSync(recursive: true);
        }

        try {
          outputFile.writeAsStringSync(decompileRPYC(file));
        } catch (e) {
          if (noFail) {
            print('Failed to decompile ${file.path}: $e');
            continue;
          } else {
            rethrow;
          }
        }

        successAmount++;
      }
    }

    print(
        'Successfully decompiled $successAmount out of $attemptedAmount file(s).');
  }

  late FileSystemEntity input;
  late Directory output;
  late bool merge;
  late bool force;
  late bool overwrite;
  late bool noFail;
  late String prefix;
  late String suffix;

  RpycCommand() {
    argParser.addOption('input',
        abbr: 'i',
        help:
            'Input file/folder, if a folder is specified, all .rpa files in the folder will be decompiled',
        mandatory: true, callback: (value) {
      if (FileSystemEntity.isDirectorySync(value!)) {
        input = Directory(value).absolute;
      } else if (FileSystemEntity.isFileSync(value)) {
        input = File(value).absolute;
      } else if (FileSystemEntity.isLinkSync(value)) {
        String path = Link(value).resolveSymbolicLinksSync();
        if (FileSystemEntity.isDirectorySync(path)) {
          input = Directory(path).absolute;
        } else if (FileSystemEntity.isFileSync(path)) {
          input = File(path).absolute;
        } else {
          throw ArgumentError('Invalid input: $value');
        }
      } else {
        throw ArgumentError('Invalid input: $value');
      }
    });
    argParser.addOption('output',
        abbr: 'o', help: 'Output folder', mandatory: true, callback: (value) {
      if (FileSystemEntity.isDirectorySync(value!)) {
        output = Directory(value).absolute;
      } else if (FileSystemEntity.isLinkSync(value)) {
        String path = Link(value).resolveSymbolicLinksSync();
        if (FileSystemEntity.isDirectorySync(path)) {
          output = Directory(path).absolute;
        } else {
          throw ArgumentError('$path must be a folder or a link to one.');
        }
      } else {
        throw ArgumentError('$value must be a folder or a link to one.');
      }
    });
    argParser.addFlag('merge',
        abbr: 'm',
        help:
            'Merge all of the RPYC files in one folder, could lead to merge conflicts if multiple RPYC files have the same name.',
        negatable: false, callback: (value) {
      merge = value;
    });
    argParser.addFlag('force',
        abbr: 'f',
        help: 'Can write in an non-empty folder',
        negatable: false, callback: (value) {
      force = value;
    });
    argParser.addFlag('overwrite',
        help: 'Can write on top of existing files',
        negatable: false, callback: (value) {
      overwrite = value;
    });
    argParser.addFlag('no-fail',
        abbr: 'n',
        help:
            'Continues to decompile even if the file before wasn\'t decompiled correctly',
        negatable: false, callback: (value) {
      noFail = value;
    });
    argParser.addOption('prefix',
        abbr: 'p',
        help: 'The prefix to add to all decompiled RPY files',
        defaultsTo: '', callback: (value) {
      prefix = value!;
    });
    argParser.addOption('suffix',
        abbr: 's',
        help: 'The suffix to add to all decompiled RPY files',
        defaultsTo: '.rpy', callback: (value) {
      suffix = value!;
    });
  }
}
