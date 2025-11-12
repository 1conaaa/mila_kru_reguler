import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiHelperPremiPosisiKru {
  static Future<void> requestListPremiPosisiKruAPI(String token, String jenisTrayek, String kelasBus) async {
    final PremiPosisiKruApiResponse = await http.get(
      Uri.parse('https://apibis.iconaaa.net/api/premiposisikru?jenis_trayek=$jenisTrayek&kelas_bus=$kelasBus'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('object $jenisTrayek $kelasBus');

    if (PremiPosisiKruApiResponse.statusCode == 200) {
      ApiResponsePremiPosisiKru apiResponsePremiPosisiKru = ApiResponsePremiPosisiKru.fromJson(jsonDecode(PremiPosisiKruApiResponse.body));
      if (apiResponsePremiPosisiKru.success == 1) {
        print('Premi Posisi Kru Bis API $apiResponsePremiPosisiKru');

        // Menyimpan data ke variabel krubisData
        List<PremiPosisiKruBis> premiposisikruData = apiResponsePremiPosisiKru.premiposisikru;

        // Simpan data ke shared preferences
        DatabaseHelper databaseHelper = DatabaseHelper();
        await databaseHelper.initDatabase(); // Panggil fungsi initDatabase dari DatabaseHelperKruBis
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('premiposisikruData', jsonEncode(premiposisikruData.map((premiposisikru) => premiposisikru.toMap()).toList()));

        // Simpan data ke database
        try {
          for (var premiposisikru in premiposisikruData) {
            await databaseHelper.insertPremiPosisiKru(premiposisikru.toMap()); // Panggil fungsi insertKruBis dari DatabaseHelperKruBis
          }
          print('Data Premi Posisi Kru Bis berhasil disimpan');
          await databaseHelper.closeDatabase(); // Panggil fungsi closeDatabase dari DatabaseHelperKruBis
        } catch (e) {
          print('Error: $e');
        }
      } else {
        print('Anda gagal melakukan simpan Premi Posisi Kru Bis. Silakan coba lagi.');
      }
    } else {
      print('Gagal melakukan simpan Premi Posisi Kru Bis');
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

class ApiResponsePremiPosisiKru {
  final int success;
  final List<PremiPosisiKruBis> premiposisikru;

  ApiResponsePremiPosisiKru({
    required this.success,
    required this.premiposisikru,
  });

  factory ApiResponsePremiPosisiKru.fromJson(Map<String, dynamic> json) {
    return ApiResponsePremiPosisiKru(
      success: json['success'],
      premiposisikru: List<PremiPosisiKruBis>.from(json['premiposisikru'].map((x) => PremiPosisiKruBis.fromJson(x))),
    );
  }
}

class PremiPosisiKruBis {
  final String namaPremi;
  final String persenPremi;

  PremiPosisiKruBis({
    required this.namaPremi,
    required this.persenPremi,
  });

  factory PremiPosisiKruBis.fromJson(Map<String, dynamic> json) {
    return PremiPosisiKruBis(
      namaPremi: json['nama_premi'] ?? '',
      persenPremi: json['persen_premi'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_premi': namaPremi,
      'persen_premi': persenPremi,
    };
  }
}
