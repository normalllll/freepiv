import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:freepiv/src/rust/api/image_utils.dart';
import 'package:freepiv/ui/custom/avatar_cropper.dart';

/// The largest picked file the profile image flow takes.
const profileImageSourceLimit = 30 * 1024 * 1024;

/// What Pixiv is told about the uploaded profile image.
const profileImageFileName = 'profile.jpg';
const profileImageMime = 'image/jpeg';

/// An image file the user chose, not read yet: the picker returns as soon as
/// the choice is made, so the form can show that it is working while the
/// bytes are read.
class PickedProfileImage {
  const PickedProfileImage({required this.size, required this.read});

  /// A file already in memory.
  PickedProfileImage.bytes(Uint8List bytes) : size = bytes.length, read = (() async => bytes);

  /// The file's length in bytes, when the platform can tell without reading it.
  final int? size;

  final Future<Uint8List> Function() read;
}

/// Asks the user for an image, or returns null when none is chosen. Replaced
/// by the automation entry and by tests.
typedef ProfileImagePicker = Future<PickedProfileImage?> Function();

/// Turns [source] and the square to keep into the JPEG that is uploaded.
/// Replaced by tests, which have no native library.
typedef ProfileImagePreparer = Future<Uint8List> Function(Uint8List source, AvatarCrop crop);

ProfileImagePicker profileImagePicker = _pickWithFilePicker;

ProfileImagePreparer profileImagePreparer = _prepareWithRust;

Future<PickedProfileImage?> _pickWithFilePicker() async {
  final result = await FilePicker.pickFiles(type: FileType.image);
  if (result.isEmpty) return null;
  final file = result.first;
  // The size may be unknown; the bytes are checked again once read.
  return PickedProfileImage(size: await file.length(), read: file.readAsBytes);
}

Future<Uint8List> _prepareWithRust(Uint8List source, AvatarCrop crop) => ImageUtils.prepareProfileImage(source: source, x: crop.x, y: crop.y, side: crop.side);

/// Decodes [source] the way the cropper shows it; throws when it is not an
/// image Flutter can decode. The caller disposes the result.
Future<ui.Image> decodeProfileImageSource(Uint8List source) async {
  final codec = await ui.instantiateImageCodec(source);
  try {
    return (await codec.getNextFrame()).image;
  } finally {
    codec.dispose();
  }
}
