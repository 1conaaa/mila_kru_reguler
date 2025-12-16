import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';


class HistroyTransaksi extends StatefulWidget {
  @override
  _HistroyTransaksiState createState() => _HistroyTransaksiState();
}

class _HistroyTransaksiState extends State<HistroyTransaksi> {
  DatabaseHelper databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> listPenjualan = [];
  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
  bool _isPushingData = false;
  double _pushDataProgress = 0.0;
  String searchQuery = ''; // Field untuk menyimpan nilai pencarian

  List<String> kotaTujuanList = []; // List untuk kota tujuan unik
  String selectedKotaTujuan = ''; // atau sesuaikan dengan nilai awal yang sesuai dengan aplikasi Anda

  Map<String, bool> isCheckedPerRute = {};

  @override
  void initState() {
    super.initState();
    _getListTransaksi();
    _loadLastTransaksi();
  }

  Future<void> _loadLastTransaksi() async {
    await databaseHelper.initDatabase();
    await _getListTransaksi();
    await databaseHelper.closeDatabase();
  }

  // Method untuk mencari dan memfilter data penjualan berdasarkan rute kota
  void _searchRuteKota(String searchQuery) async {
    try {
      List<Map<String, dynamic>> result = await PenjualanTiketService.instance.getDataRuteKota(searchQuery);
      setState(() {
        listPenjualan = result;
      });
    } catch (e) {
      print('Error saat memanggil getDataRuteKota: $e');
    }
  }


