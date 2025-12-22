import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mark4/DB/database_helper.dart';

class SyncService {
  final DatabaseHelper dbh = DatabaseHelper();

  static bool _isRunning = false; // 🔥 Sync 중인지 여부 플래그

  void start() {
    _trySyncOnce(); // 처음 1회 실행

    Connectivity().onConnectivityChanged.listen((result) async {
      print('[SyncService] connectivity changed: $result');

      if (result != ConnectivityResult.none) {
        await _trySyncOnce();
      }
    });
  }

  Future<void> _trySyncOnce() async {
    // 🔥 이미 실행 중이면 무시
    if (_isRunning) {
      print('[SyncService] Already running → Skip');
      return;
    }

    _isRunning = true; // 실행 시작
    print('[SyncService] run syncPendingImages()');

    try {
      await dbh.syncPendingHorses();
    } catch (e, st) {
      print('[SyncService] sync error: $e\n$st');
    } finally {
      _isRunning = false; // 🔥 실행 종료
      print('[SyncService] Finished syncPendingHorses()');
    }
  }
}
