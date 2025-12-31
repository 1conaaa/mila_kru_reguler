import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/rute_trayek_urutan_model.dart';

class ApiHelperRuteTrayekUrutan {
  static Future<void> requestRuteTrayekUrutanAPI(
      String token, String kodeTrayek) async {

    final response = await http.get(
      Uri.parse(
          'https://apimila.milaberkah.com/api/rutetrayekurutan?id_trayek=$kodeTrayek'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final apiResponse =
      ApiResponseRuteTrayekUrutan.fromJson(jsonDecode(response.body));

      if (apiResponse.success == 1) {
        print('Rute Trayek Urutan API sukses');

        List<RuteTrayekUrutan> data = apiResponse.ruteTrayek;

        // 🔹 Simpan ke SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString(
          'ruteTrayekUrutan',
          jsonEncode(data.map((e) => e.toMap()).toList()),
        );

        // 🔹 Simpan ke database
        DatabaseHelper db = DatabaseHelper.instance;
        await db.initDatabase();

        final existing = await db.getRuteTrayekUrutan();
        if (existing.isEmpty) {
          for (var item in data) {
            await db.insertRuteTrayekUrutan(item.toMap());
          }
          print('Data rute trayek urutan berhasil disimpan');
        } else {
          print('Data rute trayek urutan sudah ada');
        }

        await db.closeDatabase();
      } else {
        print('API Rute Trayek Urutan gagal');
      }
    } else {
      print('HTTP Error: ${response.statusCode}');
    }
  }
}

class ApiResponseRuteTrayekUrutan {
  final int success;
  final List<RuteTrayekUrutan> ruteTrayek;

  ApiResponseRuteTrayekUrutan({
    required this.success,
    required this.ruteTrayek,
  });

  factory ApiResponseRuteTrayekUrutan.fromJson(Map<String, dynamic> json) {
    return ApiResponseRuteTrayekUrutan(
      success: json['success'] is int
          ? json['success']
          : int.tryParse(json['success'].toString()) ?? 0,
      ruteTrayek: List<RuteTrayekUrutan>.from(
        json['rute_trayek'].map((x) => RuteTrayekUrutan.fromJson(x)),
      ),
    );
  }
}
