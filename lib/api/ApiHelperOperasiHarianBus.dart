import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApiHelperOperasiHarianBus {
  static get operasibus => null;

  static Future<void> addListOperasiHarianBusAPI(String token, int idBus, String noPol, String kodeTrayek) async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    String tanggalWaktuSekarang = now.toString();

    final response = await http.post(
      Uri.parse('https://apimila.sysconix.id/api/operasibusharian'),
      headers: {
        'Authorization': 'Bearer $token',
      },
      body: {
        'id_bus': idBus.toString(),
        'no_pol': noPol,
        'kode_trayek': kodeTrayek,
        'tgl_sekarang': tanggalWaktuSekarang,
        'kategori': 'Operasi',
        'keterangan': 'Bis beroperasi',
        'status': 'Y',
      },
    );
    final codestatus = response.statusCode;
    // print('$codestatus');
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Data Operasi Bus berhasil disimpan');
    } else {
      print('Data Operasi Bus gagal disimpan');
    }
    print('Response: ${response.body}');
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

class ApiResponseOperasiBus {
  final bool success;
  final List<OperasiBus> operasibus;

  ApiResponseOperasiBus({
    required this.success,
    required this.operasibus,
  });

  factory ApiResponseOperasiBus.fromJson(Map<String, dynamic> json) {
    var operasibusList = json['operasibus'] as List;
    List<OperasiBus> operasibusDataList = operasibusList.map((item) => OperasiBus.fromJson(item)).toList();

    return ApiResponseOperasiBus(
      success: json['success'],
      operasibus: operasibusDataList,
    );
  }

  // factory ApiResponseOperasiBus.fromJson(Map<String, dynamic> json) {
  //   return ApiResponseOperasiBus(
  //     success: json['success'],
  //     operasibus: List<OperasiBus>.from(json['operasibus'].map((x) => OperasiBus.fromJson(x))),
  //   );
  // }
}

class OperasiBus {
  final int id_perpal;

  OperasiBus({required this.id_perpal});

  factory OperasiBus.fromJson(Map<String, dynamic> json) {
    return OperasiBus(
      id_perpal: json['id_perpal'],
    );
  }

  // final String id_perpal;
  //
  // OperasiBus({
  //   required this.id_perpal,
  // });
  //
  // factory OperasiBus.fromJson(Map<String, dynamic> json) {
  //   return OperasiBus(
  //     id_perpal: json['id_perpal'] ?? '',
  //   );
  // }
  //
  // Map<String, dynamic> toMap() {
  //   return {
  //     'id_perpal': id_perpal,
  //   };
  // }
}
