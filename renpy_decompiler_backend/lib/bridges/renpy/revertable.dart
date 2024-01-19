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

List<PythonClassSwapper> revertableSwappers = [
  RevertableList(),
];
