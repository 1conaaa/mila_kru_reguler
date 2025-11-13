import 'package:sqflite/sqflite.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/setoranKru_model.dart';

class SetoranKruService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Insert
  Future<int> insertSetoran(SetoranKru setoran) async {
    final db = await _dbHelper.database;

    // Debug: tampilkan data yang akan dimasukkan
    print('--- INSERT SETORAN ---');
    print('Data setoran: ${setoran.toMap()}');

    try {
      final result = await db.insert(
        't_setoran_kru',
        setoran.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Debug: tampilkan hasil insert
      print('Insert berhasil, row ID: $result');

      // Debug: tampilkan semua isi tabel setelah insert
      final allSetoran = await getAllSetoran();
      print('--- ISI TABLE t_setoran_kru ---');
      for (var s in allSetoran) {
        print(s.toMap());
      }

      return result;
    } catch (e, stackTrace) {
      // Debug: tampilkan error jika gagal insert
      print('Gagal insert setoran: $e');
      print(stackTrace);

      // Debug: tampilkan semua isi tabel setelah gagal insert
      try {
        final allSetoran = await getAllSetoran();
        print('--- ISI TABLE t_setoran_kru (SETELAH GAGAL INSERT) ---');
        for (var s in allSetoran) {
          print(s.toMap());
        }
      } catch (e2) {
        print('Gagal menampilkan isi tabel: $e2');
      }

      rethrow;
    }
  }

  // Get all
  Future<List<SetoranKru>> getAllSetoran() async {
    final db = await _dbHelper.database;
    final maps = await db.query('t_setoran_kru');
    return maps.map((e) => SetoranKru.fromMap(e)).toList();
  }

  // Get by id
  Future<SetoranKru?> getSetoranById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      't_setoran_kru',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SetoranKru.fromMap(maps.first);
    }
    return null;
  }

  // Update
  Future<int> updateSetoran(SetoranKru setoran) async {
    final db = await _dbHelper.database;
    return await db.update(
      't_setoran_kru',
      setoran.toMap(),
      where: 'id = ?',
      whereArgs: [setoran.id],
    );
  }

  // Delete
  Future<int> deleteSetoran(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      't_setoran_kru',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Optional: delete all
  Future<int> clearSetoran() async {
    final db = await _dbHelper.database;
    return await db.delete('t_setoran_kru');
  }
}
