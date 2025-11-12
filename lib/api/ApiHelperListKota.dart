import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiHelperListKota {
  static Future<void> requestListKotaAPI(String token, String namaTrayek) async {
    final listKotaApiResponse = await http.get(
      Uri.parse('https://apimila.sysconix.id/api/rutetrayek/?nama_trayek=$namaTrayek'),
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
        DatabaseHelper databaseHelper = DatabaseHelper();
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

class ListKota {
  final String kodeTrayek;
  final String idKotaBerangkat;
  final String idKotaTujuan;
  final double jarak;
  final String namaKota;
  final int idHargaTiket;
  final double hargaKantor;
  final double biayaPerkursi;
  final double marginKantor;
  final double marginTarikan;
  final String aktif;

  ListKota({
    required this.kodeTrayek,
    required this.idKotaBerangkat,
    required this.idKotaTujuan,
    required this.jarak,
    required this.namaKota,
    required this.idHargaTiket,
    required this.hargaKantor,
    required this.biayaPerkursi,
    required this.marginKantor,
    required this.marginTarikan,
    required this.aktif,
  });

  factory ListKota.fromJson(Map<String, dynamic> json) {
    return ListKota(
      kodeTrayek: json['kode_trayek'] ?? '',
      idKotaBerangkat: json['id_kota_berangkat'] ?? '',
      idKotaTujuan: json['id_kota_tujuan'] ?? '',
      jarak: json['jarak'] != null ? (json['jarak'] is int ? json['jarak'].toDouble() : double.parse(json['jarak'].toString())) : 0.0,
      namaKota: json['nama_kota'] ?? '',
      idHargaTiket: json['id_harga_tiket'] is int ? json['id_harga_tiket'] : int.tryParse(json['id_harga_tiket'].toString()) ?? 0,
      hargaKantor: json['harga_kantor'] != null ? (json['harga_kantor'] is int ? json['harga_kantor'].toDouble() : double.parse(json['harga_kantor'].toString())) : 0.0,
      biayaPerkursi: json['biaya_perkursi'] != null ? (json['biaya_perkursi'] is int ? json['biaya_perkursi'].toDouble() : double.parse(json['biaya_perkursi'].toString())) : 0.0,
      marginKantor: json['margin_kantor'] != null ? (json['margin_kantor'] is int ? json['margin_kantor'].toDouble() : double.parse(json['margin_kantor'].toString())) : 0.0,
      marginTarikan: json['margin_tarikan'] != null ? (json['margin_tarikan'] is int ? json['margin_tarikan'].toDouble() : double.parse(json['margin_tarikan'].toString())) : 0.0,
      aktif: json['aktif'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kode_trayek': kodeTrayek,
      'id_kota_berangkat': idKotaBerangkat,
      'id_kota_tujuan': idKotaTujuan,
      'jarak': jarak,
      'nama_kota': namaKota,
      'id_harga_tiket': idHargaTiket,
      'harga_kantor': hargaKantor,
      'biaya_perkursi': biayaPerkursi,
      'margin_kantor': marginKantor,
      'margin_tarikan': marginTarikan,
      'aktif': aktif,
    };
  }
}
