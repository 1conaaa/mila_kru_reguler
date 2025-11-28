import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiHelperKruBis {
  static Future<void> requestKruBisAPI(String token, int idBus, String noPol, int idGarasi, BuildContext context) async {
    final KruBisApiResponse = await http.get(
      Uri.parse('https://apimila.milaberkah.com/api/krubis?id_bus=$idBus&no_pol=$noPol&id_garasi=$idGarasi'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (KruBisApiResponse.statusCode == 200) {
      ApiResponseKruBis apiResponseKruBis = ApiResponseKruBis.fromJson(jsonDecode(KruBisApiResponse.body));
      if (apiResponseKruBis.success == 1) {
        print('Kru Bis API $apiResponseKruBis');

        // Menyimpan data ke variabel krubisData
        List<KruBis> krubisData = apiResponseKruBis.krubis;

        // Simpan data ke shared preferences
        DatabaseHelper databaseHelper = DatabaseHelper();
        await databaseHelper.initDatabase(); // Panggil fungsi initDatabase dari DatabaseHelperKruBis
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('krubisData', jsonEncode(krubisData.map((krubis) => krubis.toMap()).toList()));

        // Simpan data ke database
        try {
          for (var krubis in krubisData) {
            try {
              print("➡️ INSERT: ${krubis.toMap()}");
              await databaseHelper.insertKruBis(krubis.toMap());
              print("✅ INSERT OK: ${krubis.namaLengkap}");
            } catch (e) {
              // Tangani error UNIQUE constraint tapi lanjut ke data berikutnya
              if (e.toString().contains('UNIQUE constraint failed')) {
                print("⚠️ Data duplikat, dilewati: ${krubis.namaLengkap}");
              } else {
                print("❌ Error insert: $e");
              }
            }
          }
          print('Data Kru Bis berhasil disimpan');
          // await databaseHelper.closeDatabase(); // Panggil fungsi closeDatabase dari DatabaseHelperKruBis
        } catch (e) {
          print('Error: $e');
        }
      } else {
        print('Anda gagal melakukan login. Silakan coba lagi.');
      }
    } else {
      print('Gagal melakukan permintaan ke API kedua');
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

class ApiResponseKruBis {
  final int success;
  final List<KruBis> krubis;

  ApiResponseKruBis({
    required this.success,
    required this.krubis,
  });

  factory ApiResponseKruBis.fromJson(Map<String, dynamic> json) {
    return ApiResponseKruBis(
      success: json['success'] is int ? json['success'] : int.tryParse(json['success']) ?? 0,
      krubis: List<KruBis>.from(json['krubis'].map((x) => KruBis.fromJson(x))),
    );
  }
}

class KruBis {
  final int idPersonil;
  final int idGroup;
  final String namaLengkap;
  final String groupName;

  KruBis({
    required this.idPersonil,
    required this.idGroup,
    required this.namaLengkap,
    required this.groupName,
  });

  factory KruBis.fromJson(Map<String, dynamic> json) {
    return KruBis(
      idPersonil: json['id_personil'] is int ? json['id_personil'] : int.tryParse(json['id_personil']) ?? 0,
      idGroup: json['id_group'] is int ? json['id_group'] : int.tryParse(json['id_group']) ?? 0,
      namaLengkap: json['nama_lengkap'] ?? '',
      groupName: json['group_name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_personil': idPersonil,
      'id_group': idGroup,
      'nama_lengkap': namaLengkap,
      'group_name': groupName,
    };
  }
}
