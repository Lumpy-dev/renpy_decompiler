import 'package:pickle_decompiler/pickle_decompiler.dart';

final List<({String attributeName, PythonSlotType? type})> nodeAttributes = [
  (attributeName: 'location', type: (possibleTypes: [List], nullable: false)),
  (attributeName: 'serial', type: (possibleTypes: [int], nullable: false)),
];

class SLScreen extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'layer',
          type: (possibleTypes: [String, PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'predict',
          type: (possibleTypes: [String, PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'variant',
          type: (possibleTypes: [String, PythonClassInstance], nullable: false)
        ),
        (attributeName: 'analysis', type: (possibleTypes: [], nullable: true)),
        (
          attributeName: 'prepared',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'sensitive',
          type: (possibleTypes: [String], nullable: false)
        ),
        (attributeName: 'tag', type: (possibleTypes: [String], nullable: true)),
        (
          attributeName: 'zorder',
          type: (possibleTypes: [String, PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'modal',
          type: (possibleTypes: [PythonClassInstance, String], nullable: false)
        ),
        (
          attributeName: 'roll_forward',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'parameters',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'children',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'name',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'keyword',
          type: (possibleTypes: [List], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('SLScreen', module: 'renpy.sl2.slast');
}

class SLDisplayable extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'style',
          type: (possibleTypes: [String, int], nullable: true)
        ),
        (
          attributeName: 'replaces',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'default_keywords',
          type: (
            possibleTypes: [Map, '_Map<dynamic, dynamic>'],
            nullable: false
          )
        ),
        (
          attributeName: 'unique',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'displayable',
          type: (possibleTypes: [PythonClass], nullable: false)
        ),
        (
          attributeName: 'hotspot',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'positional',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'atl_transform',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'pass_context',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'child_or_fixed',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'variable',
          type: (possibleTypes: [String], nullable: true)
        ),
        (
          attributeName: 'scope',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'imagemap',
          type: (possibleTypes: [bool], nullable: false)
        ),
        (
          attributeName: 'children',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'name',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'keyword',
          type: (possibleTypes: [List], nullable: false)
        ),
      ];

  @override
  PythonClass get klass =>
      PythonClass('SLDisplayable', module: 'renpy.sl2.slast');
}

class SLIf extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'entries',
          type: (possibleTypes: [List], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('SLIf', module: 'renpy.sl2.slast');
}

class SLBlock extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'keyword',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'children',
          type: (possibleTypes: [List], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('SLBlock', module: 'renpy.sl2.slast');
}

class SLFor extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'keyword',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'children',
          type: (possibleTypes: [List], nullable: false)
        ),
        (
          attributeName: 'variable',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'expression',
          type: (possibleTypes: [PythonClassInstance], nullable: false)
        ),
        (
          attributeName: 'index_expression',
          type: (possibleTypes: [], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('SLFor', module: 'renpy.sl2.slast');
}

class SLPython extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'code',
          type: (possibleTypes: [PythonClassInstance], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('SLPython', module: 'renpy.sl2.slast');
}

class SLUse extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'target',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'ast',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (
          attributeName: 'args',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
        (attributeName: 'id', type: (possibleTypes: [String], nullable: true)),
        (
          attributeName: 'block',
          type: (possibleTypes: [PythonClassInstance], nullable: true)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('SLUse', module: 'renpy.sl2.slast');
}

class SLTransclude extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
      ];

  @override
  PythonClass get klass =>
      PythonClass('SLTransclude', module: 'renpy.sl2.slast');
}

class SLDefault extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'variable',
          type: (possibleTypes: [String], nullable: false)
        ),
        (
          attributeName: 'expression',
          type: (possibleTypes: [PythonClassInstance], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('SLDefault', module: 'renpy.sl2.slast');
}

class SLShowIf extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [
        ...nodeAttributes,
        (
          attributeName: 'entries',
          type: (possibleTypes: [List], nullable: false)
        ),
      ];

  @override
  PythonClass get klass => PythonClass('SLShowIf', module: 'renpy.sl2.slast');
}

List<PythonClassDescriptor> slastDescriptors = [
  SLScreen(),
  SLDisplayable(),
  SLIf(),
  SLBlock(),
  SLFor(),
  SLPython(),
  SLUse(),
  SLTransclude(),
  SLDefault(),
  SLShowIf(),
];
