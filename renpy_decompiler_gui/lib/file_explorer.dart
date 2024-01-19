import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:renpy_decompiler_backend/tree_creator.dart';
import 'package:renpy_decompiler_gui/audio_player_widget.dart';
import 'package:renpy_decompiler_gui/file_readers/font.dart';
import 'package:renpy_decompiler_gui/file_readers/rpyc.dart';
import 'package:renpy_decompiler_gui/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ArchiveExplorer extends StatefulWidget {
  final RPATreeNode tree;
  final File currentArchiveFile;
  final void Function(List<RPATreeNodeFile>? selected) onNewSelection;
  final void Function(RPATreeNodeFile node) onNodeSelected;
  final bool setSelected;
  final List<RPATreeNodeFile>? selectedFiles;

  const ArchiveExplorer(
      {super.key,
      required this.tree,
      required this.currentArchiveFile,
      required this.onNewSelection,
      required this.onNodeSelected,
      this.setSelected = false,
      this.selectedFiles});

  @override
  State<ArchiveExplorer> createState() => _ArchiveExplorerState();
}

class _ArchiveExplorerState extends State<ArchiveExplorer> {
  RPATreeNodeFile? currentNode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      Widget fileViewer = FileViewer(
          key: ValueKey(currentNode?.path), currentNode: currentNode);

      Widget treeExplorer = TreeExplorer(
          tree: widget.tree,
          onNewSelection: widget.onNewSelection,
          onNodeSelected: (node) {
            if (node.path == currentNode?.path &&
                !Platform.isAndroid &&
                !Platform.isIOS) {
              return;
            }

            setState(() {
              currentNode = node;
              widget.onNodeSelected(node);
            });

            if (Platform.isAndroid || Platform.isIOS) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => FileViewer(currentNode: node)));
            }
          },
          setSelected: widget.setSelected,
          selectedFiles: widget.selectedFiles,
          currentNode: currentNode);

      if (Platform.isAndroid || Platform.isIOS) {
        return treeExplorer;
      } else {
        return Row(children: [
          SizedBox(
              width: constraints.maxWidth / 4,
              height: constraints.maxHeight,
              child: treeExplorer),
          if (!Platform.isAndroid && !Platform.isIOS)
            const VerticalDivider(width: 0),
          SizedBox(
              width: constraints.maxWidth / 4 * 3,
              height: constraints.maxHeight,
              child: fileViewer)
        ]);
      }
    });
  }
}

class TreeExplorer extends StatefulWidget {
  final void Function(RPATreeNodeFile node)? onNodeSelected;
  final void Function(List<RPATreeNodeFile>? selected) onNewSelection;
  final RPATreeNode tree;
  final bool setSelected;
  final List<RPATreeNodeFile>? selectedFiles;
  final RPATreeNode? currentNode;

  const TreeExplorer(
      {super.key,
      required this.onNodeSelected,
      required this.onNewSelection,
      required this.tree,
      this.setSelected = false,
      this.selectedFiles,
      required this.currentNode});

  @override
  State<TreeExplorer> createState() => _TreeExplorerState();
}

class _TreeExplorerState extends State<TreeExplorer> {
  List<RPATreeNodeFile>? selectedFiles;

  @override
  Widget build(BuildContext context) {
    if (widget.setSelected) {
      selectedFiles = widget.selectedFiles;
    }

    return Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(child: _buildTree(widget.tree, context)));
  }

  Widget _buildTree(RPATreeNode node, BuildContext context) {
    if (node is RPATreeNodeFile) {
      return ListTile(
          key: Key(basename(node.path)),
          title: Text(basename(node.path)),
          tileColor: widget.currentNode?.path == node.path
              ? Theme.of(context).hoverColor
              : null,
          onTap: () {
            if (selectedFiles != null) {
              setState(() {
                if (selectedFiles!.contains(node)) {
                  selectedFiles!.remove(node);

                  if (selectedFiles!.isEmpty) {
                    selectedFiles = null;
                  }
                } else {
                  selectedFiles!.add(node);
                }

                widget.onNewSelection(selectedFiles);
              });

              return;
            }

            widget.onNodeSelected?.call(node);
          },
          onLongPress: selectedFiles != null
              ? null
              : () {
                  setState(() {
                    selectedFiles = [node];
                  });

                  widget.onNewSelection(selectedFiles);
                },
          visualDensity: VisualDensity.comfortable,
          selected: selectedFiles?.contains(node) ?? false,
          selectedTileColor: Theme.of(context).colorScheme.surfaceVariant,
          selectedColor: Theme.of(context).colorScheme.onSurface);
    } else {
      return ExpansionTile(
        key: Key(basename(node.path)),
        title: Text(basename(node.path)),
        children: _buildChildren(node.childNodes, context),
      );
    }
  }

  List<Widget> _buildChildren(
      List<RPATreeNode> children, BuildContext context) {
    if (children.isEmpty) {
      return [];
    }

    return children.map<Widget>((child) => _buildTree(child, context)).toList();
  }
}

class FileViewer extends StatefulWidget {
  final RPATreeNodeFile? currentNode;

  const FileViewer({super.key, required this.currentNode});

  @override
  State<FileViewer> createState() => _FileViewerState();
}

class _FileViewerState extends State<FileViewer> {
  StreamController<List<int>> controller = StreamController<List<int>>();
  List<int> currentFileBytes = [];

