import 'package:renpy_decompiler_backend/tree_creator.dart';
import 'package:renpy_decompiler_backend/versions/official_rpa.dart';

/// Ported from https://github.com/varieget/unrpa/commit/c66d5d7f5233286d3f56ca1594f184f95d35ad66
class TMOZVersionZeroTwo extends RPAVersionThree {
  @override
  String get version => 'TMOZ-02';

  @override
  Map<String, ComplexIndexEntry> deobfuscateIndex(Map<String, IndexEntry> index, int key) {
    return {
      for(var entry in index.entries)
        entry.key: deobfuscateEntry(entry.value, key)
    };
  }

  @override
  ComplexIndexEntry deobfuscateEntry(IndexEntry entry, int key) {
    return [
      for(var entry in normaliseEntry(entry))
        [entry[1] ^ key, entry[0] ^ key, entry[2]]
    ];
  }
}