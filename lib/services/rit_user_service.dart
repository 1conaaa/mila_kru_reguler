import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class RitUserService {
  static final RitUserService instance = RitUserService._internal();
  RitUserService._internal();

  Future<void> insertRitUser({
    required int idUser,
    required int idBus,
    required String noPol,
    required int rit,
  }) async {
    final Database db = await DatabaseHelper.instance.database;

    await db.insert(
      't_rit_user',
      {
        'tanggal': DateTime.now().toIso8601String(),
        'no_pol': noPol,
        'id_bus': idBus,
        'id_user': idUser,
        'rit': rit,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('[RIT] Data rit user disimpan');

    // 🔎 DEBUG: Ambil seluruh isi tabel setelah insert
    final List<Map<String, dynamic>> result =
    await db.query('t_rit_user');

    print('[RIT] Isi seluruh tabel t_rit_user:');
    for (var row in result) {
      print(row);
    }
  }

  Future<int> getActiveRit() async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      't_rit_user',
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['rit'] as int;
    }

    // fallback default
    return 1;
  }

  Future<int> getLastRitByUser({
    required int idUser,
    required int idBus,
    required String noPol,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      't_rit_user',
      where: 'id_user = ? AND id_bus = ? AND no_pol = ?',
      whereArgs: [idUser, idBus, noPol],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['rit'] as int;
    }

    // belum ada data → default rit 1
    return 1;
  }

  Future<void> clearAll() async {
    final Database db = await DatabaseHelper.instance.database;

    await db.delete('t_rit_user');

    print('[RIT] Semua data rit user berhasil dihapus');
  }
}