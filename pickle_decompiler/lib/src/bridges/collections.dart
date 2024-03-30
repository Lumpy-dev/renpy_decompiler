import 'package:pickle_decompiler/pickle_decompiler.dart';

class DefaultDict<K, V> extends PythonClassInstance {
  Map<K, V> innerMap = {};

  DefaultDict(super.klass, this.defaultFactory);

  V Function() defaultFactory;

  @override
  void operator []=(String key, value) {
    innerMap[key as K] = value as V;
  }

  V operator [](String key) {
    return innerMap[key as K] ?? (innerMap[key as K] = defaultFactory());
  }

  @override
  PythonClass get klass => PythonClass('defaultdict',
      module: 'collections', descriptor: DefaultDictDescriptor());
}

class DefaultDictDescriptor extends PythonClassDescriptor {
  @override
  List<({String attributeName, PythonSlotType? type})> get describeState => [];

  @override
  PythonClass get klass => PythonClass('defaultdict', module: 'collections');

  @override
  construct(List args) {
    return DefaultDict<dynamic, dynamic>(
        klass, () => (args.first as PythonClass).descriptor!.construct([]));
  }
}
