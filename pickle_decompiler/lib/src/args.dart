import 'dart:convert';
import 'dart:typed_data';

import 'package:pickle_decompiler/src/pickle_reader.dart';

const upToNewLine = -1;

const takenFromArgument1 = -2;
const takenFromArgument4 = -3;
const takenFromArgument4U = -4;
const takenFromArgument8U = -5;

({dynamic result, int n}) readUint1(List<int> data, int pos) {
  return (result: data[pos], n: 1);
}

var uint1 =
    ArgumentDescriptor('uint1', 1, readUint1, 'One-byte unsigned integer.');

({dynamic result, int n}) readUint2(List<int> data, int pos) {
  List<int> bytes = data.sublist(pos, pos + 2);

  if (bytes.length < 2) {
    throw Exception('Not enough bytes to read uint2');
  }

  return (result: bytes, n: 2);
}

var uint2 = ArgumentDescriptor(
    'int2', 2, readUint2, 'Two-byte unsigned integer, little-endian.');

({dynamic result, int n}) readInt4(List<int> data, int pos) {
  List<int> bytes = data.sublist(pos, pos + 4);

  if (bytes.length < 4) {
    throw Exception('Not enough bytes to read int4');
  }

  return (
    result: ByteData.sublistView(Uint8List.fromList(bytes))
        .getInt32(0, Endian.little),
    n: 4
  );
}

var int4 = ArgumentDescriptor('uint4', 4, readInt4,
    "Four-byte signed integer, little-endian, 2's complement.");

({dynamic result, int n}) readInt8(List<int> data, int pos) {
  List<int> bytes = data.sublist(pos, pos + 8);

  if (bytes.length < 8) {
    throw Exception('Not enough bytes to read uint8');
  }

  return (result: bytes, n: 8);
}

var int8 = ArgumentDescriptor(
    'uint8', 8, readInt8, 'Eight-byte unsigned integer, little-endian.');

({dynamic result, int n}) readStringnl(List<int> data, int pos,
    {bool decode = true, bool stripQuotes = true}) {
  List<int> maxLine = data.sublist(pos);
  List<int> line = [];

  for (int i = 0; i < maxLine.length; i++) {
    line.add(maxLine[i]);

    if (maxLine[i] == '\n'.codeUnits.single) {
      break;
    }
  }

  if (line.last != '\n'.codeUnits.single) {
    throw Exception('No newline found');
  }

  line.removeLast();

  if (stripQuotes) {
    for (String q in ['"', "'"]) {
      if (line.first == q.codeUnits.single) {
        if (line.last != q.codeUnits.single) {
          throw Exception('No closing quote found');
        }

        line.removeLast();
        line.removeAt(0);

        stripQuotes = false;

        break;
      }
    }
    if (stripQuotes) {
      throw Exception('No opening quote found');
    }
  }

  if (decode) {
    return (result: ascii.decode(line), n: line.length);
  }

  return (result: line, n: line.length);
}

var stringnl = ArgumentDescriptor(
    'stringnl', upToNewLine, readStringnl, '''A newline-terminated string.

                   This is a repr-style string, with embedded escapes, and
                   bracketing quotes.
                   ''');

({dynamic result, int n}) readStringnlNoEscape(List<int> data, int pos) {
  return readStringnl(data, pos, stripQuotes: false);
}

var stringnlNoEscape = ArgumentDescriptor('stringnl_noescape', upToNewLine,
    readStringnlNoEscape, '''A newline-terminated string.

                        This is a str-style string, without embedded escapes,
                        or bracketing quotes.  It should consist solely of
                        printable ASCII characters.
                        ''');

({dynamic result, int n}) readStringNoEscapePair(List<int> data, int pos) {
  var firstString = readStringnlNoEscape(data, pos);
  var secondString = readStringnlNoEscape(data, pos + firstString.n + 1);
  return (
    result: '${firstString.result} ${secondString.result}',
    n: firstString.n + secondString.n + 2
  );
}

var stringNoEscapePair = ArgumentDescriptor(
    'stringnl_noescape_pair',
    upToNewLine,
    readStringNoEscapePair, '''A pair of newline-terminated strings.

                             These are str-style strings, without embedded
                             escapes, or bracketing quotes.  They should
                             consist solely of printable ASCII characters.
                             The pair is returned as a single string, with
                             a single blank separating the two strings.
                             ''');

({dynamic result, int n}) readString1(List<int> data, int pos) {
  int n = readUint1(data, pos).result;

  assert(n >= 0);
  pos++;

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read string1');
  }

  return (result: latin1.decode(bytes), n: n + 1);
}

var string1 = ArgumentDescriptor(
    'string1', takenFromArgument1, readString1, '''A counted string.

              The first argument is a 1-byte unsigned int giving the number
              of bytes in the string, and the second argument is that many
              bytes.
              ''');

