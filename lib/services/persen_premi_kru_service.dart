import 'dart:convert';

import 'package:mila_kru_reguler/api/ApiPersenPremiKru..dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/PersenPremiKru.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class PersenPremiKruService {
  final String tableName = 'm_persen_premi_kru';

  PersenPremiKruService._();
  static final PersenPremiKruService instance = PersenPremiKruService._();

  // Cache agar tidak bolak-balik query
  static final Map<String, Future<List<ListPersenPremiKru>>> _cache = {};

  // ============================
  // INSERT
  // ============================
  Future<int> insert(ListPersenPremiKru data) async {
    final db = await DatabaseHelper.instance.database;

    return await db.insert(
      tableName,
      data.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ============================
  // UPDATE
  // ============================
  Future<int> update(ListPersenPremiKru data) async {
    if (data.id == null) throw Exception("ID tidak boleh null");

    final db = await DatabaseHelper.instance.database;

    return await db.update(
      tableName,
      data.toMap(),
      where: 'id = ?',
      whereArgs: [data.id],
    );
  }

  // ============================
  // DELETE BY ID
  // ============================
  Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;

    return await db.delete(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================
  // DELETE BY KODE TRAYEK
  // ============================
  Future<int> deleteByKodeTrayek(String kodeTrayek) async {
    print("DEBUG: Menghapus data dengan kode_trayek: $kodeTrayek");
    final db = await DatabaseHelper.instance.database;

    final deleted = await db.delete(
      tableName,
      where: 'kode_trayek = ?',
      whereArgs: [kodeTrayek],
    );

    print("DEBUG: Jumlah data terhapus: $deleted");
    return deleted;
  }

  // ============================
  // GET BY KODE TRAYEK (MAIN FUNCTION)
  // ============================
  Future<List<ListPersenPremiKru>> getByKodeTrayek(
      String kodeTrayek, {
        Function(bool)? onDataFetchedFromApi,
        int? idJenisPremi,
      }) async {
    final cacheKey = "${kodeTrayek}_${idJenisPremi ?? "all"}";

    if (_cache.containsKey(cacheKey)) {
      print("DEBUG: 🔄 Return dari CACHE key: $cacheKey");
      return _cache[cacheKey]!;
    }

    final future = _getByKodeTrayekInternal(
        kodeTrayek, onDataFetchedFromApi, idJenisPremi);

    _cache[cacheKey] = future;

    // Cache timeout 5 menit
    future.whenComplete(() {
      Future.delayed(Duration(minutes: 5), () {
        _cache.remove(cacheKey);
      });
    });

    return future;
  }

  // ============================
  // INTERNAL HANDLER
  // ============================
  Future<List<ListPersenPremiKru>> _getByKodeTrayekInternal(
      String kodeTrayek,
      Function(bool)? onDataFetchedFromApi,
      int? idJenisPremi) async {
    try {
      final db = await DatabaseHelper.instance.database;

      String where = "kode_trayek = ? AND aktif = ?";
      List whereArgs = [kodeTrayek, "Y"];

      if (idJenisPremi != null) {
        where += " AND id_jenis_premi = ?";
        whereArgs.add(idJenisPremi);
      }

      print("DEBUG: Query SQLite: $where");
      final localData =
      await db.query(tableName, where: where, whereArgs: whereArgs);

      if (localData.isNotEmpty) {
        print("DEBUG: ✔ Data ditemukan di LOCAL DB (${localData.length})");
        return localData.map((m) => ListPersenPremiKru.fromMap(m)).toList();
      }

      print("DEBUG: ❌ Tidak ada data di SQLite → ambil dari API");

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? "";

      if (token.isEmpty) {
        print("DEBUG: ❌ Token kosong, tidak bisa akses API");
        return [];
      }

      bool apiOk = false;

      try {
        apiOk = await ApiHelperPersenPremiKru.requestListPersenPremiAPI(
            token, kodeTrayek);
      } catch (_) {
        apiOk = false;
      }

      if (onDataFetchedFromApi != null) {
        onDataFetchedFromApi(apiOk);
      }

      if (apiOk) {
        print("DEBUG: ✔ API OK. Re-query SQLite...");

        await Future.delayed(Duration(milliseconds: 300));

        final after =
        await db.query(tableName, where: where, whereArgs: whereArgs);

        if (after.isNotEmpty) {
          print("DEBUG: ✔ Data berhasil masuk setelah API (${after.length})");
          return after.map((m) => ListPersenPremiKru.fromMap(m)).toList();
        }
      }

      return [];
    } catch (e) {
      print("DEBUG ERROR getByKodeTrayek: $e");
      return [];
    }
  }

  // ============================
  // CLEAR TABLE
  // ============================
  Future<int> clearTable() async {
    final db = await DatabaseHelper.instance.database;
    return db.delete(tableName);
  }
}
