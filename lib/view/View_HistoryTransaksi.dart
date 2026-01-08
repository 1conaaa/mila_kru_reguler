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
  String selectedKotaTujuan = 'SEMUA'; // atau sesuaikan dengan nilai awal yang sesuai dengan aplikasi Anda

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
  void _markLocalDataTurunByTujuan(String kotaTujuan) {
    setState(() {
      listPenjualan = listPenjualan.map((item) {
        final rute = item['rute_kota']?.toString() ?? '';

        if (item['is_turun'] == 0 && rute.endsWith(' - $kotaTujuan')) {
          return {
            ...item,
            'is_turun': 1,
          };
        }

        return item;
      }).toList();
    });
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
    debugPrint("🔄 Ambil data transaksi");

    List<Map<String, dynamic>> penjualanData =
    await PenjualanTiketService.instance.getDataPenjualan();

    final Set<String> kotaTujuanSet = {};

    for (var e in penjualanData) {
      final rute = e['rute_kota']?.toString();
      if (rute != null && rute.contains(' - ')) {
        final parts = rute.split(' - ');
        final kotaTujuan = parts.last.trim(); // ⬅️ AMBIL TUJUAN
        kotaTujuanSet.add(kotaTujuan);
      }
    }

    setState(() {
      listPenjualan = penjualanData;
      kotaTujuanList = ['SEMUA', ...kotaTujuanSet.toList()];
    });

    debugPrint("📍 Kota tujuan unik: $kotaTujuanList");
  }


  @override
  Widget build(BuildContext context) {
    // ================================
    // FILTER BERDASARKAN KOTA TUJUAN
    // ================================
    final List<Map<String, dynamic>> filteredPenjualan =
    selectedKotaTujuan == 'SEMUA'
        ? listPenjualan
        : listPenjualan.where((e) {
      final rute = e['rute_kota']?.toString() ?? '';
      if (!rute.contains(' - ')) return false;
      final kotaTujuan = rute.split(' - ').last.trim();
      return kotaTujuan == selectedKotaTujuan;
    }).toList();

    debugPrint(
      "🔍 Filter TUJUAN: $selectedKotaTujuan | data: ${filteredPenjualan.length}",
    );

    // ==========================================
    // 2️⃣ FLAG STATUS (INI YANG KAMU TANYAKAN)
    // ==========================================
    final bool allTujuanSudahTurun =
        selectedKotaTujuan != 'SEMUA' &&
            filteredPenjualan.isNotEmpty &&
            filteredPenjualan.every(
                  (e) => (e['is_turun'] ?? 0) == 1,
            );

    // ================================
    // TOTAL PENUMPANG PER KOTA TUJUAN
    // ================================

    final num totalPerKotaTujuan =
    selectedKotaTujuan == 'SEMUA'
        ? 0
        : filteredPenjualan.fold(
      0,
          (total, item) => total + (item['jumlah_tiket'] ?? 0),
    );

    debugPrint(
      "📍 Total tujuan $selectedKotaTujuan : $totalPerKotaTujuan",
    );


    debugPrint("🔄 build() dipanggil");

    // ================================
    // PREPARE DATA
    // ================================
    debugPrint("📦 Total filteredPenjualan: ${filteredPenjualan.length}");

    /// GROUP DATA BERDASARKAN RUTE KOTA
    final Map<String, List<Map<String, dynamic>>> groupedByRuteKota = {};

    for (final item in filteredPenjualan) {
      final ruteKota = item['rute_kota']?.trim() ?? '-';
      groupedByRuteKota.putIfAbsent(ruteKota, () => []);
      groupedByRuteKota[ruteKota]!.add(item);
    }

    debugPrint("🗂️ Jumlah grup rute: ${groupedByRuteKota.length}");

    /// TOTAL SEMUA PENUMPANG
    final num totalSemuaPenumpang = listPenjualan.fold(
      0,
          (total, item) => total + (item['jumlah_tiket'] ?? 0),
    );
    debugPrint("👥 Total semua penumpang: $totalSemuaPenumpang");

    /// SISA PENUMPANG (BELUM TURUN)
    final num sisaPenumpang = listPenjualan
        .where((e) => (e['is_turun'] ?? 0) == 0)
        .fold(0, (tot, item) => tot + (item['jumlah_tiket'] ?? 0));

    debugPrint("⏳ Sisa penumpang (belum turun): $sisaPenumpang");

    // ================================
    // UI
    // ================================
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Penjualan Tiket'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload, color: Colors.green, size: 30),
            tooltip: 'Kirim Data',
            onPressed: () {
              debugPrint("☁️ Tombol Kirim Data ditekan");
              _pushDataPenjualan();
            },
          ),
        ],
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
                    // ================================
                    // DROPDOWN FILTER KOTA TUJUAN
                    // ================================
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
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                debugPrint("📌 Dropdown kota dipilih: $value");
                                setState(() {
                                  selectedKotaTujuan = value ?? 'SEMUA';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ================================
                    // TOTAL PER KOTA TUJUAN (FILTER)
                    // ================================
                    if (selectedKotaTujuan != 'SEMUA')
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
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
                              allTujuanSudahTurun ? Icons.check_circle : Icons.groups,
                              color: allTujuanSudahTurun ? Colors.red : Colors.green,
                              size: 26,
                            ),
                            const SizedBox(width: 12),

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
                                      color:
                                      allTujuanSudahTurun ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Container(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: allTujuanSudahTurun
                                    ? Colors.redAccent
                                    : Colors.green,
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
                          duration: const Duration(milliseconds: 300),
                          opacity: allTujuanSudahTurun ? 0.5 : 1,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              allTujuanSudahTurun
                                  ? Icons.lock
                                  : Icons.check_circle_outline,
                            ),
                            label: Text(
                              allTujuanSudahTurun
                                  ? "Semua Penumpang Sudah Turun"
                                  : "Konfirmasi Semua Penumpang Tujuan $selectedKotaTujuan",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              allTujuanSudahTurun ? Colors.grey : Colors.green,
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
                              final bool? confirm =
                              await showDialog<bool>(
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
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Batal"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
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

                                // 🔥 UPDATE STATE LOKAL (REALTIME)
                                setState(() {
                                  listPenjualan = listPenjualan.map((e) {
                                    if ((e['is_turun'] ?? 0) == 0 &&
                                        e['rute_kota'] != null &&
                                        e['rute_kota']
                                            .toString()
                                            .endsWith(selectedKotaTujuan)) {
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
                    // LIST DATA PER RUTE
                    // ================================
                    ...groupedByRuteKota.entries.map((entry) {
                      final String ruteKota = entry.key;
                      final List<Map<String, dynamic>> penjualanPerRute = entry.value;

                      debugPrint(
                        "➡️ Render rute: $ruteKota | item: ${penjualanPerRute.length}",
                      );

                      final num subtotalJumlahTiket = penjualanPerRute.fold(
                        0,
                            (total, pj) => total + (pj['jumlah_tiket'] ?? 0),
                      );

                      final bool allSudahTurun = penjualanPerRute.every(
                            (item) => (item['is_turun'] ?? 0) == 1,
                      );

                      debugPrint(
                        "   └─ subtotal: $subtotalJumlahTiket | allSudahTurun: $allSudahTurun",
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          /// TABLE
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
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

                          const Divider(),

                          /// ACTION + SUBTOTAL
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: allSudahTurun
                                    ? null
                                    : () async {
                                  debugPrint("🟢 Klik cek turun rute: $ruteKota");

                                  final bool? confirm =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Konfirmasi"),
                                      content: const Text(
                                        "Apakah kamu yakin semua penumpang di rute ini sudah turun?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            debugPrint("❌ Konfirmasi dibatalkan");
                                            Navigator.pop(context, false);
                                          },
                                          child: const Text("Batal"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            debugPrint("✅ Konfirmasi disetujui");
                                            Navigator.pop(context, true);
                                          },
                                          child: const Text("Iya"),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    debugPrint(
                                      "📝 Update is_turun=1 untuk rute: $ruteKota",
                                    );

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
                                        color: allSudahTurun
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                    child: Icon(
                                      allSudahTurun
                                          ? Icons.close
                                          : Icons.check,
                                      size: 16,
                                      color: allSudahTurun
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),
                              Text("Jml. Penumpang: $subtotalJumlahTiket"),
                              const SizedBox(width: 16),
                            ],
                          ),
                        ],
                      );
                    }).toList(),

                    const SizedBox(height: 20),

                    // ================================
                    // TOTAL & SISA
                    // ================================
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

            /// OVERLAY LOADING
            if (_isPushingData)
              Container(
                color: Colors.grey.withOpacity(0.5),
                child: Center(
                  child: CircularProgressIndicator(
                    value: _pushDataProgress,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ================================
  /// WIDGET BANTU
  /// ================================
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