  @override
  void initState() {
    super.initState();

    if (widget.currentNode != null) {
      RPATreeNodeFile currentFile = widget.currentNode as RPATreeNodeFile;

      currentFile.version.postProcess(currentFile, controller.sink);
      controller.sink.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Builder(builder: (context) {
      if (widget.currentNode == null ||
          widget.currentNode is RPATreeNodeDirectory) {
        return Center(
          child: Text('Select a file to open it',
              style: Theme.of(context).textTheme.displayMedium),
        );
      } else {
        return StreamBuilder<List<int>>(
            stream: controller.stream,
            builder: (context, snapshot) {
              if (!controller.isClosed || currentFileBytes.isEmpty) {
                currentFileBytes.addAll(snapshot.data ?? []);
              }

              if (snapshot.connectionState == ConnectionState.done) {
                return _buildFile(currentFileBytes);
              } else {
                return Container();
              }
            });
      }
    });

    if (Platform.isAndroid || Platform.isIOS) {
      return Scaffold(
        appBar: AppBar(
          title: Text(basename(widget.currentNode?.path ?? 'unknown')),
        ),
        body: content,
      );
    } else {
      return content;
    }
  }

  String? mimeType;
  AudioPlayer? player;
  bool firstBuild = true;

  Widget _buildFile(List<int> bytes) {
    if (mimeType == null) {
      mimeType = lookupMimeType(basename(widget.currentNode!.path),
          headerBytes: bytes.sublist(0, defaultMagicNumbersMaxLength));

      switch (extension(widget.currentNode!.path)) {
        case '.rpy':
          mimeType = 'text/plain';
          break;
        case '.rpyb':
          mimeType = 'rpyb';
          break;
        case '.rpyc':
          mimeType = 'rpyc';
          break;
      }

      if (listEquals(bytes.sublist(0, 10), utf8.encode('RENPY RPC2'))) {
        mimeType = 'rpyc';
      }
    }

    switch ((mimeType ?? 'unknown').split('/').first) {
      case 'image':
        return InteractiveViewer(
          child: Center(
            child: Image.memory(Uint8List.fromList(bytes)),
          ),
        );
      case 'audio':
        if (isMPVInstalled == false) {
          return Builder(builder: (context) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('MPV is not installed, cannot play audio',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: () async {
                        launchUrlString('https://mpv.io/installation/',
                            mode: LaunchMode.externalApplication);
                      },
                      child: const Text('Install MPV'))
                ],
              ),
            );
          });
        }

        if (player == null) {
          player = AudioPlayer()
            ..setAudioSource(PlayerAudioSource(bytes, mimeType!));
          player!.play();
        }

        return LayoutBuilder(builder: (context, constraints) {
          return Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              direction: Axis.horizontal,
              children: [
                IconButton(
                    onPressed: () => setState(() {
                          if (player!.playing) {
                            player!.pause();
                          } else {
                            player!.play();
                          }
                        }),
                    icon: player!.playing
                        ? const Icon(Icons.pause)
                        : const Icon(Icons.play_arrow)),
                StreamBuilder(
                    stream: Rx.combineLatest3<Duration, Duration, Duration?,
                            PositionData>(
                        player!.positionStream,
                        player!.bufferedPositionStream,
                        player!.durationStream,
                        (position, bufferedPosition, duration) => PositionData(
                            position,
                            bufferedPosition,
                            duration ?? Duration.zero)),
                    builder: (BuildContext context,
                        AsyncSnapshot<PositionData> snapshot) {
                      final positionData = snapshot.data;
                      return SizedBox(
                        width: constraints.maxWidth / 3 * 2,
                        child: SeekBar(
                          duration: positionData?.duration ?? Duration.zero,
                          position: positionData?.position ?? Duration.zero,
                          bufferedPosition:
                              positionData?.bufferedPosition ?? Duration.zero,
                          onChangeEnd: player!.seek,
                        ),
                      );
                    })
              ],
            ),
          );
        });
      case 'text':
        return Builder(builder: (context) {
          return SelectableText(utf8.decode(bytes, allowMalformed: true),
              scrollPhysics: const AlwaysScrollableScrollPhysics());
        });
      case 'application':
        if (mimeType!.startsWith('application/x-font')) {
          FontLoader loader = FontLoader(
              basenameWithoutExtension(widget.currentNode!.path))
            ..addFont(
                Future.value(Uint8List.fromList(bytes).buffer.asByteData()));
          return FutureBuilder(
              future: loader.load(),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return FontTextReader(family: loader.family);
                }
              });
        }
      case 'rpyc':
        return RPYCReader(bytes: bytes);
    }

    return Builder(builder: (context) {
      return Center(
        child: Text(
            'Unsupported file type${mimeType == null ? '' : ': $mimeType'} (${basename(widget.currentNode!.path)})',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    player?.stop();
    player?.dispose();
  }
}

class PlayerAudioSource extends StreamAudioSource {
  final List<int> bytes;
  final String contentType;
  PlayerAudioSource(this.bytes, this.contentType);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= bytes.length;
    return StreamAudioResponse(
        sourceLength: bytes.length,
        contentLength: end - start,
        offset: start,
        stream: Stream.value(bytes.sublist(start, end)),
        contentType: contentType);
  }
}
