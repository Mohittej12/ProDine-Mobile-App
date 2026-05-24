// Conditional platform implementation for CSV download
import 'file_download_io.dart' if (dart.library.html) 'file_download_web.dart';

/// Saves `content` into a CSV file named `filename`.
/// Returns the saved file path on IO platforms, or null on web (download initiated).
Future<String?> downloadCsv(String filename, String content) async =>
    downloadCsvImpl(filename, content);
