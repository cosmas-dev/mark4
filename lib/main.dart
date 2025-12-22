import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mark4/DB/database_helper.dart';
import 'package:mark4/home.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:window_manager/window_manager.dart';

Future<void> deleteExistingDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = join(dbPath, 'app_database.db');

  // 파일 존재하면 삭제
  await deleteDatabase(path);
  print("📌 기존 DB 삭제 완료: $path");
}

Future<void> debugPrintImagesLocal() async {
  final db = await DatabaseHelper().database;
  final rows = await db.query('run_test_local', orderBy: 'created_at DESC');

  print("====== 📦 horse_local 테이블 출력 (${rows.length}건) ======");
  for (final row in rows) {
    print(row);
  }
  print("=========================================================");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null); // 로케일 초기화

  // await deleteExistingDatabase();
  await debugPrintImagesLocal();

  if (!Platform.isAndroid && !Platform.isIOS) {
    // 데스크탑 플랫폼에서만 윈도우 매니저 초기화
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(fullScreen: true);

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setFullScreen(true);
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Home(),
    );
  }
}
