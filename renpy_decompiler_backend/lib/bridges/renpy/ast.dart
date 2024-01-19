// Translation and adaptation from parts of https://github.com/renpy/renpy/blob/113a60faa511a207ee18ef9f8c212cb65cf0b4ab/renpy/ast.py

import 'package:pickle_decompiler/pickle_decompiler.dart';

class PyExpr implements PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        (
          attributeName: 'value',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'filename',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'linenumber',
          type: (possibleTypes: [int], nullable: false)
        ),
        (attributeName: 'py', type: (possibleTypes: [int], nullable: false)),
      ];

  @override
  PythonClass get klass => PythonClass('PyExpr', module: 'renpy.ast');
}

class PyCode implements PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        // A 1 was added when serialisation occurred at the start of the state.
        (attributeName: 'one', type: (possibleTypes: [int], nullable: false)),
        (
          attributeName: 'source',
          type: (possibleTypes: [PythonClassInstance, String], nullable: false)
        ),
        (
          attributeName: 'location',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'mode',
          type: (possibleTypes: [String], nullable: false)
        ),
        (attributeName: 'py', type: (possibleTypes: [int], nullable: false))
      ];

  @override
  PythonClass get klass => PythonClass('PyCode', module: 'renpy.ast');
}

final List<({String attributeName, PythonSlotType? type})> nodeAttributes = [
  (
    attributeName: 'name',
    type: (possibleTypes: [String, List], nullable: false)
  ),
  (attributeName: 'filename', type: (possibleTypes: [String], nullable: false)),
  (attributeName: 'linenumber', type: (possibleTypes: [int], nullable: false)),
  (
    attributeName: 'next',
    type: (possibleTypes: [PythonClassInstance], nullable: true)
  ),
  (
    attributeName: 'statement_start',
    type: (possibleTypes: [PythonClassInstance], nullable: true)
  ),
];

class Say implements PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (attributeName: 'who', type: (possibleTypes: [String], nullable: true)),
        (
          attributeName: 'who_fast',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'what',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'with_',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'interact',
          type: (possibleTypes: [bool], nullable: true)
        ),
        (
          attributeName: 'attributes',
          type: (possibleTypes: [List], nullable: true)
        ),
        (
          attributeName: 'arguments',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'temporary_attributes',
          type: (possibleTypes: [List], nullable: true)
        ),
        (
          attributeName: 'rollback',
          type: (possibleTypes: [String], nullable: false)
        ),
        (attributeName: 'identifier', type: pythonAny),
        (
          attributeName: 'explicitIdentifier',
          type: (possibleTypes: [bool], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Say', module: 'renpy.ast');
}

class Init implements PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'block',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'priority',
          type: (possibleTypes: [int], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Init', module: 'renpy.ast');
}

class Label implements PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'parameters',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'block',
          type: (possibleTypes: [List], nullable: false)
        ),
        (attributeName: 'hide', type: (possibleTypes: [bool], nullable: false)),
      ];

  @override
  PythonClass get klass => PythonClass('Label', module: 'renpy.ast');
}

class Python implements PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (attributeName: 'hide', type: (possibleTypes: [bool], nullable: false)),
        (
          attributeName: 'code',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'store',
          type: (possibleTypes: [String], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Python', module: 'renpy.ast');
}

class EarlyPython extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (attributeName: 'hide', type: (possibleTypes: [bool], nullable: false)),
        (
          attributeName: 'code',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'store',
          type: (possibleTypes: [String], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('EarlyPython', module: 'renpy.ast');
}

class Image extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'imgname',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'code',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'atl',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Image', module: 'renpy.ast');
}

class Transform extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'store',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'varname',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'atl',
          type: (possibleTypes: [PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'parameters',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Transform', module: 'renpy.ast');
}

class Show extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        // A tuple if it doesn't accept a List
        (
          attributeName: 'imspec',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'atl',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Show', module: 'renpy.ast');
}

class ShowLayer extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'layer',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'at_list',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'atl',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('ShowLayer', module: 'renpy.ast');
}

class Camera extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'layer',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'at_list',
          type: (possibleTypes: [List], nullable: false)
        ),
        (attributeName: 'atl', type: pythonAny),
      ];

  @override
  PythonClass get klass => PythonClass('Camera', module: 'renpy.ast');
}

class Scene extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,

        /// A triple consisting of an image name (itself a
        /// tuple of strings), a list of at expressions, and a layer, or
        /// None to not have this scene statement also display an image.
        (
          attributeName: 'imspec',
          type: (possibleTypes: [List], nullable: true)
        ),
        (
          attributeName: 'layer',
          type: (possibleTypes: [String], nullable: true)
        ),
        (
          attributeName: 'atl',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Scene', module: 'renpy.ast');
}

class Hide extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'imspec',
          type: (possibleTypes: [List], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Hide', module: 'renpy.ast');
}

