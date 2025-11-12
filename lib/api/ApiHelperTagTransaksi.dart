import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/database/database_helper.dart';

class ApiHelperTagTransaksi {
  static Future<void> fetchAndStoreTagTransaksi(String token) async {
    final response = await http.get(
      Uri.parse('https://apimila.sysconix.id/api/tagtransaksi'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        var jsonList = jsonDecode(response.body);

        if (jsonList is List) {
          List<TagTransaksi> tagList =
          jsonList.map((item) => TagTransaksi.fromJson(item)).toList();

          DatabaseHelper dbHelper = DatabaseHelper();
          await dbHelper.initDatabase();

          for (var item in tagList) {
            await dbHelper.insertTagTransaksi(item.toMap());
          }

          print('Data tag transaksi berhasil disimpan.');
          await tampilkanDataDariDatabase();

          await dbHelper.closeDatabase();
        } else {
          print('Format JSON bukan list.');
        }
      } catch (e) {
        print('Gagal parsing JSON atau simpan DB: $e');
      }
    } else {
      print('Gagal mengambil data dari API.');
    }
  }

  static Future<void> tampilkanDataDariDatabase() async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.initDatabase();

    try {
      List<Map<String, dynamic>> rows = await dbHelper.getAllTagTransaksi();
      print('Isi tabel m_tag_transaksi:');
      for (var row in rows) {
        print(row);
      }
    } catch (e) {
      print('Gagal membaca database: $e');
    } finally {
      await dbHelper.closeDatabase();
    }
  }
}

class TagTransaksi {
  final int id;
  final String? kategoriTransaksi;
  final String? nama;

  TagTransaksi({
    required this.id,
    this.kategoriTransaksi,
    this.nama,
  });

  factory TagTransaksi.fromJson(Map<String, dynamic> json) {
    return TagTransaksi(
      id: json['id'],
      kategoriTransaksi: json['kategori_transaksi']?.toString(),
      nama: json['nama'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'kategori_transaksi': kategoriTransaksi,
      'nama': nama,
    };
  }
}

class ApiResponseTagTransaksi {
  final int success;
  final List<TagTransaksi> data;

  ApiResponseTagTransaksi({required this.success, required this.data});

  factory ApiResponseTagTransaksi.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<TagTransaksi> items =
    list.map((i) => TagTransaksi.fromJson(i)).toList();

    return ApiResponseTagTransaksi(
      success: json['success'],
      data: items,
    );
  }
}
