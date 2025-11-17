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
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> listPenjualan = [];
  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
  bool _isPushingData = false;
  double _pushDataProgress = 0.0;
  String searchQuery = ''; // Field untuk menyimpan nilai pencarian

  List<String> kotaTujuanList = []; // List untuk kota tujuan unik
  String selectedKotaTujuan = ''; // atau sesuaikan dengan nilai awal yang sesuai dengan aplikasi Anda


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
        print("\n=== KIRIM DATA ID: ${penjualan['id']} ===");

        /// ambil foto
        String? fotoPath = penjualan['fupload'];
        String? fileName = penjualan['file_name'];

        print("[DEBUG] Foto path: $fotoPath | file_name: $fileName");

        String apiUrl = "https://apimila.sysconix.id/api/penjualantiket";

        // build query params
        String queryParams =
            '?tgl_transaksi=${Uri.encodeFull(penjualan['tanggal_transaksi'])}'
            '&kategori=${Uri.encodeFull(penjualan['kategori_tiket'])}'
            '&rit=${penjualan['rit']}'
            '&no_pol=${Uri.encodeFull(penjualan['no_pol'])}'
            '&id_bus=${penjualan['id_bus']}'
            '&kode_trayek=${Uri.encodeFull(penjualan['kode_trayek'])}'
            '&id_personil=${penjualan['id_user']}'
            '&id_group=${penjualan['id_group']}'
            '&id_kota_berangkat=${Uri.encodeFull(penjualan['kota_berangkat'])}'
            '&id_kota_tujuan=${Uri.encodeFull(penjualan['kota_tujuan'])}'
            '&jml_naik=${penjualan['jumlah_tiket']}'
            '&pendapatan=${penjualan['jumlah_tagihan']}'
            '&harga_kantor=${penjualan['harga_kantor']}'
            '&nama_pelanggan=${Uri.encodeFull(penjualan['nama_pembeli'])}'
            '&no_telepon=${Uri.encodeFull(penjualan['no_telepon'])}'
            '&status=${penjualan['status']}'
            '&keterangan=${Uri.encodeFull(penjualan['keterangan'])}';

        var uri = Uri.parse(apiUrl + queryParams);
        var request = http.MultipartRequest("POST", uri);

        request.headers['Authorization'] = 'Bearer $token';

        // Jika ada foto, kirim sebagai multipart
        if (fotoPath != null && fotoPath.isNotEmpty) {
          File fotoFile = File(fotoPath);
          if (fotoFile.existsSync()) {
            request.files.add(
              await http.MultipartFile.fromPath(
                'file_name[]',     // HARUS sesuai backend
                fotoPath,
                filename: fileName ?? "foto.jpg",
              ),
            );

            print("[DEBUG] Foto ditambahkan ke request multipart");
          } else {
            print("[WARNING] Foto tidak ditemukan di path: $fotoPath");
          }
        }

        try {
          print("[DEBUG] Mengirim multipart POST...");
          var streamedResponse = await request.send();

          var response = await http.Response.fromStream(streamedResponse);

          print("[DEBUG] Response code: ${response.statusCode}");
          print("[DEBUG] Response body: ${response.body}");

          if (response.statusCode == 200 || response.statusCode == 201) {
            print("[SUCCESS] Data berhasil dikirim (ID: ${penjualan['id']})");

            // update status lokal
            await PenjualanTiketService.instance
                .updatePenjualanStatus(penjualan['id'], 'Y');

            dataSent++;
            double progress = dataSent / totalData;

            setState(() {
              _pushDataProgress = progress;
            });
          } else {
            print("[FAILED] Gagal kirim data!");
          }
        } catch (e) {
          print("[ERROR] Exception: $e");
        }
      }

      await _getListTransaksi();
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
    String? selectedKotaTujuan; // Perbarui agar dapat diakses di bawah ini

    Map<String, List<Map<String, dynamic>>> groupedByRuteKota = {};
    listPenjualan.forEach((item) {
      String ruteKota = item['rute_kota'];
      if (groupedByRuteKota.containsKey(ruteKota)) {
        groupedByRuteKota[ruteKota]!.add(item);
      } else {
        groupedByRuteKota[ruteKota] = [item];
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Data Penjualan Tiket'),
        automaticallyImplyLeading: false, // Menghilangkan icon arrow back
        actions: [
          IconButton(
            icon: Icon(
              Icons.cloud_upload,
              color: Colors.green, // Warna hijau pada ikon
              size: 30.0, // Ukuran ikon yang diperbesar
            ),
            onPressed: () {
              _pushDataPenjualan();
            },
            tooltip: 'Kirim Data',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80.0), // Tinggi PreferredSize agar muat Dropdown
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: // Perbaiki bagian build untuk DropdownButtonFormField
            DropdownButtonFormField<String>(
              value: selectedKotaTujuan,
              decoration: InputDecoration(
                labelText: 'Pilih Kota Tujuan',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              items: kotaTujuanList.map((String kota) {
                return DropdownMenuItem<String>(
                  value: kota, // Pastikan 'value' adalah String
                  child: Text(kota), // Gunakan 'kota' sebagai teks
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedKotaTujuan = value;
                });
                if (selectedKotaTujuan != null) {
                  _searchRuteKota(selectedKotaTujuan!);
                }
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isPushingData, // Disable interaction when pushing data
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...groupedByRuteKota.entries.map((entry) {
                    String ruteKota = entry.key;
                    List<Map<String, dynamic>> penjualanPerRute = entry.value;

                    // Calculate subtotal jumlah_tiket for this rute_kota
                    num subtotalJumlahTiket = penjualanPerRute.fold(
                        0, (total, penjualan) => total + penjualan['jumlah_tiket']);

                    return Column(
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
                                  DataCell(Text(
                                    formatter.format(item['jumlah_tagihan']),
                                  )),
                                  DataCell(Text(item['status'].toString())),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        Divider(), // Add separator between each rute_kota table
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Jml.Penumpang: $subtotalJumlahTiket'),
                            SizedBox(width: 16),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          if (_isPushingData)
            Container(
              color: Colors.grey.withOpacity(0.5), // Semi-transparent grey background
              child: Center(
                child: CircularProgressIndicator(
                  value: _pushDataProgress,
                ),
              ),
            ),
        ],
      ),
    );
  }


}
