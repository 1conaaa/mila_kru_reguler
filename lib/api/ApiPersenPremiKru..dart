// lib/api/ApiPersenPremiKru.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mila_kru_reguler/models/PersenPremiKru.dart';
import 'package:mila_kru_reguler/services/persen_premi_kru_service.dart';
import 'package:sqflite/sqflite.dart';

class ApiHelperPersenPremiKru {
  /// Memanggil API dan menyimpan data ke SharedPreferences + DB.
  /// Mengembalikan `true` jika API dipanggil sukses dan data berhasil diproses.
  static Future<bool> requestListPersenPremiAPI(
      String token, String kodeTrayek) async {
    print("============================================");
    print("📡 REQUEST API PERSEN PREMI KRU");
    print(
        "URL  : https://apimila.milaberkah.com/api/persenpremikru/?kode_trayek=$kodeTrayek");
    print("TOKEN: $token");
    print("============================================");

    try {
      final response = await http.get(
        Uri.parse(
            'https://apimila.milaberkah.com/api/persenpremikru/?kode_trayek=$kodeTrayek'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      );

      print("🔹 STATUS CODE: ${response.statusCode}");
      print("🔹 RAW RESPONSE BODY:");
      print(response.body);

      if (response.statusCode != 200) {
        print("❌ Gagal request API, status code != 200");
        return false;
      }

      final dynamic decoded = jsonDecode(response.body);

      // =====================================================
      // Tentukan sumber list dari response (List atau Map)
      // =====================================================
      List<dynamic> rawList = [];

      int successFlag = 0; // default fail
      if (decoded is List) {
        // CASE: API mengembalikan array langsung: [ {...}, {...} ]
        rawList = decoded;
        successFlag = 1;
        print("ℹ️ Response is a raw List with length: ${rawList.length}");
      } else if (decoded is Map<String, dynamic>) {
        // CASE: API mengembalikan object: { "success": 1, "persenpremikru": [...] }
        if (decoded.containsKey('success')) {
          successFlag = decoded['success'] is int
              ? decoded['success']
              : int.tryParse(decoded['success'].toString()) ?? 0;
        }
        if (decoded.containsKey('persenpremikru')) {
          final maybeList = decoded['persenpremikru'];
          if (maybeList is List) {
            rawList = maybeList;
            print(
                "ℹ️ Found 'persenpremikru' key with length: ${rawList.length}");
          } else {
            // Fallback: mungkin API menggunakan key lain
            print(
                "⚠️ 'persenpremikru' exists but is not a List. type=${maybeList.runtimeType}");
          }
        } else if (decoded.containsKey('data') && decoded['data'] is List) {
          rawList = decoded['data'];
          print("ℹ️ Found 'data' key with length: ${rawList.length}");
        } else {
          // Jika Map tapi tidak ada list proper, coba cari nested list pertama
          final foundList = _findFirstListInMap(decoded);
          if (foundList != null) {
            rawList = foundList;
            print("ℹ️ Found nested list in Map with length: ${rawList.length}");
          } else {
            print("❌ Map response tapi tidak ditemukan list data di body.");
          }
        }
      } else {
        print("❌ Unknown JSON structure: ${decoded.runtimeType}");
      }

      // Jika tidak ada data list, hentikan
      if (rawList.isEmpty) {
        print("❌ Tidak ada data persen premi yang bisa diproses.");
        return false;
      }

      // =====================================================
      // Map tiap element ke model (dengan safe parser)
      // =====================================================
      List<ListPersenPremiKru> dataList = rawList
          .map<ListPersenPremiKru>((e) {
        try {
          if (e is Map<String, dynamic>) {
            return ListPersenPremiKru.fromApiResponse(e);
          } else {
            // Jika elemen bukan Map, coba decode ulang
            final maybeMap = e is String ? jsonDecode(e) : null;
            if (maybeMap is Map<String, dynamic>) {
              return ListPersenPremiKru.fromApiResponse(maybeMap);
            }
          }
        } catch (err) {
          print("⚠️ Gagal parsing item ke model: $err -> item=$e");
        }
        return ListPersenPremiKru(); // fallback kosong
      })
          .where((el) => el.id != null) // saring yang valid (opsional)
          .toList();

      print("🔹 Jumlah data setelah parsing model: ${dataList.length}");

      if (dataList.isEmpty) {
        print("❌ Setelah parsing, tidak ada data valid untuk disimpan.");
        return false;
      }

      // =========================================================
      // 🔥 SIMPAN KE SHAREDPREFERENCES
      // =========================================================
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String encodeData =
        jsonEncode(dataList.map((e) => e.toMap()).toList(growable: false));
        await prefs.setString('listPersenPremiKru', encodeData);
        print("✔ Data disimpan ke SharedPreferences (listPersenPremiKru)");
      } catch (e) {
        print("⚠️ Gagal simpan ke SharedPreferences: $e");
        // tidak fatal — lanjutkan ke DB
      }

      // =========================================================
// 🔥 SIMPAN KE DATABASE (versi diperbaiki total)
// =========================================================
      final service = PersenPremiKruService.instance;
      final db = await DatabaseHelper.instance.database;

      try {
        print("=====================================================");
        print("📌 MULAI PROSES SIMPAN DATA KE DATABASE");
        print("📌 KODE TRAYEK: $kodeTrayek");
        print("📌 JUMLAH DATA API: ${dataList.length}");
        print("=====================================================");

        // 1️⃣ CEK DATA EXISTING SEBELUM DIHAPUS
        List<Map<String, dynamic>> beforeDelete = await db.query(
          "m_persen_premi_kru",
          where: "kode_trayek = ?",
          whereArgs: [kodeTrayek],
        );

        print("🔍 Data EXISTING sebelum hapus: ${beforeDelete.length}");
        for (var row in beforeDelete) {
          print("   ➡ EXISTING ROW: $row");
        }

        // 2️⃣ HAPUS DATA LAMA (hanya untuk kode_trayek terkait)
        print("🗑 Menghapus data lama untuk kode_trayek: $kodeTrayek");
        int deleteCount = await db.delete(
          "m_persen_premi_kru",
          where: "kode_trayek = ?",
          whereArgs: [kodeTrayek],
        );
        print("✔ Jumlah baris terhapus: $deleteCount");

        // 3️⃣ INSERT DATA BARU
        print("📥 MEMASUKKAN DATA BARU...");

        for (var item in dataList) {
          try {
            Map<String, dynamic> mapData = item.toMap();
            mapData.remove("id"); // pastikan AUTOINCREMENT bekerja

            print("➡ INSERT: $mapData");

            await db.insert(
              "m_persen_premi_kru",
              mapData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            print("❌ ERROR INSERT: $e");
            print("   ❗ DATA FAILED: ${item.toMap()}");
          }
        }

        // 4️⃣ CEK DATA SETELAH INSERT
        print("=====================================================");
        print("📌 CEK DATA SETELAH INSERT");
        print("=====================================================");

        List<Map<String, dynamic>> afterInsert = await db.query(
          "m_persen_premi_kru",
          where: "kode_trayek = ?",
          whereArgs: [kodeTrayek],
        );

        print("✔ JUMLAH DATA DI TABEL SEKARANG: ${afterInsert.length}");
        for (var row in afterInsert) {
          print("   ➕ ROW: $row");
        }

        print("🎉 SEMUA DATA API BERHASIL DISIMPAN KE DALAM DATABASE !");
      } catch (e) {
        print("❌ ERROR saat simpan ke database: $e");
      }


      // Jika kita sampai sini berarti setidaknya ada data yang diambil & diproses
      return true;
    } catch (e, st) {
      print("❌ ERROR requestListPersenPremiAPI: $e");
      print(st);
      return false;
    }
  }

  // Tidak berubah
  static void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Result'),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Masuk'),
            ),
          ],
        );
      },
    );
  }

  // Helper mencari List pertama di dalam Map (rekursif ringan)
  static List<dynamic>? _findFirstListInMap(Map<String, dynamic> map) {
    for (final v in map.values) {
      if (v is List) return v;
      if (v is Map<String, dynamic>) {
        final inner = _findFirstListInMap(v);
        if (inner != null) return inner;
      }
    }
    return null;
  }
}
