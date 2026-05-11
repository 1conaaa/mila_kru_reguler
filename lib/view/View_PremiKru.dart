import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/models/PersenPremiKru.dart';
import 'package:mila_kru_reguler/services/persen_premi_kru_service.dart';

import 'package:mila_kru_reguler/models/setoranKru_model.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

import 'package:mila_kru_reguler/services/premi_harian_kru_service.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';
import 'package:mila_kru_reguler/services/data_pusher_service.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:mila_kru_reguler/services/rit_user_service.dart';

import 'package:mila_kru_reguler/database/database_helper.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mila_kru_reguler/page/bluetooth_service.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

final printerService = BluetoothPrinterService();

class PremiKru extends StatefulWidget {
  @override
  _PremiKruState createState() => _PremiKruState();
}

class _PremiKruState extends State<PremiKru> {
  // Services
  final PremiHarianKruService premiHarianKruService = PremiHarianKruService();
  final SetoranKruService setoranKruService = SetoranKruService();
  final TagTransaksiService tagTransaksiService = TagTransaksiService();
  final DataPusherService dataPusherService = DataPusherService();

  final DatabaseHelper databaseHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> listPremiHarianKru = [];
  late Future<List<SetoranKru>> setoranKruData;

  bool _isPushingData = false;
  double _uploadProgress = 0.0;

  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');
  DateTime? _selectedDate;

  get kodeTrayek => null;

