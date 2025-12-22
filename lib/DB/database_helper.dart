import 'dart:io';

import 'package:path/path.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'app_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      // onUpgrade: _onUpgrade,
    );
  }

  Future<int> insertRunTest({
    required int channel,
    required String item,
    required String userId,
    int? age,
    String? gender,
  }) async {
    final db = await database;

    return await db.insert('run_test_local', {
      'channel': channel,
      'item': item,
      'user_id': userId,
      'age': age,
      'gender': gender,
      'synced': 0,
    });
  }

  /// -------------------- SQLite 테이블 생성 --------------------

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE run_test_local (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      channel INTEGER NOT NULL,           -- 1,2,3
      item TEXT NOT NULL,                 -- Flu / COVID19 / RSV
      user_id TEXT NOT NULL,
      age INTEGER,
      gender TEXT,                        -- Male / Female
      created_at TEXT DEFAULT CURRENT_TIMESTAMP,
      synced INTEGER DEFAULT 0
      )
    ''');
  }

  /// -------------------- SQLite 데이터 저장 --------------------

  Future<int> insertLocalHorse({
    required String name,
    required String species,
    required String memo,
    required String birthDate,
    required List<String> imagePaths,

    required String ownerName,
    required String phone,
    required String facility,
    required String region,

    String? gender,
    String? coatColor,
    String? father,
    String? mother,
    int? weight,
    int? height,
    String? note,
    String? medicalHistory,
    String? enrollNumber,
    String? stableNumber,
  }) async {
    final db = await database;

    return await db.insert('horses_local', {
      'name': name,
      'species': species,
      'memo': memo,
      'image_paths': imagePaths.join(','),

      'owner_name': ownerName,
      'phone': phone,
      'facility': facility,
      'region': region,

      'gender': gender,
      'birth_date': birthDate,
      'coat_color': coatColor,
      'father': father,
      'mother': mother,
      'weight': weight,
      'height': height,
      'note': note,
      'medical_history': medicalHistory,
      'enroll_number': enrollNumber,
      'stable_number': stableNumber,

      'synced': 0,
    });
  }

  Future<int> insertLocalHorseDiagnosis({
    required int horseId,
    required bool infection,
    required String localPath,
  }) async {
    final db = await database;
    return await db.insert('horses_diagnosis_local', {
      'horse_id': horseId,
      'infection': infection,
      'local_path': localPath,
      'synced': 0, // 자동으로 pending 처리
    });
  }

  /// -------------------- 말 데이터 UPDATE --------------------
  Future<void> updateLocalHorse({
    required int id,
    required String name,
    required String species,
    required String memo,
    required List<String> imagePaths,
  }) async {
    final db = await database;

    await db.update(
      'horses_local',
      {
        'name': name,
        'species': species,
        'memo': memo,
        'image_paths': imagePaths.join(','),
        'synced': 0, // 수정되면 다시 Supabase로 보내야 하므로 synced 초기화
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// -------------------- 말 데이터 불러오기 --------------------

  Future<List<Map<String, dynamic>>> getAllLocalHorses() async {
    final db = await database;
    return await db.query('horses_local', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getHorseDiagnosisList() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT 
      d.id AS diagnosis_id,
      d.horse_id,
      d.infection,
      d.local_path,
      d.created_at,
      h.name AS horse_name,
      h.species AS horse_species,
      h.birth_date
    FROM horses_diagnosis_local d
    INNER JOIN horses_local h
      ON d.horse_id = h.id
    ORDER BY d.created_at DESC
  ''');
  }

  /// -------------------- Supabase에 전송되지 않는 데이터 조회 --------------------

  Future<List<Map<String, dynamic>>> getPendingHorses({int limit = 10}) async {
    final db = await database;

    return await db.query(
      'horses_local',
      where: 'synced = 0',
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  /// -------------------- Supabase에 업로드된 데이터 synced = 1 --------------------

  Future<void> markHorseSynced(int id) async {
    final db = await database;

    await db.update(
      'horses_local',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// -------------------- Supabase에 업로드 --------------------

  Future<void> syncPendingHorses() async {
    print("[horse sync] start");

    final rows = await getPendingHorses(limit: 10);
    if (rows.isEmpty) {
      print("[horse sync] no pending horses");
      return;
    }

    final supabase = Supabase.instance.client;

    for (final row in rows) {
      final id = row['id'] as int;

      try {
        print("[horse sync:$id] uploading to Supabase...");

        // supabase 테이블: horses
        await supabase.from('horses').insert({
          'name': row['name'],
          'species': row['species'],
          'memo': row['memo'],
          'created_at': row['created_at'], // 생성시간 그대로 유지
        });

        // 성공 시 synced = 1
        await markHorseSynced(id);
        print("[horse sync:$id] upload success");
      } catch (e) {
        print("[horse sync:$id] failed: $e");
        // 실패해도 삭제하지 않으므로 다음 sync 시 재시도됨
      }
    }
  }

  /// -------------------- AWS-Supabase 연결 --------------------

  //     // 로컬 이미지 테이블
  //     await db.execute('''
  //       CREATE TABLE images_local (
  //         id INTEGER PRIMARY KEY AUTOINCREMENT,
  //         type TEXT,
  //         concentration TEXT,
  //         info TEXT,
  //         local_path TEXT,           -- 샌드박스 원본 파일 경로
  //         remote_url TEXT,           -- 업로드 후 URL (선택)
  //         status TEXT NOT NULL DEFAULT 'pending',  -- pending | syncing | synced | failed
  //         retry_count INTEGER DEFAULT 0,
  //         error TEXT,
  //         created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  //         synced INTEGER DEFAULT 0   -- 🔥 반드시 추가
  //       )
  //     ''');

  //     await db.execute(
  //       "CREATE INDEX idx_images_local_status ON images_local(status)",
  //     );
  //   }

  //   Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  //     if (oldVersion < 2) {
  //       await _createImagesLocal(db); // ✅ 마이그레이션에서도 생성
  //     }
  //   }

  //   Future<void> _createImagesLocal(Database db) async {
  //     await db.execute('''
  //     CREATE TABLE IF NOT EXISTS images_local (
  //       id INTEGER PRIMARY KEY AUTOINCREMENT,
  //       type TEXT,
  //       concentration TEXT,
  //       info TEXT,
  //       local_path TEXT,
  //       remote_url TEXT,
  //       status TEXT NOT NULL DEFAULT 'pending',
  //       retry_count INTEGER DEFAULT 0,
  //       error TEXT,
  //       created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  //       synced INTEGER DEFAULT 0
  //     )
  //   ''');
  //     await db.execute(
  //       'CREATE INDEX IF NOT EXISTS idx_images_local_status ON images_local(status)',
  //     );
  //   }

  //   // -------------------- IMAGES (로컬 대기) --------------------
  //   Future<int> insertLocalImage({
  //     required String localPath,
  //     required String type,
  //     required String concentration,
  //     required String info,
  //     required String createdAt,
  //   }) async {
  //     final db = await database;
  //     return await db.insert('images_local', {
  //       'local_path': localPath,
  //       'type': type,
  //       'concentration': concentration,
  //       'info': info,
  //       'created_at': createdAt,
  //       'status': 'pending',
  //     }, conflictAlgorithm: ConflictAlgorithm.replace);
  //   }

  //   Future<List<Map<String, dynamic>>> getAllLocalImages() async {
  //     final db = await database;
  //     return await db.query('images_local', orderBy: 'created_at DESC');
  //   }

  //   Future<List<Map<String, dynamic>>> getPendingImages({int limit = 10}) async {
  //     final db = await database;
  //     return await db.query(
  //       'images_local',
  //       where: "status IN ('pending','failed')",
  //       orderBy: 'created_at ASC',
  //       limit: limit,
  //     );
  //   }

  //   Future<void> markImageSyncing(int id) async {
  //     final db = await database;
  //     await db.update(
  //       'images_local',
  //       {'status': 'syncing'},
  //       where: 'id=?',
  //       whereArgs: [id],
  //     );
  //   }

  //   Future<void> markImageSynced({
  //     required int id,
  //     required String remoteUrl,
  //   }) async {
  //     final db = await database;
  //     await db.update(
  //       'images_local',
  //       {
  //         'status': 'synced',
  //         'remote_url': remoteUrl,
  //         'local_path': null, // 로컬 원본 삭제했음 표시
  //         'retry_count': 0,
  //         'error': null,
  //       },
  //       where: 'id=?',
  //       whereArgs: [id],
  //     );
  //   }

  //   Future<void> markImageFailed({required int id, required String error}) async {
  //     final db = await database;
  //     final row = await db.query(
  //       'images_local',
  //       where: 'id=?',
  //       whereArgs: [id],
  //       limit: 1,
  //     );
  //     final retry =
  //         (row.isNotEmpty ? (row.first['retry_count'] as int? ?? 0) : 0) + 1;

  //     await db.update(
  //       'images_local',
  //       {'status': 'failed', 'retry_count': retry, 'error': error},
  //       where: 'id=?',
  //       whereArgs: [id],
  //     );
  //   }

  //   // Future<void> syncPendingImages() async {
  //   //   final db = await database;
  //   //   print('[sync] start');

  //   //   final rows = await db.query(
  //   //     'images_local',
  //   //     where: 'synced = 0',
  //   //     orderBy: 'created_at ASC',
  //   //     limit: 5,
  //   //   );

  //   //   for (final row in rows) {
  //   //     final id = row['id'] as int;
  //   //     final localPath = row['local_path'] as String?;
  //   //     if (localPath == null) continue;

  //   //     final file = File(localPath);
  //   //     if (!file.existsSync()) {
  //   //       await markImageFailed(id: id, error: '파일 없음');
  //   //       continue;
  //   //     }

  //   //     try {
  //   //       await markImageSyncing(id);

  //   //       // filename = 로컬 파일명 그대로 사용
  //   //       final s3 = await uploadToS3ViaBackend(
  //   //         file,
  //   //         keyOverride: p.basename(localPath),
  //   //       );

  //   //       final supabase = Supabase.instance.client;

  //   //       await supabase.from('images').insert({
  //   //         'type': row['type'],
  //   //         'concentration': row['concentration'],
  //   //         'info': row['info'],
  //   //         'image_url': s3.url,
  //   //         'created_at': row['created_at'], // ← 생성 시간도 전달
  //   //       });

  //   //       // 성공 → 삭제 ❌ → synced = 1 로 변경
  //   //       await db.update(
  //   //         "images_local",
  //   //         {"synced": 1},
  //   //         where: "id = ?",
  //   //         whereArgs: [row['id']],
  //   //       );
  //   //     } catch (e) {
  //   //       // 실패해도 삭제하지 않으므로 다음에 재시도됨
  //   //     }
  //   //   }
  //   // }

  //   /// -------------------- USERS --------------------
  //   Future<void> insertUser(Map<String, dynamic> user) async {
  //     final db = await database;

  //     // password 관련 제거
  //     await db.insert(
  //       'users',
  //       user,
  //       conflictAlgorithm: ConflictAlgorithm.replace,
  //     );
  //   }

  //   Future<List<Map<String, dynamic>>> getAllUsers() async {
  //     final db = await database;
  //     return await db.query('users');
  //   }

  //   Future<Map<String, dynamic>?> getUserByEmail(String email) async {
  //     final db = await database;
  //     final result = await db.query(
  //       'users',
  //       where: 'email = ?',
  //       whereArgs: [email],
  //     );
  //     return result.isNotEmpty ? result.first : null;
  //   }

  //   Future<void> deleteUserByEmail(String email) async {
  //     final db = await database;
  //     await db.delete('users', where: 'email = ?', whereArgs: [email]);
  //   }

  //   /// -------------------- GROUPS --------------------
  //   Future<void> insertGroup(Map<String, dynamic> group) async {
  //     final db = await database;
  //     await db.insert(
  //       'groups',
  //       group,
  //       conflictAlgorithm: ConflictAlgorithm.replace,
  //     );
  //   }

  //   Future<List<Map<String, dynamic>>> getAllGroups() async {
  //     final db = await database;
  //     return await db.query('groups');
  //   }

  //   Future<void> deleteGroupByUsername(String username) async {
  //     final db = await database;
  //     await db.delete('groups', where: 'username = ?', whereArgs: [username]);
  //   }

  //   /// -------------------- GROUPS (추가 메서드 포함) --------------------
  //   Future<List<Map<String, dynamic>>> getGroupsByEmail(String email) async {
  //     final db = await database;
  //     return await db.query(
  //       'groups',
  //       where: 'email = ?',
  //       whereArgs: [email],
  //       orderBy: 'created_at DESC',
  //     );
  //   }

  //   Future<bool> checkGroupExists(String username) async {
  //     final db = await database;
  //     final result = await db.query(
  //       'groups',
  //       where: 'username = ?',
  //       whereArgs: [username],
  //     );
  //     return result.isNotEmpty;
  //   }

  //   /// -------------------- KITS --------------------
  //   Future<void> insertKit(Map<String, dynamic> kit) async {
  //     final db = await database;
  //     await db.insert('kits', kit, conflictAlgorithm: ConflictAlgorithm.replace);
  //   }

  //   Future<List<Map<String, dynamic>>> getAllKits() async {
  //     final db = await database;
  //     return await db.query('kits');
  //   }

  //   Future<void> deleteKitBySerial(int kitSerial) async {
  //     final db = await database;
  //     await db.delete('kits', where: 'kit_serial = ?', whereArgs: [kitSerial]);
  //   }

  //   /// -------------------- DEVICES --------------------
  //   Future<void> insertDevice(Map<String, dynamic> device) async {
  //     final db = await database;
  //     await db.insert(
  //       'devices',
  //       device,
  //       conflictAlgorithm: ConflictAlgorithm.replace,
  //     );
  //   }

  //   Future<List<Map<String, dynamic>>> getAllDevices() async {
  //     final db = await database;
  //     return await db.query('devices');
  //   }

  //   Future<void> deleteDeviceBySerial(String serial) async {
  //     final db = await database;
  //     await db.delete('devices', where: 'device_serial = ?', whereArgs: [serial]);
  //   }

  //   /// -------------------- DEVICES + KITS (for /me API 대응) --------------------
  //   Future<Map<String, dynamic>> getDevicesWithKitsByEmail(String email) async {
  //     final db = await database;

  //     // 1. 사용자 확인
  //     final userResult = await db.query(
  //       'users',
  //       where: 'email = ?',
  //       whereArgs: [email],
  //     );
  //     if (userResult.isEmpty) {
  //       throw Exception("User not found");
  //     }

  //     // 2. devices 조회
  //     final devices = await db.query(
  //       'devices',
  //       where: 'email = ?',
  //       whereArgs: [email],
  //       orderBy: 'created_at DESC',
  //     );

  //     List<Map<String, dynamic>> devicesData = [];

  //     for (final device in devices) {
  //       final deviceSerial = device['device_serial'];
  //       print("🔍 현재 device_serial: $deviceSerial");

  //       final kits = await db.query(
  //         'kits',
  //         where: 'device_serial = ?',
  //         whereArgs: [device['device_serial']],
  //         orderBy: 'created_at DESC',
  //       );

  //       print("🔧 매칭된 kits: $kits");

  //       devicesData.add({
  //         'device_serial': device['device_serial'],
  //         'device_name': device['device_name'],
  //         'device_type': device['device_type'],
  //         'email': device['email'],
  //         'created_at': device['created_at'],
  //         'kits': kits,
  //       });
  //     }

  //     return {'email': email, 'devices': devicesData};
  //   }

  //   Future<Map<String, dynamic>?> getLocalImageById(int id) async {
  //     final db = await database;

  //     final result = await db.query(
  //       'images_local',
  //       where: 'id = ?',
  //       whereArgs: [id],
  //       limit: 1,
  //     );

  //     return result.isNotEmpty ? result.first : null;
  //   }
}
