import 'dart:async';

import 'package:sagapi_assets/task.dart';
import 'package:http/http.dart' as http;
import 'package:sagapi_assets/downloader.dart';

class DownloadTask extends Task {
  final String path;
  final String assetsUrl;
  final String saveDirectory;
  http.Client? isolateClient;

  DownloadTask({
    required this.path,
    required this.assetsUrl,
    required this.saveDirectory,
    this.isolateClient,
    super.isolateId,
  });

  @override
  FutureOr<void> job() async {
    await Downloader.downloadFile(
      path: path,
      assetsUrl: assetsUrl,
      saveDirectory: saveDirectory,
      isolateId: isolateId,
      isolateClient: isolateClient,
    );
  }
}
