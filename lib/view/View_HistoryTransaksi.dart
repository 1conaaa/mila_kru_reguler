import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:mila_kru_reguler/services/rit_user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class HistroyTransaksi extends StatefulWidget {
  @override
  _HistroyTransaksiState createState() => _HistroyTransaksiState();
}

class _HistroyTransaksiState extends State<HistroyTransaksi> {
  DatabaseHelper databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> listPenjualan = [];
  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp',decimalDigits: 0,);
  bool _isPushingData = false;
  bool _isLoadingSync = false;
  double _pushDataProgress = 0.0;
  String searchQuery = '';

  List<String> kotaTujuanList = [];
  String selectedKotaTujuan = 'SEMUA';

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

  // ============================================
  // SYNC DATA BATAL
  // ============================================
  Future<void> _syncBatal() async {
    if (listPenjualan.isEmpty) {
      await _getListTransaksi();
      if (listPenjualan.isEmpty) {
        _showToast("Tidak ada data bus. Silakan tambahkan data penjualan terlebih dahulu.");
        return;
      }
    }

    setState(() => _isLoadingSync = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        _showToast("Token tidak ditemukan. Silakan login ulang.");
        setState(() => _isLoadingSync = false);
        return;
      }

      Map<String, dynamic>? busData;
      for (var item in listPenjualan) {
        if (item['no_pol'] != null && item['id_bus'] != null) {
          busData = item;
          break;
        }
      }

      if (busData == null) {
        _showToast("Data bus tidak lengkap.");
        setState(() => _isLoadingSync = false);
        return;
      }

      final noPol = busData['no_pol']?.toString() ?? '';
      final idBus = busData['id_bus'] as int? ?? 0;
      final rit = busData['rit']?.toString() ?? '1';

      await PenjualanTiketService.instance.syncBatalData(
        token: token,
        noPol: noPol,
        idBus: idBus,
        rit: rit,
      );

      await _getListTransaksi();

      final dataBatal = await PenjualanTiketService.instance.getPenjualanBatal();

      if (dataBatal.isNotEmpty) {
        _showToast("✅ ${dataBatal.length} data pembatalan ditemukan (warna merah)");
      } else {
        _showToast("ℹ️ Tidak ada data pembatalan");
      }

    } catch (e) {
      print('❌ Error sync: $e');
      _showToast("Gagal sync data: ${e.toString()}");
    } finally {
      setState(() => _isLoadingSync = false);
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
    List<Map<String, dynamic>> penjualanData = await PenjualanTiketService.instance.getPenjualanByStatus('N');

    if (penjualanData.isNotEmpty) {
      int totalData = penjualanData.length;
      int dataSent = 0;

      for (var penjualan in penjualanData) {
        final penjualanId = penjualan['id'];
        print("\n=== KIRIM DATA ID: $penjualanId ===");

        String apiUrl = "https://apimila.milaberkah.com/api/penjualantiket";

        var uri = Uri.parse(apiUrl);
        var request = http.MultipartRequest("POST", uri);

        request.headers['Authorization'] = 'Bearer $token';

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

        String? fotoPathRaw = penjualan['fupload']?.toString();
        String? fileNameRaw = penjualan['file_name']?.toString();

        if (fotoPathRaw != null && fotoPathRaw.trim().isNotEmpty) {
          List<String> paths = fotoPathRaw.split(RegExp(r'[,\|]'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();

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
                  'file_name[]',
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

            await PenjualanTiketService.instance.updatePenjualanStatus(penjualanId, 'Y');

            dataSent++;
            double progress = dataSent / totalData;
            setState(() {
              _pushDataProgress = progress;
            });
          } else {
            print("[FAILED] Gagal kirim data (ID: $penjualanId).");
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

  Future<int> getActiveRit() async {
    final int ritAktif = await RitUserService.instance.getActiveRit();
    print('[RIT] RIT aktif dari service = $ritAktif');
    return ritAktif;
  }

  Future<void> _getListTransaksi() async {
    debugPrint("🔄 Ambil data transaksi");

    final int rit = await getActiveRit();

    List<Map<String, dynamic>> penjualanData =
    await PenjualanTiketService.instance.getDataPenjualan();

    final ruteUrutan = await databaseHelper.getRuteTrayekUrutan(rit);

    Map<String, int> urutanKota = {};

    for (var r in ruteUrutan) {
      final namaKota = r['nama_kota']?.toString();
      final noUrut = r['no_urut_kota'] ?? 0;

      if (namaKota != null) {
        urutanKota[namaKota] = noUrut;
      }
    }

    final Set<String> kotaTujuanSet = {};

    for (var e in penjualanData) {
      final rute = e['rute_kota']?.toString();

      if (rute != null && rute.contains(' - ')) {
        final parts = rute.split(' - ');
        final kotaTujuan = parts.last.trim();
        kotaTujuanSet.add(kotaTujuan);
      }
    }

    List<String> kotaTujuanSorted = kotaTujuanSet.toList();

    kotaTujuanSorted.sort((a, b) {
      final urutA = urutanKota[a] ?? 999;
      final urutB = urutanKota[b] ?? 999;
      return urutA.compareTo(urutB);
    });

    setState(() {
      listPenjualan = penjualanData;
      kotaTujuanList = ['SEMUA', ...kotaTujuanSorted];
    });

    debugPrint("📍 Kota tujuan unik: $kotaTujuanList");
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final List<Map<String, dynamic>> filteredPenjualan = selectedKotaTujuan == 'SEMUA' ? listPenjualan : listPenjualan.where((e) {
      final rute = e['rute_kota']?.toString() ?? '';
      if (!rute.contains(' - ')) return false;
      final kotaTujuan = rute.split(' - ').last.trim();
      return kotaTujuan == selectedKotaTujuan;
    }).toList();

    final bool allTujuanSudahTurun = selectedKotaTujuan != 'SEMUA' && filteredPenjualan.isNotEmpty && filteredPenjualan.every((e) => (e['is_turun'] ?? 0) == 1,);

    final num totalPerKotaTujuan = selectedKotaTujuan == 'SEMUA' ? 0 : filteredPenjualan.fold(0,(total, item) => total + (item['jumlah_tiket'] ?? 0),);

    final Map<String, List<Map<String, dynamic>>> groupedByRuteKota = {};

    for (final item in filteredPenjualan) {
      final ruteKota = item['rute_kota']?.trim() ?? '-';
      groupedByRuteKota.putIfAbsent(ruteKota, () => []);
      groupedByRuteKota[ruteKota]!.add(item);
    }

    final num totalSemuaPenumpang = listPenjualan.fold(
      0,
          (total, item) => total + (item['jumlah_tiket'] ?? 0),
    );

    final num sisaPenumpang = listPenjualan
        .where((e) => (e['is_turun'] ?? 0) == 0)
        .fold(0, (tot, item) => tot + (item['jumlah_tiket'] ?? 0));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Penjualan Tiket'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.sync,
              color: _isLoadingSync ? Colors.grey : Colors.orange,
              size: 28,
            ),
            tooltip: 'Sync Data Batal',
            onPressed: _isLoadingSync ? null : _syncBatal,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.green, size: 28),
            tooltip: 'Kirim Data',
            onPressed: _isPushingData ? null : _pushDataPenjualan,
          ),
        ],
      ),

      body: SafeArea(
        child: Stack(
          children: [
            AbsorbPointer(
              absorbing: _isPushingData || _isLoadingSync,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 20,
                ),
                child: Column(
                  children: [
                    // DROPDOWN FILTER KOTA TUJUAN
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Colors.blueGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedKotaTujuan,
                              isDense: true,
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                labelText: 'Filter Kota Tujuan',
                              ),
                              items: kotaTujuanList.map((kota) {
                                return DropdownMenuItem(
                                  value: kota,
                                  child: Text(
                                    kota,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedKotaTujuan = value ?? 'SEMUA';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // TOTAL PER KOTA TUJUAN
                    if (selectedKotaTujuan != 'SEMUA')
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: allTujuanSudahTurun
                              ? Colors.red.withOpacity(0.08)
                              : Colors.green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: allTujuanSudahTurun ? Colors.red : Colors.green,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              allTujuanSudahTurun ? Icons.check_circle : Icons.warning_amber,
                              color: allTujuanSudahTurun ? Colors.red : Colors.green,
                              size: 25,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "TOTAL PENUMPANG TUJUAN",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedKotaTujuan,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: allTujuanSudahTurun ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: allTujuanSudahTurun ? Colors.redAccent : Colors.green,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                totalPerKotaTujuan.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (selectedKotaTujuan != 'SEMUA')
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 250),
                          opacity: allTujuanSudahTurun ? 0.5 : 1,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              allTujuanSudahTurun ? Icons.lock : Icons.check_circle_outline,
                            ),
                            label: Text(
                              allTujuanSudahTurun
                                  ? "Semua Penumpang Sudah Turun"
                                  : "Konfirmasi Semua Penumpang Tujuan $selectedKotaTujuan",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: allTujuanSudahTurun ? Colors.grey : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: allTujuanSudahTurun ? 0 : 3,
                            ),
                            onPressed: allTujuanSudahTurun
                                ? null
                                : () async {
                              final bool? confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Konfirmasi"),
                                  content: Text(
                                    "Semua penumpang tujuan $selectedKotaTujuan "
                                        "akan ditandai sudah turun.\n\n"
                                        "Tindakan ini tidak dapat dibatalkan.",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text("Batal"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text("Iya"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await PenjualanTiketService.instance
                                    .updateIsTurunByKotaTujuanLocal(
                                  selectedKotaTujuan,
                                  1,
                                );

                                setState(() {
                                  listPenjualan = listPenjualan.map((e) {
                                    if ((e['is_turun'] ?? 0) == 0 &&
                                        e['rute_kota'] != null &&
                                        e['rute_kota'].toString().endsWith(selectedKotaTujuan)) {
                                      return {
                                        ...e,
                                        'is_turun': 1,
                                      };
                                    }
                                    return e;
                                  }).toList();
                                });
                              }
                            },
                          ),
                        ),
                      ),

                    // ================================
                    // LIST DATA PER RUTE - DENGAN SCROLL
                    // ================================
                    ...groupedByRuteKota.entries.map((entry) {
                      final String ruteKota = entry.key;
                      final List<Map<String, dynamic>> penjualanPerRute = entry.value;

                      final num subtotalJumlahTiket = penjualanPerRute.fold(0,(total, pj) => total + (pj['jumlah_tiket'] ?? 0),);

                      final bool allSudahTurun = penjualanPerRute.every(
                            (item) => (item['is_turun'] ?? 0) == 1,
                      );

                      final bool hasBatalInRute = penjualanPerRute.any(
                            (item) => (item['is_batal']?.toString() ?? '0') == '1',
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Rute
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasBatalInRute ? Colors.red.shade50 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: hasBatalInRute ? Colors.red.shade300 : Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ruteKota,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: hasBatalInRute ? Colors.red : null,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ============================================
                          // TABLE DENGAN LEBAR KOLOM YANG DIATUR
                          // ============================================
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: screenWidth - 24,
                                ),
                                child: DataTable(
                                  columnSpacing: 16, // jarak antar kolom
                                  headingRowColor: MaterialStateProperty.all(
                                    hasBatalInRute ? Colors.red.shade100 : Colors.grey.shade200,
                                  ),
                                  columns: const [
                                    // Kolom Jml - lebar 50
                                    DataColumn(
                                      label: SizedBox(
                                        width: 50,
                                        child: Text('Jml', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    // Kolom Rute - lebar 200
                                    DataColumn(
                                      label: SizedBox(
                                        width: 200,
                                        child: Text('Rute', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    // Kolom Nominal - lebar 150
                                    DataColumn(
                                      label: SizedBox(
                                        width: 150,
                                        child: Text('Nominal', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    // Kolom Status - lebar 80
                                    DataColumn(
                                      label: SizedBox(
                                        width: 80,
                                        child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                  rows: penjualanPerRute.map((item) {
                                    final bool isBatal = (item['is_batal']?.toString() ?? '0') == '1';
                                    final bool isTurun = (item['is_turun'] ?? 0) == 1;
                                    final String statusKirim = item['status']?.toString() ?? 'N';

                                    return DataRow(
                                      color: MaterialStateProperty.all(
                                        isBatal ? Colors.red.shade50 : (isTurun ? Colors.green.shade50 : null),
                                      ),
                                      cells: [
                                        // Jml
                                        DataCell(
                                          Container(
                                            width: 50,
                                            child: Text(
                                              item['jumlah_tiket'].toString(),
                                              style: TextStyle(
                                                fontWeight: isBatal ? FontWeight.bold : FontWeight.normal,
                                                color: isBatal ? Colors.red : null,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                        // Rute
                                        DataCell(
                                          Container(
                                            width: 200,
                                            child: Text(
                                              item['rute_kota']?.toString() ?? '-',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isBatal ? FontWeight.bold : FontWeight.normal,
                                                color: isBatal ? Colors.red : null,
                                                decoration: isBatal ? TextDecoration.lineThrough : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        // Nominal
                                        DataCell(
                                          Container(
                                            width: 150,
                                            child: Text(
                                              formatter.format(item['jumlah_tagihan'] ?? 0),
                                              style: TextStyle(
                                                fontWeight: isBatal ? FontWeight.bold : FontWeight.normal,
                                                color: isBatal ? Colors.red : null,
                                                decoration: isBatal ? TextDecoration.lineThrough : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        // Status
                                        DataCell(
                                          Container(
                                            width: 80,
                                            child: Center(
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isBatal
                                                      ? Colors.red.shade100
                                                      : (statusKirim == 'Y' ? Colors.green.shade100 : Colors.orange.shade100),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  isBatal ? "BATAL" : statusKirim,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: isBatal
                                                        ? Colors.red
                                                        : (statusKirim == 'Y' ? Colors.green : Colors.orange),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),

                          const Divider(),

                          // ACTION + SUBTOTAL
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                GestureDetector(
                                  onTap: allSudahTurun
                                      ? null
                                      : () async {
                                    final bool? confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Konfirmasi"),
                                        content: const Text(
                                          "Apakah kamu yakin semua penumpang di rute ini sudah turun?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text("Batal"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text("Iya"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await PenjualanTiketService.instance
                                          .updateIsTurunByRute(ruteKota, 1);

                                      setState(() {
                                        listPenjualan = listPenjualan.map((e) {
                                          if (e['rute_kota'] == ruteKota && (e['is_turun'] ?? 0) == 0) {
                                            return {
                                              ...e,
                                              'is_turun': 1,
                                            };
                                          }
                                          return e;
                                        }).toList();
                                      });
                                    }
                                  },
                                  child: Opacity(
                                    opacity: allSudahTurun ? 0.4 : 1,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
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
                                        size: 16,
                                        color: allSudahTurun ? Colors.red : Colors.green,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text("Jml. Penumpang: $subtotalJumlahTiket"),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    // TOTAL & SISA
                    _buildTotalBox(
                      title: "TOTAL SEMUA PENUMPANG",
                      value: totalSemuaPenumpang,
                      color: Colors.blue,
                    ),

                    _buildTotalBox(
                      title: "SISA PENUMPANG",
                      value: sisaPenumpang,
                      color: Colors.orange,
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),

            // OVERLAY LOADING
            if (_isPushingData)
              Container(
                color: Colors.grey.withOpacity(0.5),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _pushDataProgress,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mengirim data... ${(_pushDataProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

            if (_isLoadingSync)
              Container(
                color: Colors.grey.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.orange),
                      SizedBox(height: 12),
                      Text(
                        'Sync data pembatalan...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBox({
    required String title,
    required num value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}