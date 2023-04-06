import 'dart:async';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class Debouncer{
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action){
    _timer?.cancel();

    _timer = Timer(Duration(milliseconds: milliseconds),action);
  }
}
