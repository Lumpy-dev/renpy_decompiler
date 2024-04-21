import 'package:pickle_decompiler/pickle_decompiler.dart';

class RevertableList extends PythonClassSwapper {
  @override
  getReplacementOnInit(List args) {
    return args; // Should normally be empty.
  }

  @override
  PythonClass get klass =>
      PythonClass('RevertableList', module: 'renpy.revertable');
}

class OrderedDict extends PythonClassSwapper {
  @override
  getReplacementOnInit(List args) {
    return PythonClass('defaultdict', module: 'collections');
  }

  final klassName = PythonClass('OrderedDict', module: 'collections');

  @override
  PythonClass get klass => klassName;
}

List<PythonClassSwapper> revertableSwappers = [
  OrderedDict(),
  RevertableList(),
];
