import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:sagapi_assets/download_task.dart';

import 'package:sagapi_assets/globals.dart';
import 'package:sagapi_assets/modes.dart';

Future<void> download({required OperationMode mode, bool forceUpdate = false}) async {
  final savedir = path.join(Directory.current.path, 'bundles');

  final config = jsonDecode(
    jsonDecode((await http.get(Uri.parse(cnNetworkConfigUrl))).body)['content'],
  );

  final networkUrls = config['configs'][config['funcVer']]['network'] as Map;
  final versionUrl = (networkUrls['hv'] as String).replaceAll(RegExp(r'\{0\}'), 'Android');

  final resVersion = jsonDecode((await http.get(Uri.parse(versionUrl))).body)['resVersion'];
  final assetsUrl = "${networkUrls['hu']}/Android/assets/$resVersion";

  await Directory(savedir).create();

  Map oldHashes = {};

  if (File(path.join(savedir, 'hot_update_list.json')).existsSync()) {
    final fileString = await File(path.join(savedir, 'hot_update_list.json')).readAsString();
    final fileJson = jsonDecode(fileString);

    if (fileJson['versionId'] == resVersion && !forceUpdate) {
      print('Up to date!');
      return;
    }

    for (Map obj in (fileJson['abInfos'] as List)) {
      oldHashes[obj['name']] = obj['hash'];
    }
  }

  final newDataList = await http.get(Uri.parse("$assetsUrl/hot_update_list.json"));

  // saving for future checks
  await File(path.join(savedir, 'hot_update_list.json')).writeAsBytes(newDataList.bodyBytes);
  final newDataDecoded = jsonDecode(newDataList.body);

  List<DownloadTask> tasks = [];

  for (Map obj in (newDataDecoded['abInfos'] as List)) {
    if (mode == OperationMode.sprites && (obj['name'] as String).contains('audio')) {
      continue;
    } else if (mode == OperationMode.audio && !(obj['name'] as String).contains('audio')) {
      continue;
    }

    if (obj['hash'] != oldHashes[obj['name']] || forceUpdate) {
      tasks.add(DownloadTask(path: obj['name'], assetsUrl: assetsUrl, saveDirectory: savedir));
    }
  }

  final int numOfIso = max(Platform.numberOfProcessors - 1, 1);

  List<List<DownloadTask>> chunks = tasks.slices((tasks.length ~/ numOfIso) + 1).toList();

  List<Future> isolatesTasks = List.generate(
    numOfIso,
    (i) => Isolate.run(() => processInDifferentIsolate(i, chunks[i])),
  );

  await Future.wait(isolatesTasks);

  print("[download] ${newDataDecoded['versionId']}");
}

Future<void> processInDifferentIsolate(int isoId, List<DownloadTask> taskList) async {
  var queue = QueueList.from(taskList);
  int count = 0;
  final int lenght = taskList.length;

  final thisIsoClient = http.Client();

  while (queue.isNotEmpty) {
    var task =
        queue.removeFirst()
          ..isolateId = isoId
          ..isolateClient = thisIsoClient;
    await task.job();
    count += 1;
    print("[Iso #$isoId] $count/$lenght");
  }

  thisIsoClient.close();
}
