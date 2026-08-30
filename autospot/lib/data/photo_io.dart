import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

Future<void> writePhotoFile(String dir, String id, Uint8List bytes) async {
  final file = File(p.join(dir, 'spots', '$id.jpg'));
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

Future<Uint8List?> readPhotoFile(String dir, String id) async {
  final file = File(p.join(dir, 'spots', '$id.jpg'));
  if (!await file.exists()) return null;
  return file.readAsBytes();
}
