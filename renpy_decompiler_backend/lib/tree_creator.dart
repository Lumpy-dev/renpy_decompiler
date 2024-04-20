import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:path/path.dart';
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/versions/alt.dart';
import 'package:renpy_decompiler_backend/versions/enc.dart';
import 'package:renpy_decompiler_backend/versions/hitomi.dart';
import 'package:renpy_decompiler_backend/versions/official_rpa.dart';
import 'package:renpy_decompiler_backend/versions/plz.dart';
import 'package:renpy_decompiler_backend/versions/tmoz.dart';
import 'package:renpy_decompiler_backend/versions/unofficial_rpa.dart';
import 'package:renpy_decompiler_backend/versions/zix.dart';

abstract class RPAVersion {
  (int offset, int? key) findOffsetAndKey(
      String header, List<int> rawHeader, RandomAccessFile file);
  String get version;
  List<int> get rawVersion => version.codeUnits;
  void postProcess(RPATreeNodeFile source, Sink<List<int>> sink) {
    sink.add(source.read(-1));
  }

  static List<RPAVersion> versions = [
    // "official" ones directly from UnRPA
    RPAVersionOne(),
    RPAVersionTwo(),
    RPAVersionThree(),
    RPAVersionThreePointTwo(),
    RPAVersionFour(),
    RPAAsenheim(),
    ZiX12A(),
    ZiX12B(),
    ALT1(),

    // All the other ones from forks of UnRPA
    ENC1(),
    RPAVersionNinePointTwo(),
    PLZVersion2(),
    PLZVersion3(),
    TMOZVersionZeroTwo(),
  ];

  ComplexIndexEntry normaliseEntry(IndexEntry entry) {
    return [
      for (var part in entry)
        if (part.length == 2)
          [part[0], part[1], []]
        else
          [part[0], part[1], part[2]]
    ];
  }

  Map<String, ComplexIndexEntry> deobfuscateIndex(
      Map<String, IndexEntry> index, int key) {
    return {
      for (var entry in index.entries)
        entry.key: deobfuscateEntry(entry.value, key)
    };
  }

  ComplexIndexEntry deobfuscateEntry(IndexEntry entry, int key) {
    return [
      for (var range in normaliseEntry(entry))
        [range[0] ^ key, range[1] ^ key, range[2]]
    ];
  }

  Map<String, IndexEntry> normaliseIndex(Map<String, ComplexIndexEntry> index) {
    return {
      for (var entry in index.entries) entry.key: normaliseEntry(entry.value)
    };
  }
}

abstract class TreeNode {
  List<TreeNode> childNodes;
  String path;

  TreeNode(this.path, this.childNodes);

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType &&
        other is TreeNode &&
        path == other.path;
  }

  @override
  int get hashCode => path.hashCode;
}

abstract class RPATreeNode {
  RPAVersion version;

  RPATreeNode(this.version);
}

abstract class TreeNodeFile extends TreeNode {
  String get name => basename(path);

  int get size;

  TreeNodeFile(String path) : super(path, []);

  List<int> read(int amount);

  List<int> read1() {
    return read(1);
  }
}

int countFiles(TreeNode node, int amount) {
  for (var child in node.childNodes) {
    amount = countFiles(child, amount);
  }

  if (node is RPATreeNodeFile) {
    return amount + 1;
  }

  return amount;
}

List<RPATreeNodeFile> listFiles(TreeNode node, List<RPATreeNodeFile> files) {
  for (var child in node.childNodes) {
    files = listFiles(child, files);
  }

  if (node is RPATreeNodeFile) {
    files.add(node);
  }

  return files;
}

class RPATreeNodeFile extends TreeNodeFile implements RPATreeNode {
  ComplexIndexPart data;

  @override
  RPAVersion version;

  RandomAccessFile archive;

  RPATreeNodeFile(super.path, this.data, this.version, this.archive);

  @override
  List<int> read(int amount) {
    if (amount > data[1]) {
      throw Exception('Invalid amount to read: $amount, max: ${data[1]}');
    }

    if (amount < 0) {
      amount = data[1];
    }

    Uint8List buffer = Uint8List(amount);

    archive.setPositionSync(data[0]);
    archive.readIntoSync(buffer, 0, data[1]);

    List<int> source = buffer.toList(growable: false);

    if (data[2].isNotEmpty) {
      source = List.from(data[2])..addAll(source);
    }

    return source.take(amount).toList(growable: false);
  }

  @override
  List<int> read1() => read(1);

