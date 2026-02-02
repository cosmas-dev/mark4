import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class MyWindowListener extends WindowListener {
  @override
  void onKeyEvent(KeyEvent event) async {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      await windowManager.setFullScreen(false);
    }
  }
}
