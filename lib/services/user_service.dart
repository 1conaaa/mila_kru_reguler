import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/user_data.dart';

class UserService {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Method untuk mendapatkan semua user data sebagai List<UserData>
  Future<List<UserData>> getAllUsersAsUserData() async {
    final users = await getUsers();
    return users.map((userMap) => UserData.fromMap(userMap)).toList();
  }

  Future<List<UserData>> getActiveUserDataWithInit() async {
    final users = await getActiveUsersAsUserData();
    return users;
  }

  // Method untuk mendapatkan hanya user aktif (yang terbaru) sebagai List<UserData>
  Future<List<UserData>> getActiveUsersAsUserData() async {
    final db = await _databaseHelper.database;
    final results = await db.rawQuery('''
      SELECT * FROM users 
      ORDER BY tanggal_simpan DESC 
      LIMIT 1
    ''');

    return results.map((userMap) => UserData.fromMap(userMap)).toList();
  }

  // Method untuk mendapatkan users by group sebagai List<UserData>
  Future<List<UserData>> getUsersByGroupAsUserData(int groupId) async {
    final users = await getUsersByGroup(groupId);
    return users.map((userMap) => UserData.fromMap(userMap)).toList();
  }

  // ========== EXISTING METHODS (tetap dipertahankan) ==========

  // Insert user data
  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await _databaseHelper.database;
    await db.insert('users', user);
  }

  // Get all users
  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await _databaseHelper.database;
    return await db.query('users');
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Get active user data (biasanya yang terbaru)
  Future<UserData?> getActiveUser() async {
    final db = await _databaseHelper.database;
    final results = await db.rawQuery('''
      SELECT * FROM users 
      ORDER BY tanggal_simpan DESC 
      LIMIT 1
    ''');

    if (results.isNotEmpty) {
      return UserData.fromMap(results.first);
    }
    return null;
  }

  // Get user by credentials (untuk login)
  Future<UserData?> getUserByCredentials(String username, String password) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'nama_user = ? AND password = ?',
      whereArgs: [username, password],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return UserData.fromMap(results.first);
    }
    return null;
  }

  // Update user
  Future<void> updateUser(int id, Map<String, dynamic> userData) async {
    final db = await _databaseHelper.database;
    await db.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update user name
  Future<void> updateUserName(int id, String name) async {
    final db = await _databaseHelper.database;
    await db.update(
        'users',
        {'nama_lengkap': name},
        where: 'id = ?',
        whereArgs: [id]
    );
  }

  // Delete user
  Future<void> deleteUser(int id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Query users dengan filter tertentu
  Future<List<Map<String, dynamic>>> queryUsers() async {
    final db = await _databaseHelper.database;
    return await db.query('users');
  }

  // Clear users table
  Future<void> clearUsersTable() async {
    final db = await _databaseHelper.database;
    await db.delete('users');
  }

  // Check if user exists
  Future<bool> userExists(int idUser, int idGroup) async {
    final db = await _databaseHelper.database;
    final results = await db.query(
      'users',
      where: 'id_user = ? AND id_group = ?',
      whereArgs: [idUser, idGroup],
    );
    return results.isNotEmpty;
  }

  // Get users by group
  Future<List<Map<String, dynamic>>> getUsersByGroup(int groupId) async {
    final db = await _databaseHelper.database;
    return await db.query(
      'users',
      where: 'id_group = ?',
      whereArgs: [groupId],
    );
  }

  // Get bus information for current user
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

  // Get premium settings for current user
  Future<Map<String, dynamic>> getPremiumSettings() async {
    final user = await getActiveUser();
    if (user != null) {
      return {
        'premi_extra': user.premiExtra,
        'persen_premi_kru': user.persenPremikru,
        'coa_utang_premi': user.coaUtangPremi,
      };
    }
    return {
      'premi_extra': '0',
      'persen_premi_kru': '0',
      'coa_utang_premi': '',
    };
  }
}