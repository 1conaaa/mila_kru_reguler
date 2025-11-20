// data_pusher_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/services/premi_harian_kru_service.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';
import 'package:mila_kru_reguler/models/setoranKru_model.dart';

class DataPusherService {
  final PremiHarianKruService _premiHarianKruService = PremiHarianKruService();
  final SetoranKruService _setoranKruService = SetoranKruService();

  /// Push data premi harian kru dan setoran kru ke API
  Future<void> pushDataPremiHarianKru({
    required DateTime selectedDate,
    required Function(double) onProgress,
    required Function() onSuccess,
  }) async {
    final String tanggal_transaksi = DateFormat('yyyy-MM-dd').format(selectedDate);
    print("Data dikirim untuk tanggal: $tanggal_transaksi");

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('token');

    // Get last transaction ID
    final String idTransaksiGenerated = await _getLastTransactionId(token);

    // Send premi harian kru data (will update progress)
    await _sendPremiHarianKruData(
      tanggal_transaksi: tanggal_transaksi,
      idTransaksiGenerated: idTransaksiGenerated,
      token: token,
      onProgress: onProgress,
    );

    // Send setoran kru data (multipart)
    await _sendSetoranKruData(
      tanggal_transaksi: tanggal_transaksi,
      idTransaksiGenerated: idTransaksiGenerated,
      token: token,
    );

    onSuccess();
  }

  /// Get last transaction ID from API
  Future<String> _getLastTransactionId(String? token) async {
    try {
      const String apiUrlLastId = 'https://apimila.sysconix.id/api/lastidtransaksi';
      const String queryParamsLastId = '?kode_transaksi=KEUBIS';
      final String apiUrlWithParams = apiUrlLastId + queryParamsLastId;

      final responseLastId = await http.get(
        Uri.parse(apiUrlWithParams),
        headers: token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
      );

      print("API Last ID: $apiUrlWithParams (status ${responseLastId.statusCode})");

      if (responseLastId.statusCode == 200 || responseLastId.statusCode == 201) {
        final dynamic jsonResponseLastId = json.decode(responseLastId.body);
        print('JSON Response last id: $jsonResponseLastId');

        if (jsonResponseLastId != null && jsonResponseLastId['success'] == true) {
          final dynamic lastid = jsonResponseLastId['lastid'];
          if (lastid != null && lastid is Map && lastid['id_transaksi'] != null) {
            final String idTransaksi = lastid['id_transaksi'].toString();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('idTransaksi', idTransaksi);
            print('ID Transaksi (server): $idTransaksi');

            // asumsi prefix 'KEUBIS' + number
            if (idTransaksi.length > 6) {
              try {
                final String numericPart = idTransaksi.substring(6);
                int idNum = int.parse(numericPart);
                idNum++;
                final String generated = 'KEUBIS' + idNum.toString();
                print('1.ID Transaksi Generate: $generated');
                return generated;
              } catch (e) {
                print('Parsing last id failed: $e');
                // fallthrough to fallback
              }
            }
          }
        }
      }

      // fallback generation (persistent counter in prefs)
      print('Using fallback transaction ID generation');
      final prefs = await SharedPreferences.getInstance();
      int fallbackCounter = prefs.getInt('fallback_keubis_counter') ?? 0;
      fallbackCounter++;
      await prefs.setInt('fallback_keubis_counter', fallbackCounter);
      final String idTransaksiGenerated = 'KEUBIS' + fallbackCounter.toString();
      print('2.ID Transaksi Generate: $idTransaksiGenerated');
      return idTransaksiGenerated;
    } catch (e) {
      print('Error getting last transaction ID: $e');
      final prefs = await SharedPreferences.getInstance();
      int fallbackCounter = prefs.getInt('fallback_keubis_counter') ?? 0;
      fallbackCounter++;
      await prefs.setInt('fallback_keubis_counter', fallbackCounter);
      return 'KEUBIS' + fallbackCounter.toString();
    }
  }

