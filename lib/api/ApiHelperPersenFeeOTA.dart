import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/models/PersenFeeOTA_model.dart';
import 'package:mila_kru_reguler/services/PersenFeeOTA_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiHelperPersenFeeOTA {
  /// Request data PersenFeeOTA dari API dan simpan ke SharedPreferences & database
  static Future<void> requestListPersenFeeOTAAPI(String token) async {
    final response = await http.get(
      Uri.parse('https://apimila.milaberkah.com/api/persenfeeota/2'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);

      if (jsonResponse['status'] == 'success') {
        print('Response API: $jsonResponse');

        // Parsing data dari API
        final List<PersenFeeOTA> listPersenFeeOTAData = List<PersenFeeOTA>.from(
          jsonResponse['data'].map((x) => PersenFeeOTA.fromJson(x)),
        );

        // Simpan data ke SharedPreferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(
          'listPersenFeeOTAData',
          jsonEncode(listPersenFeeOTAData.map((e) => e.toMap()).toList()),
        );

        // Simpan data ke database menggunakan PersenFeeOTAService
        final PersenFeeOTAService feeService = PersenFeeOTAService();

        try {
          final List<PersenFeeOTA> existingData = await feeService.getAllPersenFeeOTA();

          if (existingData.isEmpty) {
            for (var item in listPersenFeeOTAData) {
              await feeService.insertPersenFeeOTA(item);
            }
            print('Data PersenFeeOTA berhasil disimpan ke database');
          } else {
            print('Data PersenFeeOTA sudah ada di database, tidak perlu disimpan lagi.');
          }
        } catch (e) {
          print('Error saat menyimpan ke database: $e');
        }
      } else {
        print('Gagal mengambil data PersenFeeOTA dari API: ${jsonResponse['message']}');
      }
    } else {
      print('Request API gagal dengan status code: ${response.statusCode}');
    }
  }
}
