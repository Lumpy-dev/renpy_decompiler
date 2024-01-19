// ignore_for_file: non_constant_identifier_names

import 'dart:typed_data';

import 'package:pickle_decompiler/src/pickle_reader.dart';

var pyint =
    StackObject(name: 'int', obtype: int, doc: 'A Python integer object.');

var pylong = pyint;

var pyinteger_or_bool = StackObject(
    name: 'int_or_bool',
    obtype: (int, bool),
    doc: 'A Python integer or boolean object.');

var pybool =
    StackObject(name: 'bool', obtype: bool, doc: 'A Python boolean object.');

var pyfloat =
    StackObject(name: 'float', obtype: double, doc: 'A Python float object.');

var pybytes_or_str = StackObject(
    name: 'bytes_or_str',
    obtype: (List<int>, String),
    doc: 'A Python bytes or (Unicode) string object.');

var pystring = pybytes_or_str;

var pybytes = StackObject(
    name: 'bytes', obtype: List<int>, doc: 'A Python bytes object.');

var pybytearray = StackObject(
    name: 'bytearray', obtype: Uint8List, doc: 'A Python bytearray object.');

var pyunicode = StackObject(
    name: 'str', obtype: String, doc: 'A Python (Unicode) string object.');

var pynone =
    StackObject(name: 'None', obtype: null, doc: 'The Python None object.');

var pytuple =
    StackObject(name: 'tuple', obtype: dynamic, doc: 'A Python tuple object.');

var pylist =
    StackObject(name: 'list', obtype: List, doc: 'A Python list object.');

var pydict =
    StackObject(name: 'dict', obtype: Map, doc: 'A Python dict object.');

var pyset = StackObject(name: 'set', obtype: Set, doc: 'A Python set object.');

var pyfrozenset = StackObject(
    name: 'frozenset', obtype: Set, doc: 'A Python frozenset object.');

var pybuffer = StackObject(
    name: 'buffer', obtype: Object, doc: 'A Python buffer-like object.');

var anyobject = StackObject(
    name: 'any', obtype: Object, doc: 'Any kind of object whatsoever.');

var markobject = StackObject(
    name: 'mark', obtype: StackObject, doc: """'The mark' is a unique object.

Opcodes that operate on a variable number of objects
generally don't embed the count of objects in the opcode,
or pull it off the stack.  Instead the MARK opcode is used
to push a special marker object on the stack, and then
some other opcodes grab all the objects from the top of
the stack down to (but not including) the topmost marker
object.
""");

var stackslice = StackObject(
    name: 'stackslice',
    obtype: StackObject,
    doc: '''An object representing a contiguous slice of the stack.

This is used in conjunction with markobject, to represent all
of the stack following the topmost markobject.  For example,
the POP_MARK opcode changes the stack from

    [..., markobject, stackslice]
to
    [...]

No matter how many object are on the stack after the topmost
markobject, POP_MARK gets rid of all of them (including the
topmost markobject too).
''');