  void _pushDataPenjualan() async {
    print("=== PUSH DATA PENJUALAN DIMULAI ===");

    setState(() {
      _isPushingData = true;
      _pushDataProgress = 0.0;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    await databaseHelper.initDatabase();
    List<Map<String, dynamic>> penjualanData =
    await PenjualanTiketService.instance.getPenjualanByStatus('N');

    if (penjualanData.isNotEmpty) {
      int totalData = penjualanData.length;
      int dataSent = 0;

      for (var penjualan in penjualanData) {
        final penjualanId = penjualan['id'];
        print("\n=== KIRIM DATA ID: $penjualanId ===");

        String apiUrl = "https://apimila.milaberkah.com/api/penjualantiket";

        // Buat MultipartRequest baru untuk setiap iterasi (tidak reuse)
        var uri = Uri.parse(apiUrl);
        var request = http.MultipartRequest("POST", uri);

        request.headers['Authorization'] = 'Bearer $token';
      
        // Isi semua field sebagai request.fields sehingga request berdiri sendiri
        request.fields['id'] = penjualanId.toString();
        request.fields['tgl_transaksi'] = penjualan['tanggal_transaksi']?.toString() ?? '';
        request.fields['kategori'] = penjualan['kategori_tiket']?.toString() ?? '';
        request.fields['rit'] = penjualan['rit']?.toString() ?? '';
        request.fields['no_pol'] = penjualan['no_pol']?.toString() ?? '';
        request.fields['id_bus'] = penjualan['id_bus']?.toString() ?? '';
        request.fields['kode_trayek'] = penjualan['kode_trayek']?.toString() ?? '';
        request.fields['id_personil'] = penjualan['id_user']?.toString() ?? '';
        request.fields['id_group'] = penjualan['id_group']?.toString() ?? '';
        request.fields['id_kota_berangkat'] = penjualan['kota_berangkat']?.toString() ?? '';
        request.fields['id_kota_tujuan'] = penjualan['kota_tujuan']?.toString() ?? '';
        request.fields['jml_naik'] = penjualan['jumlah_tiket']?.toString() ?? '0';
        request.fields['pendapatan'] = penjualan['jumlah_tagihan']?.toString() ?? '0';
        request.fields['harga_kantor'] = penjualan['harga_kantor']?.toString() ?? '0';
        request.fields['nama_pelanggan'] = penjualan['nama_pembeli']?.toString() ?? '';
        request.fields['no_telepon'] = penjualan['no_telepon']?.toString() ?? '';
        request.fields['status'] = penjualan['status']?.toString() ?? '';
        request.fields['keterangan'] = penjualan['keterangan']?.toString() ?? '';
        request.fields['is_turun'] = penjualan['is_turun']?.toString() ?? '0';

        // Tangani foto: bisa berupa null / empty / single path / multiple paths (pisah koma atau |)
        String? fotoPathRaw = penjualan['fupload']?.toString();
        String? fileNameRaw = penjualan['file_name']?.toString();

        if (fotoPathRaw != null && fotoPathRaw.trim().isNotEmpty) {
          // support multiple paths mis. "path1.jpg,path2.jpg" atau "path1.jpg|path2.jpg"
          List<String> paths = fotoPathRaw.split(RegExp(r'[,\|]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

          // Jika file_name berisi banyak nama, juga pecah menjadi list
          List<String> names = [];
          if (fileNameRaw != null && fileNameRaw.trim().isNotEmpty) {
            names = fileNameRaw.split(RegExp(r'[,\|]')).map((s) => s.trim()).toList();
          }

          for (int i = 0; i < paths.length; i++) {
            String path = paths[i];
            File fotoFile = File(path);
            if (fotoFile.existsSync()) {
              String filename = (i < names.length && names[i].isNotEmpty) ? names[i] : path.split('/').last;
              try {
                request.files.add(await http.MultipartFile.fromPath(
                  'file_name[]', // tetap gunakan array name jika backend menerima multiple
                  path,
                  filename: filename,
                ));
                print("[DEBUG] Menambahkan file: $path (as $filename)");
              } catch (e) {
                print("[WARNING] Gagal menambahkan file $path : $e");
              }
            } else {
              print("[WARNING] Foto tidak ditemukan di path: $path");
            }
          }
        } else {
          print("[DEBUG] Tidak ada foto untuk ID: $penjualanId");
        }

        try {
          print("[DEBUG] Mengirim multipart POST untuk ID: $penjualanId ...");
          var streamedResponse = await request.send();
          var response = await http.Response.fromStream(streamedResponse);

          print("[DEBUG] Response code (ID $penjualanId): ${response.statusCode}");
          print("[DEBUG] Response body (ID $penjualanId): ${response.body}");

          if (response.statusCode == 200 || response.statusCode == 201) {
            print("[SUCCESS] Data berhasil dikirim (ID: $penjualanId)");

            // update status lokal
            await PenjualanTiketService.instance
                .updatePenjualanStatus(penjualanId, 'Y');

            dataSent++;
            double progress = dataSent / totalData;
            setState(() {
              _pushDataProgress = progress;
            });
          } else {
            print("[FAILED] Gagal kirim data (ID: $penjualanId). Pastikan backend menerima request.fields dan file_name[] sesuai format.");
          }
        } catch (e) {
          print("[ERROR] Exception saat mengirim ID $penjualanId: $e");
        }
      }

      await _getListTransaksi();
    } else {
      print("Tidak ada data dengan status 'N' untuk dikirim.");
    }

    setState(() {
      _isPushingData = false;
      _pushDataProgress = 0.0;
    });

    print("=== PUSH DATA SELESAI ===");
  }


  Future<void> _getListTransaksi() async {
    List<Map<String, dynamic>> penjualanData = await PenjualanTiketService.instance.getDataPenjualan();
    setState(() {
      listPenjualan = penjualanData;      kotaTujuanList = penjualanData
          .map((e) => e['rute_kota'] as String)
          .toList();
    });

    if (listPenjualan.isEmpty) {
      print('Tidak ada data dalam tabel Penjualan Tiket.');
    } else {
      print('Data ditemukan dalam tabel Penjualan Tiket. ${kotaTujuanList}');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ❗ PERBAIKAN: Jangan deklarasikan ulang selectedKotaTujuan di sini!
    // String? selectedKotaTujuan;  // Hapus baris ini

    // ================================
    // GROUP DATA BERDASARKAN RUTE KOTA
    // ================================
    Map<String, List<Map<String, dynamic>>> groupedByRuteKota = {};

    for (var item in listPenjualan) {
      final ruteKota = item['rute_kota']?.trim() ?? '-';

      groupedByRuteKota.putIfAbsent(ruteKota, () => []);
      groupedByRuteKota[ruteKota]!.add(item);
    }


    // TOTAL SEMUA PENUMPANG
    num totalSemuaPenumpang = listPenjualan.fold(
      0,
          (total, item) => total + (item['jumlah_tiket'] ?? 0),
    );

    // SISA PENUMPANG (contoh logika: subtotal per rute dikurang kapasitas?)
    // Jika yang dimaksud sisa penjualan = semua tiket yg status != 'Y'
    num sisaPenumpang = listPenjualan
        .where((e) => (e['is_turun'] ?? 0) == 0) // BELUM TURUN
        .fold(0, (tot, item) => tot + (item['jumlah_tiket'] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Penjualan Tiket'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_upload, color: Colors.green, size: 30),
            onPressed: _pushDataPenjualan,
            tooltip: 'Kirim Data',
          ),
        ],
        // bottom: PreferredSize(
        //   preferredSize: Size.fromHeight(90),
        //   child: Padding(
        //     padding: EdgeInsets.all(10),
        //     child: DropdownButtonFormField<String>(
        //       isExpanded: true,
        //       value: selectedKotaTujuan.isEmpty ? null : selectedKotaTujuan,
        //       decoration: InputDecoration(
        //         labelText: 'Pilih Kota Tujuan',
        //         border: OutlineInputBorder(),
        //         prefixIcon: Icon(Icons.location_city),
        //       ),
        //       items: kotaTujuanList.map((String kota) {
        //         return DropdownMenuItem<String>(
        //           value: kota,
        //           child: Text(kota, overflow: TextOverflow.ellipsis),
        //         );
        //       }).toList(),
        //       onChanged: (value) {
        //         setState(() => selectedKotaTujuan = value ?? '');
        //         if (value != null) _searchRuteKota(value);
        //       },
        //     ),
        //   ),
        // ),
      ),

    body: SafeArea(
    child: Stack(
    children: [
    AbsorbPointer(
    absorbing: _isPushingData,
    child: SingleChildScrollView(
    padding: EdgeInsets.only(
    bottom: MediaQuery.of(context).padding.bottom + 20,
    ),
    child: Column(
    children: [
    ...groupedByRuteKota.entries.map((entry) {
                    String ruteKota = entry.key;
                    List<Map<String, dynamic>> penjualanPerRute = entry.value;

                    num subtotalJumlahTiket = penjualanPerRute.fold(
                      0,
                          (total, pj) => total + (pj['jumlah_tiket'] ?? 0),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Jml')),
                              DataColumn(label: Text('Rute')),
                              DataColumn(label: Text('Nominal')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: penjualanPerRute.map((item) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(item['jumlah_tiket'].toString())),
                                  DataCell(Text(item['rute_kota'].toString())),
                                  DataCell(
                                    Text(formatter.format(item['jumlah_tagihan'])),
                                  ),
                                  DataCell(Text(item['status'].toString())),
                                ],
                              );
                            }).toList(),
                          ),
                        ),

                        Divider(),

                        Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                    Builder(
                    builder: (context) {
                    // CEK APAKAH SEMUA SUDAH TURUN
                    final bool allSudahTurun =
                    penjualanPerRute.every((item) => (item['is_turun'] ?? 0) == 1);

                    return GestureDetector(
                      onTap: allSudahTurun ? null : () async {
                    bool? confirm = await showDialog(
                    context: context,
                    builder: (context) {
                    return AlertDialog(
                    title: Text("Konfirmasi"),
                    content: Text(
                    "Apakah kamu yakin semua penumpang di rute ini sudah turun?",
                    ),
                    actions: [
                    TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text("Batal"),
                    ),
                    ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text("Iya"),
                    ),
                    ],
                    );
                    },
                    );

                    // Jika user tekan "Iya"
                    if (confirm == true) {
                    setState(() {
                      isCheckedPerRute[ruteKota] =
                          penjualanPerRute.every((item) => item['is_turun'] == 1);
                    });

                    await PenjualanTiketService.instance.updateIsTurunByRute(
                    ruteKota,
                    1,
                    );

                    print("UPDATE is_turun -> 1 untuk rute: $ruteKota");

                    // Refresh data dari database biar UI sesuai
                    await _getListTransaksi();
                    }
                    },
                    child: Opacity(
                    opacity: allSudahTurun ? 0.4 : 1.0,
                    child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                    color: allSudahTurun
                    ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                    color: allSudahTurun ? Colors.red : Colors.green,
                    ),
                    ),
                    child: Icon(
                    allSudahTurun ? Icons.close : Icons.check,
                    color: allSudahTurun ? Colors.red : Colors.green,
                    size: 16,
                    ),
                    ),
                    ),
                    );
                    },
                    ),

                    SizedBox(width: 10),
                    Text("Jml. Penumpang: $subtotalJumlahTiket"),
                    SizedBox(width: 16),
                    ],
                    ),
                    ],
                    );
                  }).toList(),

                  SizedBox(height: 20),

                  // ============================
                  // TOTAL SEMUA PENUMPANG
                  // ============================
                  Container(
                    margin: EdgeInsets.all(12),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blueAccent),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TOTAL SEMUA PENUMPANG",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        Text(
                          totalSemuaPenumpang.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ============================
                  // SISA PENUMPANG (BARU)
                  // ============================
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SISA PENUMPANG",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        Text(
                          sisaPenumpang.toString(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 25),
                ],
              ),
            ),
          ),

          // ❗ Overlay Progress Upload
          if (_isPushingData)
            Container(
              color: Colors.grey.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(value: _pushDataProgress),
              ),
            ),
        ],
      ),
     ),
    );
  }


}
