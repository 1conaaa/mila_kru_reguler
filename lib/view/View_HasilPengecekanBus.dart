import 'dart:async';
import 'dart:convert'; // Untuk jsonEncode
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

class HasilPengecekanBus extends StatefulWidget {
  @override
  _HasilPengecekanBusState createState() => _HasilPengecekanBusState();
}

class _HasilPengecekanBusState extends State<HasilPengecekanBus> {
  List<Map<String, dynamic>> inspectionItemsResults = [];
  late int idUser;
  int? idGarasi;
  int idBus = 0;
  String? noPol;
  late String token;

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
    List<Map<String, dynamic>> itemsResults = await databaseHelper.getAllInspectionResults();

    await databaseHelper.closeDatabase();

    print('object results : $itemsResults');

    // Update state dengan hasil pengecekan
    setState(() {
      inspectionItemsResults = itemsResults;
    });
  }

  // Fungsi untuk mengirim hasil inspeksi ke API
  Future<void> sendInspectionResult(Map<String, dynamic> inspectionResult) async {
    String apiUrl = 'https://apibis.iconaaa.net/api/inspectionresults';
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
        await databaseHelper.updateInspectionStatusQc(inspectionResult['id']);
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
                icon: Icon(
                  Icons.cloud_upload,
                  color: Colors.green, // Warna hijau pada ikon
                  size: 30.0, // Ukuran ikon yang diperbesar
                ),
                onPressed: () async {
                  // Mengirim semua hasil pengecekan ke API
                  await sendAllInspectionResults();
                },
                tooltip: 'Kirim Hasil Pengecekan', // Label tooltip
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
                return ListTile(
                  title: Text(
                    item['item_name'] ?? 'Nama item tidak tersedia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, // Menentukan teks menjadi tebal
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${item['status']}'),
                      Text('Keterangan: ${item['remarks']}'),
                      Text('Tanggal: ${item['tgl_periksa']}'),
                      Text('Kirim: ${item['status_qc'] ?? 'Belum dikirim'}'),
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
