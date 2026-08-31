import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // 🔹 untuk akses buildDrawer(context, idUser)
import 'package:intl/intl.dart';

// Tambahkan di bagian atas file
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

// Import services modular
import 'package:mila_kru_reguler/services/manifest_api_service.dart';
import 'package:mila_kru_reguler/services/manifest_local_service.dart';
import 'package:mila_kru_reguler/services/manifest_printer_service.dart';
import 'bluetooth_service.dart';

// 🔥 TAMBAHKAN IMPORT UNTUK DATABASE
import 'package:sqflite/sqflite.dart';

class ManifestPage extends StatefulWidget {
  final String idJadwalTrip;
  final String token;

  const ManifestPage({
    Key? key,
    required this.idJadwalTrip,
    required this.token,
  }) : super(key: key);

  @override
  _ManifestPageState createState() => _ManifestPageState();
}

class _ManifestPageState extends State<ManifestPage> {
  List<dynamic> manifestList = [];
  int idUser = 0;
  int idBus = 0;
  String? noPol;

  // 🔥 TAMBAHKAN MAP UNTUK MENYIMPAN STATUS SAVE PER DATA
  Map<String, bool> _savedStatus = {};
  Map<String, bool> _savingStatus = {};

  // Inisialisasi services
  final ManifestLocalService _localService = ManifestLocalService();
  final BluetoothPrinterService _printerService = BluetoothPrinterService();
  late ManifestPrinterService _manifestPrinterService;
  final NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  @override
  void initState() {
    super.initState();
    _manifestPrinterService = ManifestPrinterService(_printerService);
    _loadPrefs();
    _checkPrinterConnection();
  }

  Future<void> _checkPrinterConnection() async {
    await _printerService.checkConnection();
  }

  /// 🔹 Format angka ke Rupiah dengan pemisah ribuan
  String formatRupiah(dynamic number) {
    try {
      final value = int.tryParse(number.toString()) ?? 0;
      final formatter = NumberFormat('#,###', 'id_ID');
      return formatter.format(value);
    } catch (e) {
      return number.toString();
    }
  }

  /// 🔹 Ambil data user & bus dari SharedPreferences
  Future<void> _loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    idUser = prefs.getInt('idUser') ?? 0;
    idBus = prefs.getInt('idBus') ?? 0;
    noPol = prefs.getString('noPol');

    // Jalankan update notifikasi dulu
    await ManifestApiService.updateNotifikasi(
      token: widget.token,
      idJadwalTrip: widget.idJadwalTrip,
      idBus: idBus,
      noPol: noPol,
    );

    // Lalu ambil data manifest
    await _fetchManifest();

