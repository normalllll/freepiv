import 'dart:typed_data';
import 'dart:ui' show Size;

/// The most of a file's start [imageSizeFromHeader] ever needs to be given:
/// a JPEG's size can follow a long EXIF segment. A caller that has gathered
/// this much and still has no size can stop trying.
const imageHeaderLimit = 64 * 1024;

/// The pixel size a picture file declares in its first bytes: JPEG, PNG, GIF
/// and WebP (lossy, lossless and extended). Null when [bytes] do not reach
/// the size yet or are not a picture of those formats; more bytes of the same
/// file may then succeed. Orientation tags are not applied, so a decoder's
/// size is the authority.
Size? imageSizeFromHeader(Uint8List bytes) {
  if (bytes.length < 4) return null;
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) return _jpeg(bytes);
  if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return _png(bytes);
  if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return _gif(bytes);
  if (bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) return _webp(bytes);
  return null;
}

Size? _size(int width, int height) => width > 0 && height > 0 ? Size(width.toDouble(), height.toDouble()) : null;

int _be16(Uint8List b, int at) => (b[at] << 8) | b[at + 1];
int _le16(Uint8List b, int at) => b[at] | (b[at + 1] << 8);
int _be32(Uint8List b, int at) => (b[at] << 24) | (b[at + 1] << 16) | (b[at + 2] << 8) | b[at + 3];
int _le24(Uint8List b, int at) => b[at] | (b[at + 1] << 8) | (b[at + 2] << 16);

Size? _jpeg(Uint8List b) {
  var at = 2;
  while (at < b.length) {
    // Markers are 0xFF and a code; extra 0xFF bytes pad before one.
    if (b[at] != 0xFF) return null;
    while (at < b.length && b[at] == 0xFF) {
      at++;
    }
    if (at >= b.length) return null;
    final marker = b[at++];
    // Markers without a length: padding, TEM, RSTn, SOI and EOI.
    if (marker == 0x00 || marker == 0x01 || (marker >= 0xD0 && marker <= 0xD9)) continue;
    if (at + 2 > b.length) return null;
    final length = _be16(b, at);
    if (length < 2) return null;
    // SOF0 to SOF15, except DHT (C4), JPG (C8) and DAC (CC).
    if (marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC) {
      if (at + 7 > b.length) return null;
      return _size(_be16(b, at + 5), _be16(b, at + 3));
    }
    // The start of the scan holds no size beyond this point.
    if (marker == 0xDA) return null;
    at += length;
  }
  return null;
}

Size? _png(Uint8List b) {
  // Signature, then the IHDR chunk first: length, "IHDR", width, height.
  if (b.length < 24) return null;
  if (b[12] != 0x49 || b[13] != 0x48 || b[14] != 0x44 || b[15] != 0x52) return null;
  return _size(_be32(b, 16), _be32(b, 20));
}

Size? _gif(Uint8List b) {
  if (b.length < 10) return null;
  return _size(_le16(b, 6), _le16(b, 8));
}

Size? _webp(Uint8List b) {
  if (b.length < 16) return null;
  if (b[8] != 0x57 || b[9] != 0x45 || b[10] != 0x42 || b[11] != 0x50) return null;
  final kind = String.fromCharCodes(b.sublist(12, 16));
  const data = 20;
  switch (kind) {
    case 'VP8 ':
      // Frame tag (3 bytes), start code 9D 01 2A, then 14-bit sizes.
      if (b.length < data + 10) return null;
      if (b[data + 3] != 0x9D || b[data + 4] != 0x01 || b[data + 5] != 0x2A) return null;
      return _size(_le16(b, data + 6) & 0x3FFF, _le16(b, data + 8) & 0x3FFF);
    case 'VP8L':
      // Signature 2F, then 14 bits each of width - 1 and height - 1.
      if (b.length < data + 5) return null;
      if (b[data] != 0x2F) return null;
      final bits = b[data + 1] | (b[data + 2] << 8) | (b[data + 3] << 16) | (b[data + 4] << 24);
      return _size((bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1);
    case 'VP8X':
      // Flags and three reserved bytes, then 24-bit canvas width - 1 and height - 1.
      if (b.length < data + 10) return null;
      return _size(_le24(b, data + 4) + 1, _le24(b, data + 7) + 1);
  }
  return null;
}
