import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:sagapi_assets/globals.dart';

class ExtractTask {
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

  Future<void> job() async {
    final args = <String>[
      p.join(Directory.current.path, "ArknightsStudioCLI", "ArknightsStudioCLI.dll"),
      path,
      "-t",
      types,
      "-o",
      outputDir,
      "-g",
      groupMode.isNotEmpty ? groupMode : 'container',
      if (filtersByName.isNotEmpty) ...["--filter-by-name", filtersByName],
    ];

    final result = await Process.run("dotnet", args);

    if (result.exitCode != 0) {
      throw ProcessException(
        "dotnet",
        args,
        "${result.stdout}\n${result.stderr}".trim(),
        result.exitCode,
      );
    }
  }
}

Future<void> extractAssetsAndDeleteBundle({
  String? ouputPath,
  required String bundlesPath,
  int? isoId,
}) async {
  final outputDir = ouputPath ?? p.join(Directory.current.path, tmpDir);

  await Directory(outputDir).create();

  final files =
      (await Directory(bundlesPath).list(recursive: true).toList()).whereType<File>().where((
        element,
      ) {
        return element.path.endsWith('.ab') && !element.path.endsWith('hot_update_list.json');
      }).toList();

  List<ExtractTask> tasks = [];

  for (var file in files) {
    final filepath = file.path;

    List<String> types = [];
    List<String> filterByName = [];
    String? groupMode;

    if (filepath.contains('charportraits')) {
      // legacy portrait hub, no longer contains portrait textures
      types.addAll(["akPortrait", "textAsset"]);
    } else if (filepath.contains('char_portrait')) {
      // portraits live in spritepack/char_portrait_*.ab since ~2025-10-21
      types.add('sprite');
    } else if (filepath.contains('chararts') || filepath.contains('skinpack')) {
      types.add('sprite');
      groupMode = 'type';
    } else {
      types.addAll(["tex2d", "textAsset"]);
      if (filepath.contains('dynchars')) {
        filterByName.add('dyn_illust_');
      }
    }

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

  var queue = QueueList.from(tasks);
  while (queue.isNotEmpty) {
    var task = queue.removeFirst();
    try {
      await task.job();
      await File(task.path).delete();

      print("[AKStudio I${isoId ?? '!'}] ${task.path}");
    } on ProcessException catch (e) {
      // Keep the bundle and make the failure loud instead of silently dropping it
      stderr.writeln("[AKStudio I${isoId ?? '!'}] FAILED ${task.path}");
      stderr.writeln("[AKStudio I${isoId ?? '!'}] exit=${e.errorCode} ${e.message}");
    }
  }
}
