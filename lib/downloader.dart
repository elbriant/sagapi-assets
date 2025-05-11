import 'dart:io';
import 'package:archive/archive.dart' show ZipDecoder;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as filepath;

class Downloader {
  static String encodePath(String input) {
    return input
        .replaceAll(RegExp(r'/'), '_')
        .replaceAll(RegExp(r'#'), '__')
        .replaceAll(RegExp(r'\..*'), '.dat');
  }

  static Future<void> downloadFile({
    required String path,
    required String assetsUrl,
    String? saveDirectory,
    int? isolateId,
    http.Client? isolateClient,
  }) async {
    final savedir =
        saveDirectory ?? Directory(filepath.join(Directory.current.path, 'bundles')).path;

    final formattedPath = encodePath(path);
    final response =
        (isolateClient != null)
            ? await isolateClient.get(Uri.parse("$assetsUrl/$formattedPath"))
            : await http.get(Uri.parse("$assetsUrl/$formattedPath"));

    if (path.endsWith('.ab')) {
      // here i could do some stuff to avoid errors
      // but im lazy to do it so

      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      for (final entry in archive) {
        if (entry.isFile) {
          final fileBytes = entry.readBytes()!;
          File(filepath.join(savedir, entry.name))
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);
        }
      }
    } else {
      File(filepath.join(savedir, path, formattedPath))
        ..createSync(recursive: true)
        ..writeAsBytesSync(response.bodyBytes);
    }

    print('[download $isolateId] $path');
  }
}
