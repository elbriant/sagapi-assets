import 'dart:async';

class Task {
  int? isolateId;

  Task({this.isolateId});

  FutureOr<void> job() async {}
}
