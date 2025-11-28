import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/services/premi_posisi_kru_service.dart';
import 'package:mila_kru_reguler/models/premi_posisi_kru_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiHelperPremiPosisiKru {
  static Future<void> requestListPremiPosisiKruAPI(String token, String jenisTrayek, String kelasBus) async {
    final premiPosisiKruService = PremiPosisiKruService(); // Buat instance service

    final premiPosisiKruApiResponse = await http.get(
      Uri.parse('https://apimila.milaberkah.com/api/premiposisikru?jenis_trayek=$jenisTrayek&kelas_bus=$kelasBus'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('object $jenisTrayek $kelasBus');

    if (premiPosisiKruApiResponse.statusCode == 200) {
      ApiResponsePremiPosisiKru apiResponsePremiPosisiKru = ApiResponsePremiPosisiKru.fromJson(jsonDecode(premiPosisiKruApiResponse.body));
      if (apiResponsePremiPosisiKru.success == 1) {
        print('Premi Posisi Kru Bis API $apiResponsePremiPosisiKru');

        // Menyimpan data ke variabel premiPosisiKruData
        List<PremiPosisiKruBis> premiPosisiKruData = apiResponsePremiPosisiKru.premiposisikru;

        // Simpan data ke shared preferences
        DatabaseHelper databaseHelper = DatabaseHelper();
        await databaseHelper.initDatabase();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        prefs.setString('premiposisikruData', jsonEncode(premiPosisiKruData.map((premiPosisiKru) => premiPosisiKru.toMap()).toList()));

        // Simpan data ke database
        try {
          // Clear data lama terlebih dahulu
          await premiPosisiKruService.clearPremiPosisiKru();
          print('✅ Data lama premi posisi kru berhasil dihapus');

          // Convert ke model PremiPosisiKru dan simpan
          List<PremiPosisiKru> savedModels = [];
          for (var premiPosisiKru in premiPosisiKruData) {
            final premiModel = PremiPosisiKru(
              namaPremi: premiPosisiKru.namaPremi,
              persenPremi: premiPosisiKru.persenPremi,
              tanggalSimpan: DateTime.now().toString(),
            );

            final insertedId = await premiPosisiKruService.insertPremiPosisiKru(premiModel);
            savedModels.add(premiModel.copyWith(id: insertedId));
            print('✅ Premi posisi kru berhasil disimpan: $premiModel');
          }

          print('🎉 Data Premi Posisi Kru Bis berhasil disimpan: ${premiPosisiKruData.length} data');

          // TAMPILKAN ISI TABLE SETELAH INSERT
          print('=== ISI TABLE m_premi_posisi_kru SETELAH INSERT ===');
          try {
            final List<PremiPosisiKru> dataSetelahInsert = await premiPosisiKruService.getAllPremiPosisiKru();

            print('📊 TOTAL DATA DALAM TABLE: ${dataSetelahInsert.length}');

            if (dataSetelahInsert.isEmpty) {
              print('⚠️ Table m_premi_posisi_kru MASIH KOSONG setelah insert!');
            } else {
              print('📋 DETAIL DATA DALAM TABLE:');
              for (var i = 0; i < dataSetelahInsert.length; i++) {
                final data = dataSetelahInsert[i];
                print('   --- Data ${i + 1} ---');
                print('      ID: ${data.id}');
                print('      Nama Premi: "${data.namaPremi}"');
                print('      Persen Premi: "${data.persenPremi}"');
                print('      Tanggal Simpan: "${data.tanggalSimpan}"');

                // Validasi data
                if (data.namaPremi.isEmpty) {
                  print('      ❌ ERROR: nama_premi NULL atau KOSONG');
                }
                if (data.persenPremi.isEmpty) {
                  print('      ❌ ERROR: persen_premi NULL atau KOSONG');
                }
              }

              // Validasi kelengkapan data
              print('🔍 VALIDASI KELENGKAPAN DATA:');
              final requiredPositions = ['supir', 'kernet', 'kondektur'];
              final existingPositions = dataSetelahInsert.map((e) => e.namaPremi.toLowerCase() ?? '').toList();

              for (var position in requiredPositions) {
                if (existingPositions.contains(position)) {
                  print('      ✅ $position: ADA');
                } else {
                  print('      ❌ $position: TIDAK ADA');
                }
              }
            }
          } catch (e) {
            print('❌ Gagal membaca data setelah insert: $e');
          }
          print('=== END ISI TABLE ===');

          await databaseHelper.closeDatabase();

          // Tampilkan summary
          print('''
=== SUMMARY SINKRONISASI PREMI POSISI KRU ===
✅ Data dari API: ${premiPosisiKruData.length} record
✅ Data tersimpan di database: ${savedModels.length} record
✅ Proses sinkronisasi BERHASIL
===========================================
      ''');

        } catch (e) {
          print('❌ Error menyimpan data premi posisi kru: $e');

          // Tampilkan isi table meski ada error
          try {
            final List<PremiPosisiKru> dataError = await premiPosisiKruService.getAllPremiPosisiKru();
            print('⚠️ ISI TABLE SAAT ERROR: ${dataError.length} data');
            for (var data in dataError) {
              print('   - ${data.namaPremi}: ${data.persenPremi}');
            }
          } catch (e2) {
            print('❌ Gagal membaca table saat error: $e2');
          }
        }
      } else {
        print('❌ Anda gagal melakukan simpan Premi Posisi Kru Bis. Silakan coba lagi.');

        // Tampilkan data yang ada di table meski gagal
        try {
          final List<PremiPosisiKru> existingData = await premiPosisiKruService.getAllPremiPosisiKru();
          print('📋 Data existing dalam table: ${existingData.length} record');
          for (var data in existingData) {
            print('   - ${data.namaPremi}: ${data.persenPremi}');
          }
        } catch (e) {
          print('❌ Gagal membaca data existing: $e');
        }
      }
    } else {
      print('❌ Gagal melakukan simpan Premi Posisi Kru Bis. Status code: ${premiPosisiKruApiResponse.statusCode}');

      // Tampilkan data yang ada di table meski API gagal
      try {
        final List<PremiPosisiKru> existingData = await premiPosisiKruService.getAllPremiPosisiKru();
        print('📋 Data existing dalam table (API gagal): ${existingData.length} record');
        if (existingData.isNotEmpty) {
          print('💡 Menggunakan data existing dari database');
          for (var data in existingData) {
            print('   - ${data.namaPremi}: ${data.persenPremi}');
          }
        } else {
          print('⚠️ Table kosong, perlu sinkronisasi ulang');
        }
      } catch (e) {
        print('❌ Gagal membaca data existing: $e');
      }
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