import 'package:sagapi_assets/modes.dart';

import 'download.dart';
import 'download_studio.dart';
import 'extract_assets.dart';
import 'move_assets.dart';

void main(List<String> arguments) async {
  // HERE WE SHOULD DO THE CHECK FILE
  // BUT BC IDK HOW WE CAN CHECK FIRST, LETS
  // SKIP THIS STEP FOR NOW
  final OperationMode mode = OperationMode.sprites;

  final Stopwatch timer = Stopwatch()..start();
  print('Step: download/install/check lastest assets');
  await download(mode: mode);
  print("[download] Elapsed time: ${timer.elapsed.toString()}");

  timer.reset();

  print('Step: download/install/check ArknightsStudioCLI');
  // optional flag: forceUpdate, self-explanatory
  await downloadAKstudio();
  print("[AKStudio setup] finish, Elapsed time: ${timer.elapsed.toString()}");

  timer.reset();

  print('Step: Extract Assets');
  await extractAssets(operationMode: mode);
  print("[AKStudio] finished extracting assets, Elapsed time: ${timer.elapsed.toString()}");

  timer.reset();

  print('Step: Move Assets');
  await moveAssets();
  print("[move] finished moving assets, Elapsed time: ${timer.elapsed.toString()}");

  timer.stop();
}
