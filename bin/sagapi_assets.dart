import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:sagapi_assets/download_studio.dart';
import 'package:sagapi_assets/downloader.dart';
import 'package:sagapi_assets/globals.dart';
import 'package:sagapi_assets/move_assets.dart';
import 'package:sagapi_assets/task.dart';

import 'package:sagapi_assets/extract_assets.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

ProcessResult runGit(List<String> args, {bool check = false}) {
  final result = Process.runSync('git', args);
  if (check && result.exitCode != 0) {
    throw ProcessException(
      'git',
      args,
      '${result.stdout}${result.stderr}'.trim(),
      result.exitCode,
    );
  }
  return result;
}

void main(List<String> arguments) async {
  final savedir = p.join(Directory.current.path, bundlesDir);
  final bool forceUpdate = arguments.contains('--force');

  // checkout assets branch
  runGit(["fetch", "--depth=1", "origin", "$branchName:$branchName"]);
  runGit(["checkout", branchName], check: true);

  final config = jsonDecode(
    jsonDecode((await http.get(Uri.parse(cnNetworkConfigUrl))).body)['content'],
  );
  final networkUrls = config['configs'][config['funcVer']]['network'] as Map;
  final versionUrl = (networkUrls['hv'] as String).replaceAll(RegExp(r'\{0\}'), 'Android');
  final resVersion = jsonDecode((await http.get(Uri.parse(versionUrl))).body)['resVersion'];
  final assetsUrl = "${networkUrls['hu']}/Android/assets/$resVersion";

  final newDataList = await http.get(Uri.parse("$assetsUrl/hot_update_list.json"));
  final newHotUpdateList = jsonDecode(newDataList.body);

  List<Task> totalTasks = [];

  if (File(p.join(savedir, 'hot_update_list.json')).existsSync() && !forceUpdate) {
    final oldHotUpdateListRaw = await File(p.join(savedir, 'hot_update_list.json')).readAsString();
    final oldHotUpdateList = jsonDecode(oldHotUpdateListRaw);

    final oldHotUpdateListByNames = {};
    for (Map obj in (oldHotUpdateList['abInfos'] as List)) {
      oldHotUpdateListByNames[obj['name']] = obj;
    }

    for (Map obj in (newHotUpdateList['abInfos'] as List)) {
      // all except audio and filter by desired bundles
      if ((obj['name'] as String).contains('audio') ||
          !spriteBundlePaths.any((p) => (obj['name'] as String).contains(p.join('/')))) {
        continue;
      }

      if (!oldHotUpdateListByNames.containsKey(obj['name']) ||
          oldHotUpdateListByNames[obj['name']]['hash'] != obj['hash']) {
        totalTasks.add(Task(name: obj['name'], assetsUrl: assetsUrl));
      }
    }
  } else {
    for (Map obj in (newHotUpdateList['abInfos'] as List)) {
      // all except audio and filter by desired bundles
      if ((obj['name'] as String).contains('audio') ||
          !spriteBundlePaths.any((p) => (obj['name'] as String).contains(p.join('/')))) {
        continue;
      }

      totalTasks.add(Task(name: obj['name'], assetsUrl: assetsUrl));
    }
  }

  if (totalTasks.isEmpty) {
    print('is up to date!');
    return;
  }

  await Directory(savedir).create();
  await downloadAKstudio();

  int totalTasksLength = totalTasks.length;
  int processedTasks = 0;
  final int numOfIso = max(Platform.numberOfProcessors - 1, 1);
  final tmpFolder = Directory(p.join(Directory.current.path, tmpDir));
  final bundleFolder = Directory(p.join(Directory.current.path, bundlesDir));

  while (totalTasks.isNotEmpty) {
    print("\nStarting to process. $processedTasks/$totalTasksLength");

    // just to be sure
    await tmpFolder.create();
    await bundleFolder.create();

    List<List<Task>> chunks = totalTasks.slices((totalTasks.length ~/ numOfIso) + 1).toList();
    List<Future<List<Task>>> isolatesTasks = List.generate(
      min(numOfIso, chunks.length),
      (i) => Isolate.run(() => processInDifferentIsolate(i, chunks[i])),
    );
    // this will supposedly exit when over or max space reached
    List<List<Task>> remainingTasks = await Future.wait<List<Task>>(isolatesTasks);

    totalTasks = [];
    for (List<Task> l in remainingTasks) {
      totalTasks += l;
    }
    processedTasks = totalTasksLength - totalTasks.length;

    print('moving files');
    moveAssets();

    // cleaning up just to be sure
    print('cleaning');
    await tmpFolder.delete(recursive: true);
    await bundleFolder.delete(recursive: true);

    // push current assets to repo
    print('pushing to git');
    await stdout.flush();
    Process.runSync('git', ['add', assetsDir]);
    // not sure what this does
    var result = Process.runSync('git', ['diff', '--cached', '--name-only', 'assets']);
    print(result.stdout);
    // if ((result.stdout as String).trim().isEmpty) {
    //   continue;
    // }
    Process.runSync('git', [
      'commit',
      '-m',
      'update $resVersion $processedTasks/$totalTasksLength',
    ]);
    runGit(['log', '--oneline']);
    runGit(['push', 'origin', branchName], check: true);

    // clean git commit
    print('cleaning up git');
    var sha = runGit(['rev-parse', 'HEAD'], check: true).stdout.trim();
    runGit(['checkout', '--detach', sha], check: true);
    runGit(['fetch', '--depth=1', 'origin', '$branchName:$branchName']);
    runGit(['checkout', branchName], check: true);
    runGit(['reflog', 'expire', '--expire=now', '--all']);
    runGit(['gc', '--prune=now']);
  }

  await bundleFolder.create();
  await File(p.join(bundleFolder.path, 'hot_update_list.json')).writeAsBytes(newDataList.bodyBytes);

  // push final commit
  runGit(['add', bundlesDir]);
  runGit(['commit', '-m', 'update $resVersion final hot_update_list']);
  runGit(['push', 'origin', branchName], check: true);
  runGit(['checkout', 'master'], check: true);
  print("updated ${newHotUpdateList['versionId']}");
}

Future<List<Task>> processInDifferentIsolate(int isoId, List<Task> taskList) async {
  var queue = QueueList.from(taskList);
  int count = 0;
  final int length = taskList.length;
  final thisIsoClient = http.Client();
  final thisIsoBundleFolder = Directory(
    p.join(Directory.current.path, bundlesDir, isoId.toString()),
  );

  await thisIsoBundleFolder.create(recursive: true);

  while (queue.isNotEmpty) {
    Task t = queue.removeFirst()..isolateId = isoId;

    await Downloader.downloadSingleBundle(
      path: t.name,
      saveDirectory: thisIsoBundleFolder.path,
      assetsUrl: t.assetsUrl,
      isolateId: t.isolateId,
      isolateClient: thisIsoClient,
    );

    await extractAssetsAndDeleteBundle(bundlesPath: thisIsoBundleFolder.path, isoId: isoId);

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
