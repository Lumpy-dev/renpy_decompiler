import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:renpy_decompiler_backend/tree_creator.dart';
import 'package:renpy_decompiler_backend/tree_exporter.dart';
import 'package:renpy_decompiler_gui/file_explorer.dart';
import 'package:renpy_decompiler_gui/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

bool? isMPVInstalled;
late final PackageInfo packageInfo;

void main(List<String> args) async {
  await loadFlutter();
}

Future<void> loadFlutter() async {
  WidgetsFlutterBinding.ensureInitialized();

  isMPVInstalled = Platform.isLinux
      ? Process.runSync('mpv', ['--version']).exitCode != 127
      : null;

  packageInfo = await PackageInfo.fromPlatform();

  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ren\'Py decompiler',
      theme: const MaterialTheme(TextTheme()).light(),
      highContrastTheme: const MaterialTheme(TextTheme()).lightHighContrast(),
      darkTheme: const MaterialTheme(TextTheme()).dark(),
      highContrastDarkTheme:
          const MaterialTheme(TextTheme()).darkHighContrast(),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  TreeNode? tree;
  String? currentFilePath;
  RPAVersion? version;
  List<TreeNodeFile>? selectedFiles;
  TreeNodeFile? currentFileNode;

  StreamController<({int amount, int max})>? unarchivalStreamController;

  Future<void> exportFiles(List<TreeNode> files, Directory directory) async {
    setState(() {
      unarchivalStreamController = StreamController();
    });

    int fileAmount = 0;

    for (var child in files) {
      fileAmount += countFiles(child, 0);
    }

    int currentFileAmount = 0;
    // We cannot give the root of the tree or it would try to write on the root of the OS.
    for (var child in files) {
      currentFileAmount = (await exportTree(child, directory, true, null, '',
          currentFileAmount, fileAmount, unarchivalStreamController!.sink));
    }

    setState(() {
      unarchivalStreamController = null;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
          'Exported $currentFileAmount file${currentFileAmount == 1 ? '' : 's'}'),
    ));
  }

  void openFile() {
    FilePicker.platform
        .pickFiles(
            allowMultiple: false,
            allowCompression: false,
            dialogTitle: 'Select a file',
            lockParentWindow: true)
        .then((value) async {
      if (value != null) {
        setState(() {
          unarchivalStreamController = StreamController();
          tree = null;
          currentFilePath = value.files.single.path;
          version = null;

          var futureTree = createTree(File(currentFilePath!));
          futureTree.then((value) {
            unarchivalStreamController = null;
            setState(() {
              tree = value;
              if (tree is RPATreeNode) {
                version = (tree as RPATreeNode).version;
              }
            });
          }, onError: (err) {
            if (err is UnsupportedRPAVersionException) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(err.message),
              ));
            } else {
              if (kDebugMode) {
                throw err;
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content:
                    Text('Couldn\'t open the file, please report this: $err'),
              ));
            }
            setState(() {
              currentFilePath = null;
            });
          });
        });
      }
    });
  }

  void openDirectory() {
    FilePicker.platform
        .getDirectoryPath(
            dialogTitle: 'Select a folder to open', lockParentWindow: true)
        .then((value) async {
      if (value != null) {
        setState(() {
          unarchivalStreamController = StreamController();
          tree = null;
          currentFilePath = value;
          version = null;

          var futureTree = createTree(Directory(currentFilePath!));
          futureTree.then((value) {
            unarchivalStreamController = null;
            setState(() {
              tree = value;
              if (tree is RPATreeNode) {
                version = (tree as RPATreeNode).version;
              }
            });
          }, onError: (err) {
            if (err is UnsupportedRPAVersionException) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(err.message),
              ));
            } else {
              if (kDebugMode) {
                throw err;
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'Couldn\'t open the directory, please report this: $err'),
              ));
            }
            setState(() {
              currentFilePath = null;
            });
          });
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    if (isMPVInstalled == false) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
        final SharedPreferences prefs = await SharedPreferences.getInstance();

        shouldShowDialog = prefs.getBool('shouldHideMPVDialog') ?? false;

        if (!shouldShowDialog!) {
          if (!mounted) return;

          showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return const MPVDialog();
            },
          );
        }
      });
    }
  }

  void _dialogBuilder(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text(
            'You are going to export the entire archive to a folder.',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Export'),
              onPressed: () {
                Navigator.of(context).pop();
                FilePicker.platform
                    .getDirectoryPath(
                        dialogTitle: 'Pick folder to save the archive to',
                        lockParentWindow: true,
                        initialDirectory: currentFileNode is TreeNodeFile
                            ? File(currentFilePath!).parent.path
                            : currentFilePath)
                    .then((value) async {
                  if (value != null) {
                    exportFiles(tree!.childNodes, Directory(value));
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  int? countSelectedFiles([TreeNode? current, int amount = 0]) {
    if (selectedFiles == null) {
      return null;
    }

    if (current == null) {
      for (var child in selectedFiles!) {
        amount = countSelectedFiles(child, amount)!;
      }
    }

    if (current is TreeNodeFile) {
      return amount + 1;
    }

    return amount;
  }

  bool setSelected = true;

  bool? shouldShowDialog;

  @override
  Widget build(BuildContext context) {
    Widget openButton = IconButton(
        tooltip: 'Open', onPressed: openFile, icon: const Icon(Icons.add));

    List<PopupMenuItem<List<TreeNode>>> possibilities = [
      PopupMenuItem(
        value: tree?.childNodes ?? [],
        child: const Text('Unarchive all'),
      ),
    ];

    if (selectedFiles != null) {
      possibilities.add(PopupMenuItem(
        value: selectedFiles!,
        child: const Text('Unarchive selected files'),
      ));
    }

    if (currentFileNode != null) {
      possibilities.add(PopupMenuItem(
        value: [currentFileNode!],
        child: const Text('Unarchive current file'),
      ));
    }

    Widget unarchiveAllButton = IconButton(
      onPressed: () {
        _dialogBuilder(context);
      },
      icon: const Icon(Icons.unarchive),
      tooltip: 'Unarchive',
    );

    Widget unarchiveChooseButton = PopupMenuButton<List<TreeNode>>(
        itemBuilder: (context) {
          return possibilities;
        },
        tooltip: 'Choose what to export',
        icon: const Icon(Icons.unarchive),
        onSelected: (selection) {
          FilePicker.platform
              .getDirectoryPath(
                  dialogTitle: 'Pick folder to save the files to',
                  lockParentWindow: true,
                  initialDirectory: currentFileNode is TreeNodeFile
                      ? File(currentFilePath!).parent.path
                      : currentFilePath)
              .then((value) async {
            if (value != null) {
              if (selection == tree!.childNodes) {
                _dialogBuilder(context);
                return;
              }

              exportFiles(selection, Directory(value));
            }
          });
        });

    Widget infoButton = IconButton(
      onPressed: () {
        showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Information'),
                content: Text('Name: ${currentFileNode!.name}\n'
                    'Size: ${(currentFileNode!.size / 1000000).toStringAsFixed(2)} MB\n'
                    'Version: ${version?.version ?? 'Not an archive'}'),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'))
                ],
              );
            });
      },
      icon: const Icon(Icons.info),
      tooltip: 'Information',
    );

    int? selectedFileAmount = countSelectedFiles();

    return Scaffold(
      appBar: currentFilePath == null
          ? null
          : AppBar(
              backgroundColor: selectedFiles == null
                  ? null
                  : Theme.of(context).colorScheme.surfaceVariant,
              leading: IconButton(
                  onPressed: () {
                    setState(() {
                      if (selectedFiles != null) {
                        selectedFiles = null;
                      } else {
                        currentFilePath = null;
                        tree = null;
                        version = null;
                        currentFileNode = null;
                      }
                    });
                  },
                  icon: const Icon(Icons.close),
                  tooltip: selectedFiles == null
                      ? 'Close the archive'
                      : 'Deselect all files'),
              title: Text(tree == null
                  ? 'Location is being opened...'
                  : (selectedFiles != null
                      ? '$selectedFileAmount location${selectedFileAmount == 1 ? '' : 's'} selected'
                      : '${p.basename(tree!.path)}${version != null ? ', ${version!.version}' : ''}')),
              actions: tree == null
                  ? []
                  : [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: (!Platform.isAndroid &&
                                    !Platform.isIOS &&
                                    !kDebugMode) ||
                                selectedFiles == null ||
                                currentFileNode == null
                            ? Container()
                            : infoButton,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: openButton,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                        child: possibilities.length == 1
                            ? unarchiveAllButton
                            : unarchiveChooseButton,
                      ),
                    ],
              bottom: unarchivalStreamController == null
                  ? null
                  : PreferredSize(
                      preferredSize: const Size(double.infinity, 6),
                      child: StreamBuilder<({int amount, int max})>(
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return LinearProgressIndicator(
                                  value: snapshot.data!.amount /
                                      snapshot.data!.max);
                            } else {
                              return const LinearProgressIndicator();
                            }
                          },
                          stream: unarchivalStreamController!.stream))),
      body: tree == null
          ? Stack(
              children: [
                Center(
                    child: Platform.isAndroid || Platform.isIOS
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FilledButton(
                                  onPressed: openFile,
                                  child: const Text('Open archive/file')),
                              FilledButton(
                                  onPressed: openDirectory,
                                  child: const Text('Open directory')),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              FilledButton(
                                  onPressed: openFile,
                                  child: const Text('Open archive/file')),
                              FilledButton(
                                  onPressed: openDirectory,
                                  child: const Text('Open directory')),
                            ],
                          )),
                Positioned.directional(
                    textDirection: TextDirection.ltr,
                    bottom: 8,
                    end: 8,
                    child: IconButton(
                        onPressed: () {
                          showAboutDialog(
                              context: context,
                              applicationLegalese:
                                  'Available under the MIT license.',
                              applicationVersion: packageInfo.version);
                        },
                        icon: const Icon(Icons.info),
                        tooltip: 'About'))
              ],
            )
          : ArchiveExplorer(
              tree: tree!,
              currentPosition: currentFileNode is TreeNodeFile
                  ? File(currentFilePath!)
                  : Directory(currentFilePath!),
              onNewSelection: (selected) => setState(() {
                selectedFiles = selected;
              }),
              onNodeSelected: (node) {
                setState(() {
                  currentFileNode = node;
                });
              },
              setSelected: setSelected,
              selectedFiles: selectedFiles,
            ),
    );
  }
}

class MPVDialog extends StatefulWidget {
  const MPVDialog({super.key});

  @override
  State<MPVDialog> createState() => _MPVDialogState();
}

class _MPVDialogState extends State<MPVDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('MPV not found'),
      content: const Text(
          'MPV is required to play audio files. Audio files won\'t be played in the app until you install MPV, but you can export them then play them with another app.'),
      actions: [
        TextButton(
            onPressed: () {
              launchUrlString('https://mpv.io/installation/',
                  mode: LaunchMode.externalApplication);
            },
            child: const Text('See instructions')),
        TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();

              prefs.setBool('shouldHideMPVDialog', true);
            },
            child: const Text('Do not show again')),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);

            final SharedPreferences prefs =
                await SharedPreferences.getInstance();

            prefs.setBool('shouldHideMPVDialog', false);
          },
          child: const Text('Continue anyway'),
        )
      ],
    );
  }
}
