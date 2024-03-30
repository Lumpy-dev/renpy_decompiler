import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
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
      String header, List<int> rawHeader, File file);
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

abstract class RPATreeNode {
  List<RPATreeNode> childNodes;
  String path;

  RPATreeNode(this.path, this.childNodes);

  @override
  bool operator ==(Object other) {
    return other.runtimeType == runtimeType &&
        other is RPATreeNode &&
        path == other.path;
  }

  @override
  int get hashCode => path.hashCode;
}

int countFiles(RPATreeNode node, int amount) {
  for (var child in node.childNodes) {
    amount = countFiles(child, amount);
  }

  if (node is RPATreeNodeFile) {
    return amount + 1;
  }

  return amount;
}

List<RPATreeNodeFile> listFiles(RPATreeNode node, List<RPATreeNodeFile> files) {
  for (var child in node.childNodes) {
    files = listFiles(child, files);
  }

  if (node is RPATreeNodeFile) {
    files.add(node);
  }

  return files;
}

class RPATreeNodeFile implements RPATreeNode {
  @override
  List<RPATreeNode> childNodes = [];

  @override
  String path;

  ComplexIndexPart data;
  RPAVersion version;

  RandomAccessFile archive;

  RPATreeNodeFile(this.path, this.data, this.version, this.archive);

  List<int> read1() {
    return read(1);
  }

  List<int> read(int amount) {
    if (amount > data[1]) {
      throw Exception('Invalid amount to read: $amount, max: ${data[1]}');
    }

    if (amount < 0) {
      amount = data[1];
    }

    Uint8List buffer = Uint8List(data[1]);

    archive.setPositionSync(data[0]);
    archive.readIntoSync(buffer, 0, data[1]);

    List<int> source = buffer.toList();

    if (data[2].isNotEmpty) {
      source = List.from(data[2])..addAll(source);
    }

    return source.take(amount).toList();
  }
}

class RPATreeNodeDirectory implements RPATreeNode {
  @override
  List<RPATreeNode> childNodes;

  @override
  String path;

  RPATreeNodeDirectory(this.path, this.childNodes);
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
    })> findIndexAndVersion(File file) async {
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

Future<({RPATreeNode tree, RPAVersion version, int fileAmount})> createTree(
    File file) async {
  var decompressedIndex = await findIndexAndVersion(file);

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

  var archive = file.openSync();

  var root = RPATreeNodeDirectory('/', []);

  for (var file in normalIndex.entries) {
    List<String> parts = file.key.split('/');
    RPATreeNode currentNode = root;

    for (int i = 0; i < parts.length; i++) {
      var part = parts[i];
      if (part.isEmpty) {
        continue;
      }

      var childNode = currentNode.childNodes
          .firstWhere((node) => node.path.split('/').last == part, orElse: () {
        if (i == parts.length - 1) {
          var newNode = RPATreeNodeFile(
              part, file.value.first, decompressedIndex.version, archive);
          currentNode.childNodes.add(newNode);
          return newNode;
        }

        var newNode = RPATreeNodeDirectory(part, []);
        currentNode.childNodes.add(newNode);
        return newNode;
      });

      currentNode = childNode;
    }
  }

  return (
    tree: root,
    version: decompressedIndex.version,
    fileAmount: index.length
  );
}
