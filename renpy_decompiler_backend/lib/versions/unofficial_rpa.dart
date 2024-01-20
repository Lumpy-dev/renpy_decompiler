import 'package:renpy_decompiler_backend/versions/official_rpa.dart';

class RPAVersionThreePointTwo extends RPAVersionThree {
  @override
  String get version => 'RPA-3.2';
}

class RPAVersionFour extends RPAVersionThree {
  @override
  String get version => 'RPA-4.0';
}

/// Ported from https://github.com/einstein95/unrpa/commit/496f376d8c6d82529a67749a814e72ce7855b378
class RPAAsenheim extends RPAVersionThree {
  @override
  String get version => 'RPA-Asenheim';

  @override
  List<int> get rawVersion => '\x01\x13\x05\x0e\x08\x05\x09\x0d'.codeUnits;
}