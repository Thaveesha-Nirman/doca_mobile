import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<Uint8List?> readBytesFromPath(String? path) async {
  if (path == null || path.isEmpty) return null;
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsBytes();
}

Future<String?> openDocumentBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final file = File('${tempDir.path}/$safeName');
    await file.writeAsBytes(bytes, flush: true);

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      return result.message.isNotEmpty
          ? result.message
          : 'No app found on this device to open $safeName.';
    }
    return null;
  } catch (e) {
    return 'Could not open file: $e';
  }
}