({dynamic result, int n}) readString4(List<int> data, int pos) {
  int n = readInt4(data, pos).result;
  pos += 4;

  if (n < 0) {
    throw Exception('Negative string length');
  }

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read string4');
  }

  return (result: latin1.decode(bytes), n: n);
}

var string4 = ArgumentDescriptor(
    'string4', takenFromArgument4, readString4, '''A counted string.

              The first argument is a 4-byte little-endian signed int giving
              the number of bytes in the string, and the second argument is
              that many bytes.
              ''');

({dynamic result, int n}) readBytes1(List<int> data, int pos) {
  int n = readUint1(data, pos).result;
  pos++;

  if (n < 0) {
    throw Exception('Negative bytes length');
  }

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read bytes1');
  }

  return (result: bytes, n: n);
}

var bytes1 = ArgumentDescriptor(
    'bytes1', takenFromArgument1, readBytes1, '''A counted bytes string.

              The first argument is a 1-byte unsigned int giving the number
              of bytes, and the second argument is that many bytes.
              ''');

({dynamic result, int n}) readBytes4(List<int> data, int pos) {
  int n = readInt4(data, pos).result;
  pos += 4;

  if (n < 0) {
    throw Exception('Negative bytes length');
  }

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read bytes4');
  }

  return (result: bytes, n: n);
}

var bytes4 = ArgumentDescriptor(
    'bytes4', takenFromArgument4U, readBytes4, '''A counted bytes string.

              The first argument is a 4-byte little-endian unsigned int giving
              the number of bytes, and the second argument is that many bytes.
              ''');

({dynamic result, int n}) readBytes8(List<int> data, int pos) {
  int n = readInt8(data, pos).result;
  pos += 8;

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read bytes8');
  }

  return (result: bytes, n: n);
}

var bytes8 = ArgumentDescriptor(
    'bytes8', takenFromArgument8U, readBytes8, '''A counted bytes string.

              The first argument is an 8-byte little-endian unsigned int giving
              the number of bytes, and the second argument is that many bytes.
              ''');

({dynamic result, int n}) readBytearray8(List<int> data, int pos) {
  int n = readInt8(data, pos).result;
  pos += 8;

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read bytearray8');
  }

  return (result: Uint8List.fromList(bytes), n: n);
}

var bytearray8 = ArgumentDescriptor(
    'bytearray8', takenFromArgument8U, readBytearray8, '''A counted bytearray.

              The first argument is an 8-byte little-endian unsigned int giving
              the number of bytes, and the second argument is that many bytes.
              ''');

({dynamic result, int n}) readUnicodeStringnl(List<int> data, int pos) {
  List<int> maxLine = data.sublist(pos);
  List<int> line = [];

  for (int i = 0; i < maxLine.length; i++) {
    line.add(maxLine[i]);

    if (maxLine[i] == '\n'.codeUnits.single) {
      break;
    }
  }

  if (line.last != '\n'.codeUnits.single) {
    throw Exception('No newline found');
  }

  line.removeLast();

  return (result: utf8.decode(line), n: line.length);
}

var unicodeStringnl = ArgumentDescriptor('unicodestringnl', upToNewLine,
    readUnicodeStringnl, '''A newline-terminated Unicode string.

                      This is raw-unicode-escape encoded, so consists of
                      printable ASCII characters, and may contain embedded
                      escape sequences.
                      ''');

({dynamic result, int n}) readUnicodeString1(List<int> data, int pos) {
  int n = readUint1(data, pos).result;
  pos++;

  if (n < 0) {
    throw Exception('Negative unicode string length');
  }

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read unicode string1');
  }

  return (result: utf8.decode(bytes), n: n + 1);
}

var unicodeString1 = ArgumentDescriptor('unicodestring1', takenFromArgument1,
    readUnicodeString1, '''A counted Unicode string.

                    The first argument is a 1-byte little-endian signed int
                    giving the number of bytes in the string, and the second
                    argument-- the UTF-8 encoding of the Unicode string --
                    contains that many bytes.
                    ''');

({dynamic result, int n}) readUnicodeString4(List<int> data, int pos) {
  int n = readInt4(data, pos).result;
  pos += 4;

  if (n < 0) {
    throw Exception('Negative unicode string length');
  }

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read unicode string4');
  }

  return (result: utf8.decode(bytes), n: n + 4);
}

var unicodeString4 = ArgumentDescriptor('unicodestring4', takenFromArgument4,
    readUnicodeString4, '''A counted Unicode string.

                    The first argument is a 4-byte little-endian signed int
                    giving the number of bytes in the string, and the second
                    argument-- the UTF-8 encoding of the Unicode string --
                    contains that many bytes.
                    ''');

({dynamic result, int n}) readUnicodeString8(List<int> data, int pos) {
  int n = readInt8(data, pos).result;
  pos += 8;

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read unicode string8');
  }

  return (result: utf8.decode(bytes), n: n + 8);
}