class With extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'expr',
          type: (possibleTypes: [String, PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'paired',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('With', module: 'renpy.ast');
}

class Call extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'label',
          type: (possibleTypes: [String, PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'arguments',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'expression',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'global_label',
          type: (possibleTypes: [String], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Call', module: 'renpy.ast');
}

class Return extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'expression',
          type: (possibleTypes: [String, PythonClassInstance], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Return', module: 'renpy.ast');
}

class Menu extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'items',
          type: (possibleTypes: [List], nullable: false)
        ),
        (attributeName: 'set', type: pythonAny),
        (attributeName: 'with_', type: pythonAny),
        (
          attributeName: 'has_caption',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'arguments',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'item_arguments',
          type: (possibleTypes: [List], nullable: true)
        ),
        (
          attributeName: 'rollback',
          type: (possibleTypes: [String], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Menu', module: 'renpy.ast');
}

class Jump extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'target',
          type: (possibleTypes: [String, PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'expression',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'global_label',
          type: (possibleTypes: [String], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Jump', module: 'renpy.ast');
}

class Pass extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState =>
      nodeAttributes;

  @override
  PythonClass get klass => PythonClass('Pass', module: 'renpy.ast');
}

class While extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'condition',
          type: (possibleTypes: [String, PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'block',
          type: (possibleTypes: [List], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('While', module: 'renpy.ast');
}

class If extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'entries',
          type: (possibleTypes: [List], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('If', module: 'renpy.ast');
}

class UserStatement extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'line',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'parsed',
          type: (possibleTypes: [List], nullable: true)
        ),
        (
          attributeName: 'block',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'translatable',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'code_block',
          type: (possibleTypes: [List], nullable: true)
        ),
        (
          attributeName: 'translation_relevant',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'rollback',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'subparses',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'init_priority',
          type: (possibleTypes: [int], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('UserStatement', module: 'renpy.ast');
}

class PostUserStatement extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'parent',
          type: (possibleTypes: [PythonClassInstance], nullable: false)
        ),
      ];

  @override
  PythonClass get klass =>
      PythonClass('PostUserStatement', module: 'renpy.ast');
}

class Define extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'varname',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'code',
          type: (possibleTypes: [PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'store',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'operator',
          type: (possibleTypes: [String], nullable: false)
        ),
        (attributeName: 'index', type: (possibleTypes: [int], nullable: true)),
      ];

  @override
  PythonClass get klass => PythonClass('Define', module: 'renpy.ast');
}

class Default extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'varname',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'code',
          type: (possibleTypes: [PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'store',
          type: (possibleTypes: [String], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Default', module: 'renpy.ast');
}

/// WARNING: screenlong.ScreenLangScreen and sl2.slast.SLScreen are not described yet
class Screen extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'screen',
          type: (possibleTypes: [PythonClassInstance], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Screen', module: 'renpy.ast');
}

class Translate extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'identifier',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'alternate',
          type: (possibleTypes: [String], nullable: true)
        ),
        (
          attributeName: 'language',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'block',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'after',
          type: (possibleTypes: [String], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Translate', module: 'renpy.ast');
}

class TranslateSay extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'identifier',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'alternate',
          type: (possibleTypes: [String], nullable: true)
        ),
        (
          attributeName: 'language',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'block',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'after',
          type: (possibleTypes: [String], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('TranslateSay', module: 'renpy.ast');
}

class EndTranslate extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState =>
      nodeAttributes;

  @override
  PythonClass get klass => PythonClass('EndTranslate', module: 'renpy.ast');
}

class TranslateString extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'language',
          type: (possibleTypes: [String], nullable: true)
        ),
        (
          attributeName: 'old',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'new',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'newloc',
          type: (possibleTypes: [List], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('TranslateString', module: 'renpy.ast');
}

class TranslatePython extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'language',
          type: (possibleTypes: [Object], nullable: false)
        ),
        (
          attributeName: 'code',
          type: (possibleTypes: [PythonClassInstance], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('TranslatePython', module: 'renpy.ast');
}

class TranslateBlock extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'block',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'language',
          type: (possibleTypes: [Object], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('TranslateBlock', module: 'renpy.ast');
}

class TranslateEarlyBlock extends TranslateBlock {
  @override
  PythonClass get klass =>
      PythonClass('TranslateEarlyBlock', module: 'renpy.ast');
}

class Style extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'style_name',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'parent',
          type: (possibleTypes: [String], nullable: true)
        ),
        (
          attributeName: 'properties',
          type: null
        ), // the value is a _Map, which is a private Dart type.
        (
          attributeName: 'clear',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'take',
          type: (possibleTypes: [String], nullable: true)
        ),
        (
          attributeName: 'delattr',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'variant',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Style', module: 'renpy.ast');
}

class Testcase extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'label',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'test',
          type: (
            possibleTypes: [PythonClassDescriptor, String],
            nullable: false
          )
        ),
      ];

  @override
  PythonClass get klass => PythonClass('Testcase', module: 'renpy.ast');
}

class RPY extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        (
          attributeName: 'rest',
          type: (possibleTypes: [String], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('RPY', module: 'renpy.ast');
}

List<PythonClassDescriptor> astDescriptors = [
  PyExpr(),
  PyCode(),
  Say(),
  Init(),
  Label(),
  Python(),
  EarlyPython(),
  Image(),
  Transform(),
  Show(),
  ShowLayer(),
  Camera(),
  Scene(),
  Hide(),
  With(),
  Call(),
  Return(),
  Menu(),
  Jump(),
  Pass(),
  While(),
  If(),
  UserStatement(),
  PostUserStatement(),
  Define(),
  Default(),
  Screen(),
  Translate(),
  TranslateSay(),
  EndTranslate(),
  TranslateString(),
  TranslatePython(),
  TranslateBlock(),
  TranslateEarlyBlock(),
  Style(),
  Testcase(),
  RPY(),
];
