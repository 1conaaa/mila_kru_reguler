import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

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
          List<TagTransaksi> tagList = (jsonList).map((item) => TagTransaksi.fromJson(item)).toList();

          TagTransaksiService tagService = TagTransaksiService();

          for (var item in tagList) {
            await tagService.insertTagTransaksi(item);
          }

          print('Data tag transaksi berhasil disimpan.');
          await tampilkanDataDariDatabase();
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
    TagTransaksiService tagService = TagTransaksiService();

    try {
      List<TagTransaksi> rows = await tagService.getAllTagTransaksi();
      print('Isi tabel m_tag_transaksi:');
      for (var row in rows) {
        print(row.toMap());
      }
    } catch (e) {
      print('Gagal membaca database: $e');
    }
  }
}
