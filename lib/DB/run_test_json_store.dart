// import 'dart:convert';
// import 'dart:io';

// import 'package:path_provider/path_provider.dart';
// import 'package:uuid/uuid.dart';

// class RunTestJsonStore {
//   static const _fileName = 'run_tests.json';

//   Future<File> _file() async {
//     final dir = await getApplicationSupportDirectory();
//     return File('${dir.path}/$_fileName');
//   }

//   Future<List<Map<String, dynamic>>> readAll() async {
//     final file = await _file();
//     if (!await file.exists()) return [];
//     return List<Map<String, dynamic>>.from(
//       jsonDecode(await file.readAsString()),
//     );
//   }

//   Future<void> save({
//     // required RunTestData data,
//     required String userId,
//     required String age,
//     required String gender,
//     required String item,
//     required String sampleType,
//     required String imagePath,
//     required String result,
//   }) async {
//     final list = await readAll();

//     list.add({
//       'id': const Uuid().v4(),
//       'userName': userId,
//       'age': age,
//       'gender': gender,
//       'item': item,
//       'sampleType': sampleType,
//       'imagePath': imagePath,
//       // 'runTestData': data.toJson(),
//       'result': result,
//       'createdAt': DateTime.now().toIso8601String(),
//       'synced': false,
//     });

//     final file = await _file();
//     await file.writeAsString(jsonEncode(list));
//   }

//   Future<void> deleteByIds(List<String> ids) async {
//     final list = await readAll();
//     list.removeWhere((e) => ids.contains(e['id']));
//     final file = await _file();
//     await file.writeAsString(jsonEncode(list));
//   }
// }
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class RunTestJsonStore {
  static const _fileName = 'run_tests.json';

  Future<Directory> _appSupportDir() async {
    return getApplicationSupportDirectory();
  }

  Future<File> _file() async {
    final dir = await _appSupportDir();
    return File('${dir.path}/$_fileName');
  }

  Future<Directory> _imageDir() async {
    final dir = await _appSupportDir();
    final imageDir = Directory('${dir.path}/run_test_images');

    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    return imageDir;
  }

  Future<List<Map<String, dynamic>>> readAll() async {
    final file = await _file();
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(content));
  }

  Future<String> _saveImagePermanently(
    String sourcePath,
    String shutterSpeed,
  ) async {
    final sourceFile = File(sourcePath);

    if (!await sourceFile.exists()) {
      throw Exception('이미지 파일이 존재하지 않습니다: $sourcePath');
    }

    final imageDir = await _imageDir();

    final ext =
        p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';

    final fileName = '${shutterSpeed}_${DateTime.now()}$ext';

    final savedFile = await sourceFile.copy('${imageDir.path}/$fileName');
    return savedFile.path;
  }

  Future<void> save({
    required String shutterSpeed,
    required String userId,
    required String item,
    required String sampleType,
    required String imagePath,
    String? analysisPlotPath,
    Map<String, dynamic>? analysisResult,
    required String result,
  }) async {
    final rows = await readAll();

    rows.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'createdAt': DateTime.now().toIso8601String(),
      'shutterSpeed': shutterSpeed,
      'userId': userId,
      'item': item,
      'sampleType': sampleType,
      'imagePath': imagePath,
      'analysisPlotPath': analysisPlotPath,
      'analysisResult': analysisResult,
      'result': result,
    });

    // await _writeAll(rows);

    final file = await _file();
    await file.writeAsString(jsonEncode(rows), flush: true);
  }

  // Future<void> deleteByIds(List<String> ids) async {
  //   final list = await readAll();

  //   final toDelete = list.where((e) => ids.contains(e['id'])).toList();

  //   for (final item in toDelete) {
  //     final imagePath = item['imagePath'];
  //     if (imagePath is String && imagePath.isNotEmpty) {
  //       final imageFile = File(imagePath);
  //       if (await imageFile.exists()) {
  //         try {
  //           await imageFile.delete();
  //         } catch (_) {
  //           // 이미지 삭제 실패 시에도 JSON 정리는 계속 진행
  //         }
  //       }
  //     }
  //   }

  //   list.removeWhere((e) => ids.contains(e['id']));

  //   final file = await _file();
  //   await file.writeAsString(jsonEncode(list), flush: true);
  // }
  Future<void> deleteByIds(List<String> ids) async {
    final list = await readAll();

    final toDelete = list.where((e) => ids.contains(e['id'])).toList();

    Future<void> deleteFilePath(dynamic pathValue) async {
      if (pathValue is! String || pathValue.isEmpty) return;

      final file = File(pathValue);

      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {
          // 파일 삭제 실패 시에도 JSON 정리는 계속 진행
        }
      }
    }

    for (final item in toDelete) {
      await deleteFilePath(item['imagePath']);
      await deleteFilePath(item['analysisPlotPath']);
    }

    list.removeWhere((e) => ids.contains(e['id']));

    final file = await _file();
    await file.writeAsString(jsonEncode(list), flush: true);
  }
}
