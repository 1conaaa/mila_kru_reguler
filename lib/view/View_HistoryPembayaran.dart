import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/view/Invoice_Webview.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import 'package:mila_kru_reguler/page/bluetooth_service.dart';

final printerService = BluetoothPrinterService();

class HistoryPembayaran extends StatefulWidget {
  const HistoryPembayaran({Key? key}) : super(key: key);

  @override
  State<HistoryPembayaran> createState() => _HistoryPembayaranState();
}

class _HistoryPembayaranState extends State<HistoryPembayaran> {
  List<Map<String, dynamic>> _dataInvoice = [];
  final DatabaseHelper dbHelper = DatabaseHelper();
  bool _isLoading = true;
  bool _isRefreshing = false;

  //bagian dari printer
  get hasBluetoothPermission => null;
  bool connected = false;
  List availableBluetoothDevices = [];

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  @override
  void initState() {
    super.initState();
    _loadDataInvoice();
    _checkPrinterConnection();
  }

  Future<void> _loadDataInvoice() async {
    try {
      final result = await dbHelper.getInvoicePenjualan();
      setState(() {
        _dataInvoice = result;
        _isLoading = false;
        _isRefreshing = false;
      });

      print('📦 Jumlah data invoice ditemukan: ${result.length}');
      for (var item in result) {
        print('🧾 Invoice ID: ${item['id_invoice']} | Kota: ${item['nama_kota_berangkat']} - ${item['nama_kota_tujuan']} | Total: ${item['nominal_tagihan']}');
      }
    } catch (e) {
      print('❌ Gagal memuat data invoice: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchInvoiceStatus(String idInvoice) async {
    print('🔍 Memulai pengecekan status invoice: $idInvoice');

    try {
      // 1. Ambil token dari SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      if (token.isEmpty) {
        print('‼️ Token tidak tersedia di SharedPreferences');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sesi telah berakhir, silakan login kembali')),
        );
        return null;
      }

      final url = 'https://apimila.sysconix.id/api/InvoiceReguler/$idInvoice';
      print('🌐 Mengirim request ke: $url');

      // 2. Gunakan token dalam header
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Response status code: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      // 3. Handle response berdasarkan struktur yang diberikan
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'SUCCESS') {
          final invoiceData = data['invoice'];
          print('✅ Data invoice diterima:');
          print('🆔 ID Invoice: ${invoiceData['id_invoice']}');
          print('💳 Status Bayar: ${invoiceData['status_bayar']}');
          print('🔄 Status: ${invoiceData['status']}');

          return {
            'status_bayar': int.tryParse(invoiceData['status_bayar'] ?? '0') ?? 0,
            'status': invoiceData['status'],
            'nominal_tagihan': double.tryParse(invoiceData['nominal_tagihan'] ?? '0') ?? 0,
            'redirect_url': invoiceData['redirect_url'],
            // Tambahkan field lain yang diperlukan
          };
        } else {
          print('❌ Status API tidak SUCCESS: ${data['status']}');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('🔒 Error 401: Unauthorized - Token mungkin tidak valid');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Autentikasi gagal, silakan login kembali')),
        );
      } else {
        print('❌ Gagal mendapatkan data, status code: ${response.statusCode}');
      }

