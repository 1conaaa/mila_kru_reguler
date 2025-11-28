import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/database/database_helper.dart';

class ApiHelperJenisPaket {
  static Future<void> addListJenisPaketAPI(String token) async {
    final response = await http.get(
      Uri.parse('https://apimila.milaberkah.com/api/jenispaket'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('cek response status: ${response.statusCode}');
    print('cek response body: ${response.body}');

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      if (jsonResponse is Map<String, dynamic>) {
        ApiResponseListJenisPaket apiResponse = ApiResponseListJenisPaket
            .fromJson(jsonResponse);

        if (apiResponse.success == 1) {
          print('Data Jenis Paket API berhasil diambil: $apiResponse');
          List<JenisPaket> jenisPaketData = apiResponse.jenispaket;

          DatabaseHelper databaseHelper = DatabaseHelper();
          await databaseHelper.initDatabase();

          try {
            for (var jenisPaket in jenisPaketData) {
              await databaseHelper.insertJenisPaket(jenisPaket.toMap());
            }
            print('Data Jenis Paket berhasil disimpan');

            // Panggil fungsi untuk menampilkan data dari tabel m_inspection_items
            await getJenisPaketFromDB();
          } catch (e) {
            print('Error menyimpan data: $e');
          } finally {
            await databaseHelper.closeDatabase();
          }
        } else {
          print('Gagal menyimpan data Jenis Paket. Silakan coba lagi.');
        }
      } else if (jsonResponse is List) {
        print('Respons berupa List, memproses data sebagai List.');
        List<JenisPaket> jenisPaketList = jsonResponse
            .map((item) => JenisPaket.fromJson(item))
            .toList();

        DatabaseHelper databaseHelper = DatabaseHelper();
        await databaseHelper.initDatabase();

        try {
          for (var jenisPaket in jenisPaketList) {
            await databaseHelper.insertJenisPaket(jenisPaket.toMap());
            print('Data item ${jenisPaket.jenis_paket} berhasil disimpan.');
          }
          print('Data Jenis Paket berhasil disimpan dari List');

          // Panggil fungsi untuk menampilkan data dari tabel m_inspection_items
          await getJenisPaketFromDB();
        } catch (e) {
          print('Error menyimpan data dari List: $e');
        } finally {
          await databaseHelper.closeDatabase();
        }
      } else {
        print('Format respons API tidak sesuai, diharapkan Map atau List');
      }
    } else {
      print('Gagal mengambil data Jenis Paket dari API');
    }
  }

  // Fungsi untuk mengambil dan menampilkan data dari tabel m_inspection_items
  static Future<void> getJenisPaketFromDB() async {
    DatabaseHelper databaseHelper = DatabaseHelper();
    await databaseHelper.initDatabase();

    try {
      List<Map<String, dynamic>> jenisPaket = await databaseHelper.getAllJenisPaket();
      print('Data Jenis Paket dari tabel m_jenis_paket: $jenisPaket');
    } catch (e) {
      print('Error mengambil data dari database: $e');
    } finally {
      await databaseHelper.closeDatabase();
    }
  }
}

class JenisPaket {
  final int id;
  final String jenis_paket;
  final String deskripsi;
  final double harga_paket;
  final double persen;

  JenisPaket({required this.id, required this.jenis_paket, required this.deskripsi, required this.persen, required this.harga_paket});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jenis_paket': jenis_paket,
      'deskripsi': deskripsi,
      'harga_paket': harga_paket,
      'persen': persen,
    };
  }

  factory JenisPaket.fromJson(Map<String, dynamic> json) {
    return JenisPaket(
      id: json['id'],
      jenis_paket: json['jenis_paket'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      harga_paket: double.parse(json['harga_paket']),  // Mengubah string menjadi double
      persen: double.parse(json['persen']),  // Mengubah string menjadi double
    );
  }

}

class ApiResponseListJenisPaket {
  final int success;
  final List<JenisPaket> jenispaket;

  ApiResponseListJenisPaket({required this.success, required this.jenispaket});

  factory ApiResponseListJenisPaket.fromJson(Map<String, dynamic> json) {
    var list = json['jenispaket'] as List;
    List<JenisPaket> jenisPaketList =
    list.map((i) => JenisPaket.fromJson(i)).toList();

    return ApiResponseListJenisPaket(
      success: json['success'],
      jenispaket: jenisPaketList,
    );
  }
}
