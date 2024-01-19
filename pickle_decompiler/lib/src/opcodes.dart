import 'package:pickle_decompiler/src/args.dart';
import 'package:pickle_decompiler/src/pickle_reader.dart';
import 'package:pickle_decompiler/src/stack_objects.dart';

typedef I = OpCodeInfo;

List<OpCodeInfo> opcodes = [
  I(
      name: 'INT',
      code: 'I',
      arg: decimalnlShort,
      stackBefore: [],
      stackAfter: [pyinteger_or_bool],
      proto: 0,
      doc: """Push an integer or bool.

      The argument is a newline-terminated decimal literal string.

      The intent may have been that this always fit in a short Python int,
      but INT can be generated in pickles written on a 64-bit box that
      require a Python long on a 32-bit box.  The difference between this
      and LONG then is that INT skips a trailing 'L', and produces a short
      int whenever possible.

      Another difference is due to that, when bool was introduced as a
      distinct type in 2.3, builtin names True and False were also added to
      2.2.2, mapping to ints 1 and 0.  For compatibility in both directions,
      True gets pickled as INT + "I01\\n", and False as INT + "I00\\n".
      Leading zeroes are never produced for a genuine integer.  The 2.3
      (and later) unpicklers special-case these and return bool instead;
      earlier unpicklers ignore the leading "0" and return the int.
      """),
  I(
      name: 'BININT',
      code: 'J',
      arg: int4,
      stackBefore: [],
      stackAfter: [pyint],
      proto: 1,
      doc: '''Push a four-byte signed integer.

      This handles the full range of Python (short) integers on a 32-bit
      box, directly as binary bytes (1 for the opcode and 4 for the integer).
      If the integer is non-negative and fits in 1 or 2 bytes, pickling via
      BININT1 or BININT2 saves space.
      '''),
  I(
      name: 'BININT1',
      code: 'K',
      arg: uint1,
      stackBefore: [],
      stackAfter: [pyint],
      proto: 1,
      doc: '''Push a one-byte unsigned integer.

      This is a space optimization for pickling very small non-negative ints,
      in range(256).
      '''),
  I(
      name: 'BININT2',
      code: 'M',
      arg: uint2,
      stackBefore: [],
      stackAfter: [pyint],
      proto: 1,
      doc: '''Push a two-byte unsigned integer.

      This is a space optimization for pickling small positive ints, in
      range(256, 2**16).  Integers in range(256) can also be pickled via
      BININT2, but BININT1 instead saves a byte.
      '''),
  I(
      name: 'LONG',
      code: 'L',
      arg: decimalnlLong,
      stackBefore: [],
      stackAfter: [pyint],
      proto: 0,
      doc: """Push a long integer.

      The same as INT, except that the literal ends with 'L', and always
      unpickles to a Python long.  There doesn't seem a real purpose to the
      trailing 'L'.

      Note that LONG takes time quadratic in the number of digits when
      unpickling (this is simply due to the nature of decimal->binary
      conversion).  Proto 2 added linear-time (in C; still quadratic-time
      in Python) LONG1 and LONG4 opcodes.
      """),
  I(
      name: 'LONG1',
      code: '\x8a',
      arg: long1,
      stackBefore: [],
      stackAfter: [pyint],
      proto: 2,
      doc: '''Long integer using one-byte length.

      A more efficient encoding of a Python long; the long1 encoding
      says it all.'''),
  I(
      name: 'LONG4',
      code: '\x8b',
      arg: long4,
      stackBefore: [],
      stackAfter: [pyint],
      proto: 2,
      doc: '''Long integer using found-byte length.

      A more efficient encoding of a Python long; the long4 encoding
      says it all.'''),
  I(
      name: 'STRING',
      code: 'S',
      arg: stringnl,
      stackBefore: [],
      stackAfter: [pybytes_or_str],
      proto: 0,
      doc: """Push a Python string object.

      The argument is a repr-style string, with bracketing quote characters,
      and perhaps embedded escapes.  The argument extends until the next
      newline character.  These are usually decoded into a str instance
      using the encoding given to the Unpickler constructor. or the default,
      'ASCII'.  If the encoding given was 'bytes' however, they will be
      decoded as bytes object instead.
      """),
  I(
      name: 'BINSTRING',
      code: 'T',
      arg: string4,
      stackBefore: [],
      stackAfter: [pybytes_or_str],
      proto: 1,
      doc: """Push a Python string object.

      There are two arguments: the first is a 4-byte little-endian
      signed int giving the number of bytes in the string, and the
      second is that many bytes, which are taken literally as the string
      content.  These are usually decoded into a str instance using the
      encoding given to the Unpickler constructor. or the default,
      'ASCII'.  If the encoding given was 'bytes' however, they will be
      decoded as bytes object instead.
      """),
  I(
      name: 'SHORT_BINSTRING',
      code: 'U',
      arg: string1,
      stackBefore: [],
      stackAfter: [pybytes_or_str],
      proto: 1,
      doc: """Push a Python string object.

      There are two arguments: the first is a 1-byte unsigned int giving
      the number of bytes in the string, and the second is that many
      bytes, which are taken literally as the string content.  These are
      usually decoded into a str instance using the encoding given to
      the Unpickler constructor. or the default, 'ASCII'.  If the
      encoding given was 'bytes' however, they will be decoded as bytes
      object instead.
      """),
  I(
      name: 'BINBYTES',
      code: 'B',
      arg: bytes4,
      stackBefore: [],
      stackAfter: [pybytes],
      proto: 3,
      doc: '''Push a Python bytes object.

      There are two arguments:  the first is a 4-byte little-endian unsigned int
      giving the number of bytes, and the second is that many bytes, which are
      taken literally as the bytes content.
      '''),
  I(
      name: 'SHORT_BINBYTES',
      code: 'C',
      arg: bytes1,
      stackBefore: [],
      stackAfter: [pybytes],
      proto: 3,
      doc: '''Push a Python bytes object.

      There are two arguments:  the first is a 1-byte unsigned int giving
      the number of bytes, and the second is that many bytes, which are taken
      literally as the string content.
      '''),
  I(
      name: 'BINBYTES8',
      code: '\x8e',
      arg: bytes8,
      stackBefore: [],
      stackAfter: [pybytes],
      proto: 4,
      doc: '''Push a Python bytes object.

      There are two arguments:  the first is an 8-byte unsigned int giving
      the number of bytes in the string, and the second is that many bytes,
      which are taken literally as the string content.
      '''),
  I(
      name: 'BYTEARRAY8',
      code: '\x96',
      arg: bytearray8,
      stackBefore: [],
      stackAfter: [pybytearray],
      proto: 5,
      doc: '''Push a Python bytearray object.

      There are two arguments:  the first is an 8-byte unsigned int giving
      the number of bytes in the bytearray, and the second is that many bytes,
      which are taken literally as the bytearray content.
      '''),
  I(
      name: 'NEXT_BUFFER',
      code: '\x97',
      arg: null,
      stackBefore: [],
      stackAfter: [pybuffer],
      proto: 5,
      doc: 'Push an out-of-band buffer object.'),
  I(
      name: 'READONLY_BUFFER',
      code: '\x98',
      arg: null,
      stackBefore: [pybuffer],
      stackAfter: [pybuffer],
      proto: 5,
      doc: 'Make an out-of-band buffer object read-only.'),
  I(
      name: 'null',
      code: 'N',
      arg: null,
      stackBefore: [],
      stackAfter: [pynone],
      proto: 0,
      doc: 'Push null on the stack.'),
  I(
      name: 'NEWTRUE',
      code: '\x88',
      arg: null,
      stackBefore: [],
      stackAfter: [pybool],
      proto: 2,
      doc: 'Push True onto the stack.'),
  I(
      name: 'NEWFALSE',
      code: '\x89',
      arg: null,
      stackBefore: [],
      stackAfter: [pybool],
      proto: 2,
      doc: 'Push False onto the stack.'),
  I(
      name: 'UNICODE',
      code: 'V',
      arg: unicodeStringnl,
      stackBefore: [],
      stackAfter: [pyunicode],
      proto: 0,
      doc: '''Push a Python Unicode string object.

      The argument is a raw-unicode-escape encoding of a Unicode string,
      and so may contain embedded escape sequences.  The argument extends
      until the next newline character.
      '''),
  I(
      name: 'SHORT_BINUNICODE',
      code: '\x8c',
      arg: unicodeString1,
      stackBefore: [],
      stackAfter: [pyunicode],
      proto: 4,
      doc: '''Push a Python Unicode string object.

      There are two arguments:  the first is a 1-byte little-endian signed int
      giving the number of bytes in the string.  The second is that many
      bytes, and is the UTF-8 encoding of the Unicode string.
      '''),
  I(
      name: 'BINUNICODE',
      code: 'X',
      arg: unicodeString4,
      stackBefore: [],
      stackAfter: [pyunicode],
      proto: 1,
      doc: '''Push a Python Unicode string object.

      There are two arguments:  the first is a 4-byte little-endian unsigned int
      giving the number of bytes in the string.  The second is that many
      bytes, and is the UTF-8 encoding of the Unicode string.
      '''),
  I(
      name: 'BINUNICODE8',
      code: '\x8d',
      arg: unicodeString8,
      stackBefore: [],
      stackAfter: [pyunicode],
      proto: 4,
      doc: '''Push a Python Unicode string object.

      There are two arguments:  the first is an 8-byte little-endian signed int
      giving the number of bytes in the string.  The second is that many
      bytes, and is the UTF-8 encoding of the Unicode string.
      '''),
  I(
      name: 'FLOAT',
      code: 'F',
      arg: floatnl,
      stackBefore: [],
      stackAfter: [pyfloat],
      proto: 0,
      doc: """Newline-terminated decimal float literal.

      The argument is repr(a_float), and in general requires 17 significant
      digits for roundtrip conversion to be an identity (this is so for
      IEEE-754 double precision values, which is what Python float maps to
      on most boxes).

      In general, FLOAT cannot be used to transport infinities, NaNs, or
      minus zero across boxes (or even on a single box, if the platform C
      library can't read the strings it produces for such things -- Windows
      is like that), but may do less damage than BINFLOAT on boxes with
      greater precision or dynamic range than IEEE-754 double.
      """),
  I(
      name: 'BINFLOAT',
      code: 'G',
      arg: float8,
      stackBefore: [],
      stackAfter: [pyfloat],
      proto: 1,
      doc: '''Float stored in binary form, with 8 bytes of data.

      This generally requires less than half the space of FLOAT encoding.
      In general, BINFLOAT cannot be used to transport infinities, NaNs, or
      minus zero, raises an exception if the exponent exceeds the range of
      an IEEE-754 double, and retains no more than 53 bits of precision (if
      there are more than that, "add a half and chop" rounding is used to
      cut it back to 53 significant bits).
      '''),
  I(
      name: 'EMPTY_LIST',
      code: ']',
      arg: null,
      stackBefore: [],
      stackAfter: [pylist],
      proto: 1,
      doc: 'Push an empty list.'),
  I(
      name: 'APPEND',
      code: 'a',
      arg: null,
      stackBefore: [pylist, anyobject],
      stackAfter: [pylist],
      proto: 0,
      doc: '''Append an object to a list.

      Stack before:  ... pylist anyobject
      Stack after:   ... pylist+[anyobject]

      although pylist is really extended in-place.
      '''),
  I(
      name: 'APPENDS',
      code: 'e',
      arg: null,
      stackBefore: [pylist, markobject, stackslice],
      stackAfter: [pylist],
      proto: 1,
      doc: '''Extend a list by a slice of stack objects.

      Stack before:  ... pylist markobject stackslice
      Stack after:   ... pylist+stackslice

      although pylist is really extended in-place.
      '''),
  I(
      name: 'LIST',
      code: 'l',
      arg: null,
      stackBefore: [markobject, stackslice],
      stackAfter: [pylist],
      proto: 0,
      doc: """Build a list out of the topmost stack slice, after markobject.

      All the stack entries following the topmost markobject are placed into
      a single Python list, which single list object replaces all of the
      stack from the topmost markobject onward.  For example,

      Stack before: ... markobject 1 2 3 'abc'
      Stack after:  ... [1, 2, 3, 'abc']
      """),
  I(
      name: 'EMPTY_TUPLE',
      code: ')',
      arg: null,
      stackBefore: [],
      stackAfter: [pytuple],
      proto: 1,
      doc: 'Push an empty tuple.'),
  I(
      name: 'TUPLE',
      code: 't',
      arg: null,
      stackBefore: [markobject, stackslice],
      stackAfter: [pytuple],
      proto: 0,
      doc: """Build a tuple out of the topmost stack slice, after markobject.

      All the stack entries following the topmost markobject are placed into
      a single Python tuple, which single tuple object replaces all of the
      stack from the topmost markobject onward.  For example,

      Stack before: ... markobject 1 2 3 'abc'
      Stack after:  ... (1, 2, 3, 'abc')
      """),
  I(
      name: 'TUPLE1',
      code: '\x85',
      arg: null,
      stackBefore: [anyobject],
      stackAfter: [pytuple],
      proto: 2,
      doc: '''Build a one-tuple out of the topmost item on the stack.

      This code pops one value off the stack and pushes a tuple of
      length 1 whose one item is that value back onto it.  In other
      words:

          stack[-1] = tuple(stack[-1:])
      '''),
  I(
      name: 'TUPLE2',
      code: '\x86',
      arg: null,
      stackBefore: [anyobject, anyobject],
      stackAfter: [pytuple],
      proto: 2,
      doc: '''Build a two-tuple out of the top two items on the stack.

      This code pops two values off the stack and pushes a tuple of
      length 2 whose items are those values back onto it.  In other
      words:

          stack[-2:] = [tuple(stack[-2:])]
      '''),
  I(
      name: 'TUPLE3',
      code: '\x87',
      arg: null,
      stackBefore: [anyobject, anyobject, anyobject],
      stackAfter: [pytuple],
      proto: 2,
      doc: '''Build a three-tuple out of the top three items on the stack.

      This code pops three values off the stack and pushes a tuple of
      length 3 whose items are those values back onto it.  In other
      words:

          stack[-3:] = [tuple(stack[-3:])]
      '''),
  I(
      name: 'EMPTY_DICT',
      code: '}',
      arg: null,
      stackBefore: [],
      stackAfter: [pydict],
      proto: 1,
      doc: 'Push an empty dict.'),
  I(
      name: 'DICT',
      code: 'd',
      arg: null,
      stackBefore: [markobject, stackslice],
      stackAfter: [pydict],
      proto: 0,
      doc: """Build a dict out of the topmost stack slice, after markobject.

      All the stack entries following the topmost markobject are placed into
      a single Python dict, which single dict object replaces all of the
      stack from the topmost markobject onward.  The stack slice alternates
      key, value, key, value, ....  For example,

      Stack before: ... markobject 1 2 3 'abc'
      Stack after:  ... {1: 2, 3: 'abc'}
      """),
  I(
      name: 'SETITEM',
      code: 's',
      arg: null,
      stackBefore: [pydict, anyobject, anyobject],
      stackAfter: [pydict],
      proto: 0,
      doc: '''Add a key+value pair to an existing dict.

      Stack before:  ... pydict key value
      Stack after:   ... pydict

      where pydict has been modified via pydict[key] = value.
      '''),
  I(
      name: 'SETITEMS',
      code: 'u',
      arg: null,
      stackBefore: [pydict, markobject, stackslice],
      stackAfter: [pydict],
      proto: 1,
      doc: '''Add an arbitrary number of key+value pairs to an existing dict.

      The slice of the stack following the topmost markobject is taken as
      an alternating sequence of keys and values, added to the dict
      immediately under the topmost markobject.  Everything at and after the
      topmost markobject is popped, leaving the mutated dict at the top
      of the stack.

      Stack before:  ... pydict markobject key_1 value_1 ... key_n value_n
      Stack after:   ... pydict

      where pydict has been modified via pydict[key_i] = value_i for i in
      1, 2, ..., n, and in that order.
      '''),
  I(
      name: 'EMPTY_SET',
      code: '\x8f',
      arg: null,
      stackBefore: [],
      stackAfter: [pyset],
      proto: 4,
      doc: 'Push an empty set.'),
  I(
      name: 'ADDITEMS',
      code: '\x90',
      arg: null,
      stackBefore: [pyset, markobject, stackslice],
      stackAfter: [pyset],
      proto: 4,
      doc: '''Add an arbitrary number of items to an existing set.

      The slice of the stack following the topmost markobject is taken as
      a sequence of items, added to the set immediately under the topmost
      markobject.  Everything at and after the topmost markobject is popped,
      leaving the mutated set at the top of the stack.

      Stack before:  ... pyset markobject item_1 ... item_n
      Stack after:   ... pyset

      where pyset has been modified via pyset.add(item_i) = item_i for i in
      1, 2, ..., n, and in that order.
      '''),
  I(
      name: 'FROZENSET',
      code: '\x91',
      arg: null,
      stackBefore: [markobject, stackslice],
      stackAfter: [pyfrozenset],
      proto: 4,
      doc: '''Build a frozenset out of the topmost slice, after markobject.

      All the stack entries following the topmost markobject are placed into
      a single Python frozenset, which single frozenset object replaces all
      of the stack from the topmost markobject onward.  For example,

      Stack before: ... markobject 1 2 3
      Stack after:  ... frozenset({1, 2, 3})
      '''),
  I(
      name: 'POP',
      code: '0',
      arg: null,
      stackBefore: [anyobject],
      stackAfter: [],
      proto: 0,
      doc: 'Discard the top stack item, shrinking the stack by one item.'),
  I(
      name: 'DUP',
      code: '2',
      arg: null,
      stackBefore: [anyobject],
      stackAfter: [anyobject, anyobject],
      proto: 0,
      doc: 'Push the top stack item onto the stack again, duplicating it.'),
  I(
      name: 'MARK',
      code: '(',
      arg: null,
      stackBefore: [],
      stackAfter: [markobject],
      proto: 0,
      doc: '''Push markobject onto the stack.

      markobject is a unique object, used by other opcodes to identify a
      region of the stack containing a variable number of objects for them
      to work on.  See markobject.doc for more detail.
      '''),
  I(
      name: 'POP_MARK',
      code: '1',
      arg: null,
      stackBefore: [markobject, stackslice],
      stackAfter: [],
      proto: 1,
      doc: '''Pop all the stack objects at and above the topmost markobject.

      When an opcode using a variable number of stack objects is done,
      POP_MARK is used to remove those objects, and to remove the markobject
      that delimited their starting position on the stack.
      '''),
  I(
      name: 'GET',
      code: 'g',
      arg: decimalnlShort,
      stackBefore: [],
      stackAfter: [anyobject],
      proto: 0,
      doc: '''Read an object from the memo and push it on the stack.

      The index of the memo object to push is given by the newline-terminated
      decimal string following.  BINGET and LONG_BINGET are space-optimized
      versions.
      '''),
  I(
      name: 'BINGET',
      code: 'h',
      arg: uint1,
      stackBefore: [],
      stackAfter: [anyobject],
      proto: 1,
      doc: '''Read an object from the memo and push it on the stack.

      The index of the memo object to push is given by the 1-byte unsigned
      integer following.
      '''),
  I(
      name: 'LONG_BINGET',
      code: 'j',
      arg: int4,
      stackBefore: [],
      stackAfter: [anyobject],
      proto: 1,
      doc: '''Read an object from the memo and push it on the stack.

      The index of the memo object to push is given by the 4-byte unsigned
      little-endian integer following.
      '''),
  I(
      name: 'PUT',
      code: 'p',
      arg: decimalnlShort,
      stackBefore: [],
      stackAfter: [],
      proto: 0,
      doc: '''Store the stack top into the memo.  The stack is not popped.

      The index of the memo location to write into is given by the newline-
      terminated decimal string following.  BINPUT and LONG_BINPUT are
      space-optimized versions.
      '''),
  I(
      name: 'BINPUT',
      code: 'q',
      arg: uint1,
      stackBefore: [],
      stackAfter: [],
      proto: 1,
      doc: '''Store the stack top into the memo.  The stack is not popped.

      The index of the memo location to write into is given by the 1-byte
      unsigned integer following.
      '''),
  I(
      name: 'LONG_BINPUT',
      code: 'r',
      arg: int4,
      stackBefore: [],
      stackAfter: [],
      proto: 1,
      doc: '''Store the stack top into the memo.  The stack is not popped.

      The index of the memo location to write into is given by the 4-byte
      unsigned little-endian integer following.
      '''),
  I(
      name: 'MEMOIZE',
      code: '\x94',
      arg: null,
      stackBefore: [anyobject],
      stackAfter: [anyobject],
      proto: 4,
      doc: '''Store the stack top into the memo.  The stack is not popped.

      The index of the memo location to write is the number of
      elements currently present in the memo.
      '''),
  I(
      name: 'EXT1',
      code: '\x82',
      arg: uint1,
      stackBefore: [],
      stackAfter: [anyobject],
      proto: 2,
      doc: '''Extension code.

      This code and the similar EXT2 and EXT4 allow using a registry
      of popular objects that are pickled by name, typically classes.
      It is envisioned that through a global negotiation and
      registration process, third parties can set up a mapping between
      ints and object names.

      In order to guarantee pickle interchangeability, the extension
      code registry ought to be global, although a range of codes may
      be reserved for private use.

      EXT1 has a 1-byte integer argument.  This is used to index into the
      extension registry, and the object at that index is pushed on the stack.
      '''),
  I(
      name: 'EXT2',
      code: '\x83',
      arg: uint2,
      stackBefore: [],
      stackAfter: [anyobject],
      proto: 2,
      doc: '''Extension code.

      See EXT1.  EXT2 has a two-byte integer argument.
      '''),
  I(
      name: 'EXT4',
      code: '\x84',
      arg: int4,
      stackBefore: [],
      stackAfter: [anyobject],
      proto: 2,
      doc: '''Extension code.

      See EXT1.  EXT4 has a four-byte integer argument.
      '''),
  I(
      name: 'GLOBAL',
      code: 'c',
      arg: stringNoEscapePair,
      stackBefore: [],
      stackAfter: [anyobject],
      proto: 0,
      doc: '''Push a global object (module.attr) on the stack.

      Two newline-terminated strings follow the GLOBAL opcode.  The first is
      taken as a module name, and the second as a class name.  The class
      object module.class is pushed on the stack.  More accurately, the
      object returned by self.find_class(module, class) is pushed on the
      stack, so unpickling subclasses can override this form of lookup.
      '''),
  I(
      name: 'STACK_GLOBAL',
      code: '\x93',
      arg: null,
      stackBefore: [pyunicode, pyunicode],
      stackAfter: [anyobject],
      proto: 4,
      doc: '''Push a global object (module.attr) on the stack.
      '''),
  I(
      name: 'REDUCE',
      code: 'R',
      arg: null,
      stackBefore: [anyobject, anyobject],
      stackAfter: [anyobject],
      proto: 0,
      doc: """Push an object built from a callable and an argument tuple.

      The opcode is named to remind of the __reduce__() method.

      Stack before: ... callable pytuple
      Stack after:  ... callable(*pytuple)

      The callable and the argument tuple are the first two items returned
      by a __reduce__ method.  Applying the callable to the argtuple is
      supposed to reproduce the original object, or at least get it started.
      If the __reduce__ method returns a 3-tuple, the last component is an
      argument to be passed to the object's __setstate__, and then the REDUCE
      opcode is followed by code to create setstate's argument, and then a
      BUILD opcode to apply  __setstate__ to that argument.

      If not isinstance(callable, type), REDUCE complains unless the
      callable has been registered with the copyreg module's
      safe_constructors dict, or the callable has a magic
      '__safe_for_unpickling__' attribute with a true value.  I'm not sure
      why it does this, but I've sure seen this complaint often enough when
      I didn't want to <wink>.
      """),
  I(
      name: 'BUILD',
      code: 'b',
      arg: null,
      stackBefore: [anyobject, anyobject],
      stackAfter: [anyobject],
      proto: 0,
      doc: '''Finish building an object, via __setstate__ or dict update.

      Stack before: ... anyobject argument
      Stack after:  ... anyobject

      where anyobject may have been mutated, as follows:

      If the object has a __setstate__ method,

          anyobject.__setstate__(argument)

      is called.

      Else the argument must be a dict, the object must have a __dict__, and
      the object is updated via

          anyobject.__dict__.update(argument)
      '''),
  I(
      name: 'INST',
      code: 'i',
      arg: stringNoEscapePair,
      stackBefore: [markobject, stackslice],
      stackAfter: [anyobject],
      proto: 0,
      doc: """Build a class instance.

      This is the protocol 0 version of protocol 1's OBJ opcode.
      INST is followed by two newline-terminated strings, giving a
      module and class name, just as for the GLOBAL opcode (and see
      GLOBAL for more details about that).  self.find_class(module, name)
      is used to get a class object.

      In addition, all the objects on the stack following the topmost
      markobject are gathered into a tuple and popped (along with the
      topmost markobject), just as for the TUPLE opcode.

      Now it gets complicated.  If all of these are true:

        + The argtuple is empty (markobject was at the top of the stack
          at the start).

        + The class object does not have a __getinitargs__ attribute.

      then we want to create an old-style class instance without invoking
      its __init__() method (pickle has waffled on this over the years; not
      calling __init__() is current wisdom).  In this case, an instance of
      an old-style dummy class is created, and then we try to rebind its
      __class__ attribute to the desired class object.  If this succeeds,
      the new instance object is pushed on the stack, and we're done.

      Else (the argtuple is not empty, it's not an old-style class object,
      or the class object does have a __getinitargs__ attribute), the code
      first insists that the class object have a __safe_for_unpickling__
      attribute.  Unlike as for the __safe_for_unpickling__ check in REDUCE,
      it doesn't matter whether this attribute has a true or false value, it
      only matters whether it exists (XXX this is a bug).  If
      __safe_for_unpickling__ doesn't exist, UnpicklingError is raised.

      Else (the class object does have a __safe_for_unpickling__ attr),
      the class object obtained from INST's arguments is applied to the
      argtuple obtained from the stack, and the resulting instance object
      is pushed on the stack.

      NOTE:  checks for __safe_for_unpickling__ went away in Python 2.3.
      NOTE:  the distinction between old-style and new-style classes does
             not make sense in Python 3.
      """),
  I(
      name: 'OBJ',
      code: 'o',
      arg: null,
      stackBefore: [markobject, anyobject, stackslice],
      stackAfter: [anyobject],
      proto: 1,
      doc: """Build a class instance.

      This is the protocol 1 version of protocol 0's INST opcode, and is
      very much like it.  The major difference is that the class object
      is taken off the stack, allowing it to be retrieved from the memo
      repeatedly if several instances of the same class are created.  This
      can be much more efficient (in both time and space) than repeatedly
      embedding the module and class names in INST opcodes.

      Unlike INST, OBJ takes no arguments from the opcode stream.  Instead
      the class object is taken off the stack, immediately above the
      topmost markobject:

      Stack before: ... markobject classobject stackslice
      Stack after:  ... new_instance_object

      As for INST, the remainder of the stack above the markobject is
      gathered into an argument tuple, and then the logic seems identical,
      except that no __safe_for_unpickling__ check is done (XXX this is
      a bug).  See INST for the gory details.

      NOTE:  In Python 2.3, INST and OBJ are identical except for how they
      get the class object.  That was always the intent; the implementations
      had diverged for accidental reasons.
      """),
  I(
      name: 'NEWOBJ',
      code: '\x81',
      arg: null,
      stackBefore: [anyobject, anyobject],
      stackAfter: [anyobject],
      proto: 2,
      doc: '''Build an object instance.

      The stack before should be thought of as containing a class
      object followed by an argument tuple (the tuple being the stack
      top).  Call these cls and args.  They are popped off the stack,
      and the value returned by cls.__new__(cls, *args) is pushed back
      onto the stack.
      '''),
  I(
      name: 'NEWOBJ_EX',
      code: '\x92',
      arg: null,
      stackBefore: [anyobject, anyobject, anyobject],
      stackAfter: [anyobject],
      proto: 4,
      doc: '''Build an object instance.

      The stack before should be thought of as containing a class
      object followed by an argument tuple and by a keyword argument dict
      (the dict being the stack top).  Call these cls and args.  They are
      popped off the stack, and the value returned by
      cls.__new__(cls, *args, *kwargs) is  pushed back  onto the stack.
      '''),
  I(
      name: 'PROTO',
      code: '\x80',
      arg: uint1,
      stackBefore: [],
      stackAfter: [],
      proto: 2,
      doc: '''Protocol version indicator.

      For protocol 2 and above, a pickle must start with this opcode.
      The argument is the protocol version, an int in range(2, 256).
      '''),
  I(
      name: 'STOP',
      code: '.',
      arg: null,
      stackBefore: [anyobject],
      stackAfter: [],
      proto: 0,
      doc: """Stop the unpickling machine.

      Every pickle ends with this opcode.  The object at the top of the stack
      is popped, and that's the result of unpickling.  The stack should be
      empty then.
      """),
  I(
      name: 'FRAME',
      code: '\x95',
      arg: int8,
      stackBefore: [],
      stackAfter: [],
      proto: 4,
      doc: '''Indicate the beginning of a new frame.

      The unpickler may use this opcode to safely prefetch data from its
      underlying stream.
      '''),
  I(
      name: 'PERSID',
      code: 'P',
      arg: stringnlNoEscape,
      stackBefore: [],
      stackAfter: [anyobject],
      proto: 0,
      doc: """Push an object identified by a persistent ID.

      The pickle module doesn't define what a persistent ID means.  PERSID's
      argument is a newline-terminated str-style (no embedded escapes, no
      bracketing quote characters) string, which *is* "the persistent ID".
      The unpickler passes this string to self.persistent_load().  Whatever
      object that returns is pushed on the stack.  There is no implementation
      of persistent_load() in Python's unpickler:  it must be supplied by an
      unpickler subclass.
      """),
  I(
      name: 'BINPERSID',
      code: 'Q',
      arg: null,
      stackBefore: [anyobject],
      stackAfter: [anyobject],
      proto: 1,
      doc: '''Push an object identified by a persistent ID.

      Like PERSID, except the persistent ID is popped off the stack (instead
      of being a string embedded in the opcode bytestream).  The persistent
      ID is passed to self.persistent_load(), and whatever object that
      returns is pushed on the stack.  See PERSID for more detail.
      '''),
];
