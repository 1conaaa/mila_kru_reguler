import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kru_reguler/database/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
      List<Map<String, dynamic>> result = await databaseHelper.getDataRuteKota(searchQuery);
      setState(() {
        listPenjualan = result;
      });
    } catch (e) {
      print('Error saat memanggil getDataRuteKota: $e');
    }
  }


  void _pushDataPenjualan() async {
    setState(() {
      _isPushingData = true;
      _pushDataProgress = 0.0;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    await databaseHelper.initDatabase();

    // Mendapatkan data penjualan dengan kondisi status='N'
    List<Map<String, dynamic>> penjualanData = await databaseHelper.getPenjualanByStatus('N');
    print('data penjualan : $penjualanData');
    if (penjualanData.isNotEmpty) {
      // Kirim data penjualan ke server
      int totalData = penjualanData.length;
      int dataSent = 0;
      for (var penjualan in penjualanData) {
        String tanggalTransaksi = penjualan['tanggal_transaksi'];
        String kategoriTiket = penjualan['kategori_tiket'];
        int rit = penjualan['rit'];
        String noPol = penjualan['no_pol'];
        int idBus = penjualan['id_bus'];
        String kodeTrayek = penjualan['kode_trayek'];
        int idUser = penjualan['id_user'];
        int idGroup = penjualan['id_group'];
        String idKotaBerangkat = penjualan['kota_berangkat'];
        String idKotaTujuan = penjualan['kota_tujuan'];
        int jumlahTiket = penjualan['jumlah_tiket'];
        double jumlahTagihan = penjualan['jumlah_tagihan'];
        double hargaKantor = penjualan['harga_kantor'];
        String status = penjualan['status'];
        String namaPembeli = penjualan['nama_pembeli'];
        String noTelepon = penjualan['no_telepon'];
        String keterangan = penjualan['keterangan'];

        String apiUrl = 'https://apibis.iconaaa.net/api/penjualantiket';
        String queryParams = '?tgl_transaksi=${Uri.encodeFull(tanggalTransaksi)}'
            '&kategori=${Uri.encodeFull(kategoriTiket)}'
            '&rit=$rit'
            '&no_pol=${Uri.encodeFull(noPol)}'
            '&id_bus=$idBus'
            '&kode_trayek=${Uri.encodeFull(kodeTrayek)}'
            '&id_personil=$idUser'
            '&id_group=$idGroup'
            '&id_kota_berangkat=${Uri.encodeFull(idKotaBerangkat)}'
            '&id_kota_tujuan=${Uri.encodeFull(idKotaTujuan)}'
            '&jml_naik=$jumlahTiket'
            '&pendapatan=$jumlahTagihan'
            '&harga_kantor=$hargaKantor'
            '&nama_pelanggan=${Uri.encodeFull(namaPembeli)}'
            '&no_telepon=${Uri.encodeFull(noTelepon)}'
            '&status=$status'
            '&keterangan=${Uri.encodeFull(keterangan)}';

        String apiUrlWithParams = apiUrl + queryParams;
        print('link api $apiUrlWithParams - $token');
        try {
          final response = await http.post(
            Uri.parse(apiUrlWithParams),
            headers: {
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Berhasil mengirim data, perbarui status menjadi 'Y' pada tabel
            int id = penjualan['id'];
            await databaseHelper.updatePenjualanStatus(id, 'Y');
            await databaseHelper.closeDatabase();
            // Hitung progress pengiriman data
            dataSent++;
            double progress = dataSent / totalData;
            setState(() {
              _pushDataProgress = progress;
            });
          } else {
            print('Gagal mengirim data penjualan. Status code: ${response.statusCode}');
          }
        } catch (e) {
          print('Terjadi kesalahan saat mengirim data penjualan: $e');
        }
      }
      // Perbarui list penjualan setelah mengubah status
      await _getListTransaksi();

      print('Data penjualan dikirim');
    } else {
      print('Tidak ada data penjualan dengan status \'N\'');
    }
    setState(() {
      _isPushingData = false;
      _pushDataProgress = 0.0;
    });
  }

  Future<void> _getListTransaksi() async {
    List<Map<String, dynamic>> penjualanData = await databaseHelper.getDataPenjualan();
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
