import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path/path.dart';

class SaveKondisiBus {
  static Future<void> saveLaporanKondisiBus({
    required BuildContext context,
    required String lokasi,
    required String kategori,
    required String keterangan,
    required List<File> imageFiles,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? token = prefs.getString('token');
      final String? noPol = prefs.getString('noPol');
      final int? idBus = prefs.getInt('idBus');
      final String? kodeTrayek = prefs.getString('kode_trayek');

      // 🔴 Validasi data WAJIB
      if (token == null || idBus == null) {
        throw Exception('Data login tidak lengkap. Silakan login ulang.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://apimila.milaberkah.com/api/laporkondisibus'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // ✅ Semua fields dijamin String (non-null)
      request.fields['id_bus'] = idBus.toString();
      request.fields['no_pol'] = noPol ?? '';
      request.fields['kode_trayek'] = kodeTrayek ?? '';
      request.fields['lokasi'] = lokasi;
      request.fields['kategori'] = kategori;
      request.fields['keterangan'] = keterangan;
      request.fields['status'] = 'N';

      if (kategori == '1') {
        request.fields['tgl_operasi'] =
            DateTime.now().toIso8601String();
      } else {
        request.fields['tgl_perpal'] =
            DateTime.now().toIso8601String();
      }

      // Upload gambar
      for (final imageFile in imageFiles) {
        final stream = http.ByteStream(imageFile.openRead());
        final length = await imageFile.length();

        final multipartFile = http.MultipartFile(
          'foto[]',
          stream,
          length,
          filename: basename(imageFile.path),
        );

        request.files.add(multipartFile);
      }

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog(context);
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception(
          'Gagal kirim data (${response.statusCode}): $responseBody',
        );
      }
    } catch (e) {
      _showErrorDialog(context, e);
    }
  }

  static void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sukses'),
        content: const Text('Laporan kondisi bus berhasil dikirim.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(error.toString()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
