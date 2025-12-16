import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/user.dart';

class UserService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // =======================
  // INSERT
  // =======================

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await _databaseHelper.database;
    await db.insert('users', user);
  }

  // =======================
  // RAW QUERIES (MAP)
  // =======================

  Future<List<Map<String, dynamic>>> getUsersRaw() async {
    final db = await _databaseHelper.database;
    return await db.query('users');
  }

  Future<List<Map<String, dynamic>>> getUsersByGroupRaw(int groupId) async {
    final db = await _databaseHelper.database;
    return await db.query(
      'users',
      where: 'id_group = ?',
      whereArgs: [groupId],
    );
  }

  // =======================
  // MODEL QUERIES (User)
  // =======================

  Future<List<User>> getAllUsers() async {
    final results = await getUsersRaw();
    return results.map<User>((e) => User.fromMap(e)).toList();
  }

  /// ✅ ALIAS UNTUK KODE LAMA (Home.dart)
  /// JANGAN DIHAPUS sebelum semua file dirapikan
  Future<List<User>> getAllUsersAsUserData() async {
    return await getAllUsers();
  }

  Future<List<User>> getUsersByGroup(int groupId) async {
    final results = await getUsersByGroupRaw(groupId);
    return results.map<User>((e) => User.fromMap(e)).toList();
  }

  Future<User?> getActiveUser() async {
    final db = await _databaseHelper.database;
    final results = await db.rawQuery('''
      SELECT * FROM users
      ORDER BY tanggal_simpan DESC
      LIMIT 1
    ''');

    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }
    return null;
  }

  Future<User?> getUserByCredentials(String username, String password) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'nama_user = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }
    return null;
  }

  // =======================
  // UPDATE
  // =======================

  Future<void> updateUser(int id, Map<String, dynamic> userData) async {
    final db = await _databaseHelper.database;
    await db.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateUserName(int id, String name) async {
    final db = await _databaseHelper.database;
    await db.update(
      'users',
      {'nama_lengkap': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =======================
  // DELETE
  // =======================

  Future<void> deleteUser(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearUsersTable() async {
    final db = await _databaseHelper.database;
    await db.delete('users');
  }

  // =======================
  // UTILITIES
  // =======================

  Future<bool> userExists(int idUser, int idGroup) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'id_user = ? AND id_group = ?',
      whereArgs: [idUser, idGroup],
    );
    return results.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getCurrentBusInfo() async {
    final user = await getActiveUser();
    if (user != null) {
      return {
        'no_pol': user.noPol,
        'id_bus': user.idBus,
        'kelas_bus': user.kelasBus,
        'nama_trayek': user.namaTrayek,
      };
    }
    return null;
  }

  Future<Map<String, dynamic>> getPremiumSettings() async {
    final user = await getActiveUser();
    if (user != null) {
      return {
        'premi_extra': user.premiExtra ?? '0',
        'persen_premi_kru': user.persenPremikru ?? '0',
        'coa_utang_premi': user.coaUtangPremi ?? '',
      };
    }
    return {
      'premi_extra': '0',
      'persen_premi_kru': '0',
      'coa_utang_premi': '',
    };
  }
}
