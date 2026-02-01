import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/persentase_susukan_model.dart';
import 'package:mila_kru_reguler/api/ApiHelperPersentaseSusukan.dart';

class PersentaseSusukanService {
  /// =============================
  /// S - SYNC API → LOCAL
  /// =============================
  Future<bool> syncFromApi(String token) async {
    final jsonResponse = await ApiHelperPersentaseSusukan.fetchFromApi(token);

    if (jsonResponse == null) return false;

    if (jsonResponse['status'] != true ||
        jsonResponse['data'] is! List) {
      print('❌ Format response tidak valid');
      return false;
    }

    List<PersentaseSusukan> list = (jsonResponse['data'] as List)
        .map((e) => PersentaseSusukan.fromJson(e))
        .toList();

    DatabaseHelper db = DatabaseHelper.instance;
    await db.initDatabase();

    try {
      // Sinkron penuh
      await db.deleteAllPersentaseSusukan();

      for (var item in list) {
        await db.insertPersentaseSusukan(item.toMap());
      }

      print('✅ Sync persentase susukan berhasil');
      return true;
    } catch (e) {
      print('❌ DB Error: $e');
      return false;
    } finally {
      await db.closeDatabase();
    }
  }

  /// =============================
  /// C - CREATE LOCAL
  /// =============================
  static Future<void> createLocal(PersentaseSusukan data) async {
    DatabaseHelper db = DatabaseHelper.instance;
    await db.initDatabase();
    try {
      await db.insertPersentaseSusukan(data.toMap());
    } finally {
      await db.closeDatabase();
    }
  }

  /// =============================
  /// R - READ LOCAL
  /// =============================
  static Future<List<PersentaseSusukan>> getAllLocal() async {
    DatabaseHelper db = DatabaseHelper.instance;
    await db.initDatabase();
    try {
      final result = await db.getAllPersentaseSusukan();
      return result
          .map((e) => PersentaseSusukan.fromJson(e))
          .toList();
    } finally {
      await db.closeDatabase();
    }
  }

  /// =============================
  /// U - UPDATE LOCAL
  /// =============================
  static Future<void> updateLocal(PersentaseSusukan data) async {
    DatabaseHelper db = DatabaseHelper.instance;
    await db.initDatabase();
    try {
      await db.updatePersentaseSusukan(data.toMap(), data.id);
    } finally {
      await db.closeDatabase();
    }
  }

  /// =============================
  /// D - DELETE LOCAL
  /// =============================
  static Future<void> deleteLocal(int id) async {
    DatabaseHelper db = DatabaseHelper.instance;
    await db.initDatabase();
    try {
      await db.deletePersentaseSusukan(id);
    } finally {
      await db.closeDatabase();
    }
  }

  /// =============================
  /// HELPER - Cari persentase
  /// =============================
  static Future<double?> getPersentaseByNominal(double nominal) async {
    DatabaseHelper db = DatabaseHelper.instance;
    await db.initDatabase();
    try {
      final result = await db.getPersentaseByNominal(nominal);
      return result?['persentase']?.toDouble();
    } finally {
      await db.closeDatabase();
    }
  }
}
