import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/list_kota_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        await databaseHelper.initDatabase(); // Panggil fungsi initDatabase dari DatabaseHelperKruBis
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('listkotaData', jsonEncode(listkotaData.map((listkota) => listkota.toMap()).toList()));

        // Simpan data ke database
        try {
          List<Map<String, dynamic>> existingListKota = await databaseHelper.getListKota();
          if (existingListKota.isEmpty) {
            for (var listkota in listkotaData) {
              await databaseHelper.insertListKota(listkota.toMap()); // Panggil fungsi insertListKota dari DatabaseHelper
            }
            print('Data List Kota berhasil disimpan');
            await databaseHelper.closeDatabase(); // Panggil fungsi closeDatabase dari DatabaseHelper
          } else {
            print('Data List Kota sudah ada, tidak perlu disimpan lagi.');
          }

        } catch (e) {
          print('Error: $e');
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

