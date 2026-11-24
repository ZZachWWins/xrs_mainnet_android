import 'dart:typed_data';
import 'dart:convert';

Uint8List encodeU32(int value) {
  final buf = ByteData(4);
  buf.setUint32(0, value, Endian.little);
  return buf.buffer.asUint8List();
}

Uint8List encodeU64(int value) {
  final buf = ByteData(8);
  buf.setUint64(0, value, Endian.little);
  return buf.buffer.asUint8List();
}

Uint8List encodeU8(int value) => Uint8List.fromList([value & 0xFF]);

Uint8List encodeBool(bool value) => Uint8List.fromList([value ? 1 : 0]);

Uint8List encodeBincodeString(String s) {
  final bytes = utf8.encode(s);
  return Uint8List.fromList([...encodeU64(bytes.length), ...bytes]);
}

Uint8List encodeBincodeVec(Uint8List bytes) {
  return Uint8List.fromList([...encodeU64(bytes.length), ...bytes]);
}

Uint8List encodeBincodeStringVec(List<String> strings) {
  final parts = <int>[...encodeU64(strings.length)];
  for (final s in strings) {
    parts.addAll(encodeBincodeString(s));
  }
  return Uint8List.fromList(parts);
}

/// Encodes `Option<T>::None` as a single 0x00 byte.
Uint8List encodeNone() => Uint8List.fromList([0x00]);

/// Encodes `Option<u64>::Some(value)` as 0x01 followed by the u64 LE bytes.
Uint8List encodeSomeU64(int value) =>
    Uint8List.fromList([0x01, ...encodeU64(value)]);

/// Encodes `Option<Vec<String>>::Some(strings)`.
Uint8List encodeSomeStringVec(List<String> strings) =>
    Uint8List.fromList([0x01, ...encodeBincodeStringVec(strings)]);
