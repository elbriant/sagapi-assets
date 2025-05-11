import 'dart:io';

import 'package:path/path.dart' as p;

void logMove(String path) {
  print('[move] moved $path');
}

Future<void> moveAssets() async {
  final String fromDir = p.join(Directory.current.path, 'tmp');
  final String toDir = p.join(Directory.current.path, 'assets');

  Directory pathFrom;
  Directory pathTo;

  // building skills
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'building', 'skills']));
  pathTo = Directory(p.joinAll([toDir, 'building_skill']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
    logMove(file.path);
  }

  // logo/factions img
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'camplogo']));
  pathTo = Directory(p.joinAll([toDir, 'logo']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
    logMove(file.path);
  }

  // char avatars
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'charavatars']));
  pathTo = Directory(p.joinAll([toDir, 'charavatars']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
    logMove(file.path);
  }

  // char portraits
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'charportraits']));
  pathTo = Directory(p.joinAll([toDir, 'charportraits']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
    logMove(file.path);
  }

  // dynamic assets
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'dynchars']));
  pathTo = Directory(p.joinAll([toDir, 'dyn', 'dynchars']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    List<String> relFilePath = p
      .join(pathTo.path, file.path.replaceFirst('${pathFrom.path}${p.separator}', ''))
      .split(p.separator)..removeLast();
    Directory(p.joinAll(relFilePath)).createSync(recursive: true);
    file.copySync(
      p.join(pathTo.path, file.path.replaceFirst('${pathFrom.path}${p.separator}', '')),
    );
    logMove(file.path);
  }

  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'dyncharstart']));
  pathTo = Directory(p.joinAll([toDir, 'dyn', 'dyncharstart']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    List<String> relFilePath = p
      .join(pathTo.path, file.path.replaceFirst('${pathFrom.path}${p.separator}', ''))
      .split(p.separator)..removeLast();
    Directory(p.joinAll(relFilePath)).createSync(recursive: true);
    file.copySync(
      p.join(pathTo.path, file.path.replaceFirst('${pathFrom.path}${p.separator}', '')),
    );
    logMove(file.path);
  }

  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'dynportraits']));
  pathTo = Directory(p.joinAll([toDir, 'dyn', 'dynportraits']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    List<String> relFilePath = p
      .join(pathTo.path, file.path.replaceFirst('${pathFrom.path}${p.separator}', ''))
      .split(p.separator)..removeLast();
    Directory(p.joinAll(relFilePath)).createSync(recursive: true);
    file.copySync(
      p.join(pathTo.path, file.path.replaceFirst('${pathFrom.path}${p.separator}', '')),
    );
    logMove(file.path);
  }

  // enemies avatars
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'enemies']));
  pathTo = Directory(p.joinAll([toDir, 'enemies']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
    logMove(file.path);
  }

  // items icons
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'items', 'icons']));
  pathTo = Directory(p.joinAll([toDir, 'items']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
    logMove(file.path);
  }

  // integrated strategies items
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'ui', 'rogueliketopic', 'itempic']));
  pathTo = Directory(p.joinAll([toDir, 'items', 'is']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
    logMove(file.path);
  }

  // skills icon
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'skills']));
  pathTo = Directory(p.joinAll([toDir, 'skills']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
    logMove(file.path);
  }

  // ui assets
  pathFrom = Directory(p.joinAll([fromDir, 'dyn', 'arts', 'ui']));
  pathTo = Directory(p.joinAll([toDir, 'ui']))..createSync(recursive: true);

  for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
    if (file.path.startsWith(p.join(pathFrom.path, 'rogueliketopic'))) {
      continue;
    }

    List<String> relFilePath = p
      .join(pathTo.path, file.path.replaceFirst('${pathFrom.path}${p.separator}', ''))
      .split(p.separator)..removeLast();
    Directory(p.joinAll(relFilePath)).createSync(recursive: true);
    file.copySync(
      p.join(pathTo.path, file.path.replaceFirst('${pathFrom.path}${p.separator}', '')),
    );
    logMove(file.path);
  }

  // clean up
  print('[move] deleting temp folder');
  pathFrom = Directory(fromDir)..deleteSync(recursive: true);
  print('[move] temp folder deleted');
}