      return null;
    } catch (e) {
      print('‼️ Error saat fetch invoice status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memeriksa status invoice: $e')),
      );
      return null;
    }
  }

  Future<void> _refreshInvoices() async {
    print('\n🔄 Memulai proses refresh invoices...');
    setState(() {
      _isRefreshing = true;
    });

    try {
      final invoicesToUpdate = _dataInvoice.where((i) => i['status_bayar'] != 1).toList();
      print('📋 Jumlah invoice yang perlu diperiksa: ${invoicesToUpdate.length}');

      for (var invoice in invoicesToUpdate) {
        final idInvoice = invoice['id_invoice'];
        print('\n📝 Memproses invoice: $idInvoice');
        print('📌 Status bayar lokal saat ini: ${invoice['status_bayar']}');

        final apiData = await _fetchInvoiceStatus(idInvoice);

        if (apiData != null) {
          print('🔍 Data dari API:');
          print('💰 Status Bayar: ${apiData['status_bayar']}');
          print('🔄 Status: ${apiData['status']}');

          if (apiData['status_bayar'] == 1) {
            print('🆕 Invoice perlu diupdate ke status bayar=1');

            try {
              await dbHelper.updateInvoiceStatus(
                idInvoice,
                apiData['status_bayar'],
                'Y', // Gunakan 'Y' sebagai default jika null
              );
              print('💾 Berhasil update database lokal');

            } catch (e) {
              print('‼️ Gagal update database lokal: $e');
            }
          }
        }
      }

      print('\n♻️ Memuat ulang data dari database lokal...');
      await _loadDataInvoice();
      print('✅ Proses refresh selesai');
    } catch (e) {
      print('‼️ Error dalam proses refresh: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui status invoice: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  // Future<void> printTicket() async {
  //   if (!_isConnected || _selectedDevice == null) {
  //     Fluttertoast.showToast(msg: "Printer belum terhubung");
  //     return;
  //   }
  //
  //   try {
  //     final bytes = await getTicket();
  //     // Konversi List<int> ke Uint8List
  //     await _bluetooth.writeBytes(Uint8List.fromList(bytes));
  //     Fluttertoast.showToast(msg: "Tiket berhasil dicetak");
  //   } catch (e) {
  //     Fluttertoast.showToast(msg: "Error mencetak: ${e.toString()}");
  //   }
  // }

  Future<void> _checkPrinterConnection() async {
    await printerService.checkConnection();
  }

  // Function to request the Bluetooth permission.
  Future<void> _requestBluetoothPermission() async {
    if (Platform.isAndroid) {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final androidSdk = androidInfo.version.sdkInt ?? 0;

      if (androidSdk >= 31) {
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.bluetoothAdvertise,
        ].request();
      } else {
        await Permission.bluetooth.request();
      }
    }
  }

  Future<void> disconnectPrinter() async {
    try {
      await _bluetooth.disconnect();

      setState(() {
        _isConnected = false;
        _selectedDevice = null;
      });

      Fluttertoast.showToast(msg: "Printer terputus");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error memutuskan koneksi: ${e.toString()}");
    }
  }

  // Function to check if the Bluetooth permission is granted.
  Future<bool> _checkBluetoothPermission() async {
    final PermissionStatus status = await Permission.bluetoothConnect.status;
    return status.isGranted;
  }

  // Function to request the Bluetooth scan permission.
  Future<void> _requestBluetoothScanPermission() async {
    final PermissionStatus status = await Permission.bluetoothScan.request();
    if (!status.isGranted) {
      print("Error requesting Bluetooth scan permission");
    }
  }

  Future<void> getBluetooth() async {
    try {
      await _requestBluetoothPermission();

      // Dapatkan daftar perangkat yang dipasangkan
      _devices = await _bluetooth.getBondedDevices();

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
      await printerService.connect(device);
      Fluttertoast.showToast(msg: "Terhubung ke printer ${device.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal terhubung ke printer: ${e.toString()}");
    }
  }

  Future<List<int>> getTicket(int index) async {
    // Ambil data dari _dataInvoice berdasarkan index yang dipilih
    final item = _dataInvoice[index];

    // Ekstrak data yang diperlukan dari item
    final idInvoice = item['id_invoice'];
    final rit = item['rit'] ?? 0;
    final kotaBerangkat = item['kota_berangkat']?.toString() ?? '';
    final kotaTujuan = item['kota_tujuan']?.toString() ?? '';
    final namaPembeli = item['nama_pembeli']?.toString() ?? '';
    final noTelepon = item['no_telepon']?.toString() ?? '';
    final jumlahTiket = item['jumlah_tiket'] ?? 1;
    final jumlahTagihan = item['jumlah_tagihan']?.toDouble() ?? 0.0;
    final nominalBayar = item['nominal_bayar']?.toDouble() ?? 0.0;
    final jumlahKembalian = item['jumlah_kembalian']?.toDouble() ?? 0.0;
    final tagihanFaspay = item['nominal_tagihan']?.toDouble() ?? 0.0;
    final tanggalTransaksi = item['tanggal_transaksi']?.toString() ?? '';
    // final biayaAdmin = item['biaya_admin']?.toDouble() ?? 0.0;
    final biayaAdminRaw = item['biaya_admin']?.toDouble() ?? 0.0;

    // Hitung biaya admin jika < 100 (persentase)
    double biayaAdmin = biayaAdminRaw;
    if (biayaAdminRaw < 100 && biayaAdminRaw > 0) {
      biayaAdmin = (biayaAdminRaw / 100) * jumlahTagihan;
    }

    // Format tanggal
    var formattedDate = '';
    try {
      var dateParts = tanggalTransaksi.split('-');
      if (dateParts.length >= 3) {
        formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
      } else {
        formattedDate = tanggalTransaksi;
      }
    } catch (e) {
      formattedDate = tanggalTransaksi;
    }

    // Format mata uang
    String jumlahTagihanCetak = formatter.format(jumlahTagihan);
    String jumlahBayarCetak = formatter.format(nominalBayar);
    String jumlahKembalianCetak = formatter.format(jumlahKembalian);
    String tagihanFaspayCetak = formatter.format(tagihanFaspay);
    String biayaAdminCetak = formatter.format(biayaAdmin);

    // Nama kota (sudah tersedia dari join query)
    String namaKotaAwal = item['nama_kota_berangkat']?.toString() ?? '';
    String namaKotaAkhir = item['nama_kota_tujuan']?.toString() ?? '';

    // Konversi ke uppercase
    namaKotaAwal = namaKotaAwal.toUpperCase();
    namaKotaAkhir = namaKotaAkhir.toUpperCase();

    // Kategori tiket dan trayek
    String kategoriTiket = item['kategori_tiket']?.toString() ?? 'REGULER';
    String kodeTrayek = item['kode_trayek']?.toString() ?? '';

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.reset();

    // 1. TAMBAHKAN LOGO
    try {
      final ByteData logoData = await rootBundle.load('assets/images/logo_print.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final img.Image? image = img.decodeImage(logoBytes);

      if (image != null) {
        final img.Image resizedImage = img.copyResize(image, width: 380);
        bytes += generator.image(resizedImage);
      }
    } catch (e) {
      print('Gagal memuat logo: $e');
    }

    // Header
    bytes += generator.text("PT. ANDRY FEBIOLA TRANSPORTASI",
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1, bold: true));
    bytes += generator.text("Probolinggo - Jatim 67251", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("IG: akas.aaa.official", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("WA: 0853-9991-2500", styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Informasi rute
    bytes += generator.row([
      PosColumn(text: "$namaKotaAwal -", width: 6, styles: PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: " $namaKotaAkhir", width: 6, styles: PosStyles(align: PosAlign.left, bold: true)),
    ]);
    bytes += generator.text("$formattedDate", styles: PosStyles(align: PosAlign.center, bold: false));

    // Informasi rit dan kategori tiket
    bytes += generator.row([
      PosColumn(text: "Rit-$rit", width: 3, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "Tiket $kategoriTiket", width: 9, styles: PosStyles(align: PosAlign.right)),
    ]);

    // Informasi pembeli
    if (namaPembeli.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: "$namaPembeli", width: 6, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: "$noTelepon", width: 6, styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    // Informasi pembayaran
    bytes += generator.row([
      PosColumn(text: "$jumlahTiket Tiket", width: 3, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "Tagihan: $jumlahTagihanCetak", width: 9, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Biaya Admin", width: 6, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "$biayaAdminCetak", width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Bayar", width: 6, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "$tagihanFaspayCetak", width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.hr();
    bytes += generator.qrcode("https://www.akasaurora.com/");
    bytes += generator.text('Barang hilang atau rusak resiko penumpang sendiri.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Tiket ini, bukti transaksi yang sah dan mohon simpan tiket ini selama perjalanan Anda.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Semoga Allah SWT melindungi kita dalam perjalanan ini.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.hr();

    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: null,
        actions: [
          IconButton(
            icon: Icon(_isRefreshing ? Icons.refresh : Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshInvoices,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _dataInvoice.isEmpty
          ? Center(child: Text('Tidak ada data pembayaran'))
          : Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshInvoices,
              child: ListView.builder(
                itemCount: _dataInvoice.length,
                itemBuilder: (context, index) {
                  final item = _dataInvoice[index];
                  final isPaid = item['status_bayar'] == 1;

                  return Card(
                    elevation: 2,
                    margin:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                        backgroundColor: isPaid
                            ? Colors.green.shade100
                            : Colors.blue.shade100,
                      ),
                      title: Text('Invoice: ${item['id_invoice']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Rute: ${item['nama_kota_berangkat']} → ${item['nama_kota_tujuan']}'),
                          Text(
                              'Total Bayar: Rp ${item['nominal_tagihan']}'),
                          if (isPaid)
                            Text('Status: Sudah Dibayar',
                                style: TextStyle(color: Colors.green)),
                          if (!isPaid)
                            Text('Status: Belum Dibayar',
                                style: TextStyle(color: Colors.red)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPaid)
                            IconButton(
                              icon: Icon(Icons.print, color: Colors.blue),
                              onPressed: () async {
                                // Di bagian build, ubah pengecekan koneksi menjadi:
                                if (!printerService.isConnected || printerService.selectedDevice == null) {
                                  Fluttertoast.showToast(msg: "Printer belum terhubung");
                                  return;
                                }

                                try {
                                  final bytes = await getTicket(index);
                                  await printerService.bluetooth.writeBytes(Uint8List.fromList(bytes));
                                  Fluttertoast.showToast(
                                      msg: "Tiket berhasil dicetak");
                                } catch (e) {
                                  Fluttertoast.showToast(
                                      msg: "Error mencetak: ${e.toString()}");
                                }
                              },
                            ),
                          IconButton(
                            icon: Icon(Icons.receipt_long,
                                color: Colors.blue),
                            onPressed: () {
                              final url = item['redirect_url'] ?? '';
                              if (url.isNotEmpty) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        InvoiceWebviewPage(
                                            redirectUrl: url),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Redirect URL tidak tersedia')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // ✅ Tombol Set Printer di bawah
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  this.getBluetooth();
                  if (!await _checkBluetoothPermission()) {
                    await _requestBluetoothPermission();
                  }
                },
                style: ButtonStyle(
                  backgroundColor:
                  WidgetStateProperty.resolveWith<Color>(
                        (states) => states.contains(WidgetState.pressed)
                        ? Colors.grey
                        : Colors.blue,
                  ),
                  foregroundColor:
                  WidgetStateProperty.resolveWith<Color>(
                          (states) => Colors.white),
                ),
                child: Text('Set.Printer'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}