  @override
  int get size => data[1];

  @override
  String get name => basename(path);
}

class DirectTreeNodeFile extends TreeNodeFile {
  File file;
  FileStat stats;

  DirectTreeNodeFile(super.path, this.file, this.stats);

  @override
  List<int> read(int amount) {
    if (amount > stats.size) {
      throw Exception('Invalid amount to read: $amount, max: ${stats.size}');
    }

    if (amount < 0) {
      amount = stats.size;
    }

    RandomAccessFile inst = file.openSync();
    Uint8List data = inst.readSync(amount);
    inst.closeSync();
    return data;
  }

  @override
  int get size => stats.size;

  @override
  List<int> read1() => read(1);

  @override
  String get name => basename(path);
}

class LoadableTreeNodeDirectory extends TreeNode {
  bool loaded;

  FutureOr<List<TreeNode>> Function(LoadableTreeNodeDirectory current)?
      loadChildNodes;

  FutureOr<LoadableTreeNodeDirectory> loadDirectory() {
    if (!loaded) {
      return () async {
        childNodes = await loadChildNodes!(this);
        loaded = true;
        loadChildNodes = null;

        return this;
      }();
    } else {
      return this;
    }
  }

  LoadableTreeNodeDirectory(super.path, super.childNodes,
      [this.loaded = true, this.loadChildNodes]);
}

class RPATreeNodeDirectory extends TreeNode
    implements RPATreeNode, LoadableTreeNodeDirectory {
  @override
  RPAVersion version;

  @override
  FutureOr<RPATreeNodeDirectory> loadDirectory() {
    if (!loaded) {
      return () async {
        childNodes = await loadChildNodes!(this);
        loaded = true;
        loadChildNodes = null;

        return this;
      }();
    } else {
      return this;
    }
  }

  RPATreeNodeDirectory(super.path, super.childNodes, this.version,
      [this.loaded = true, this.loadChildNodes]);

  @override
  FutureOr<List<TreeNode>> Function(LoadableTreeNodeDirectory current)?
      loadChildNodes;

  @override
  bool loaded;
}

class DirectTreeNodeDirectory extends TreeNode
    implements LoadableTreeNodeDirectory {
  DirectTreeNodeDirectory(super.path, super.childNodes,
      [this.loaded = true, this.loadChildNodes]);

  @override
  FutureOr<List<TreeNode>> Function(LoadableTreeNodeDirectory current)?
      loadChildNodes;

  @override
  bool loaded;

  @override
  FutureOr<DirectTreeNodeDirectory> loadDirectory() {
    if (!loaded) {
      return () async {
        childNodes = await loadChildNodes!(this);
        loaded = true;
        loadChildNodes = null;

        return this;
      }();
    } else {
      return this;
    }
  }
}

// We can just make the tuples into lists.

typedef SimpleIndexPart = List<dynamic>;

typedef SimpleIndexEntry = List<SimpleIndexPart>;

/// Should be (offset, length, start)
typedef ComplexIndexPart = List<dynamic>;

typedef ComplexIndexEntry = List<ComplexIndexPart>;

typedef IndexPart = List<dynamic>;

typedef IndexEntry = List<IndexPart>;

class UnsupportedRPAVersionException implements Exception {
  String message;

  UnsupportedRPAVersionException(this.message);
}

Future<bool> isRPAFile(File file) async {
  List<int> headerLine = [];
  bool finished = false;
  await for (var byteList in file.openRead()) {
    for (var byte in byteList) {
      if (byte == utf8.encode('\n').first) {
        finished = true;
        break;
      }
      headerLine.add(byte);
    }
    if (finished) {
      break;
    }
  }

  String header = utf8.decode(headerLine, allowMalformed: true);

  for (RPAVersion version in RPAVersion.versions) {
    if (header.startsWith(version.version)) {
      return true;
    }
  }

  return false;
}

