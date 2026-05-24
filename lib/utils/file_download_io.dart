import 'dart:io';

Future<String?> downloadCsvImpl(String filename, String content) async {
  final file = File('${Directory.systemTemp.path}/$filename');
  await file.writeAsString(content);
  return file.path;
}
