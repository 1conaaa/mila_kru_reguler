import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kru_reguler/database/database_helper.dart';

class ApiHelperMetodePembayaran {
  static Future<void> fetchAndStoreMetodePembayaran(String token) async {
    final response = await http.get(
      Uri.parse('https://apibis.iconaaa.net/api/FaspayChannelReguler'),
      headers: {'Authorization': 'Bearer $token'},
    );

    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        var jsonList = jsonDecode(response.body);

        if (jsonList is List) {
          List<MetodePembayaran> metodeList =
          jsonList.map((item) => MetodePembayaran.fromJson(item)).toList();

          DatabaseHelper dbHelper = DatabaseHelper();
          await dbHelper.initDatabase();

          for (var item in metodeList) {
            await dbHelper.insertMetodePembayaran(item.toMap());
          }

          print('Data metode pembayaran berhasil disimpan.');
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
      List<Map<String, dynamic>> rows = await dbHelper.getAllMetodePembayaran();
      print('Isi tabel m_metode_pembayaran:');
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

class MetodePembayaran {
  final int id;
  final String? nama;
  final int? paymentChannel;
  final String? namaBank;
  final String? pemilikRekening;
  final String? noRekening;
  final double? biayaAdmin; // Ubah ke double
  final String? deskripsi;

  MetodePembayaran({
    required this.id,
    this.nama,
    this.paymentChannel,
    this.namaBank,
    this.pemilikRekening,
    this.noRekening,
    this.biayaAdmin,
    this.deskripsi,
  });

  factory MetodePembayaran.fromJson(Map<String, dynamic> json) {
    return MetodePembayaran(
      id: json['id'],
      nama: json['nama'],
      paymentChannel: (json['payment_channel'] != null)
          ? int.tryParse(json['payment_channel'].toString())
          : null,
      namaBank: json['nama_bank'],
      pemilikRekening: json['pemilik_rekening'],
      noRekening: json['no_rekening'],
      biayaAdmin: (json['biaya_admin'] != null)
          ? double.tryParse(json['biaya_admin'].toString())
          : null,
      deskripsi: json['deskripsi'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'payment_channel': paymentChannel,
      'nama_bank': namaBank,
      'pemilik_rekening': pemilikRekening,
      'no_rekening': noRekening,
      'biaya_admin': biayaAdmin,
      'deskripsi': deskripsi,
    };
  }
}

class ApiResponseMetodePembayaran {
  final int success;
  final List<MetodePembayaran> data;

  ApiResponseMetodePembayaran({required this.success, required this.data});

  factory ApiResponseMetodePembayaran.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<MetodePembayaran> items =
    list.map((i) => MetodePembayaran.fromJson(i)).toList();

    return ApiResponseMetodePembayaran(
      success: json['success'],
      data: items,
    );
  }
}
