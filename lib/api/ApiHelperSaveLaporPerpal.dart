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
      // Get data from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? noPol = prefs.getString('noPol');
      int? idBus = prefs.getInt('idBus');
      String? kodeTrayek = prefs.getString('kode_trayek');

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://apimila.milaberkah.com/api/laporkondisibus'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add fields
      request.fields['id_bus'] = idBus.toString();
      request.fields['no_pol'] = noPol!;
      request.fields['kode_trayek'] = kodeTrayek!;
      request.fields['lokasi'] = lokasi;
      request.fields['kategori'] = kategori;
      request.fields['keterangan'] = keterangan;
      request.fields['status'] = 'N';

      // Set appropriate date field based on category
      if (kategori == '1') { // Operasi
        request.fields['tgl_operasi'] = DateTime.now().toIso8601String();
      } else {
        request.fields['tgl_perpal'] = DateTime.now().toIso8601String();
      }

      // Add images
      for (var imageFile in imageFiles) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        var multipartFile = http.MultipartFile(
          'foto[]', // Note the [] for multiple files
          stream,
          length,
          filename: basename(imageFile.path),
        );
        request.files.add(multipartFile);
      }

      // Send request
      var response = await request.send();

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog(context);
      } else {
        var responseBody = await response.stream.bytesToString();
        throw Exception('Failed to send data. Status: ${response.statusCode}, Response: $responseBody');
      }
    } catch (e) {
      _showErrorDialog(context, e);
      rethrow;
    }
  }

  static void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sukses'),
          content: const Text('Laporan kondisi bus berhasil dikirim.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Close the form if needed
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void _showErrorDialog(BuildContext context, dynamic error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text('Terjadi kesalahan: ${error.toString()}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}