  final UserService _userService = UserService();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];

  @override
  void initState() {
    super.initState();
    setoranKruData = setoranKruService.getAllSetoran();
    _getListPremiKru();
    _loadLastPremiKru();
  }

  //----------------------------------------------------------------------
  // LOAD DATA
  //----------------------------------------------------------------------

  Future<void> _loadLastPremiKru() async {
    await databaseHelper.initDatabase();
    await _getListPremiKru();
    await databaseHelper.closeDatabase();
  }

  Future<void> _getListPremiKru() async {
    print("🔍 Memulai query premi harian kru...");

    List<Map<String, dynamic>> premiKruData =
    await premiHarianKruService.getPremiHarianKruWithKruBis();

    print("📊 Jumlah data hasil query: ${premiKruData.length}");

    if (premiKruData.isEmpty) {
      print("⚠️ Tidak ada data premi harian kru.");
    } else {
      print("✅ Data premi harian kru ditemukan:");

      // Print tiap baris hasil query
      for (int i = 0; i < premiKruData.length; i++) {
        print("➡️ Row ${i + 1}: ${premiKruData[i]}");
      }
    }

    setState(() {
      listPremiHarianKru = premiKruData;
    });
  }


  Future<void> _refreshSetoranKruData() async {
    setState(() {
      setoranKruData = setoranKruService.getAllSetoran();
    });
  }

  //----------------------------------------------------------------------
  // TAG TRANSAKSI
  //----------------------------------------------------------------------

  Future<List<TagTransaksi>> _getAllTagTransaksi() async {
    try {
      return await tagTransaksiService.getAllTagTransaksi();
    } catch (e) {
      print("Error load tag transaksi: $e");
      return [];
    }
  }

  String _getNamaTagFromList(int? idTagTransaksi, List<TagTransaksi> tags) {
    if (idTagTransaksi == null) return "-";

    try {
      final tag = tags.firstWhere(
            (tag) => tag.id == idTagTransaksi,
        orElse: () => TagTransaksi(id: 0, nama: "Tag Tidak Ditemukan", kategoriTransaksi: ""),
      );

      return tag.nama ?? "Tag $idTagTransaksi";
    } catch (_) {
      return "Tag $idTagTransaksi";
    }
  }

  void _updateUploadProgress(double progress) {
    setState(() => _uploadProgress = progress);
  }

  //----------------------------------------------------------------------
  // PUSH DATA
  //----------------------------------------------------------------------

  int toggleRit(int lastRit) {
    return lastRit == 1 ? 2 : 1;
  }

  Future<void> _pushDataPremiHarianKru() async {
    if (_selectedDate == null) {
      _showAlertDialog(context, "Silakan pilih tanggal terlebih dahulu.");
      return;
    }

    if (_isPushingData) return;

    setState(() {
      _isPushingData = true;
      _uploadProgress = 0.0;
    });

    try {
      print("====================================");
      print("🚀 PUSH DATA PREMI & SETORAN DIMULAI");
      print("Tanggal: $_selectedDate");
      print("====================================");

      final String idTransaksi = await dataPusherService.pushDataPremiHarianKru(
        selectedDate: _selectedDate!,
        onProgress: (progress) {
          setState(() => _uploadProgress = progress);
          print("📊 Progress upload: ${(progress * 100).toStringAsFixed(1)}%");
        },
      );

      print("✅ PUSH DATA BERHASIL");
      print("🔰 ID TRANSAKSI: $idTransaksi");

      // =============================
      // 🔁 INSERT RIT USER (SETELAH PUSH BERHASIL)
      // =============================
      final users = await _userService.getAllUsers();

      for (final user in users) {
        // validasi data wajib
        if (user.idUser == 0 || user.idBus == 0 || user.noPol == null) {
          print('⚠️ Skip user tidak valid: ${user.namaLengkap}');
          continue;
        }

        final lastRit = await RitUserService.instance.getLastRitByUser(
          idUser: user.idUser,
          idBus: user.idBus,
          noPol: user.noPol!,
        );

        final newRit = toggleRit(lastRit);

        await RitUserService.instance.insertRitUser(
          idUser: user.idUser,
          idBus: user.idBus,
          noPol: user.noPol!,
          rit: newRit,
        );

        print(
          '🔁 RIT disimpan | User:${user.idUser} | Bus:${user.idBus} | '
              'Pol:${user.noPol} | $lastRit → $newRit',
        );
      }

      // =============================
      // 🔄 REFRESH DATA UI
      // =============================
      await _getListPremiKru();
      await _refreshSetoranKruData();

      print("====================================");
      print("✅ PUSH DATA PREMI & SETORAN SELESAI");
      print("====================================");

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false, // tidak bisa klik luar
          builder: (context) {
            return AlertDialog(
              title: const Text("Push Berhasil"),
              content: const Text(
                "Data berhasil dikirim.\n\n"
                    "Silakan klik menu KELUAR terlebih dahulu sebelum memulai transaksi kembali.",
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
      }
    } catch (e, s) {
      print("❌ ERROR PUSH DATA");
      print(e);
      print(s);
      _showAlertDialog(context, "Gagal push data: $e");
    } finally {
      setState(() {
        _isPushingData = false;
        _uploadProgress = 0.0;
      });
    }
  }

  //----------------------------------------------------------------------
  // PILIH TANGGAL
  //----------------------------------------------------------------------

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDate: _selectedDate ?? DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  //----------------------------------------------------------------------
  // ALERT DIALOG
  //----------------------------------------------------------------------

  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Pemberitahuan"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> getBluetooth() async {
    try {
      print("🔍 Mulai getBluetooth...");
      await _requestBluetoothPermission();

      print("📡 Mendapatkan daftar perangkat yang dipasangkan...");
      _devices = await _bluetooth.getBondedDevices();
      print("✅ Perangkat ditemukan: ${_devices.length}");

      if (_devices.isEmpty) {
        Fluttertoast.showToast(msg: "Tidak ada printer yang ditemukan");
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Pilih Printer"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  title: Text(device.name ?? 'Printer ${index + 1}'),
                  subtitle: Text(device.address ?? 'Alamat tidak tersedia'),
                  onTap: () async {
                    print("📌 Memilih printer: ${device.name} - ${device.address}");
                    Navigator.pop(context);
                    await _connectToDevice(device);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      print("❌ Error getBluetooth: ${e.toString()}");
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  // Function to request the Bluetooth permission.
  Future<void> _requestBluetoothPermission() async {
    if (Platform.isAndroid) {
      print("🔍 Memeriksa permission Bluetooth...");
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final androidSdk = androidInfo.version.sdkInt ?? 0;

      print("✅ Android SDK Version: $androidSdk");
      if (androidSdk >= 31) {
        print("📌 Meminta permission bluetoothScan, bluetoothConnect, bluetoothAdvertise");
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();
      } else {
        print("📌 Meminta permission bluetooth");
        await Permission.bluetooth.request();
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await printerService.connect(device);
      Fluttertoast.showToast(msg: "Terhubung ke printer ${device.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal terhubung ke printer: ${e.toString()}");
    }
  }

  Future<void> _printSetoran() async {
    print("🖨️ Cek koneksi sebelum print...");

    if (!printerService.isConnected || printerService.selectedDevice == null) {
      print("❌ Printer belum terhubung");
      Fluttertoast.showToast(msg: "Printer belum terhubung");

      // langsung tampilkan pilihan bluetooth
      await getBluetooth();
      return;
    }

    try {
      final setoranList = await setoranKruService.getAllSetoran();
      final tagList = await _getAllTagTransaksi();
      final users = await _userService.getAllUsers();
      final user = users.isNotEmpty ? users.first : null;
      final kruList = await databaseHelper.queryKruBis();

      String formatPrinter(double value) {
        return NumberFormat("#,###", "id_ID").format(value.toInt());
      }

      if (setoranList.isEmpty) {
        Fluttertoast.showToast(msg: "Tidak ada data untuk dicetak");
        return;
      }

      // ===============================
      // CEK SEMUA DATA SUDAH TERKIRIM
      // ===============================
      final allDataSent = setoranList.every((item) => item.status == "Y");

      if (!allDataSent) {
        _showAlertDialog(
          context,
          "Tidak dapat mencetak laporan.\n\n"
              "Pastikan semua data setoran sudah dikirim ke server.\n"
              "Status harus 'Y' untuk semua data.",
        );
        return;
      }

      // ===============================
      // AMBIL DATA RIT (dari setoran pertama)
      // ===============================
      int rit = 1;
      if (setoranList.isNotEmpty && setoranList.first.rit != null) {
        rit = int.tryParse(setoranList.first.rit.toString()) ?? 1;
      }

      // ===============================
      // HITUNG TOTAL & DETAIL PENDAPATAN
      // ===============================

      double totalPendapatan = 0;
      double totalPengeluaran = 0;
      double pendapatanBersih = 0;
      double pendapatanDisetor = 0;

      // Detail pendapatan
      double pendapatanTiketReguler = 0;
      double pendapatanTiketOnline = 0;
      double pendapatanBagasi = 0;

      for (var item in setoranList) {

        // 🔎 ambil tag berdasarkan id_tag_transaksi
        TagTransaksi? tag;

        try {
          tag = tagList.firstWhere(
                (e) => e.id == item.idTagTransaksi,
          );
        } catch (e) {
          tag = null;
        }

        // ==========================
        // PENJUMLAHAN BERDASARKAN KATEGORI
        // ==========================

        if (tag != null) {

          // pastikan kategoriTransaksi angka
          int kategori = int.tryParse(tag.kategoriTransaksi ?? '0') ?? 0;

          if (kategori == 1) {
            totalPendapatan += item.nilai ?? 0;

            // Detail pendapatan berdasarkan ID tag
            if (item.idTagTransaksi == 1) {
              pendapatanTiketReguler = item.nilai ?? 0;
            } else if (item.idTagTransaksi == 2) {
              pendapatanTiketOnline = item.nilai ?? 0;
            } else if (item.idTagTransaksi == 3) {
              pendapatanBagasi = item.nilai ?? 0;
            }
          }
          else if (kategori == 2) {
            totalPengeluaran += item.nilai ?? 0;
          }
        }

        // khusus ID tertentu
        if (item.idTagTransaksi == 60) {
          pendapatanBersih = item.nilai ?? 0;
        }

        if (item.idTagTransaksi == 61) {
          pendapatanDisetor = item.nilai ?? 0;
        }
      }

      // ===== TANGGAL LAPORAN DARI DATE PICKER =====
      final DateTime tanggalDipilih = _selectedDate ?? DateTime.now();
      final String tanggalLaporan =
      DateFormat('dd-MM-yyyy').format(tanggalDipilih);

      // ===============================
      // FORMAT TEXT THERMAL (DIPERBAIKI)
      // ===============================

      String text = "";

      // Header
      text += "=" * 32 + "\n";
      text += "   LAPORAN SETORAN KRU   \n";
      text += "=" * 32 + "\n\n";

      // Informasi Umum
      text += "Tanggal    : $tanggalLaporan\n";
      text += "Rit ke     : $rit\n";
      text += "No. Polisi : ${user?.noPol ?? '-'}\n";
      text += "Trayek     : ${user?.namaTrayek ?? '-'}\n";
      text += "-" * 32 + "\n\n";

      // Data Kru
      text += "DATA KRU:\n";
      for (var kru in kruList) {
        final group = kru['group_name'] ?? '-';
        final nama = kru['nama_lengkap'] ?? '-';
        final nik = kru['nik'] ?? '-';
        text += "• $group - $nama\n";
        text += "  (NIK: $nik)\n";
      }
      text += "-" * 32 + "\n\n";

      // Detail Pendapatan
      text += "DETAIL PENDAPATAN:\n";
      text += "├ Tiket Reguler : Rp ${formatPrinter(pendapatanTiketReguler)}\n";
      text += "├ Tiket Online  : Rp ${formatPrinter(pendapatanTiketOnline)}\n";
      text += "└ Bagasi        : Rp ${formatPrinter(pendapatanBagasi)}\n";
      text += "-" * 32 + "\n";
      text += "TOTAL PENDAPATAN : Rp ${formatPrinter(totalPendapatan)}\n\n";

      // Pengeluaran
      text += "TOTAL PENGELUARAN : Rp ${formatPrinter(totalPengeluaran)}\n";
      text += "-" * 32 + "\n\n";

      // Hasil Akhir
      text += "PENDAPATAN BERSIH : Rp ${formatPrinter(pendapatanBersih)}\n";
      text += "PENDAPATAN DISETOR: Rp ${formatPrinter(pendapatanDisetor)}\n";
      text += "=" * 32 + "\n";
      text += "Terima kasih\n";
      text += "\n\n\n";

      // kirim ke printer
      await printerService.bluetooth.writeBytes(
        Uint8List.fromList(utf8.encode(text)),
      );

      Fluttertoast.showToast(msg: "Laporan berhasil dicetak");

    } catch (e) {
      print("❌ Error cetak: $e");
      Fluttertoast.showToast(msg: "Error mencetak: $e");
    }
  }

  //----------------------------------------------------------------------
  // EXPORT TO PDF (SIMPLE VERSION)
  //----------------------------------------------------------------------
  Future<void> _exportToPDF() async {
    try {
      final setoranList = await setoranKruService.getAllSetoran();
      final tagList = await _getAllTagTransaksi();
      final users = await _userService.getAllUsers();
      final user = users.isNotEmpty ? users.first : null;

      if (setoranList.isEmpty) {
        _showAlertDialog(context, "Tidak ada data setoran kru untuk diekspor.");
        return;
      }

      // ===== VALIDASI STATUS DATA =====
      // Cek apakah ada data dengan status "N" (belum dikirim)
      final hasUnsentData = setoranList.any((item) => item.status == "N");

      if (hasUnsentData) {
        _showAlertDialog(
          context,
          "Tidak dapat mengekspor PDF. Masih ada data yang belum dikirim ke server.\n"
              "Silakan klik tombol 'Kirim Data' terlebih dahulu dan pastikan semua data telah berstatus 'Y'.",
        );
        return;
      }

      // Cek apakah semua data sudah berstatus "Y"
      final allDataSent = setoranList.every((item) => item.status == "Y");

      if (!allDataSent) {
        _showAlertDialog(
          context,
          "Tidak dapat mengekspor PDF. Pastikan semua data telah dikirim ke server.\n"
              "Status data yang valid harus 'Y' untuk semua setoran.",
        );
        return;
      }

      // Loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text("Membuat PDF..."),
            ],
          ),
        ),
      );

      final pdf = pw.Document();
      final now = DateTime.now();
      final dateFormat = DateFormat('dd-MM-yyyy HH:mm');
      final fileNameFormat = DateFormat('yyyyMMdd_HHmmss');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (context) {
            // ===== GROUPING DATA =====
            final Map<String, List<dynamic>> groupedData = {};

            for (var item in setoranList) {
              final key = '${item.noPol}_${item.tglTransaksi}_${item.kodeTrayek}';

              groupedData.putIfAbsent(key, () => []);
              groupedData[key]!.add(item);
            }

            // ===== AMBIL TANGGAL LAPORAN DARI DATA =====
            // ===== TANGGAL LAPORAN DARI DATE PICKER =====
            final DateTime tanggalDipilih = _selectedDate ?? DateTime.now();

            final String tanggalLaporan = DateFormat('dd-MM-yyyy').format(tanggalDipilih);

            return [
              // ================= HEADER =================
              pw.Text(
                'LAPORAN SETORAN KRU',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),

              // ===== DATA KRU / BUS =====
              if (user != null) ...[
                _pdfRow("No Pol", user.noPol ?? "-"),
                _pdfRow("Nama Kru", user.namaLengkap ?? "-"),
                _pdfRow("Trayek", user.namaTrayek ?? "-"),
                // _pdfRow("Jenis Trayek", user.jenisTrayek ?? "-"),
                // _pdfRow("Kelas Bus", user.kelasBus ?? "-"),
              ],

              // ===== TANGGAL OPERASIONAL =====
              _pdfRow("Tanggal", tanggalLaporan),

              pw.Divider(),

              // ================= LIST GROUP =================
              ...groupedData.entries.map((entry) {
                final items = entry.value;
                final first = items.first;

                String tgl = first.tglTransaksi ?? '-';
                if (tgl != '-') {
                  try {
                    DateTime parsedDate = DateTime.parse(tgl.substring(0, 10));
                    tgl = DateFormat('dd MMMM yyyy', 'id_ID').format(parsedDate);
                  } catch (e) {
                    // Jika parsing gagal, biarkan tetap format awal
                  }
                }

                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 12),
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header Group
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "No. Polisi : ${first.noPol ?? '-'}",
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                "Tanggal kirim : $tgl",
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                              pw.Text(
                                "Trayek : ${first.kodeTrayek ?? '-'}",
                                style: const pw.TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                          // Tambahkan indikator status (opsional)
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: PdfColors.green,
                              borderRadius: pw.BorderRadius.circular(10),
                            ),
                            child: pw.Text(
                              "TERKIRIM",
                              style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 8),

                      // ===== LIST TAG TRANSAKSI =====
                      ...items.map((data) {
                        final bool isPremiAtas = data.idTagTransaksi == 27;

                        final String namaTag = isPremiAtas
                            ? "Premi Atas"
                            : _getNamaTagFromList(
                          data.idTagTransaksi,
                          tagList,
                        );

                        return pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "- $namaTag",
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              pw.Text(
                                formatter.format(data.nilai ?? 0),
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),

              pw.Divider(),
              pw.Text(
                'Dibuat oleh: Aplikasi Mila KRU Reguler',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Status Data: Semua data telah dikirim ke server',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.green,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'setoran_kru_${fileNameFormat.format(now)}.pdf';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(bytes);

      Navigator.pop(context);
      await _showPDFSuccessDialog(filePath, fileName);
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.pop(context);
      _showAlertDialog(context, "Error membuat PDF: $e");
    }
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
          pw.Text(": ", style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPDFSuccessDialog(String filePath, String fileName) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("PDF Berhasil Dibuat"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "File telah disimpan sebagai:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              fileName,
              style: TextStyle(fontSize: 12, color: Colors.blue),
            ),
            SizedBox(height: 10),
            Text(
              "Lokasi:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 5),
            Text(
              filePath,
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            SizedBox(height: 15),
            Text(
              "Pilih aksi:",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 1),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_open, size: 18),
                SizedBox(width: 5),
                Text("Buka File"),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download, size: 18),
                SizedBox(width: 5),
                Text("Download Ulang"),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 0),
            child: Text("Tutup"),
          ),
        ],
      ),
    );

    switch (result) {
      case 1:
      // Buka file dengan aplikasi default
        await OpenFile.open(filePath);
        break;
      case 2:
      // Download ulang ke folder Downloads jika ada
        await _saveToDownloads(filePath, fileName);
        break;
    }
  }

  Future<void> _saveToDownloads(String sourcePath, String fileName) async {
    try {
      // Coba akses folder Downloads
      final downloadsDirectory = await getDownloadsDirectory();

      if (downloadsDirectory != null) {
        final destPath = '${downloadsDirectory.path}/$fileName';
        final sourceFile = File(sourcePath);
        final destFile = File(destPath);

        await sourceFile.copy(destFile.path);

        _showAlertDialog(
          context,
          "File berhasil disalin ke folder Downloads:\n$fileName",
        );

        // Buka file setelah disalin
        await OpenFile.open(destPath);
      } else {
        // Fallback ke Documents directory
        final documents = await getApplicationDocumentsDirectory();
        final destPath = '${documents.path}/$fileName';
        final sourceFile = File(sourcePath);
        final destFile = File(destPath);

        await sourceFile.copy(destFile.path);

        _showAlertDialog(
          context,
          "File disalin ke:\n$destPath",
        );
      }
    } catch (e) {
      _showAlertDialog(context, "Error menyimpan file: $e");
    }
  }

  final Map<String, Future<List<ListPersenPremiKru>>> _persenPremiCache = {};

  //----------------------------------------------------------------------
  // BUILD UI
  //----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Data Premi Disetor Harian Kru"),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                tooltip: "Export to PDF",
                onPressed: _exportToPDF,
              ),
              IconButton(
                icon: const Icon(Icons.print),
                tooltip: "Cetak Laporan",
                onPressed: _printSetoran,
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today),
                tooltip: "Pilih Tanggal",
                onPressed: () => _selectDate(context),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                tooltip: "Kirim Data",
                onPressed: _pushDataPremiHarianKru,
              ),
            ],
          ),

          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ================= PREMI HARIAN KRU =================
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Kru")),
                        DataColumn(label: Text("%")),
                        DataColumn(label: Text("Nominal"), numeric: true),
                        DataColumn(label: Text("Status")),
                      ],
                      rows: listPremiHarianKru.map((item) {
                        return DataRow(
                          cells: [
                            DataCell(Text(item["nama_kru"].toString())),
                            DataCell(Text(item["persen_premi"].toString())),
                            DataCell(Text(
                              formatter.format(item["nominal_premi_disetor"]),
                            )),
                            DataCell(Text(item["status"].toString())),
                          ],
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// ================= SETORAN KRU =================
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          "Data Setoran Kru",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        FutureBuilder<List<SetoranKru>>(
                          future: setoranKruData,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError) {
                              return Text("Error: ${snapshot.error}");
                            }

                            final setoranList = snapshot.data ?? [];
                            if (setoranList.isEmpty) {
                              return const Text("Tidak ada data setoran kru");
                            }

                            return FutureBuilder<List<TagTransaksi>>(
                              future: _getAllTagTransaksi(),
                              builder: (context, tagSnap) {
                                if (!tagSnap.hasData) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final tagList = tagSnap.data!;

                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text("ID")),
                                      DataColumn(label: Text("Nama Tag")),
                                      DataColumn(label: Text("Nilai"), numeric: true),
                                      DataColumn(label: Text("Keterangan")),
                                      DataColumn(label: Text("Status")),
                                    ],
                                    rows: setoranList.expand((s) {
                                      if ([6, 7, 81].contains(s.idTagTransaksi)) {
                                        return <DataRow>[];
                                      }

                                      final rows = <DataRow>[];

                                      final isPremiAtas = s.idTagTransaksi == 27;
                                      final isTag61 = s.idTagTransaksi == 61;

                                      final namaTag = isPremiAtas ? "Premi Atas" : _getNamaTagFromList(s.idTagTransaksi, tagList);

                                      /// ---------- ROW UTAMA ----------
                                      rows.add(
                                        DataRow(
                                          cells: [
                                            DataCell(Text(
                                              s.id?.toString() ?? "-",
                                              style: isTag61
                                                  ? TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[800],
                                              )
                                                  : null,
                                            )),
                                            DataCell(Text(
                                              namaTag,
                                              style: isTag61
                                                  ? TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.red[800],
                                              )
                                                  : null,
                                            )),
                                            DataCell(Text(
                                              formatter.format(s.nilai),
                                              style: isTag61
                                                  ? TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[800],
                                              )
                                                  : null,
                                            )),
                                            DataCell(Text(s.keterangan ?? "-")),
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  s.status ?? "-",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      /// ---------- DETAIL PREMI ATAS ----------
                                      if (isPremiAtas) {
                                        rows.add(const DataRow(cells: [
                                          DataCell(Text("")),
                                          DataCell(Text("🔽 Pembagian Premi Atas")),
                                          DataCell(Text("")),
                                          DataCell(Text("")),
                                          DataCell(Text("")),
                                        ]));

                                        rows.add(
                                          DataRow(
                                            cells: [
                                              const DataCell(Text("")),
                                              DataCell(
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width * 0.6,
                                                  child: FutureBuilder<List<ListPersenPremiKru>>(
                                                    future: PersenPremiKruService.instance.getByKodeTrayek(
                                                      s.kodeTrayek ?? "",
                                                      idJenisPremi: 1,
                                                    ),
                                                    builder: (context, ps) {
                                                      print("📥 FutureBuilder status: ${ps.connectionState}");

                                                      if (!ps.hasData) {
                                                        print("⏳ Menunggu data pembagian premi...");
                                                        return const SizedBox(
                                                          height: 20,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        );
                                                      }

                                                      final persenList = ps.data!;
                                                      print("📊 Jumlah data pembagian premi: ${persenList.length}");

                                                      if (persenList.isEmpty) {
                                                        print("⚠️ Data pembagian premi kosong");
                                                        return const Text(
                                                          "⚠️ Data pembagian belum tersedia",
                                                          style: TextStyle(fontSize: 12),
                                                        );
                                                      }

                                                      /// Hitung total persen
                                                      final totalPersen = persenList.fold<double>(
                                                        0,
                                                            (sum, e) => sum + e.nilaiAsDouble,
                                                      );

                                                      print("🧮 Total persen premi: $totalPersen");
                                                      print("💰 Nilai premi dasar (s.nilai): ${s.nilai}");

                                                      return Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: persenList.asMap().entries.map((entry) {
                                                          final index = entry.key;
                                                          final p = entry.value;

                                                          print("--------------------------------------------------");
                                                          print("➡️ Item #${index + 1}");
                                                          print("   • ID Posisi Kru : ${p.idPosisiKru}");
                                                          print("   • Persen        : ${p.nilaiAsDouble}");

                                                          final nominal = totalPersen > 0
                                                              ? (p.nilaiAsDouble / totalPersen) * (s.nilai ?? 0)
                                                              : 0;

                                                          debugPrint("   • Nominal Hitung: $nominal");

                                                          final kruData = listPremiHarianKru.firstWhere(
                                                                (k) => k["id_posisi_kru"] == p.idPosisiKru,
                                                            orElse: () => {
                                                              "nama_kru": "Kru #${p.idPosisiKru}"
                                                            },
                                                          );

                                                          final namaKru = kruData["nama_kru"];
                                                          print("   • Nama Kru      : $namaKru");

                                                          return Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                                            child: Row(
                                                              children: [
                                                                Expanded(
                                                                  child: Text(
                                                                    namaKru,
                                                                    overflow: TextOverflow.ellipsis,
                                                                    style: const TextStyle(fontSize: 12),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  formatter.format(nominal),
                                                                  style: const TextStyle(
                                                                    fontSize: 12,
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                              const DataCell(Text("")),
                                              const DataCell(Text("")),
                                              const DataCell(Text("")),
                                            ],
                                          ),
                                        );
                                      }


                                      return rows;
                                    }).toList(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        /// ================= OVERLAY LOADING =================
        if (_isPushingData)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(value: _uploadProgress),
                  const SizedBox(height: 16),
                  const Text(
                    "Sedang mengirim data...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}