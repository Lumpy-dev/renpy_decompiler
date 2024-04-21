// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
// The license of codegen.py is included in the file itself.
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:pickle_decompiler/pickle_decompiler.dart';
import 'package:renpy_decompiler_backend/decompilers/rpyc.dart';

class Translator {
  String language;
  bool savingTranslations;
  Map<String, String> strings = {};
  Map<String, List<PythonClassInstance>> dialogue = {};
  Set<String> identifiers = {};
  String? alternate;

  String? label;

  Translator({required this.language, this.savingTranslations = false});

  String uniqueIdentifier(String? label, String digest) {
    String base;
    if (label == null) {
      base = digest;
    } else {
      base = '${label.replaceAll('.', '_')}_$digest';
    }

    int i = 0;
    String suffix = '';

    String identifier;
    while (true) {
      identifier = base + suffix;

      if (!identifiers.contains(identifier)) {
        break;
      }

      i++;
      suffix = '_$i';
    }

    return identifier;
  }

  List<PythonClassInstance> createTranslate(List<PythonClassInstance> block) {
    if (savingTranslations) {
      return [];
    }

    List<int> toEncrypt = [];

    for (PythonClassInstance i in block) {
      String code;
      if (i.klass == PythonClass('Say', module: 'renpy.ast')) {
        code = RPYCDecompiler.sayGetCode(i);
      } else if (i.klass == PythonClass('UserStatement', module: 'renpy.ast')) {
        code = i.vars['line'];
      } else {
        throw Exception(
            'Don\'t know how to get canonical code for a ${i.klass}');
      }

      toEncrypt.addAll(utf8.encode('$code\r\n'));
    }

    String digest = md5.convert(toEncrypt).toString().substring(0, 8);

    String identifier = uniqueIdentifier(label, digest);
    identifiers.add(identifier);

    if (alternate != null) {
      alternate = uniqueIdentifier(alternate, digest);
      identifiers.add(alternate!);
    } else {
      // Was present in original code, keeping it in case it's doing something strange
      alternate = null;
    }

    List<PythonClassInstance>? translatedBlock = dialogue[identifier];
    if (translatedBlock == null && alternate != null && alternate!.isNotEmpty) {
      translatedBlock = dialogue[alternate];
    }
    if (translatedBlock == null) {
      return block;
    }

    List<PythonClassInstance> newBlock = [];
    int oldLineNumber = block.first.vars['linenumber'];
    for (PythonClassInstance ast in translatedBlock) {
      PythonClassInstance newAst = ast.copyWith();
      // TODO: test is you can edit args with the namedArgs getter.
      newAst.vars['linenumber'] = oldLineNumber;
      newBlock.add(newAst);
    }

    return newBlock;
  }

  void walk(
      PythonClassInstance ast, void Function(List<PythonClassInstance>) f) {
    if (['Init', 'Label', 'While', 'Translate', 'TranslateBlock']
            .contains(ast.klass.name) &&
        ast.klass.module == 'renpy.ast') {
      f(ast.vars['block']);
    } else if (ast.klass == PythonClass('Menu', module: 'renpy.ast')) {
      for (var i in ast.vars['items']) {
        if (i[2] != null) {
          f(i[2]);
        }
      }
    } else if (ast.klass == PythonClass('If', module: 'renpy.ast')) {
      for (var i in ast.vars['entries']) {
        f(i[1]);
      }
    }
  }

  void translateDialogue(List<PythonClassInstance> children) {
    List<PythonClassInstance> newChildren = [];
    List<PythonClassInstance> group = [];

    for (PythonClassInstance i in children) {
      if (i.klass == PythonClass('Label', module: 'renpy.ast')) {
        if (!(i.vars.containsKey('hide') && i.vars['hide'] == true)) {
          if (i.vars['name'].startsWith('_')) {
            alternate = i.vars['name'];
          } else {
            label = i.vars['name'];
            alternate = null;
          }
        }
      }

      if (savingTranslations &&
          i.klass == PythonClass('TranslateString', module: 'renpy.ast') &&
          i.vars['language'] == language) {
        strings[i.vars['old']] = i.vars['new'];
      }

      if (i.klass != PythonClass('Translate', module: 'renpy.ast')) {
        walk(i, translateDialogue);
      } else if (savingTranslations && i.vars['language'] == language) {
        dialogue[i.vars['identifier']] = i.vars['block'];
        if (i.vars.containsKey('alternate') && i.vars['alternate'] != null) {
          dialogue[i.vars['alternate']] = i.vars['block'];
        }
      }

      if (i.klass != PythonClass('Say', module: 'renpy.ast')) {
        group.add(i);
        List<PythonClassInstance> tl = createTranslate(group);
        newChildren.addAll(tl);
        group = [];
      } else if (i.vars.containsKey('translatable') &&
          i.vars['translatable'] == true) {
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

    children.clear();
    children.addAll(newChildren);
  }
}
