import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'id_generator.dart';

/// Re-encodes a picked image with its EXIF block (including GPS location
/// tags) dropped, so a photo picked for a profile or note never carries the
/// place/device it was taken with into app storage. The sanitized copy is
/// written under the app's own documents directory - the original file
/// picked from the OS media library is left untouched.
Future<String> sanitizeAndStoreImage(String sourcePath) async {
  final bytes = await File(sourcePath).readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw FormatException('Unrecognized image format at $sourcePath');
  }

  decoded.exif = img.ExifData();

  final isPng = sourcePath.toLowerCase().endsWith('.png');
  final outBytes = isPng ? img.encodePng(decoded) : img.encodeJpg(decoded, quality: 90);
  final outExt = isPng ? 'png' : 'jpg';

  final docsDir = await getApplicationDocumentsDirectory();
  final outPath = '${docsDir.path}/images/${generateId()}.$outExt';
  final outFile = File(outPath);
  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(outBytes);
  return outPath;
}
