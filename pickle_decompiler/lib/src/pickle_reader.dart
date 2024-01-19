// Converted/modified from Python's pickle.py and pickletools.py: https://github.com/python/cpython/blob/main/Lib/pickle.py https://github.com/python/cpython/blob/main/Lib/pickletools.py

typedef Entries = Map<List<int>, List<(int, int, List<int>)>>;

// Mainly copied and translated from https://github.com/python/cpython/blob/3.12/Lib/pickletools.py

String reprByte(int byte) {
  // Check if the byte is a valid ASCII character (0-127)
  if (byte >= 0 && byte <= 127) {
    return String.fromCharCode(byte);
  } else {
    // If not, return the hexadecimal representation
    return '\\x${byte.toRadixString(16).padLeft(2, '0')}';
  }
}

class ArgumentDescriptor {
  final String name;
  final int n;
  final ({dynamic result, int n}) Function(List<int> data, int pos) reader;
  final String doc;

  ArgumentDescriptor(this.name, this.n, this.reader, this.doc);
}

class StackObject {
  final String name;
  final dynamic obtype;
  final String doc;

  StackObject({required this.name, required this.obtype, required this.doc});
}

class OpCodeInfo {
  final String name;
  final String code;
  final ArgumentDescriptor? arg;
  final List<StackObject> stackBefore;
  final List<StackObject> stackAfter;
  final int proto;
  final String doc;

  OpCodeInfo(
      {required this.name,
      required this.code,
      this.arg,
      required this.stackBefore,
      required this.stackAfter,
      this.proto = 0,
      required this.doc});
}

abstract class Frame {
  int readInto(List<int> buf);

  List<int> readline();
  abstract List<int> Function()? fileReadline;

  List<int> read(int? n);
  abstract List<int> Function(int? n)? fileRead;
}

class RawFrame extends Frame {
  int pos = 0;
  List<int> data;
  @override
  List<int> Function(int? n)? fileRead;
  @override
  List<int> Function()? fileReadline;

  List<int> _fileRead(int? n) {
    List<int> outData = data.sublist(pos, n == null ? null : pos + n);
    pos += outData.length;

    return outData;
  }

  List<int> _fileReadline() {
    List<int> outData = [];
    while (pos < data.length) {
      int byte = data[pos];
      pos++;
      outData.add(byte);
      if (byte == '\n'.codeUnitAt(0)) {
        break;
      }
    }

    return outData;
  }

  RawFrame({required this.data}) {
    fileRead = _fileRead;
    fileReadline = _fileReadline;
  }

  @override
  List<int> read(int? n) {
    return fileRead!(n);
  }

  @override
  int readInto(List<int> buf) {
    int n = buf.length;
    List<int> replacements = fileRead!(n);
    buf.replaceRange(n - replacements.length, n, replacements);
    return n;
  }

  @override
  List<int> readline() {
    return fileReadline!();
  }
}

class Unframer extends Frame {
  @override
  List<int> Function(int? n)? fileRead;
  @override
  List<int> Function()? fileReadline;
  Frame? currentFrame;

  Unframer({required this.fileRead, required this.fileReadline});

  @override
  int readInto(List<int> buf) {
    int n;

    if (currentFrame != null) {
      n = currentFrame!.readInto(buf);
      if (n == 0 && buf.isNotEmpty) {
        currentFrame = null;
        n = buf.length;
        buf = fileRead!(n);
        return n;
      }
      if (n < buf.length) {
        throw Exception('pickle exhausted before end of frame');
      }
      return n;
    } else {
      int n = buf.length;
      List<int> replacements = fileRead!(n);
      buf.replaceRange(n - replacements.length, n, replacements);
      return n;
    }
  }

  @override
  List<int> read(int? n) {
    if (currentFrame != null) {
      List<int> data = currentFrame!.read(n);
      if (data.isEmpty && n != 0) {
        currentFrame = null;
        return fileRead!(n);
      }
      if (n != null && data.length < n) {
        throw Exception('pickle exhausted before end of frame');
      }
      return data;
    } else {
      return fileRead!(n);
    }
  }

  @override
  List<int> readline() {
    if (currentFrame != null) {
      List<int> data = currentFrame!.readline();
      if (data.isEmpty) {
        currentFrame = null;
        return fileReadline!();
      }
      if (data.last != '\n'.codeUnitAt(0)) {
        throw Exception('pickle exhausted before end of frame');
      }
      return data;
    } else {
      return fileReadline!();
    }
  }

  void loadFrame(int frameSize) {
    if (currentFrame != null && currentFrame!.read(null).isNotEmpty) {
      throw Exception('beginning of a new frame before end of current frame');
    }

    currentFrame = RawFrame(data: fileRead!(frameSize));
  }
}
