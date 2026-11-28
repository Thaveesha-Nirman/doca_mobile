import 'dart:typed_data';

Future<Uint8List?> readBytesFromPath(String? path) async => null;

Future<String?> openDocumentBytes({
  required Uint8List bytes,
  required String fileName,
}) async {
  return 'Open "$fileName" on the Android app to view PDF/document attachments.';
}