    setState(() {}); // update tampilan drawer
  }

  /// 🔹 Fungsi untuk mengambil data manifest
  Future<void> _fetchManifest() async {
    final data = await ManifestApiService.fetchManifest(
      token: widget.token,
      idJadwalTrip: widget.idJadwalTrip,
    );

    setState(() {
      manifestList = data;
    });

    // 🔥 CEK STATUS SAVE UNTUK SEMUA DATA
    await _checkAllSavedStatus();
  }

  /// 🔥 CEK STATUS SAVE UNTUK SEMUA DATA
  Future<void> _checkAllSavedStatus() async {
    for (var item in manifestList) {
      final idInvoice = item['id_order_transaksi']?.toString() ?? '';
      if (idInvoice.isNotEmpty) {
        final exists = await _localService.isIdInvoiceExists(idInvoice);
        setState(() {
          _savedStatus[idInvoice] = exists;
        });
      }
    }
  }

  /// 🔥 CEK APAKAH DATA SUDAH TERSIMPAN
  Future<bool> _checkDataExists(String idInvoice) async {
    if (idInvoice.isEmpty) return false;
    return await _localService.isIdInvoiceExists(idInvoice);
  }

  /// 🔹 Ambil kode kursi dari string seperti "A4(3A.1)" → "3A"
  String _extractSeatCode(String seat) {
    return _manifestPrinterService.extractSeatCode(seat);
  }

  Future<void> _getBluetoothDevices() async {
    try {
      final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();

      if (devices.isEmpty) {
        Fluttertoast.showToast(msg: "Tidak ada printer yang ditemukan");
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Pilih Printer"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name ?? 'Printer ${index + 1}'),
                  subtitle: Text(device.address ?? 'Alamat tidak tersedia'),
                  onTap: () async {
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
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await _printerService.connect(device);
      Fluttertoast.showToast(msg: "Terhubung ke printer ${device.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal terhubung ke printer: ${e.toString()}");
    }
  }

  // Fungsi untuk handle print dengan data dari database lokal
  Future<void> _printTicketManifest(Map<String, dynamic> item) async {
    if (!_printerService.isConnected || _printerService.selectedDevice == null) {
      Fluttertoast.showToast(msg: "Printer belum terhubung");
      return;
    }

    try {
      print('🖨️ Memulai proses print untuk data manifest...');

      // Cek apakah data sudah tersimpan di database lokal
      final idInvoice = item['id_order_transaksi']?.toString() ?? '';
      final localData = await _localService.getPenjualanDataFromLocal(idInvoice);

      if (localData == null) {
        Fluttertoast.showToast(
          msg: "Data belum disimpan ke database lokal. Tekan tombol SIMPAN dulu.",
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // Ambil data dari SharedPreferences untuk info bus
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final noPol = prefs.getString('noPol') ?? '';
      final jenisTrayek = prefs.getString('jenisTrayek') ?? 'REGULER';
      final kelasBus = prefs.getString('kelasBus') ?? 'EKONOMI';

      final kursi = _extractSeatCode(item['id_cell_kategori_kursi'] ?? '');

      print('✅ Data ditemukan di database lokal, memulai print...');

      // Generate bytes untuk print
      final bytes = await _manifestPrinterService.getTicketManifestBytes(
        localData: localData,
        kursi: kursi,
        noPol: noPol,
        jenisTrayek: jenisTrayek,
        kelasBus: kelasBus,
      );

      await _printerService.bluetooth.writeBytes(Uint8List.fromList(bytes));
      Fluttertoast.showToast(msg: "✅ Tiket berhasil dicetak dari data lokal");
    } catch (e) {
      print('❌ Error mencetak tiket: $e');
      Fluttertoast.showToast(
        msg: "Error mencetak: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  // ============================================================
  // 🔥 FUNGSI BARU: SIMPAN & KIRIM PER DATA (1 transaksi saja)
  // ============================================================
  Future<void> _simpanDanKirimPerData(Map<String, dynamic> item) async {
    final idInvoice = item['id_order_transaksi']?.toString() ?? '';

    if (idInvoice.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ ID Invoice tidak valid')),
      );
      return;
    }

    // 🔥 CEK APAKAH SEDANG PROSES SAVE UNTUK DATA INI
    if (_savingStatus[idInvoice] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⏳ Sedang memproses data ini...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 🔥 CEK APAKAH SUDAH TERSIMPAN
    final bool isExists = await _checkDataExists(idInvoice);
    if (isExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Data ID: $idInvoice sudah tersimpan'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    // 🔥 SET STATUS SAVING
    setState(() {
      _savingStatus[idInvoice] = true;
    });

    // Tampilkan loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.deepOrange),
                SizedBox(height: 16),
                Text('Menyimpan data...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // ========================================
      // STEP 1: SIMPAN 1 DATA KE DATABASE
      // ========================================
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final int idUser = prefs.getInt('idUser') ?? 0;
      final int idGroup = prefs.getInt('idGroup') ?? 0;
      final int idCompany = prefs.getInt('idCompany') ?? 0;
      final int idGarasi = prefs.getInt('idGarasi') ?? 0;
      final int idBus = prefs.getInt('idBus') ?? 0;
      final String? noPol = prefs.getString('noPol');
      final String? kodeTrayek = prefs.getString('kode_trayek');
      final String? token = prefs.getString('token') ?? widget.token;

      // Validasi token
      if (token == null || token.isEmpty) {
        if (context.mounted) Navigator.pop(context);
        setState(() {
          _savingStatus[idInvoice] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Token tidak valid, silakan login ulang'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final Database database = await _localService.databaseHelper.database;

      // Ambil RIT terakhir
      final int rit = await _localService.getCurrentRit(database, idUser);

      // Format tanggal
      final String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

      // Tentukan kategori tiket
      String getKategoriTiket(dynamic idAgen) {
        final int agenId = int.tryParse(idAgen.toString()) ?? 0;
        const Map<int, String> kategoriMap = {
          29: 'traveloka',
          30: 'red_bus',
          31: 'sysconix',
        };
        return kategoriMap[agenId] ?? 'offline';
      }

      final String kategoriTiket = getKategoriTiket(item['id_agen']);
      final hargaKantor = double.tryParse(item['harga_kantor']?.toString() ?? '0') ?? 0.0;
      final hargaTercatat = double.tryParse(item['harga_tercatat']?.toString() ?? '0') ?? 0.0;

      // 🔥 CEK DUPLIKAT SEKALI LAGI SEBELUM INSERT
      final existing = await database.query(
        'penjualan_tiket',
        where: 'id_invoice = ?',
        whereArgs: [idInvoice],
      );

      if (existing.isNotEmpty) {
        // Tutup dialog
        if (context.mounted) Navigator.pop(context);

        setState(() {
          _savingStatus[idInvoice] = false;
          _savedStatus[idInvoice] = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Data ID: $idInvoice sudah ada di database'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // ✅ INSERT ke database
      await database.insert('penjualan_tiket', {
        'no_pol': noPol ?? '',
        'id_bus': idBus,
        'id_user': idUser,
        'id_group': idGroup,
        'id_garasi': idGarasi,
        'id_company': idCompany,
        'jumlah_tiket': 1,
        'kategori_tiket': kategoriTiket,
        'rit': rit,
        'kota_berangkat': item['id_kota_berangkat']?.toString() ?? '',
        'kota_tujuan': item['id_kota_tujuan']?.toString() ?? '',
        'nama_pembeli': item['nama_penumpang']?.toString() ?? '',
        'no_telepon': item['no_tlp']?.toString() ?? '',
        'harga_kantor': hargaKantor,
        'jumlah_tagihan': hargaTercatat,
        'nominal_bayar': hargaTercatat,
        'jumlah_kembalian': 0.0,
        'tanggal_transaksi': formattedDate,
        'status': 'N', // Belum dikirim
        'kode_trayek': kodeTrayek ?? '',
        'keterangan': 'Penumpang MILA BUS',
        'id_invoice': idInvoice,
        'is_turun': 0,
        'status_bayar': 1,
      });

      print('✅ Data $idInvoice berhasil disimpan ke database dengan RIT: $rit');

      // ========================================
      // STEP 2: KIRIM KE SERVER - PAKAI COMPLETER
      // ========================================
      final penjualanData = await _localService.getPenjualanDataFromLocal(idInvoice);

      // 🔥 BUAT COMPLETER UNTUK MENUNGGU CALLBACK
      final completer = Completer<void>();

      bool kirimSukses = false;
      String errorMessage = '';

      if (penjualanData != null) {
        print('📤 Mengirim data ke server untuk ID: $idInvoice');

        await ManifestApiService.kirimPenjualanKeServer(
          penjualan: penjualanData,
          token: token,
          onSuccess: (idInvoice) async {
            print('🔵 [onSuccess] CALLBACK DIPANGGIL untuk ID: $idInvoice');
            // Update status jadi Y (sudah dikirim)
            await _localService.updateStatusPenjualan(idInvoice, 'Y');
            kirimSukses = true;
            print('🔵 [onSuccess] kirimSukses = $kirimSukses');
            print('✅ Data $idInvoice berhasil dikirim ke server');

            // 🔥 BERI TANDA COMPLETER SELESAI
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
          onError: (error) {
            print('🔴 [onError] CALLBACK DIPANGGIL untuk ID: $idInvoice');
            print('🔴 [onError] Error: $error');
            errorMessage = error;
            // Status tetap N, nanti bisa dikirim ulang

            // 🔥 BERI TANDA COMPLETER SELESAI
            if (!completer.isCompleted) {
              completer.complete();
            }
          },
        );
      } else {
        errorMessage = 'Gagal mengambil data dari database';
        print('❌ $errorMessage');
        completer.complete();
      }

      // 🔥 TUNGGU SAMPAI COMPLETER SELESAI
      await completer.future;

      // Tutup dialog loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 🔥 UPDATE STATUS SAVE
      setState(() {
        _savingStatus[idInvoice] = false;
        _savedStatus[idInvoice] = true;
      });

      // Tampilkan hasil
      if (kirimSukses) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Data ID: $idInvoice berhasil disimpan & dikirim'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Data ID: $idInvoice disimpan tapi gagal dikirim: $errorMessage'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }

    } catch (e, stacktrace) {
      // Tutup dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // 🔥 UPDATE STATUS SAVING
      setState(() {
        _savingStatus[idInvoice] = false;
      });

      print('🔥 Error: $e');
      print('📚 Stacktrace: $stacktrace');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ❌ HAPUS FUNGSI LAMA _simpanDanKirimData()
  // Fungsi ini sudah diganti dengan _simpanDanKirimPerData()

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manifest Penumpang'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 🔥 HANYA TOMBOL PRINTER SAJA DI APP BAR
          IconButton(
            icon: const Icon(Icons.print, color: Colors.deepOrange),
            tooltip: 'Set Printer',
            onPressed: () async {
              await _getBluetoothDevices();
            },
          ),
          // ❌ TOMBOL SAVE GLOBAL DIHAPUS
        ],
      ),
      drawer: buildDrawer(context, idUser),
      body: Container(
        color: Colors.white,
        child: manifestList.isEmpty
            ? const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: manifestList.length,
          itemBuilder: (context, index) {
            final item = manifestList[index];
            final kursi = _extractSeatCode(item['id_cell_kategori_kursi'] ?? '');
            final nama = item['nama_penumpang'] ?? '-';
            final tlp = item['no_tlp'] ?? '-';
            final naik = item['nama_lokasi'] ?? '-';
            final turun = item['nama_daerah'] ?? '-';
            final harga = item['harga_tercatat'] ?? '0';
            final idInvoice = item['id_order_transaksi']?.toString() ?? '';

            // 🔥 CEK STATUS SAVE
            final bool isSaved = _savedStatus[idInvoice] ?? false;
            final bool isSaving = _savingStatus[idInvoice] ?? false;

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: isSaved
                      ? Colors.green.shade100
                      : Colors.deepOrange.shade100,
                  child: Text(
                    kursi,
                    style: TextStyle(
                      color: isSaved ? Colors.green : Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSaved)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 18,
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📞 $tlp', style: const TextStyle(fontSize: 13)),
                      Text('🟢 Naik: $naik', style: const TextStyle(fontSize: 13)),
                      Text('🔻 Turun: $turun', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '💰 Rp${formatRupiah(harga)}',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔥 TOMBOL SAVE PER DATA
                    if (!isSaved)
                      IconButton(
                        icon: isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.deepOrange,
                          ),
                        )
                            : const Icon(Icons.save, color: Colors.deepOrange),
                        onPressed: isSaving ? null : () => _simpanDanKirimPerData(item),
                        tooltip: isSaving ? 'Menyimpan...' : 'Simpan data ini',
                      ),

                    // TOMBOL PRINT
                    IconButton(
                      icon: const Icon(Icons.print, color: Colors.blue),
                      onPressed: isSaved ? () => _printTicketManifest(item) : null,
                      tooltip: isSaved ? 'Cetak Tiket' : 'Simpan dulu untuk cetak',
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

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../main.dart'; // 🔹 untuk akses buildDrawer(context, idUser)
// import 'package:intl/intl.dart';
//
// // Tambahkan di bagian atas file
// import 'package:blue_thermal_printer/blue_thermal_printer.dart';
// import 'package:flutter/services.dart';
// import 'package:fluttertoast/fluttertoast.dart';
//
// // Import services modular
// import 'package:mila_kru_reguler/services/manifest_api_service.dart';
// import 'package:mila_kru_reguler/services/manifest_local_service.dart';
// import 'package:mila_kru_reguler/services/manifest_printer_service.dart';
// import 'bluetooth_service.dart';
//
// class ManifestPage extends StatefulWidget {
//   final String idJadwalTrip;
//   final String token;
//
//   const ManifestPage({
//     Key? key,
//     required this.idJadwalTrip,
//     required this.token,
//   }) : super(key: key);
//
//   @override
//   _ManifestPageState createState() => _ManifestPageState();
// }
//
// class _ManifestPageState extends State<ManifestPage> {
//   List<dynamic> manifestList = [];
//   int idUser = 0;
//   int idBus = 0;
//   String? noPol;
//
//   // Inisialisasi services
//   final ManifestLocalService _localService = ManifestLocalService();
//   final BluetoothPrinterService _printerService = BluetoothPrinterService();
//   late ManifestPrinterService _manifestPrinterService;
//   final NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
//
//   @override
//   void initState() {
//     super.initState();
//     _manifestPrinterService = ManifestPrinterService(_printerService);
//     _loadPrefs();
//     _checkPrinterConnection();
//   }
//
//   Future<void> _checkPrinterConnection() async {
//     await _printerService.checkConnection();
//   }
//
//   /// 🔹 Format angka ke Rupiah dengan pemisah ribuan
//   String formatRupiah(dynamic number) {
//     try {
//       final value = int.tryParse(number.toString()) ?? 0;
//       final formatter = NumberFormat('#,###', 'id_ID');
//       return formatter.format(value);
//     } catch (e) {
//       return number.toString();
//     }
//   }
//
//   /// 🔹 Ambil data user & bus dari SharedPreferences
//   Future<void> _loadPrefs() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     idUser = prefs.getInt('idUser') ?? 0;
//     idBus = prefs.getInt('idBus') ?? 0;
//     noPol = prefs.getString('noPol');
//
//     // Jalankan update notifikasi dulu
//     await ManifestApiService.updateNotifikasi(
//       token: widget.token,
//       idJadwalTrip: widget.idJadwalTrip,
//       idBus: idBus,
//       noPol: noPol,
//     );
//
//     // Lalu ambil data manifest
//     await _fetchManifest();
//
//     setState(() {}); // update tampilan drawer
//   }
//
//   /// 🔹 Fungsi untuk mengambil data manifest
//   Future<void> _fetchManifest() async {
//     final data = await ManifestApiService.fetchManifest(
//       token: widget.token,
//       idJadwalTrip: widget.idJadwalTrip,
//     );
//
//     setState(() {
//       manifestList = data;
//     });
//   }
//
//   /// 🔹 Ambil kode kursi dari string seperti "A4(3A.1)" → "3A"
//   String _extractSeatCode(String seat) {
//     return _manifestPrinterService.extractSeatCode(seat);
//   }
//
//   Future<void> _getBluetoothDevices() async {
//     try {
//       final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
//       List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
//
//       if (devices.isEmpty) {
//         Fluttertoast.showToast(msg: "Tidak ada printer yang ditemukan");
//         return;
//       }
//
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: const Text("Pilih Printer"),
//           content: SizedBox(
//             width: double.maxFinite,
//             child: ListView.builder(
//               shrinkWrap: true,
//               itemCount: devices.length,
//               itemBuilder: (context, index) {
//                 final device = devices[index];
//                 return ListTile(
//                   title: Text(device.name ?? 'Printer ${index + 1}'),
//                   subtitle: Text(device.address ?? 'Alamat tidak tersedia'),
//                   onTap: () async {
//                     Navigator.pop(context);
//                     await _connectToDevice(device);
//                   },
//                 );
//               },
//             ),
//           ),
//         ),
//       );
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Error: ${e.toString()}");
//     }
//   }
//
//   Future<void> _connectToDevice(BluetoothDevice device) async {
//     try {
//       await _printerService.connect(device);
//       Fluttertoast.showToast(msg: "Terhubung ke printer ${device.name}");
//     } catch (e) {
//       Fluttertoast.showToast(msg: "Gagal terhubung ke printer: ${e.toString()}");
//     }
//   }
//
//   // Fungsi untuk handle print dengan data dari database lokal
//   Future<void> _printTicketManifest(Map<String, dynamic> item) async {
//     if (!_printerService.isConnected || _printerService.selectedDevice == null) {
//       Fluttertoast.showToast(msg: "Printer belum terhubung");
//       return;
//     }
//
//     try {
//       print('🖨️ Memulai proses print untuk data manifest...');
//
//       // Cek apakah data sudah tersimpan di database lokal
//       final idInvoice = item['id_order_transaksi']?.toString() ?? '';
//       final localData = await _localService.getPenjualanDataFromLocal(idInvoice);
//
//       if (localData == null) {
//         Fluttertoast.showToast(
//           msg: "Data belum disimpan ke database lokal. Tekan tombol SIMPAN dulu.",
//           toastLength: Toast.LENGTH_LONG,
//         );
//         return;
//       }
//
//       // Ambil data dari SharedPreferences untuk info bus
//       SharedPreferences prefs = await SharedPreferences.getInstance();
//       final noPol = prefs.getString('noPol') ?? '';
//       final jenisTrayek = prefs.getString('jenisTrayek') ?? 'REGULER';
//       final kelasBus = prefs.getString('kelasBus') ?? 'EKONOMI';
//
//       final kursi = _extractSeatCode(item['id_cell_kategori_kursi'] ?? '');
//
//       print('✅ Data ditemukan di database lokal, memulai print...');
//
//       // Generate bytes untuk print
//       final bytes = await _manifestPrinterService.getTicketManifestBytes(
//         localData: localData,
//         kursi: kursi,
//         noPol: noPol,
//         jenisTrayek: jenisTrayek,
//         kelasBus: kelasBus,
//       );
//
//       await _printerService.bluetooth.writeBytes(Uint8List.fromList(bytes));
//       Fluttertoast.showToast(msg: "✅ Tiket berhasil dicetak dari data lokal");
//     } catch (e) {
//       print('❌ Error mencetak tiket: $e');
//       Fluttertoast.showToast(
//         msg: "Error mencetak: ${e.toString()}",
//         toastLength: Toast.LENGTH_LONG,
//       );
//     }
//   }
//
//   Future<void> _simpanDanKirimData() async {
//     // Simpan ke database lokal
//     final idInvoices = await _localService.simpanManifestKeDatabase(
//       manifestList: manifestList,
//       context: context,
//     );
//
//     if (idInvoices.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Tidak ada data baru untuk dikirim')),
//       );
//       return;
//     }
//
//     // Ambil data yang belum dikirim
//     final penjualanData = await _localService.getPenjualanBelumDikirim(idInvoices);
//
//     if (penjualanData.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Tidak ada data penjualan baru untuk dikirim')),
//       );
//       return;
//     }
//
//     // Ambil token dari SharedPreferences
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString('token') ?? widget.token;
//
//     int suksesKirim = 0;
//     int gagalKirim = 0;
//
//     // Kirim data ke server satu per satu
//     for (var penjualan in penjualanData) {
//       await ManifestApiService.kirimPenjualanKeServer(
//         penjualan: penjualan,
//         token: token,
//         onSuccess: (idInvoice) async {
//           suksesKirim++;
//           await _localService.updateStatusPenjualan(idInvoice, 'Y');
//         },
//         onError: (error) {
//           gagalKirim++;
//           print('❌ $error');
//         },
//       );
//     }
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Kirim selesai: $suksesKirim berhasil, $gagalKirim gagal')),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Manifest Penumpang'),
//         backgroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           // Tombol set printer
//           IconButton(
//             icon: const Icon(Icons.print, color: Colors.deepOrange),
//             tooltip: 'Set Printer',
//             onPressed: () async {
//               await _getBluetoothDevices();
//             },
//           ),
//           // Tombol simpan ke penjualan
//           IconButton(
//             icon: const Icon(Icons.save, color: Colors.deepOrange),
//             tooltip: 'Simpan ke Penjualan',
//             onPressed: () async {
//               await _simpanDanKirimData();
//             },
//           ),
//         ],
//       ),
//       drawer: buildDrawer(context, idUser),
//       body: Container(
//         color: Colors.white,
//         child: manifestList.isEmpty
//             ? const Center(
//           child: CircularProgressIndicator(color: Colors.deepOrange),
//         )
//             : ListView.builder(
//           padding: const EdgeInsets.all(12),
//           itemCount: manifestList.length,
//           itemBuilder: (context, index) {
//             final item = manifestList[index];
//             final kursi = _extractSeatCode(item['id_cell_kategori_kursi'] ?? '');
//             final nama = item['nama_penumpang'] ?? '-';
//             final tlp = item['no_tlp'] ?? '-';
//             final naik = item['nama_lokasi'] ?? '-';
//             final turun = item['nama_daerah'] ?? '-';
//             final harga = item['harga_tercatat'] ?? '0';
//
//             return Card(
//               elevation: 3,
//               margin: const EdgeInsets.symmetric(vertical: 6),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: ListTile(
//                 contentPadding: const EdgeInsets.symmetric(
//                     vertical: 10, horizontal: 16),
//                 leading: CircleAvatar(
//                   radius: 24,
//                   backgroundColor: Colors.deepOrange.shade100,
//                   child: Text(
//                     kursi,
//                     style: const TextStyle(
//                       color: Colors.deepOrange,
//                       fontWeight: FontWeight.bold,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//                 title: Text(
//                   nama,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.w600,
//                     fontSize: 16,
//                   ),
//                 ),
//                 subtitle: Padding(
//                   padding: const EdgeInsets.only(top: 4.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text('📞 $tlp', style: const TextStyle(fontSize: 13)),
//                       Text('🟢 Naik: $naik', style: const TextStyle(fontSize: 13)),
//                       Text('🔻 Turun: $turun', style: const TextStyle(fontSize: 13)),
//                       const SizedBox(height: 4),
//                       Text(
//                         '💰 Rp${formatRupiah(harga)}',
//                         style: const TextStyle(
//                           color: Colors.deepOrange,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 // TAMBAHKAN TOMBOL PRINT DI TRAILING
//                 trailing: IconButton(
//                   icon: const Icon(Icons.print, color: Colors.blue),
//                   onPressed: () => _printTicketManifest(item),
//                   tooltip: 'Cetak Tiket',
//                 ),
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }