import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/premi_posisi_kru_model.dart';
import 'package:sqflite/sqflite.dart';

class PremiPosisiKruService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Insert data premi posisi kru
  Future<int> insertPremiPosisiKru(PremiPosisiKru premi) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.insert(
        'm_premi_posisi_kru',
        premi.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Premi posisi kru berhasil disimpan: $premi');
      return result;
    } catch (e) {
      print('❌ Error insert premi posisi kru: $e');
      rethrow;
    }
  }

  // Get all data premi posisi kru
  Future<List<PremiPosisiKru>> getAllPremiPosisiKru() async {
    try {
      final db = await _databaseHelper.database;

      // DEBUG: Cek apakah tabel exists
      final tableCheck = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='m_premi_posisi_kru'"
      );

      if (tableCheck.isEmpty) {
        print('❌ DEBUG: Tabel m_premi_posisi_kru tidak ditemukan dalam database');
        return [];
      }

      print('✅ DEBUG: Tabel m_premi_posisi_kru ditemukan');

      final List<Map<String, dynamic>> maps = await db.query('m_premi_posisi_kru');

      // DEBUG: Tampilkan jumlah data dan detail isi tabel
      print('=== DEBUG PREMI_POSISI_KRU ===');
      print('📊 Jumlah data dalam m_premi_posisi_kru: ${maps.length}');

      if (maps.isEmpty) {
        print('⚠️ DEBUG: Tabel m_premi_posisi_kru KOSONG');
        print('ℹ️ DEBUG: Cek apakah data premi posisi sudah di-sync dari server');
      } else {
        print('📋 DEBUG: Detail data m_premi_posisi_kru:');
        for (var i = 0; i < maps.length; i++) {
          final data = maps[i];
          print('   Data $i:');
          print('     - id: ${data['id']}');
          print('     - nama_premi: "${data['nama_premi']}"');
          print('     - persen_premi: "${data['persen_premi']}"');
          print('     - tanggal_simpan: "${data['tanggal_simpan']}"');

          // Validasi data
          if (data['nama_premi'] == null || data['nama_premi'].toString().isEmpty) {
            print('     ❌ ERROR: nama_premi NULL atau KOSONG');
          }
          if (data['persen_premi'] == null || data['persen_premi'].toString().isEmpty) {
            print('     ❌ ERROR: persen_premi NULL atau KOSONG');
          }
        }
      }
      print('=== END DEBUG PREMI_POSISI_KRU ===');

      // Convert maps to objects
      final result = List.generate(maps.length, (i) {
        return PremiPosisiKru.fromMap(maps[i]);
      });

      // DEBUG: Tampilkan hasil konversi
      print('✅ DEBUG: Berhasil mengkonversi ${result.length} data ke objek PremiPosisiKru');

      return result;

    } catch (e) {
      print('❌ ERROR get all premi posisi kru: $e');
      print('📋 Stack trace:');
      print(e.toString());
      rethrow;
    }
  }

  // Get premi posisi kru by ID
  Future<PremiPosisiKru?> getPremiPosisiKruById(int id) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'm_premi_posisi_kru',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        return PremiPosisiKru.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error get premi posisi kru by id: $e');
      rethrow;
    }
  }

  // Get premi posisi kru by nama premi
  Future<PremiPosisiKru?> getPremiPosisiKruByNama(String namaPremi) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'm_premi_posisi_kru',
        where: 'LOWER(nama_premi) = LOWER(?)',
        whereArgs: [namaPremi],
      );

      if (maps.isNotEmpty) {
        return PremiPosisiKru.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      print('❌ Error get premi posisi kru by nama: $e');
      rethrow;
    }
  }

  // Update data premi posisi kru
  Future<int> updatePremiPosisiKru(PremiPosisiKru premi) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.update(
        'm_premi_posisi_kru',
        premi.toMap(),
        where: 'id = ?',
        whereArgs: [premi.id],
      );
      print('✅ Premi posisi kru berhasil diupdate: $premi');
      return result;
    } catch (e) {
      print('❌ Error update premi posisi kru: $e');
      rethrow;
    }
  }

  // Delete data premi posisi kru
  Future<int> deletePremiPosisiKru(int id) async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.delete(
        'm_premi_posisi_kru',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('✅ Premi posisi kru berhasil dihapus: id=$id');
      return result;
    } catch (e) {
      print('❌ Error delete premi posisi kru: $e');
      rethrow;
    }
  }

  // Clear all data premi posisi kru
  Future<void> clearPremiPosisiKru() async {
    try {
      final db = await _databaseHelper.database;
      await db.delete('m_premi_posisi_kru');
      print('✅ Semua data premi posisi kru berhasil dihapus');
    } catch (e) {
      print('❌ Error clear premi posisi kru: $e');
      rethrow;
    }
  }

  // Bulk insert data premi posisi kru
  Future<void> insertBulkPremiPosisiKru(List<PremiPosisiKru> premiList) async {
    try {
      final db = await _databaseHelper.database;
      final batch = db.batch();

      for (final premi in premiList) {
        batch.insert(
          'm_premi_posisi_kru',
          premi.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit();
      print('✅ ${premiList.length} data premi posisi kru berhasil disimpan');
    } catch (e) {
      print('❌ Error bulk insert premi posisi kru: $e');
      rethrow;
    }
  }

  // Get premi dengan join ke kru_bis
  Future<List<Map<String, dynamic>>> getPremiWithKruBis() async {
    try {
      final db = await _databaseHelper.database;
      return await db.rawQuery('''
        SELECT 
          a.id_group, a.id_personil, a.nama_lengkap, a.group_name, 
          b.persen_premi, b.nama_premi
        FROM 
          kru_bis AS a
          JOIN m_premi_posisi_kru AS b ON LOWER(a.group_name) = LOWER(b.nama_premi)
        ORDER BY a.id DESC
      ''');
    } catch (e) {
      print('❌ Error get premi with kru bis: $e');
      rethrow;
    }
  }

  // Check if premi exists
  Future<bool> isPremiExists(String namaPremi) async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'm_premi_posisi_kru',
        where: 'LOWER(nama_premi) = LOWER(?)',
        whereArgs: [namaPremi],
      );
      return maps.isNotEmpty;
    } catch (e) {
      print('❌ Error check premi exists: $e');
      rethrow;
    }
  }

  // Get count of premi posisi kru
  Future<int> getPremiCount() async {
    try {
      final db = await _databaseHelper.database;
      final List<Map<String, dynamic>> result =
      await db.rawQuery('SELECT COUNT(*) as count FROM m_premi_posisi_kru');
      return result.first['count'] as int;
    } catch (e) {
      print('❌ Error get premi count: $e');
      rethrow;
    }
  }
}