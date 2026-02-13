import 'dart:async';
import 'dart:convert'; // Untuk jsonEncode
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';

class HistoryBagasiBus extends StatefulWidget {
  @override
  _HistoryBagasiBusState createState() => _HistoryBagasiBusState();
}

class _HistoryBagasiBusState extends State<HistoryBagasiBus> {
  List<Map<String, dynamic>> inspectionItemsResults = [];
  late int idUser;
  int? idGarasi;
  int idBus = 0;
  String? noPol;
  late String token;
  bool _isSending = false;


  DatabaseHelper databaseHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _getInspectionResults();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        idUser = prefs.getInt('idUser') ?? 0;
        idGarasi = prefs.getInt('idGarasi');
        idBus = prefs.getInt('idBus') ?? 0;
        noPol = prefs.getString('noPol');
        token = prefs.getString('token') ?? '';
      });
    });
  }

  Future<void> _getInspectionResults() async {
    await databaseHelper.initDatabase();

    // Mengambil hasil pengecekan dari database
    List<Map<String, dynamic>> itemsResults = await databaseHelper.getAllTransaksiBagasi();

    await databaseHelper.closeDatabase();

    print('object results : $itemsResults');

    // Update state dengan hasil pengecekan
    setState(() {
      inspectionItemsResults = itemsResults;
    });
  }

  // Fungsi untuk mengirim hasil inspeksi ke API
  Future<void> sendInspectionResult(Map<String, dynamic> inspectionResult) async {
    String apiUrl = 'https://apimila.milaberkah.com/api/orderbagasi';
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Gunakan token autentikasi jika diperlukan
        },
        body: jsonEncode(inspectionResult),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Fluttertoast.showToast(msg: 'Hasil pengecekan berhasil dikirim');
        // Update status_qc di database menjadi 'Y' jika berhasil
        await databaseHelper.updateTransaksiBagasiStatusQc(inspectionResult['id']);
        Fluttertoast.showToast(msg: 'Hasil pengecekan berhasil dikirim');
      } else {
        Fluttertoast.showToast(msg: 'Gagal mengirim hasil pengecekan. Kode: ${response.statusCode}');
        print('Error response: ${response.body}');
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Terjadi kesalahan saat mengirim data');
      print('Error: $e');
    }
  }

  // Fungsi untuk mengirim semua hasil inspeksi ke API
  Future<void> sendAllInspectionResults() async {
    for (var item in inspectionItemsResults) {
      print('Mengirim data berikut: $item'); // Menampilkan nilai yang dikirim
      await sendInspectionResult(item);
    }
    // 🔥 REFRESH DATA SETELAH SEMUA TERKIRIM
    await _getInspectionResults();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Menghilangkan tanda panah kembali
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0), // Margin kanan
            child: Tooltip(
              message: 'Kirim Hasil Pengecekan', // Label tooltip
              child: IconButton(
                icon: _isSending
                    ? CircularProgressIndicator(color: Colors.green)
                    : Icon(
                  Icons.cloud_upload,
                  color: Colors.green,
                  size: 30.0,
                ),
                onPressed: _isSending
                    ? null
                    : () async {
                  setState(() => _isSending = true);
                  await sendAllInspectionResults();
                  setState(() => _isSending = false);
                },
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: inspectionItemsResults.isEmpty
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: inspectionItemsResults.length,
              itemBuilder: (context, index) {
                var item = inspectionItemsResults[index];
                // Ambil data base64 dari database
                String? base64Image = item['fupload'];
                Uint8List? imageBytes;

                // Jika base64 image ada, konversi menjadi Uint8List
                if (base64Image != null && base64Image.isNotEmpty) {
                  imageBytes = base64Decode(base64Image);
                }

                return ListTile(
                  title: Text(
                    '${item['jenis_paket']} ${item['id']}-${item['id_order']} (${item['status']})', // Menggabungkan string dengan benar
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Menentukan teks menjadi tebal
                    ),
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kode Trayek: ${item['kode_trayek']}'),
                      Text('Keterangan: ${item['keterangan']}'),
                      Text('Kota Pengiriman: ${item['kota_berangkat']}'),
                      Text('Kota Tujuan: ${item['kota_tujuan']}'),
                      Text('Biaya Pengiriman: ${item['jml_harga']}'),
                      Text('Pengirim: ${item['nama_pengirim']}.-.${item['no_tlp_pengirim']}'),
                      Text('Penerima: ${item['nama_penerima']}.-.${item['no_tlp_penerima']}'),
                      // Tampilkan gambar jika ada
                      if (imageBytes != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Image.memory(
                            imageBytes, // Gambar dalam bentuk Uint8List
                            width: 100, // Sesuaikan lebar gambar
                            height: 100, // Sesuaikan tinggi gambar
                            fit: BoxFit.cover,
                          ),
                        ),

                      // Text('Gambar: ${item['file_name']}'),

                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
