import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

Future<void> downloadAKstudio({bool forceUpdate = false}) async {
  final savedir = path.join(Directory.current.path, 'ArknightsStudioCLI');

  if (!Directory(savedir).existsSync() || forceUpdate) {
    if (forceUpdate && Directory(savedir).existsSync()) {
      Directory(savedir).deleteSync(recursive: true);
    }

    final response = await http.get(
      Uri.parse(r'https://api.github.com/repos/aelurum/AssetStudio/releases'),
    );
    final data = (jsonDecode(response.body) as List).firstWhere(
      (e) => (e['tag_name'] as String).startsWith('ak'),
    );

    final url =
        (data['assets'] as List).firstWhere(
          (element) =>
              (element['name'] as String).contains(RegExp(r'net6', caseSensitive: false)) &&
              (element['name'] as String).contains(RegExp(r'portable', caseSensitive: false)),
        )['browser_download_url'];

    final responseDownload = await http.get(Uri.parse(url));

    Directory(savedir).createSync();

    final archive = ZipDecoder().decodeBytes(responseDownload.bodyBytes);
    for (final entry in archive) {
      if (entry.isFile) {
        final fileBytes = entry.readBytes()!;
        File(path.join(savedir, entry.name))
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
      }
    }
  }

  if (Platform.isLinux) {
    await Process.run("chmod", ["+x", savedir]);
    await Process.run("apt-get", ["install", "-qq", "-y", "dotnet-sdk-6.0"]);
  }
}
