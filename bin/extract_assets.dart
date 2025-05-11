import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;

import 'package:sagapi_assets/modes.dart';
import 'package:sagapi_assets/task.dart';

class ExtractTask extends Task {
  final String path;
  final String types;
  final String filtersByName;
  final String outputDir;
  final String groupMode;

  ExtractTask({
    required this.path,
    required this.types,
    required this.outputDir,
    this.filtersByName = '',
    this.groupMode = '',
  });

  @override
  FutureOr<void> job() async {
    if (filtersByName.isNotEmpty) {
      await Process.run("dotnet", [
        (p.join(Directory.current.path, "ArknightsStudioCLI", "ArknightsStudioCLI.dll")),
        path,
        "-t",
        (types),
        "-o",
        (outputDir),
        "-g",
        groupMode.isNotEmpty ? (groupMode) : 'container',
        "--filter-by-name",
        (filtersByName),
      ]);
    } else {
      await Process.run("dotnet", [
        (p.join(Directory.current.path, "ArknightsStudioCLI", "ArknightsStudioCLI.dll")),
        path,
        "-t",
        (types),
        "-o",
        (outputDir),
        "-g",
        groupMode.isNotEmpty ? (groupMode) : 'container',
      ]);
    }
  }
}

Future<void> extractAssets({
  String? ouputPath,
  String? bundlesPath,
  OperationMode? operationMode,
}) async {
  final outputDir = ouputPath ?? p.join(Directory.current.path, 'tmp');
  final bundlesDir = bundlesPath ?? p.join(Directory.current.path, 'bundles');
  final opMode = operationMode ?? OperationMode.sprites;

  await Directory(outputDir).create();

  final files =
      (await Directory(bundlesDir).list(recursive: true).toList()).whereType<File>().where((
        element,
      ) {
        return element.path.endsWith('.ab') && !element.path.endsWith('hot_update_list.json');
      }).toList();

  List<ExtractTask> tasks = [];

  for (var file in files) {
    final filepath = file.path;

    bool isInRules = false;
    switch (opMode) {
      case OperationMode.sprites:
        for (List<String> rule in spriteBundlePaths) {
          if (filepath.startsWith(p.joinAll([bundlesDir, ...rule]))) {
            isInRules = true;
            break;
          }
        }

      case OperationMode():
    }
    if (!isInRules) continue;

    List<String> types = [];
    List<String> filterByName = [];
    String? groupMode;

    if (opMode != OperationMode.audio) {
      if (filepath.contains('charportraits')) {
        types.addAll(["akPortrait", "textAsset"]);
      } else {
        if (filepath.contains('chararts') || filepath.contains('skinpack')) {
          types.add('sprite');
          groupMode = 'type';
        } else {
          types.addAll(["tex2d", "textAsset"]);
          if (filepath.contains('dynchars')) {
            filterByName.add('dyn_illust_');
          }
        }
      }
    }

    if (opMode != OperationMode.sprites) types.addAll(["AudioClip"]);

    tasks.add(
      ExtractTask(
        path: filepath,
        types: types.join(','),
        outputDir: outputDir,
        filtersByName: filterByName.join(','),
        groupMode: groupMode ?? '',
      ),
    );
  }

  final int numOfIso = max(Platform.numberOfProcessors - 1, 1);

  List<List<ExtractTask>> chunks = tasks.slices((tasks.length ~/ numOfIso) + 1).toList();

  List<Future> isolatesTasks = List.generate(
    numOfIso,
    (i) => Isolate.run(() => processInDifferentIsolate(i, chunks[i])),
  );
  await Future.wait(isolatesTasks);
}

Future<void> processInDifferentIsolate(int isoId, List<ExtractTask> taskList) async {
  var queue = QueueList.from(taskList);
  int count = 0;
  final int lenght = taskList.length;

  while (queue.isNotEmpty) {
    var task = queue.removeFirst();
    await task.job();
    count += 1;

    print("[AKStudio #$isoId] ${task.path} $count/$lenght");
  }
}
