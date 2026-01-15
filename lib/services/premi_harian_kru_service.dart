import 'package:sqflite/sqflite.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/premi_harian_kru_model.dart';

class PremiHarianKruService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Insert data premi harian kru
  Future<int> insertPremiHarianKru(PremiHarianKru premi) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.insert(
        'premi_harian_kru',
        premi.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Premi harian kru berhasil disimpan: $premi');
      return result;
    } catch (e) {
      print('❌ Error insert premi harian kru: $e');
      rethrow;
    }
  }

  // Get all data premi harian kru
  Future<List<PremiHarianKru>> getAllPremiHarianKru() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('premi_harian_kru');

      return List.generate(maps.length, (i) {
        return PremiHarianKru.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error get all premi harian kru: $e');
      rethrow;
    }
  }

  // Get premi harian kru by ID
  Future<PremiHarianKru?> getPremiHarianKruById(int id) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'premi_harian_kru',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return PremiHarianKru.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error get premi harian kru by id: $e');
      rethrow;
    }
  }

  // Get premi harian kru by status
  Future<List<PremiHarianKru>> getPremiHarianKruByStatus(String status) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'premi_harian_kru',
        where: 'status = ?',
        whereArgs: [status],
      );

      return List.generate(maps.length, (i) {
        return PremiHarianKru.fromMap(maps[i]);
      });
    } catch (e) {
      print('❌ Error get premi harian kru by status: $e');
      rethrow;
    }
  }

  // Get premi harian kru dengan join ke kru_bis
  Future<List<Map<String, dynamic>>> getPremiHarianKruWithKruBis() async {
    try {
      final db = await _databaseHelper.database;

      const String sql = '''
      SELECT 
        a.*, 
        b.nama_lengkap AS nama_kru, 
        (a.persen_premi_disetor) AS persen_premi 
      FROM premi_harian_kru AS a
      JOIN kru_bis AS b ON a.id_user = b.id_personil
      ORDER BY a.tanggal_simpan DESC
    ''';

      print("🧾 Menjalankan SQL Query:");
      print(sql);

      final List<Map<String, dynamic>> result = await db.rawQuery(sql);

      print("📊 Jumlah data dikembalikan: ${result.length}");

      if (result.isEmpty) {
        print("⚠️ Query berhasil, tetapi data kosong.");
      } else {
        print("✅ Data premi harian kru ditemukan.");

        // Print 5 data pertama saja (aman untuk data besar)
        for (int i = 0; i < result.length && i < 5; i++) {
          print("➡️ Row ${i + 1}: ${result[i]}");
        }

        // Print struktur kolom (keys)
        print("🔑 Kolom tersedia: ${result.first.keys}");
      }

      return result;
    } catch (e, stacktrace) {
      print('❌ Error getPremiHarianKruWithKruBis: $e');
      print('📍 Stacktrace: $stacktrace');
      rethrow;
    }
  }


  // Get premi harian kru dengan join ke kru_bis by status
  Future<List<Map<String, dynamic>>> getPremiHarianKruWithKruBisByStatus(String status) async {
    try {
      final db = await _databaseHelper.database;
      return await db.rawQuery('''
        SELECT 
          a.*, 
          b.nama_lengkap AS nama_kru, 
          (a.persen_premi_disetor * 100) AS persen_premi 
        FROM premi_harian_kru AS a
        JOIN kru_bis AS b ON a.id_user = b.id_personil
        WHERE a.status = ?
        ORDER BY a.tanggal_simpan DESC
      ''', [status]);
    } catch (e) {
      print('❌ Error get premi harian kru with kru bis by status: $e');
      rethrow;
    }
  }

  // Update data premi harian kru
  Future<int> updatePremiHarianKru(PremiHarianKru premi) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.update(
        'premi_harian_kru',
        premi.toMap(),
        where: 'id = ?',
        whereArgs: [premi.id],
      );
      print('✅ Premi harian kru berhasil diupdate: $premi');
      return result;
    } catch (e) {
      print('❌ Error update premi harian kru: $e');
      rethrow;
    }
  }

  // Update status premi harian kru
  Future<int> updatePremiHarianKruStatus(int id, String status) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.update(
        'premi_harian_kru',
        {'status': status},
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Status premi harian kru berhasil diupdate: id=$id, status=$status');
      return result;
    } catch (e) {
      print('❌ Error update premi harian kru status: $e');
      rethrow;
    }
  }

  // Delete data premi harian kru
  Future<int> deletePremiHarianKru(int id) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.delete(
        'premi_harian_kru',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Premi harian kru berhasil dihapus: id=$id');
      return result;
    } catch (e) {
      print('❌ Error delete premi harian kru: $e');
      rethrow;
    }
  }

  // Clear all data premi harian kru
  Future<void> clearPremiHarianKru() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete('premi_harian_kru');
      print('✅ Semua data premi harian kru berhasil dihapus');
    } catch (e) {
      print('❌ Error clear premi harian kru: $e');
      rethrow;
    }
  }

  // Bulk insert data premi harian kru
  Future<void> insertBulkPremiHarianKru(List<PremiHarianKru> premiList) async {
    try {
      final db = await _databaseHelper.database;
      print("🗄️ DB isOpen: ${db.isOpen}");

      print("📥 Mulai bulk insert premi harian kru");
      print("📊 Total data diterima: ${premiList.length}");

      final batch = db.batch();

      int index = 1;
      for (final premi in premiList) {
        final mapData = premi.toMap();

        print("--------------------------------------------------");
        print("➡️ Data #$index yang akan disimpan:");
        mapData.forEach((key, value) {
          print("   • $key : $value");
        });

        batch.insert(
          'premi_harian_kru',
          mapData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        index++;
      }

      final results = await batch.commit(noResult: false);

      print("--------------------------------------------------");
      print("✅ Batch commit selesai");
      print("📊 Jumlah operasi DB: ${results.length}");

      for (int i = 0; i < results.length; i++) {
        print("   ✔️ Insert result #${i + 1}: ${results[i]}");
      }

      print("🎉 ${premiList.length} data premi harian kru berhasil disimpan");
    } catch (e, stackTrace) {
      print("❌ Error bulk insert premi harian kru");
      print("   Error: $e");
      print("   StackTrace:");
      print(stackTrace);
      rethrow;
    }
  }


  // Check if premi harian kru exists
  Future<bool> isPremiHarianKruExists(int idTransaksi, int idUser, int idGroup, String tanggalSimpan) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'premi_harian_kru',
        where: 'id_transaksi = ? AND id_user = ? AND id_group = ? AND tanggal_simpan = ?',
        whereArgs: [idTransaksi, idUser, idGroup, tanggalSimpan],
      );
      return maps.isNotEmpty;
    } catch (e) {
      print('❌ Error check premi harian kru exists: $e');
      rethrow;
    }
  }

  // Get count of premi harian kru
  Future<int> getPremiHarianKruCount() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> result = await db.rawQuery(
          'SELECT COUNT(*) as count FROM premi_harian_kru'
      );
      return result.first['count'] as int;
    } catch (e) {
      print('❌ Error get premi harian kru count: $e');
      rethrow;
    }
  }

  // Get total nominal premi disetor
  Future<double> getTotalNominalPremiDisetor() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> result = await db.rawQuery(
          'SELECT SUM(nominal_premi_disetor) as total FROM premi_harian_kru WHERE status = "Y"'
      );
      return result.first['total'] as double? ?? 0.0;
    } catch (e) {
      print('❌ Error get total nominal premi disetor: $e');
      rethrow;
    }
  }
}