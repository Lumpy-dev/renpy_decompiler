// Converted from Python's pickle.py: https://github.com/python/cpython/blob/main/Lib/pickle.py

// ignore_for_file: non_constant_identifier_names, constant_identifier_names

final MARK = '('.codeUnits.single; // push special markobject on stack
final STOP = '.'.codeUnits.single; // every pickle ends with STOP
final POP = '0'.codeUnits.single; // discard topmost stack item
final POP_MARK =
    '1'.codeUnits.single; // discard stack top through topmost markobject
final DUP = '2'.codeUnits.single; // duplicate top stack item
final FLOAT =
    'F'.codeUnits.single; // push float object; decimal string argument
final INT =
    'I'.codeUnits.single; // push integer or bool; decimal string argument
final BININT = 'J'.codeUnits.single; // push four-byte signed int
final BININT1 = 'K'.codeUnits.single; // push 1-byte unsigned int
final LONG = 'L'.codeUnits.single; // push long; decimal string argument
final BININT2 = 'M'.codeUnits.single; // push 2-byte unsigned int
final NONE = 'N'.codeUnits.single; // push None
final PERSID =
    'P'.codeUnits.single; // push persistent object; id is taken from string arg
final BINPERSID =
    'Q'.codeUnits.single; //  "       "         "  ;  "  "   "     "  stack
final REDUCE =
    'R'.codeUnits.single; // apply callable to argtuple, both on stack
final STRING =
    'S'.codeUnits.single; // push string; NL-terminated string argument
final BINSTRING =
    'T'.codeUnits.single; // push string; counted binary string argument
final SHORT_BINSTRING =
    'U'.codeUnits.single; //  "     "   ;    "      "       "      " < 256 bytes
final UNICODE =
    'V'.codeUnits.single; // push Unicode string; raw-unicode-escaped'd argument
final BINUNICODE =
    'X'.codeUnits.single; //   "     "       "  ; counted UTF-8 string argument
final APPEND = 'a'.codeUnits.single; // append stack top to list below it
final BUILD = 'b'.codeUnits.single; // call __setstate__ or __dict__.update()
final GLOBAL =
    'c'.codeUnits.single; // push self.find_class(modname, name); 2 string args
final DICT = 'd'.codeUnits.single; // build a dict from stack items
final EMPTY_DICT = '}'.codeUnits.single; // push empty dict
final APPENDS =
    'e'.codeUnits.single; // extend list on stack by topmost stack slice
final GET =
    'g'.codeUnits.single; // push item from memo on stack; index is string arg
final BINGET =
    'h'.codeUnits.single; //   "    "    "    "   "   "  ;   "    " 1-byte arg
final INST = 'i'.codeUnits.single; // build & push class instance
final LONG_BINGET =
    'j'.codeUnits.single; // push item from memo on stack; index is 4-byte arg
final LIST = 'l'.codeUnits.single; // build list from topmost stack items
final EMPTY_LIST = ']'.codeUnits.single; // push empty list
final OBJ = 'o'.codeUnits.single; // build & push class instance
final PUT =
    'p'.codeUnits.single; // store stack top in memo; index is string arg
final BINPUT =
    'q'.codeUnits.single; //   "     "    "   "   " ;   "    " 1-byte arg
final LONG_BINPUT =
    'r'.codeUnits.single; //   "     "    "   "   " ;   "    " 4-byte arg
final SETITEM = 's'.codeUnits.single; // add key+value pair to dict
final TUPLE = 't'.codeUnits.single; // build tuple from topmost stack items
final EMPTY_TUPLE = ')'.codeUnits.single; // push empty tuple
final SETITEMS =
    'u'.codeUnits.single; // modify dict by adding topmost key+value pairs
final BINFLOAT =
    'G'.codeUnits.single; // push float; arg is 8-byte float encoding

// Protocol 2

const PROTO = 0x80; // identify pickle protocol
const NEWOBJ = 0x81; // build object by applying cls.__new__ to argtuple
const EXT1 = 0x82; // push object from extension registry; 1-byte index
const EXT2 = 0x83; // ditto, but 2-byte index
const EXT4 = 0x84; // ditto, but 4-byte index
const TUPLE1 = 0x85; // build 1-tuple from stack top
const TUPLE2 = 0x86; // build 2-tuple from two topmost stack items
const TUPLE3 = 0x87; // build 3-tuple from three topmost stack items
const NEWTRUE = 0x88; // push True
const NEWFALSE = 0x89; // push False
const LONG1 = 0x8a; // push long from < 256 bytes
const LONG4 = 0x8b; // push really big long

// Protocol 3 (Python 3.x)

final BINBYTES =
    'B'.codeUnits.single; // push bytes; counted binary string argument
final SHORT_BINBYTES =
    'C'.codeUnits.single; //  "     "   ;    "      "       "      " < 256 bytes

// Protocol 4

const SHORT_BINUNICODE = 0x8c; // push short string; UTF-8 length < 256 bytes
const BINUNICODE8 = 0x8d; // push very long string
const BINBYTES8 = 0x8e; // push very long bytes string
const EMPTY_SET = 0x8f; // push empty set on the stack
const ADDITEMS = 0x90; // modify set by adding topmost stack items
const FROZENSET = 0x91; // build frozenset from topmost stack items
const NEWOBJ_EX = 0x92; // like NEWOBJ but work with keyword only arguments
const STACK_GLOBAL = 0x93; // same as GLOBAL but using names on the stacks
const MEMOIZE = 0x94; // store top of the stack in memo
const FRAME = 0x95; // indicate the beginning of a new frame

// Protocol 5

const BYTEARRAY8 = 0x96; // push bytearray
const NEXT_BUFFER = 0x97; // push next out-of-band buffer
const READONLY_BUFFER = 0x98; // make top of stack readonly
