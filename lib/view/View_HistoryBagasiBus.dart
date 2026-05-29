import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    List<Map<String, dynamic>> itemsResults = await databaseHelper.getAllTransaksiBagasi();
    await databaseHelper.closeDatabase();

    print('object results : $itemsResults');

    setState(() {
      inspectionItemsResults = itemsResults;
    });
  }

  // =========================
  // KIRIM SATU DATA
  // =========================
  Future<void> sendInspectionResult(Map<String, dynamic> inspectionResult) async {
    String apiUrl = 'https://apimila.milaberkah.com/api/orderbagasi';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(inspectionResult),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await databaseHelper.updateTransaksiBagasiStatusQc(inspectionResult['id']);

        Fluttertoast.showToast(
          msg: 'Data berhasil dikirim',
          gravity: ToastGravity.BOTTOM,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Gagal mengirim data (${response.statusCode})',
          gravity: ToastGravity.BOTTOM,
        );
        print('Error response: ${response.body}');
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Terjadi kesalahan saat mengirim data',
        gravity: ToastGravity.BOTTOM,
      );
      print('Error: $e');
    }
  }

  // =========================
  // KIRIM SEMUA DATA
  // =========================
  Future<void> sendAllInspectionResults() async {
    for (var item in inspectionItemsResults) {
      print('Mengirim data berikut: $item');
      await sendInspectionResult(item);
    }
    await _getInspectionResults();
  }

  // =========================
  // WARNA STATUS
  // =========================
  Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SELESAI':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'BATAL':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  // =========================
  // ITEM INFORMASI
  // =========================
  Widget buildInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[800], fontSize: 12),
                children: [
                  TextSpan(
                    text: '$label : ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // DIALOG KONFIRMASI UPLOAD
  // =========================
  Future<void> _showUploadConfirmation() async {
    final pendingItems = inspectionItemsResults.where(
            (item) => item['status']?.toString().toUpperCase() != 'SELESAI'
    ).toList();

    if (pendingItems.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Semua data sudah terupload',
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Upload'),
        content: Text(
          'Apakah Anda yakin ingin mengupload ${pendingItems.length} data yang belum terkirim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSending = true);
              await sendAllInspectionResults();
              setState(() => _isSending = false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Upload', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text(
          'History Bagasi',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _isSending ? null : _showUploadConfirmation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _isSending
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.green,
                      ),
                    )
                        : const Icon(Icons.cloud_upload_rounded, color: Colors.green, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      _isSending ? 'Mengirim...' : 'Upload',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: inspectionItemsResults.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _getInspectionResults,
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
          itemCount: inspectionItemsResults.length,
          itemBuilder: (context, index) {
            var item = inspectionItemsResults[index];

            String? base64Image = item['fupload'];
            Uint8List? imageBytes;

            if (base64Image != null && base64Image.isNotEmpty) {
              imageBytes = base64Decode(base64Image);
            }

            final status = item['status']?.toString() ?? 'PENDING';
            final qtyBarang = item['qty_barang'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // =========================
                    // HEADER
                    // =========================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.inventory_2_rounded,
                            color: Colors.blue,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${item['jenis_paket']}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID : ${item['id']} - ${item['id_order']}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: getStatusColor(status),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rp ${NumberFormat('#,###', 'id_ID').format(
                                double.tryParse(item['jml_harga'].toString()) ?? 0,
                              )}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.inventory,
                                    size: 12,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$qtyBarang barang',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(height: 1, color: Colors.grey[300]),
                    const SizedBox(height: 10),

                    // =========================
                    // CONTENT
                    // =========================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // DETAIL (LEFT SIDE)
                        Expanded(
                          child: Column(
                            children: [
                              buildInfoItem(
                                Icons.route_rounded,
                                'Trayek',
                                '${item['kode_trayek']}',
                              ),
                              buildInfoItem(
                                Icons.repeat_rounded,
                                'Rit',
                                '${item['rit']}',
                              ),
                              buildInfoItem(
                                Icons.location_on_outlined,
                                'Asal',
                                '${item['kota_berangkat']}',
                              ),
                              buildInfoItem(
                                Icons.flag_outlined,
                                'Tujuan',
                                '${item['kota_tujuan']}',
                              ),
                              buildInfoItem(
                                Icons.person_outline,
                                'Pengirim',
                                '${item['nama_pengirim']}',
                              ),
                              buildInfoItem(
                                Icons.phone_outlined,
                                'HP Pengirim',
                                '${item['no_tlp_pengirim']}',
                              ),
                              buildInfoItem(
                                Icons.person_2_outlined,
                                'Penerima',
                                '${item['nama_penerima']}',
                              ),
                              buildInfoItem(
                                Icons.phone_android_outlined,
                                'HP Penerima',
                                '${item['no_tlp_penerima']}',
                              ),
                              if (item['keterangan'] != null &&
                                  item['keterangan'].toString().isNotEmpty)
                                buildInfoItem(
                                  Icons.notes_rounded,
                                  'Keterangan',
                                  '${item['keterangan']}',
                                ),
                            ],
                          ),
                        ),
                        // FOTO (RIGHT SIDE)
                        if (imageBytes != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                imageBytes,
                                width: 78,
                                height: 78,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}