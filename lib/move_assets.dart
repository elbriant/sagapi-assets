import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:sagapi_assets/globals.dart';

class MoveData {
  final List<String> from;
  final List<String> to;
  final bool moveAsFolder;

  const MoveData({required this.from, required this.to, this.moveAsFolder = false});
}

void logMove(String path) {
  print('[move] moved $path');
}

void _moveAndDelete(MoveData data) {
  Directory pathFrom = Directory(p.joinAll([Directory.current.path, tmpDir, ...data.from]));
  if (pathFrom.existsSync()) {
    Directory pathTo = Directory(p.joinAll([Directory.current.path, assetsDir, ...data.to]))
      ..createSync(recursive: true);

    if (data.moveAsFolder) {
      for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
        File(
          p.join(pathTo.path, p.relative(file.path, from: pathFrom.path)),
        ).createSync(recursive: true);
        file.copySync(p.join(pathTo.path, p.relative(file.path, from: pathFrom.path)));
        file.deleteSync();
        logMove(file.path);
      }
    } else {
      for (File file in pathFrom.listSync(recursive: true).whereType<File>()) {
        file.copySync(p.join(pathTo.path, file.path.split(p.separator).last));
        file.deleteSync();
        logMove(file.path);
      }
    }
  }
}

const List<MoveData> movedatas = [
  MoveData(from: ['dyn', 'arts', 'building', 'skills'], to: ['building_skill']),
  MoveData(from: ['dyn', 'arts', 'camplogo'], to: ['logo']),
  MoveData(from: ['dyn', 'arts', 'charavatars'], to: ['charavatars']),
  MoveData(from: ['dyn', 'arts', 'charportraits'], to: ['charportraits']),
  MoveData(from: ['dyn', 'arts', 'dynchars'], to: ['dyn', 'dynchars'], moveAsFolder: true),
  MoveData(from: ['dyn', 'arts', 'dyncharstart'], to: ['dyn', 'dyncharstart'], moveAsFolder: true),
  MoveData(from: ['dyn', 'arts', 'dynportraits'], to: ['dyn', 'dynportraits'], moveAsFolder: true),
  MoveData(from: ['dyn', 'arts', 'enemies'], to: ['enemies']),
  MoveData(from: ['dyn', 'arts', 'items', 'icons'], to: ['items']),
  MoveData(from: ['dyn', 'arts', 'ui', 'rogueliketopic', 'itempic'], to: ['items', 'is']),
  MoveData(from: ['dyn', 'arts', 'skills'], to: ['skills']),
  MoveData(from: ['dyn', 'arts', 'ui'], to: ['ui'], moveAsFolder: true),
];

void moveAssets() {
  for (var data in movedatas) {
    _moveAndDelete(data);
  }
}