Future<
    ({
      List<int> decompressedIndex,
      RPAVersion version,
      int offset,
      int? key
    })> findIndexAndVersion(RandomAccessFile file) async {
  List<int> headerLine = [];
  file.setPositionSync(0);

  while (true) {
    var byte = file.readByteSync();
    if (byte == utf8.encode('\n').first) {
      break;
    }
    headerLine.add(byte);
  }

  String header = utf8.decode(headerLine, allowMalformed: true);

  String version = header.split(' ').first;

  RPAVersion? currentVersion;

  for (var v in RPAVersion.versions) {
    if (ListEquality()
        .equals(v.rawVersion, headerLine.sublist(0, v.rawVersion.length))) {
      currentVersion = v;
      break;
    }
  }

  if (currentVersion == null) {
    throw UnsupportedError(
        'Unsupported RPA version: $version, please report this issue on GitHub to get it fixed, you can find an email to send anonymously the archive if you prefer.');
  }

  if ([ZiX12A(), ZiX12B()].contains(currentVersion)) {
    throw UnsupportedRPAVersionException(
        'Zix archives (${currentVersion.version} in your case) are not supported yet as they use heavy obfuscation which is harder to port/reverse engineer.');
  }

  var (offset, key) = currentVersion.findOffsetAndKey(header, headerLine, file);

  List<int> compressedIndex = [];
  await for (var byteList in File(file.path).openRead(offset)) {
    compressedIndex.addAll(byteList);
  }

  List<int> decompressedIndex = zlib.decode(compressedIndex);

  return (
    decompressedIndex: decompressedIndex,
    version: currentVersion,
    offset: offset,
    key: key
  );
}

Future<RPATreeNodeDirectory> openArchive(
    RandomAccessFile file, String currentPath) async {
  var decompressedIndex = await findIndexAndVersion(file);

  var root = RPATreeNodeDirectory(
      currentPath, [], decompressedIndex.version, false, (root) {
    Map<String, List<dynamic>> index = Map<String, List<dynamic>>.from(loads(
        Uint8List.fromList(decompressedIndex.decompressedIndex),
        encoding: 'bytes'));

    Map<String, List<List<dynamic>>> normalIndex = {};

    for (var entry in index.entries) {
      normalIndex[entry.key] = IndexEntry.from(entry.value);
    }

    if (decompressedIndex.key != null) {
      normalIndex = decompressedIndex.version
          .deobfuscateIndex(normalIndex, decompressedIndex.key!);
    } else {
      normalIndex = decompressedIndex.version.normaliseIndex(normalIndex);
    }

    for (var curFile in normalIndex.entries) {
      List<String> parts = curFile.key.split('/');
      TreeNode currentNode = root;

      for (int i = 0; i < parts.length; i++) {
        var part = parts[i];
        if (part.isEmpty) {
          continue;
        }

        var childNode = currentNode.childNodes.firstWhere(
            (node) => node.path.split('/').last == part, orElse: () {
          if (i == parts.length - 1) {
            var newNode = RPATreeNodeFile(
                part, curFile.value.first, decompressedIndex.version, file);
            currentNode.childNodes.add(newNode);
            return newNode;
          }

          var newNode = RPATreeNodeDirectory(
              join(currentPath, part), [], decompressedIndex.version);
          currentNode.childNodes.add(newNode);
          return newNode;
        });

        currentNode = childNode;
      }
    }

    return root.childNodes;
  });

  return root;
}

Future<DirectTreeNodeDirectory> openDirectory(
    Directory directory, String currentPath) async {
  var root = DirectTreeNodeDirectory(currentPath, [], false, (root) async {
    for (var entity in directory.listSync()) {
      if (entity is File) {
        if (await isRPAFile(entity)) {
          var newNode = await openArchive(
              entity.openSync(), join(currentPath, basename(entity.path)));
          root.childNodes.add(newNode);
          continue;
        }
        var newNode = DirectTreeNodeFile(
            join(currentPath, basename(entity.path)),
            entity,
            entity.statSync());
        root.childNodes.add(newNode);
      } else if (entity is Directory) {
        var newNode = await openDirectory(
            entity, join(currentPath, basename(entity.path)));
        root.childNodes.add(newNode);
      }
    }

    return root.childNodes;
  });

  return root;
}

Future<TreeNode> createTree(FileSystemEntity file) async {
  if (file is Link) {
    String link = file.resolveSymbolicLinksSync();
    if (File(link).existsSync()) {
      return createTree(File(link));
    } else if (Directory(link).existsSync()) {
      return createTree(Directory(link));
    } else {
      throw Exception('Invalid link: $link');
    }
  }

  if (file is File) {
    if (await isRPAFile(file)) {
      var archive = await openArchive(file.openSync(), basename(file.path));
      return archive;
    }

    var direct = DirectTreeNodeFile(basename(file.path), file, file.statSync());
    return direct;
  } else if (file is Directory) {
    var dir = await openDirectory(file, basename(file.path));
    return dir;
  } else {
    throw Exception('Invalid file type: $file (${file.runtimeType})');
  }
}
