import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/list_kota_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

class ApiHelperListKota {
  static Future<void> requestListKotaAPI(String token, String kodeTrayek) async {
    final listKotaApiResponse = await http.get(
      Uri.parse('https://apimila.milaberkah.com/api/rutetrayek/?nama_trayek=$kodeTrayek'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (listKotaApiResponse.statusCode == 200) {
      ApiResponseListKota apiResponseListKota = ApiResponseListKota.fromJson(jsonDecode(listKotaApiResponse.body));
      if (apiResponseListKota.success == 1) {
        print('List Kota API $apiResponseListKota');

        // Menyimpan data ke variabel listkotaData
        List<ListKota> listkotaData = apiResponseListKota.listkota;

        // Simpan data ke shared preferences
        DatabaseHelper databaseHelper = DatabaseHelper.instance;
        await databaseHelper.initDatabase();

// 🔹 Simpan ke SharedPreferences (tetap seperti semula)
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(
          'listkotaData',
          jsonEncode(listkotaData.map((e) => e.toMap()).toList()),
        );

// 🔹 Simpan ke database (BATCH)
        try {
          final db = await databaseHelper.database;
          final batch = db.batch();

          for (var listkota in listkotaData) {
            batch.insert(
              'list_kota',
              listkota.toMap(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          await batch.commit(noResult: true);
          print('Data List Kota berhasil di-sync (batch insert / update)');
        } catch (e, stacktrace) {
          print('Error sync List Kota (batch): $e');
          print(stacktrace);
        } finally {
          await databaseHelper.closeDatabase();
        }

      } else {
        print('Anda gagal simpan API List Kota. Silakan coba lagi.');
      }
    } else {
      print('Gagal melakukan permintaan ke API List Kota');
    }
  }

  static void _showDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Result'),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Masuk'),
            ),
          ],
        );
      },
    );
  }
}

class ApiResponseListKota {
  final int success;
  final List<ListKota> listkota;

  ApiResponseListKota({
    required this.success,
    required this.listkota,
  });

  factory ApiResponseListKota.fromJson(Map<String, dynamic> json) {
    return ApiResponseListKota(
      success: json['success'] is int ? json['success'] : int.tryParse(json['success'].toString()) ?? 0,
      listkota: List<ListKota>.from(json['rutetrayek'].map((x) => ListKota.fromJson(x))),
    );
  }
}

