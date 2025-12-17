import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // 🔹 untuk akses buildDrawer(context, idUser)
import 'package:intl/intl.dart';

// Tambahkan di bagian atas file
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';

// Import services modular
import 'package:mila_kru_reguler/services/manifest_api_service.dart';
import 'package:mila_kru_reguler/services/manifest_local_service.dart';
import 'package:mila_kru_reguler/services/manifest_printer_service.dart';
import 'bluetooth_service.dart';

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

  Future<void> _simpanDanKirimData() async {
    // Simpan ke database lokal
    final idInvoices = await _localService.simpanManifestKeDatabase(
      manifestList: manifestList,
      context: context,
    );

    if (idInvoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data baru untuk dikirim')),
      );
      return;
    }

    // Ambil data yang belum dikirim
    final penjualanData = await _localService.getPenjualanBelumDikirim(idInvoices);

    if (penjualanData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data penjualan baru untuk dikirim')),
      );
      return;
    }

    // Ambil token dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token') ?? widget.token;

    int suksesKirim = 0;
    int gagalKirim = 0;

    // Kirim data ke server satu per satu
    for (var penjualan in penjualanData) {
      await ManifestApiService.kirimPenjualanKeServer(
        penjualan: penjualan,
        token: token,
        onSuccess: (idInvoice) async {
          suksesKirim++;
          await _localService.updateStatusPenjualan(idInvoice, 'Y');
        },
        onError: (error) {
          gagalKirim++;
          print('❌ $error');
        },
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kirim selesai: $suksesKirim berhasil, $gagalKirim gagal')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manifest Penumpang'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tombol set printer
          IconButton(
            icon: const Icon(Icons.print, color: Colors.deepOrange),
            tooltip: 'Set Printer',
            onPressed: () async {
              await _getBluetoothDevices();
            },
          ),
          // Tombol simpan ke penjualan
          IconButton(
            icon: const Icon(Icons.save, color: Colors.deepOrange),
            tooltip: 'Simpan ke Penjualan',
            onPressed: () async {
              await _simpanDanKirimData();
            },
          ),
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
                  backgroundColor: Colors.deepOrange.shade100,
                  child: Text(
                    kursi,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
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
                // TAMBAHKAN TOMBOL PRINT DI TRAILING
                trailing: IconButton(
                  icon: const Icon(Icons.print, color: Colors.blue),
                  onPressed: () => _printTicketManifest(item),
                  tooltip: 'Cetak Tiket',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}