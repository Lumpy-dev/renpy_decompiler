import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/decompilers/rpyc.dart';

class Translator {
  String language;
  bool savingTranslations = false;
  Map<String, String> strings = {};
  Map<String, List<PythonClassInstance>> dialogue = {};
  Set<String> identifiers = {};
  String? alternate;

  String? label;

  Translator(this.language);

  String uniqueIdentifier(String? label, String digest) {
    String base;
    if (label == null) {
      base = digest;
    } else {
      base = '${label.replaceAll('.', '_')}_$digest';
    }

    int i = 0;
    String suffix = '';

    while (true) {
      String identifier = '$base$suffix';
      if (!identifiers.contains(identifier)) {
        break;
      }
      i++;
      suffix = '_$i';
    }

    return '$base$suffix';
  }

  List<PythonClassInstance> createTranslate(List<PythonClassInstance> block) {
    if (savingTranslations) {
      return [];
    }

    List<int> md5ToHash = [];

    for (var i in block) {
      String code;
      if (i.klass == PythonClass('Say', module: 'renpy.ast')) {
        code = RPYCDecompiler.sayGetCode(i);
      } else if (i.klass == PythonClass('UserStatement', module: 'renpy.ast')) {
        code = i.namedArgs['line'];
      } else {
        throw Exception(
            'Don\'t know how to get canonical code for a ${i.klass}');
      }
      md5ToHash.addAll(utf8.encode(code) + utf8.encode('\r\n'));
    }

    String digest = md5.convert(md5ToHash).toString().substring(8);

    String identifier = uniqueIdentifier(label, digest);
    identifiers.add(identifier);

    String? alternate;

    if (this.alternate != null) {
      alternate = uniqueIdentifier(this.alternate, digest);
      identifiers.add(alternate);
    } else {
      alternate = null;
    }

    List<PythonClassInstance>? translatedBlock =
        dialogue.containsKey(identifier) ? dialogue[identifier] : null;
    if (translatedBlock == null && alternate != null && alternate.isNotEmpty) {
      translatedBlock =
          dialogue.containsKey(alternate) ? dialogue[alternate] : null;
    }
    if (translatedBlock == null) {
      return block;
    }

    List<PythonClassInstance> newBlock = [];
    int oldLineNumber = block.first.namedArgs['linenumber'];
    for (PythonClassInstance ast in translatedBlock) {
      PythonClassInstance newAst = PythonClassInstance(ast.klass);
      newAst.state?.addAll(ast.state ?? {});
      newAst.namedArgs['linenumber'] = oldLineNumber;
      newBlock.add(newAst);
    }

    return newBlock;
  }

  void walk(
      PythonClassInstance ast, void Function(List<PythonClassInstance>) f) {
    if (['Init', 'Label', 'While', 'Translate', 'TranslateBlock']
            .contains(ast.klass.name) &&
        ast.klass.module == 'renpy.ast') {
      f(ast.namedArgs['block']);
    } else if (ast.klass == PythonClass('Menu', module: 'renpy.ast')) {
      for (var i in ast.namedArgs['items']) {
        if (i[2] != null) {
          f(i[2]);
        }
      }
    } else if (ast.klass == PythonClass('If', module: 'renpy.ast')) {
      for (var i in ast.namedArgs['entries']) {
        f(i[1]);
      }
    }
  }

  void translateDialogue(List<PythonClassInstance> children) {
    List<PythonClassInstance> newChildren = [];
    List<PythonClassInstance> group = [];

    for (var i in children) {
      if (i.klass == PythonClass('Label', module: 'renpy.ast')) {
        if (!(i.namedArgs['hide'] != null && i.namedArgs['hide'] == true)) {
          if (i.namedArgs['name'].startsWith('_')) {
            alternate = i.namedArgs['name'];
          } else {
            label = i.namedArgs['name'];
            alternate = null;
          }
        }
      }

      if (savingTranslations &&
          i.klass == PythonClass('TranslateString', module: 'renpy.ast') &&
          i.namedArgs['language'] != language) {
        strings[i.namedArgs['old']] = i.namedArgs['new'];
      }

      if (i.klass != PythonClass('Translate', module: 'renpy.ast')) {
        walk(i, translateDialogue);
      } else if (savingTranslations && i.namedArgs['language'] == language) {
        dialogue[i.namedArgs['identifier']] = i.namedArgs['block'];
        if (i.namedArgs.containsKey('alternate') &&
            i.namedArgs['alternate'] != null) {
          dialogue[i.namedArgs['alternate']] = i.namedArgs['block'];
        }
      }

      if (i.klass == PythonClass('Say', module: 'renpy.ast')) {
        group.add(i);
        List<PythonClassInstance> tl = createTranslate(group);
        newChildren.addAll(tl);
        group = [];
      } else if (i.namedArgs.containsKey('translatable') &&
          i.namedArgs['translatable'] == true) {
        group.add(i);
      } else {
        if (group.isNotEmpty) {
          List<PythonClassInstance> tl = createTranslate(group);
          newChildren.addAll(tl);
          group = [];
        }
        newChildren.add(i);
      }
    }

    if (group.isNotEmpty) {
      List<PythonClassInstance> nodes = createTranslate(group);
      newChildren.addAll(nodes);
      group = [];
    }

    children = newChildren;
  }
}
