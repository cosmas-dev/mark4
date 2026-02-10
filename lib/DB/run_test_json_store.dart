import 'dart:convert';
import 'dart:io';

import 'package:mark4/class/run_test_data.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class RunTestJsonStore {
  static const _fileName = 'run_tests.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Map<String, dynamic>>> readAll() async {
    final file = await _file();
    if (!await file.exists()) return [];
    return List<Map<String, dynamic>>.from(
      jsonDecode(await file.readAsString()),
    );
  }

  Future<void> save({
    // required RunTestData data,
    required String name,
    required String age,
    required String gender,
    required String item,
    required String sampleType,
    required String imagePath,
    required String result,
  }) async {
    final list = await readAll();

    list.add({
      'id': const Uuid().v4(),
      'userName': name,
      'age': age,
      'gender': gender,
      'item': item,
      'sampleType': sampleType,
      'imagePath': imagePath,
      // 'runTestData': data.toJson(),
      'result': result,
      'createdAt': DateTime.now().toIso8601String(),
      'synced': false,
    });

    final file = await _file();
    print('📁 저장 시도 경로: ${file.path}');

    await file.writeAsString(jsonEncode(list));
    print('✅ 파일 저장 완료');
  }

  Future<void> deleteByIds(List<String> ids) async {
    final list = await readAll();
    list.removeWhere((e) => ids.contains(e['id']));
    final file = await _file();
    await file.writeAsString(jsonEncode(list));
  }
}
