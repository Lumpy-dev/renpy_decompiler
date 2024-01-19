class PythonClass {
  String? module;
  String name;

  PythonClassDescriptor? descriptor;

  PythonClass(this.name, {this.module, this.descriptor});

  @override
  String toString() {
    if (module == null) {
      return name;
    } else {
      return '$module.$name';
    }
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(Object other) {
    return toString() == other.toString();
  }
}

class PythonClassInstance {
  PythonClass klass;
  Map<String, dynamic>? state;

  PythonClassInstance(this.klass);

  Map<String, dynamic> get namedArgs =>
      Map<String, dynamic>.from(state?['named_args'] ?? {});

  void setState(dynamic state) {
    if (klass.descriptor != null) {
      this.state ??= {};

      if (state.length == 2 &&
          (state is List && (state.first == null || state.first.isEmpty))) {
        state = state.last;
      }

      if (state is List) {
        for (int i = 0; i < state.length; i++) {
          this.state!['named_args'] ??= {};

          var slot = klass.descriptor!.describeState[i];
          var value = state[i];

          if (slot.type != null) {
            if (slot.type!.possibleTypes.contains(value.runtimeType)) {
              this.state!['named_args'][slot.attributeName] = value;
            } else {
              if (value == null && slot.type!.nullable) {
                this.state!['named_args'][slot.attributeName] = null;
                continue;
              }

              if (slot.type!.possibleTypes.any((element) => element is String
                  ? (element == value.runtimeType.toString())
                  : false)) {
                this.state!['named_args'][slot.attributeName] = value;
                continue;
              } else {
                for (var possibleType in slot.type!.possibleTypes) {
                  if (possibleType is String) {
                    print(
                        'Comparing $possibleType with ${value.runtimeType.toString()}');
                  }
                }
              }

              throw Exception(
                  'Invalid type for attribute ${slot.attributeName}: ${value.runtimeType}, expected one of ${slot.type!.possibleTypes} for class $klass');
            }
          } else {
            this.state!['named_args'][slot.attributeName] = value;
          }
        }
      } else if (state is Map) {
        if (state.length > klass.descriptor!.describeState.length) {
          throw Exception(
              'Too many arguments for class ${klass.name}, described ${klass.descriptor!.describeState.length} but got ${state.length}');
        }

        for (var entry in state.entries) {
          this.state!['named_args'] ??= {};

          if (klass.descriptor!.describeState
              .any((element) => element.attributeName == entry.key)) {
            var slot = klass.descriptor!.describeState
                .firstWhere((element) => element.attributeName == entry.key);
            if (slot.type != null) {
              if (slot.type!.possibleTypes.contains(entry.value.runtimeType)) {
                this.state!['named_args'][slot.attributeName] = entry.value;
              } else {
                if (entry.value == null && slot.type!.nullable) {
                  this.state!['named_args'][slot.attributeName] = null;
                  continue;
                }

                if (slot.type!.possibleTypes.any((element) => element is String
                    ? (element == entry.value.runtimeType.toString())
                    : false)) {
                  this.state!['named_args'][slot.attributeName] = entry.value;
                  continue;
                }

                throw Exception(
                    'Invalid type for attribute ${slot.attributeName}: ${entry.value.runtimeType}, expected one of ${slot.type!.possibleTypes} for class $klass');
              }
            } else {
              this.state!['named_args'][slot.attributeName] = entry.value;
            }
          } else {
            this.state!['named_args'][entry.key] = entry.value;
          }
        }
      }
    } else {
      if (state is List) {
        if (state.length == 2) {
          this.state = {'named_args': state[1], ...?this.state};
        } else {
          // We do not know the signature of the Python class, we just present them in a list..
          this.state ??= {};

          if (!this.state!.containsKey('unknown')) {
            this.state!['unknown'] = [];
          }

          this.state!['unknown'].addAll(state);

          if (this.state!['unknown'].isEmpty) {
            this.state!.remove('unknown');
          }
        }
      } else if (state is Map) {
        if (!state.containsKey('arguments')) {
          this.state = Map<String, dynamic>.from(state);
        }
      } else {
        throw Exception(
            'Unknown state type: ${state.runtimeType}, state is $state');
      }
    }
  }

  @override
  String toString() {
    return '$klass($state)';
  }

  void operator []=(String key, dynamic value) {
    state ??= {};
    state!['named_args'] ??= {};
    state!['named_args'][key] = value;
  }
}

/// [possibleTypes] should be List<Type> or List<String> or a combination of both
typedef PythonSlotType = ({List<dynamic> possibleTypes, bool nullable});

final PythonSlotType pythonAny = (possibleTypes: [Object], nullable: true);

/// Could be described as mappings for the Python classes, if those aren't given to the unpickler,
/// the outputted complex types could not come with their associated name.
/// Those mappings can also ensure that the attributes parsed from the pickle are the right type.
abstract class PythonClassDescriptor {
  PythonClass get klass;

  List<({String attributeName, PythonSlotType? type})> get describeState;
}

/// Some Python objects may not be replaced by native Dart objects because the object is an expansion of this
/// translatable object.
/// This class fixes this issue by replacing the object with any other object, including native ones.
abstract class PythonClassSwapper {
  PythonClass get klass;

  dynamic getReplacementOnInit(List<dynamic> args);
}