var unicodeString8 = ArgumentDescriptor('unicodestring8', takenFromArgument8U,
    readUnicodeString8, '''A counted Unicode string.

                    The first argument is an 8-byte little-endian signed int
                    giving the number of bytes in the string, and the second
                    argument-- the UTF-8 encoding of the Unicode string --
                    contains that many bytes.
                    ''');

({dynamic result, int n}) readDecimalnlShort(List<int> data, int pos) {
  var s = readStringnl(data, pos, decode: false, stripQuotes: false);

  if (s.result == [0]) {
    return (result: false, n: s.n);
  } else if (s.result == [1]) {
    return (result: true, n: s.n);
  } else {
    return (result: int.parse(utf8.decode(s.result)), n: s.n);
  }
}

var decimalnlShort = ArgumentDescriptor('decimalnl_short', upToNewLine,
    readDecimalnlShort, """A newline-terminated decimal integer literal.

                          This never has a trailing 'L', and the integer fit
                          in a short Python int on the box where the pickle
                          was written -- but there's no guarantee it will fit
                          in a short Python int on the box where the pickle
                          is read.
                          """);

({dynamic result, int n}) readDecimalnlLong(List<int> data, int pos) {
  var s = readStringnl(data, pos, decode: false, stripQuotes: false);
  List<int> res = List.from(s.result);
  if (res.last == 'L'.codeUnits.single) {
    res.removeLast();
  }

  return (result: int.parse(utf8.decode(res)), n: s.n);
}

var decimalnlLong = ArgumentDescriptor('decimalnl_long', upToNewLine,
    readDecimalnlLong, """A newline-terminated decimal integer literal.

                         This has a trailing 'L', and can represent integers
                         of any size.
                         """);

({dynamic result, int n}) readFloatnl(List<int> data, int pos) {
  var s = readStringnl(data, pos, decode: false, stripQuotes: false);

  return (result: double.parse(utf8.decode(s.result)), n: s.n);
}

var floatnl = ArgumentDescriptor('floatnl', upToNewLine, readFloatnl,
    """A newline-terminated decimal floating literal.

              In general this requires 17 significant digits for roundtrip
              identity, and pickling then unpickling infinities, NaNs, and
              minus zero doesn't work across boxes, or on some boxes even
              on itself (e.g., Windows can't read the strings it produces
              for infinities or NaNs).
              """);

({dynamic result, int n}) readFloat8(List<int> data, int pos) {
  List<int> bytes = data.sublist(pos, pos + 8);

  if (bytes.length < 8) {
    throw Exception('Not enough bytes to read float8');
  }

  return (
    result: ByteData.sublistView(Uint8List.fromList(bytes))
        .getFloat64(0, Endian.big),
    n: 8
  );
}

var float8 = ArgumentDescriptor('float8', 8, readFloat8,
    """An 8-byte binary representation of a float, big-endian.

             The format is unique to Python, and shared with the struct
             module (format string '>d') "in theory" (the struct and pickle
             implementations don't share the code -- they should).  It's
             strongly related to the IEEE-754 double format, and, in normal
             cases, is in fact identical to the big-endian 754 double format.
             On other boxes the dynamic range is limited to that of a 754
             double, and "add a half and chop" rounding is used to reduce
             the precision to 53 bits.  However, even on a 754 box,
             infinities, NaNs, and minus zero may not be handled correctly
             (may not survive roundtrip pickling intact).
             """);

int decodeLong(List<int> data) {
  int result = 0;
  for (int i = 0; i < data.length; i++) {
    result += data[i] << (8 * i);
  }
  return result;
}

({dynamic result, int n}) readLong1(List<int> data, int pos) {
  int n = readUint1(data, pos).result;
  pos++;

  if (n < 0) {
    throw Exception('Negative long length');
  }

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read long1');
  }

  return (result: decodeLong(bytes), n: n + 1);
}

var long1 = ArgumentDescriptor('long1', takenFromArgument1, readLong1,
    """A binary long, little-endian, using 1-byte size.

    This first reads one byte as an unsigned size, then reads that
    many bytes and interprets them as a little-endian 2's-complement long.
    If the size is 0, that's taken as a shortcut for the long 0L.
    """);

({dynamic result, int n}) readLong4(List<int> data, int pos) {
  int n = readInt4(data, pos).result;
  pos += 4;

  if (n < 0) {
    throw Exception('Negative long length');
  }

  List<int> bytes = data.sublist(pos, pos + n);

  if (bytes.length < n) {
    throw Exception('Not enough bytes to read long4');
  }

  return (result: decodeLong(bytes), n: n + 4);
}

var long4 = ArgumentDescriptor('long4', takenFromArgument4, readLong4,
    """A binary representation of a long, little-endian.

    This first reads four bytes as a signed size (but requires the
    size to be >= 0), then reads that many bytes and interprets them
    as a little-endian 2's-complement long.  If the size is 0, that's taken
    as a shortcut for the int 0, although LONG1 should really be used
    then instead (and in any case where # of bytes < 256).
    """);