  /// Send premi harian kru data to API
  Future<void> _sendPremiHarianKruData({
    required String tanggal_transaksi,
    required String idTransaksiGenerated,
    required String? token,
    required Function(double) onProgress,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String noPol = prefs.getString('noPol') ?? '';
    final String kodeTrayek = prefs.getString('kode_trayek') ?? '';

    final List<Map<String, dynamic>> premiKruData =
    await _premiHarianKruService.getPremiHarianKruWithKruBisByStatus('N');

    if (premiKruData.isEmpty) {
      print('Tidak ada data premi harian kru dengan status \'N\'');
      onProgress(1.0);
      return;
    }

    print('Premi kru data: ${premiKruData.length} rows');
    final int idBus = prefs.getInt('idBus') ?? 0;
    const String apiUrl = 'https://apimila.sysconix.id/api/premihariankru';

    final int totalDataPremiKru = premiKruData.length;
    int dataSent = 0;

    for (var row in premiKruData) {
      final int id_user = row['id_user'] ?? 0;
      final int id_group = row['id_group'] ?? 0;
      final double persen_premi_disetor = (row['persen_premi_disetor'] ?? 0).toDouble();
      final double nominal_premi_disetor = (row['nominal_premi_disetor'] ?? 0).toDouble();
      final String tanggal_simpan = row['tanggal_simpan'] ?? tanggal_transaksi;

      // Update progress before send
      onProgress(dataSent / totalDataPremiKru);

      final String queryParams = '?id_transaksi=${Uri.encodeFull(idTransaksiGenerated)}'
          '&no_pol=${Uri.encodeFull(noPol)}'
          '&id_bus=$idBus'
          '&kode_trayek=${Uri.encodeFull(kodeTrayek)}'
          '&id_personil=$id_user'
          '&id_group=$id_group'
          '&persen=$persen_premi_disetor'
          '&nominal=$nominal_premi_disetor'
          '&tgl_transaksi=${Uri.encodeFull(tanggal_simpan)}';

      final String apiUrlWithParams = apiUrl + queryParams;
      print('API Request (premi): $apiUrlWithParams');

      try {
        final response = await http.post(
          Uri.parse(apiUrlWithParams),
          headers: token != null && token.isNotEmpty ? {'Authorization': 'Bearer $token'} : {},
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          try {
            final int id = row['id'];
            await _premiHarianKruService.updatePremiHarianKruStatus(id, 'Y');
          } catch (e) {
            print('Warning: gagal update status premi lokal: $e');
          }
          dataSent++;
          onProgress(dataSent / totalDataPremiKru);
          print('Berhasil kirim premi: status code ${response.statusCode}');
        } else {
          print('Gagal kirim premi. status: ${response.statusCode}, body: ${response.body}');
        }
      } catch (e) {
        print('Error mengirim premi harian kru: $e');
      }
    }

    // Ensure progress finished
    onProgress(1.0);
  }

  /// Send setoran kru data to API (multipart/form-data)
  Future<void> _sendSetoranKruData({
    required String tanggal_transaksi,
    required String idTransaksiGenerated,
    required String? token,
  }) async {
    try {
      // Get setoran kru data with status 'N'
      final List<SetoranKru> setoranKruData = await _setoranKruService.getAllSetoran();
      final List<SetoranKru> setoranKruToSend =
      setoranKruData.where((setoran) => setoran.status == 'N').toList();

      if (setoranKruToSend.isEmpty) {
        print('Tidak ada data setoran kru dengan status \'N\'');
        return;
      }

      print('Mengirim ${setoranKruToSend.length} data setoran kru ke API');

      final bool success = await _sendWithFormDataAndFiles(
        setoranKruToSend: setoranKruToSend,
        idTransaksiGenerated: idTransaksiGenerated,
        token: token,
      );

      if (!success) {
        print('❌ Gagal mengirim data setoran kru');
      }
    } catch (e) {
      print('❌ Terjadi kesalahan saat mengirim data setoran kru: $e');
    }
  }

  /// Build and send multipart/form-data with i[field] and file_name[i][]
  Future<bool> _sendWithFormDataAndFiles({
    required List<SetoranKru> setoranKruToSend,
    required String idTransaksiGenerated,
    required String? token,
  }) async {
    try {
      const String endpoint = 'https://apimila.sysconix.id/api/simpansetorankrumobile';
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));

      // Header token
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      print("==========================================");
      print("🚀 MEMULAI PENGIRIMAN DATA SETORAN KRU");
      print("==========================================");
      print("ID Transaksi: $idTransaksiGenerated");
      print("Jumlah data: ${setoranKruToSend.length} rows");
      print("Endpoint: $endpoint");

      // ID transaksi dikirim satu kali (top-level) - INI YANG DIPERLUKAN BACKEND
      request.fields['id_transaksi'] = idTransaksiGenerated;
      print("✅ Field id_transaksi: $idTransaksiGenerated");

      // Siapkan data rows untuk dikirim sebagai JSON
      List<Map<String, dynamic>> rowsData = [];

      // Loop setiap row untuk menyiapkan data
      for (int i = 0; i < setoranKruToSend.length; i++) {
        final d = setoranKruToSend[i];

        // Debug detail setiap row
        print("\n--- DATA ROW $i ---");
        print("id_transaksi: ${idTransaksiGenerated}");
        print("tgl_transaksi: ${d.tglTransaksi ?? ""}");
        print("km_pulang: ${(d.kmPulang ?? '').toString()}");
        print("rit: ${d.rit ?? "1"}");
        print("no_pol: ${d.noPol ?? ""}");
        print("id_bus: ${(d.idBus ?? 0).toString()}");
        print("kode_trayek: ${d.kodeTrayek ?? ""}");
        print("id_personil: ${(d.idPersonil ?? 0).toString()}");
        print("id_group: ${(d.idGroup ?? 0).toString()}");
        print("jumlah: ${(d.jumlah ?? '').toString()}");
        print("coa: ${d.coa ?? ""}");
        print("nilai: ${(d.nilai ?? 0).toString()}");
        print("id_tag_transaksi: ${(d.idTagTransaksi ?? 0).toString()}");
        print("status: ${d.status ?? "N"}");
        print("keterangan: ${d.keterangan ?? ""}");

        // Siapkan data untuk JSON
        Map<String, dynamic> rowData = {
          'id_transaksi': idTransaksiGenerated,
          'tgl_transaksi': d.tglTransaksi ?? "",
          'km_pulang': d.kmPulang ?? "",
          'rit': d.rit ?? "1",
          'no_pol': d.noPol ?? "",
          'id_bus': d.idBus ?? 0,
          'kode_trayek': d.kodeTrayek ?? "",
          'id_personil': d.idPersonil ?? 0,
          'id_group': d.idGroup ?? 0,
          'jumlah': d.jumlah ?? "",
          'coa': d.coa ?? "",
          'nilai': d.nilai ?? 0,
          'id_tag_transaksi': d.idTagTransaksi ?? 0,
          'status': d.status ?? "N",
          'keterangan': d.keterangan ?? "",
        };

        rowsData.add(rowData);
        print("✅ Row $i disiapkan untuk JSON (id personil: ${d.idPersonil})");
      }

      // Kirim rows sebagai JSON string - INI YANG DIHARAPKAN BACKEND
      String rowsJson = json.encode(rowsData);
      request.fields['rows'] = rowsJson;
      print("\n📦 Data rows sebagai JSON:");
      print(rowsJson);

      // ==== FILES: support up to 2 files per row ====
      print("\n--- PROSES FILE ---");
      for (int i = 0; i < setoranKruToSend.length; i++) {
        final d = setoranKruToSend[i];

        // Expecting model fields: file1 (String?), file2 (String?)
        final String? f1 = (d as dynamic).fupload as String?;
        final String? f2 = (d as dynamic).fileName as String?;

        print("\n🔍 Cek file untuk row $i:");
        print("File1 path: $f1");
        print("File2 path: $f2");

        if (f1 != null && f1.isNotEmpty) {
          try {
            final File fileObj = File(f1);
            if (await fileObj.exists()) {
              final multipart = await http.MultipartFile.fromPath(
                  "file_name[$i][]",
                  f1,
                  filename: f1.split('/').last
              );
              request.files.add(multipart);
              print("✅ File1 row $i attached: ${f1.split('/').last}");
            } else {
              print("⚠ File1 not found for row $i: $f1");
            }
          } catch (e) {
            print("❌ Error attaching file1 row $i: $e");
          }
        }

        if (f2 != null && f2.isNotEmpty) {
          try {
            final File fileObj = File(f2);
            if (await fileObj.exists()) {
              final multipart = await http.MultipartFile.fromPath(
                  "file_name[$i][]",
                  f2,
                  filename: f2.split('/').last
              );
              request.files.add(multipart);
              print("✅ File2 row $i attached: ${f2.split('/').last}");
            } else {
              print("⚠ File2 not found for row $i: $f2");
            }
          } catch (e) {
            print("❌ Error attaching file2 row $i: $e");
          }
        }
      }

      print("\n==========================================");
      print("📤 MENGIRIM REQUEST KE SERVER");
      print("==========================================");
      print("Total files: ${request.files.length}");
      print("Total fields: ${request.fields.length}");

      // Debug: print semua fields yang akan dikirim
      print("\n📋 SEMUA FIELDS YANG DIKIRIM:");
      request.fields.forEach((key, value) {
        if (key == 'rows') {
          print("$key: [JSON DATA - length: ${value.length}]");
        } else {
          print("$key: $value");
        }
      });

      final stopwatch = Stopwatch()..start();
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      stopwatch.stop();

      print("\n==========================================");
      print("📥 RESPONSE DARI SERVER");
      print("==========================================");
      print("Waktu request: ${stopwatch.elapsedMilliseconds}ms");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          if (responseData['success'] == true) {
            print('✅ Berhasil mengirim data setoran kru');
            print('📝 Pesan: ${responseData['message']}');
            print('🔑 ID Transaksi: ${responseData['id_transaksi']}');
            print('📊 Data inserted: ${responseData['data_id_dimasukkan']}');

            await _updateSetoranKruStatus(setoranKruToSend);
            return true;
          } else {
            print('❌ Server returned success=false');
            print('📝 Pesan: ${responseData['message'] ?? responseData}');
            if (responseData['errors'] != null) print('❌ Errors: ${responseData['errors']}');
            if (responseData['data_yang_error'] != null) print('❌ Data yang error: ${responseData['data_yang_error']}');
            return false;
          }
        } catch (e) {
          print('❌ Gagal parse response JSON: $e');
          return false;
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        if (response.statusCode == 422) {
          try {
            final Map<String, dynamic> responseData = json.decode(response.body);
            print('❌ Validation errors: ${responseData['errors'] ?? responseData}');
          } catch (_) {
            print('❌ Response error (non-JSON): ${response.body}');
          }
        } else if (response.statusCode == 500) {
          print('❌ Server error 500');
          print('Response: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      print('❌ Error building/sending multipart: $e');
      print('❌ Stack trace: ${e.toString()}');
      return false;
    }
  }

  /// Update status setoran kru
  Future<void> _updateSetoranKruStatus(List<SetoranKru> setoranKruToSend) async {
    for (var setoran in setoranKruToSend) {
      if (setoran.id != null) {
        try {
          await _setoranKruService.updateSetoran(setoran.copyWith(status: 'Y'));
        } catch (e) {
          print('Gagal update status local untuk id ${setoran.id}: $e');
        }
      }
    }
    print('✅ Status setoran kru berhasil diupdate menjadi \'Y\'');
  }
}
