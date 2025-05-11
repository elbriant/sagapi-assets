import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:sagapi_assets/downloader.dart';
import 'package:sagapi_assets/globals.dart';
import 'package:sagapi_assets/task.dart';

import 'extract_assets.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

void main(List<String> arguments) async {
  final bool forceUpdate = arguments.contains('--force');

  final savedir = p.join(Directory.current.path, bundlesDir);
  final config = jsonDecode(
    jsonDecode((await http.get(Uri.parse(cnNetworkConfigUrl))).body)['content'],
  );

  final networkUrls = config['configs'][config['funcVer']]['network'] as Map;
  final versionUrl = (networkUrls['hv'] as String).replaceAll(RegExp(r'\{0\}'), 'Android');

  final resVersion = jsonDecode((await http.get(Uri.parse(versionUrl))).body)['resVersion'];
  final assetsUrl = "${networkUrls['hu']}/Android/assets/$resVersion";

  await Directory(savedir).create();

  Map oldHashes = {};

  // downloadAKstudio();

  if (File(p.join(savedir, 'hot_update_list.json')).existsSync()) {
    final fileString = await File(p.join(savedir, 'hot_update_list.json')).readAsString();
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
  await File(p.join(savedir, 'hot_update_list.json')).writeAsBytes(newDataList.bodyBytes);
  final newDataDecoded = jsonDecode(newDataList.body);

  List<Task> totalTasks = [];

  for (Map obj in (newDataDecoded['abInfos'] as List)) {
    // all except audio
    if ((obj['name'] as String).contains('audio')) {
      continue;
    }
    // filter desired bundles
    if (!spriteBundlePaths.any((p) => (obj['name'] as String).contains(p.join('/')))) {
      continue;
    }

    if (obj['hash'] != oldHashes[obj['name']] || forceUpdate) {
      totalTasks.add(Task(name: obj['name'], assetsUrl: assetsUrl));
    }
  }

  int totalTasksLength = totalTasks.length;
  int processedTasks = 0;
  while (totalTasks.isNotEmpty) {
    print("\nStarting to process. $processedTasks/$totalTasksLength");
    final int numOfIso = max(Platform.numberOfProcessors - 1, 1);

    while (totalTasks.isNotEmpty) {
      List<List<Task>> chunks = totalTasks.slices((totalTasks.length ~/ numOfIso) + 1).toList();
      List<Future<List<Task>>> isolatesTasks = List.generate(
        numOfIso,
        (i) => Isolate.run(() => processInDifferentIsolate(i, chunks[i])),
      );
      List<List<Task>> remainingTasks = await Future.wait<List<Task>>(isolatesTasks);

      totalTasks = [];
      for (List l in remainingTasks) {
        totalTasks += [...l];
      }
    }

    print("[download] ${newDataDecoded['versionId']}");
  }
}

Future<List<Task>> processInDifferentIsolate(int isoId, List<Task> taskList) async {
  var queue = QueueList.from(taskList);
  int count = 0;
  final int length = taskList.length;
  final thisIsoClient = http.Client();
  final thisIsoBundleFolder =
      Directory(p.join(Directory.current.path, bundlesDir, isoId.toString())).path;

  while (queue.isNotEmpty) {
    Task t = queue.removeFirst()..isolateId = isoId;

    await Downloader.downloadSingleBundle(
      path: t.name,
      saveDirectory: thisIsoBundleFolder,
      assetsUrl: t.assetsUrl,
      isolateId: t.isolateId,
      isolateClient: thisIsoClient,
    );

    await extractAssetsAndDeleteBundle(bundlesPath: thisIsoBundleFolder, isoId: isoId);

    count += 1;
    print("[I$isoId] $count/$length");

    // this step could introduce some inaccuracy cuz there will be probably some other isolates
    // working on the background
    // so im gonna increase the 'spare' space to cover that (hopefully)
    int folderSize = 0;
    Directory(
      p.join(Directory.current.path, tmpDir),
    ).listSync(recursive: true).whereType<File>().forEach((e) => folderSize += e.lengthSync());

    if (folderSize > 1800 * 1024 * 1024) {
      break;
    }
  }

  thisIsoClient.close();

  return queue.toList();
}
