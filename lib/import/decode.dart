import 'dart:convert';
import 'dart:typed_data';

/// Decodes bank files: UTF-8 (with/without BOM) first, Latin-1/Windows-1252 as fallback
/// (older OFX files declare CHARSET:1252 and are not valid UTF-8).
String decodeBankFile(Uint8List bytes) {
  var b = bytes;
  if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) b = b.sublist(3);
  try {
    return utf8.decode(b);
  } on FormatException {
    return latin1.decode(b);
  }
}
