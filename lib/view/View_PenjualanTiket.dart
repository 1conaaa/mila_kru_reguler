import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:mila_kru_reguler/page/bluetooth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';


final printerService = BluetoothPrinterService();

class PenjualanForm extends StatefulWidget {
  @override
  _PenjualanFormState createState() => _PenjualanFormState();
}

class _PenjualanFormState extends State<PenjualanForm> {
  // Add these two variables
  bool isTombolVisible = false;
  bool isKotaBerangkatVisible = false;
  bool isKotaTujuanVisible = false;
  bool isSarantagihanVisible = false;
  bool isTagihanVisible = false;
  bool isJumlahBayarVisible = false;
  bool isJumlahKembalianVisible = false;
  bool isNamaPembeliVisible = false;
  bool isNotlpPembeliVisible = false;
  bool isHargaKantorVisible = false;
  bool isKeteranganVisible = false;
  bool isMetodePembayaranVisible = false;
  //bagian dari printer
  get hasBluetoothPermission => null;
  bool connected = false;
  List availableBluetoothDevices = [];

  List<Map<String, dynamic>> listKota = [];
  String? selectedKotaBerangkat;
  String? selectedKotaTujuan;

  List<Map<String, dynamic>> listMetodePembayaran = [];
  String? selectedMetodePembayaran;

  int paymentChannel = 0;
  int biayaAdmin = 0;
  double totalTagihanPlusBiayaAdmin = 0.0;
  bool isTotalDenganAdminVisible = false;
  TextEditingController totalDenganAdminController = TextEditingController();

  final UserService _userService = UserService(); // Tambahkan ini

  int idUser = 0;
  int idGroup = 0;
  int idCompany = 0;
  int? idGarasi;
  int idBus = 0;
  String? noPol;
  String? kodeTrayek;
  String? namaTrayek;
  String? jenisTrayek;
  String? kelasBus;
  String? keydataPremiextra;
  String? premiExtra;
  String? keydataPremikru;
  String? persenPremikru;
  String selectedPilihRit = '1';
  String selectedKategoriTiket = 'default';
  final _formKey = GlobalKey<FormState>();

  int jumlahTiket = 0;
  double jumlahTagihan = 0;
  double jumlahBayar = 0;
  double jumlahKembalian = 0;
  double biayaPerkursi = 0;
  double marginKantor = 0;
  double marginTarikan = 0;
  double hargaKantor = 0;

  var jarakPP;
  var namaKotaTerakhir;

  late String namaPembeli = ''; // Initialize with an empty string
  late String noTelepon = ''; // Initialize with an empty string
  late String keteranganTagihan = ''; // Initialize with an empty string

  get selectedValue => null;

  TextEditingController hargaKantorController = TextEditingController();
  TextEditingController tagihanController = TextEditingController();
  TextEditingController bayarController = TextEditingController();
  TextEditingController kembalianController = TextEditingController();

  get index => null;

  get keteranganController => null;

  get $bluetooths => null;

  set subtitleText(String subtitleText) {}

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  XFile? fotoPenumpang;
  bool isFotoVisible = false;
  String? fotoLocalPath;
  String? fotoFileName;

  @override
  void initState() {
    super.initState();
    _getListKota();
    _loadLastKotaTerakhir();
    _getListMetodePembayaran();
    hargaKantorController = TextEditingController();
    tagihanController = TextEditingController();
    bayarController = TextEditingController();
    kembalianController = TextEditingController();
    // Listener untuk update otomatis biaya admin
    tagihanController.addListener(_updateTotalDenganBiayaAdmin);
    sarantagihanController.addListener(_updateTotalDenganBiayaAdmin);
    _checkPrinterConnection();
  }

  DatabaseHelper databaseHelper = DatabaseHelper();

  TextEditingController sarantagihanController = TextEditingController();
  NumberFormat formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,   // <-- hilangkan ,00
  );

  Future<void> _loadLastKotaTerakhir() async {
    await databaseHelper.initDatabase();
    await _getListKota();
    await _getUserData();
    await _getListKotaTerakhir();
    await databaseHelper.closeDatabase();

    // Set initial value for tagihanController
    tagihanController.text = formatter.format(jumlahTagihan);
  }

  Future<void> _getListKota() async {
    try {
      List<Map<String, dynamic>> kotaData = await databaseHelper.getListKota();
      setState(() {
        listKota = kotaData; // Pastikan 'listKota' adalah list yang sesuai
      });

      if (listKota.isEmpty) {
        print('Tidak ada data dalam tabel list_kota.');
      } else {
        print('Data ditemukan dalam tabel list_kota.');
        print_r(listKota);
      }
    } catch (e) {
      print('Error saat mengambil data: $e');
    }
  }

  void print_r(List<Map<String, dynamic>> list) {
    for (var item in list) {
      print(item.toString());
    }
  }

  Future<void> _getListKotaTerakhir() async {
    try {
      Map<String, dynamic> kotaTerakhir = await databaseHelper.getLastKotaTerakhir();
      if (kotaTerakhir.isNotEmpty) {
        setState(() {
          jarakPP = kotaTerakhir['jarak'] != null ? (kotaTerakhir['jarak'] as num).toDouble() : 0.0;
          namaKotaTerakhir = kotaTerakhir['nama_kota'] ?? '';
          biayaPerkursi = kotaTerakhir['biaya_perkursi'] != null ? (kotaTerakhir['biaya_perkursi'] as num).toDouble() : 0.0;
          // hargaKantor = kotaTerakhir['harga_kantor'] != null ? (kotaTerakhir['harga_kantor'] as num).toDouble() : 0.0;
          marginKantor = kotaTerakhir['margin_kantor'] != null ? (kotaTerakhir['margin_kantor'] as num).toDouble() : 0.0;
          marginTarikan = kotaTerakhir['margin_tarikan'] != null ? (kotaTerakhir['margin_tarikan'] as num).toDouble() : 0.0;
        });
      }
      print('kota terakhir $jarakPP $namaKotaTerakhir');
    } catch (e) {
      print('Error retrieving kota terakhir: $e');
    }
  }

  Future<void> _getListMetodePembayaran() async {
    try {
      List<Map<String, dynamic>> data = await databaseHelper.getAllMetodePembayaran();
      setState(() {
        listMetodePembayaran = data;
        if (data.isNotEmpty && selectedMetodePembayaran == null) {
          // Set default ke ID 1
          var defaultItem = data.firstWhere(
                (item) => item['id'].toString() == '1',
            orElse: () => {},
          );
          if (defaultItem.isNotEmpty) {
            selectedMetodePembayaran = defaultItem['id'].toString();
          }
        }
      });

      if (listMetodePembayaran.isEmpty) {
        print('Tidak ada data metode pembayaran.');
      } else {
        print('Data metode pembayaran ditemukan:');
        listMetodePembayaran.forEach(print);
      }
    } catch (e) {
      print('Gagal mengambil metode pembayaran: $e');
    }
  }

  // 1. Perbaikan pada fungsi _updateTotalDenganBiayaAdmin
  void _updateTotalDenganBiayaAdmin() {
    print('[DEBUG] Memulai _updateTotalDenganBiayaAdmin');
    print('[DEBUG] Metode pembayaran saat ini: $selectedMetodePembayaran');
    print('[DEBUG] Biaya Admin saat ini: $biayaAdmin');
    print('[DEBUG] Payment Channel saat ini: $paymentChannel');

    // Reset nilai total
    double dasarTagihan = 0.0;
    totalTagihanPlusBiayaAdmin = 0.0;

    // Pilih sumber nilai tagihan berdasarkan yang visible
    if (isTagihanVisible && tagihanController.text.isNotEmpty) {
      String cleanText = tagihanController.text
          .replaceAll('Rp ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      dasarTagihan = double.tryParse(cleanText) ?? 0.0;
      print('[DEBUG] Menggunakan tagihanController: $dasarTagihan');
    } else if (isSarantagihanVisible && sarantagihanController.text.isNotEmpty) {
      String cleanText = sarantagihanController.text
          .replaceAll('Rp ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');
      dasarTagihan = double.tryParse(cleanText) ?? 0.0;
      print('[DEBUG] Menggunakan sarantagihanController: $dasarTagihan');
    }

    setState(() {
      totalTagihanPlusBiayaAdmin = dasarTagihan + biayaAdmin;
      print('[DEBUG] Total dengan admin: $totalTagihanPlusBiayaAdmin');

      // Format untuk display
      totalDenganAdminController.text = formatter.format(totalTagihanPlusBiayaAdmin);
    });
  }

  Future<void> _getUserData() async {
    List<Map<String, dynamic>> users = await _userService.getUsers();
    if (users.isNotEmpty) {
      Map<String, dynamic> firstUser = users[0];
      setState(() {
        idUser = firstUser['id_user'];
        idGroup = firstUser['id_group'];
        idCompany = firstUser['id_company'];
        idGarasi = firstUser['id_garasi'];
        idBus = firstUser['id_bus'];
        noPol = firstUser['no_pol'];
        kodeTrayek = firstUser['kode_trayek'];
        namaTrayek = firstUser['nama_trayek'];
        jenisTrayek = firstUser['jenis_trayek'];
        kelasBus = firstUser['kelas_bus'];
        keydataPremiextra = firstUser['keydataPremiextra'];
        premiExtra = firstUser['premiExtra'];
        keydataPremikru = firstUser['keydataPremikru'];
        persenPremikru = firstUser['persenPremikru'];
      });
    }
  }

  void _calculateKembalian(double jumlahBayar, double jumlahTagihan) {
    setState(() {
      jumlahKembalian = jumlahBayar - jumlahTagihan;
      if (jumlahKembalian < 0) {
        jumlahKembalian = -jumlahKembalian; // Mengambil nilai absolut
      }
      kembalianController.text = formatter.format(jumlahKembalian);
      print('kembalian $jumlahKembalian');
    });
  }

  int pembulatanRibuan(double nilai) {
    int floorValue = nilai.floor();           // hilangkan desimal
    int sisa = floorValue % 1000;             // ambil 3 digit terakhir

    if (sisa < 500) {
      return floorValue - sisa;               // bulatkan ke bawah
    } else {
      return floorValue + (1000 - sisa);      // bulatkan ke atas
    }
  }

  @override
  void dispose() {
    // Putuskan koneksi printer saat dispose
    // if (_isConnected) {
    //   _bluetooth.disconnect();
    // }
    tagihanController.removeListener(_updateTotalDenganBiayaAdmin);
    sarantagihanController.removeListener(_updateTotalDenganBiayaAdmin);
    totalDenganAdminController.dispose();
    super.dispose();
  }

  Future<void> _checkPrinterConnection() async {
    await printerService.checkConnection();
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

  Future<void> disconnectPrinter() async {
    try {
      print("🔌 Memutuskan koneksi printer...");
      await _bluetooth.disconnect();

      setState(() {
        _isConnected = false;
        _selectedDevice = null;
      });

      print("✅ Printer berhasil diputuskan");
      Fluttertoast.showToast(msg: "Printer terputus");
    } catch (e) {
      print("❌ Error memutuskan koneksi: ${e.toString()}");
      Fluttertoast.showToast(msg: "Error memutuskan koneksi: ${e.toString()}");
    }
  }

// Function to check if the Bluetooth permission is granted.
  Future<bool> _checkBluetoothPermission() async {
    final PermissionStatus status = await Permission.bluetoothConnect.status;
    print("🔍 Status permission Bluetooth: ${status.isGranted}");
    return status.isGranted;
  }

// Function to request the Bluetooth scan permission.
  Future<void> _requestBluetoothScanPermission() async {
    print("📌 Meminta permission bluetoothScan");
    final PermissionStatus status = await Permission.bluetoothScan.request();
    if (!status.isGranted) {
      print("❌ Gagal meminta permission bluetoothScan");
    } else {
      print("✅ Permission bluetoothScan diberikan");
    }
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

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await printerService.connect(device);
      Fluttertoast.showToast(msg: "Terhubung ke printer ${device.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal terhubung ke printer: ${e.toString()}");
    }
  }

  Future<void> printTicket() async {
    print("🖨️ Cek koneksi sebelum print...");
    print("Status isConnected: ${printerService.isConnected}");
    print("Printer terpilih: ${printerService.selectedDevice?.name}");

    if (!printerService.isConnected || printerService.selectedDevice == null) {
      print("❌ Printer belum terhubung");
      Fluttertoast.showToast(msg: "Printer belum terhubung");
      return;
    }

    try {
      print("📄 Mendapatkan data tiket untuk dicetak...");
      final bytes = await getTicket();
      await printerService.bluetooth.writeBytes(Uint8List.fromList(bytes));
      print("✅ Tiket berhasil dikirim ke printer");
      Fluttertoast.showToast(msg: "Tiket berhasil dicetak");
    } catch (e) {
      print("❌ Error mencetak: ${e.toString()}");
      Fluttertoast.showToast(msg: "Error mencetak: ${e.toString()}");
    }
  }

  Future<List<int>> getTicket() async {
    // Ambil SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String noWhatsapp = prefs.getString('noKontak') ?? '0822-3490-9090'; // Default value jika tidak ada

    int idkotaAwal = int.tryParse(selectedKotaBerangkat!.split(' - ')[0]) ?? 1;
    int idkotaAkhir = int.tryParse(selectedKotaTujuan!.split(' - ')[0]) ?? 1;

    String namaKotaAwal = await DatabaseHelper.instance.getNamaKota(idkotaAwal);
    String namaKotaAkhir = await DatabaseHelper.instance.getNamaKota(idkotaAkhir);

    // Mengubah string menjadi uppercase
    namaKotaAwal = namaKotaAwal.toUpperCase();
    namaKotaAkhir = namaKotaAkhir.toUpperCase();

    List<Map<String, dynamic>> lastTransaksi = await PenjualanTiketService.instance.getDataPenjualanTerakhir();
    String noOrderTransaksiTerakhir = lastTransaksi.isNotEmpty ? lastTransaksi[0]['noOrderTransaksi'] : '';
    int rit = lastTransaksi.isNotEmpty ? lastTransaksi[0]['rit'] : 0;
    String kotaBerangkat = lastTransaksi.isNotEmpty ? lastTransaksi[0]['kota_berangkat'] : '';
    String kotaTujuan = lastTransaksi.isNotEmpty ? lastTransaksi[0]['kota_tujuan'] : '';
    String namaPembeli = lastTransaksi.isNotEmpty ? lastTransaksi[0]['nama_pembeli'] : '';
    String noTelepon = lastTransaksi.isNotEmpty ? lastTransaksi[0]['no_telepon'] : '';

    double jumlahTagihan = lastTransaksi.isNotEmpty ? lastTransaksi[0]['jumlah_tagihan'] : 0.0;
    String jumlahTagihanCetak = formatter.format(jumlahTagihan);

    double nominalBayar = lastTransaksi.isNotEmpty ? lastTransaksi[0]['nominal_bayar'] : 0.0;
    String jumlahBayarCetak = formatter.format(nominalBayar);

    double jumlahKembalian = lastTransaksi.isNotEmpty ? lastTransaksi[0]['jumlah_kembalian'] : 0.0;
    String jumlahKembalianCetak = formatter.format(jumlahKembalian);

    String tanggalTransaksi = lastTransaksi.isNotEmpty ? lastTransaksi[0]['tanggal_transaksi'] : '';
    var dateParts = tanggalTransaksi.split('-');
    var formattedDate = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0];

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.reset();

    // 1. TAMBAHKAN LOGO DI SINI (SEBELUM TEKS APAPUN)
    try {
      final ByteData logoData = await rootBundle.load('assets/images/icon_mila.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();

      // Decode gambar
      final img.Image? image = img.decodeImage(logoBytes);

      if (image != null) {
        // Resize gambar agar sesuai dengan lebar printer (lebar maksimal 380 pixel untuk printer 58mm)
        final img.Image resizedImage = img.copyResize(image, width: 380);

        // Konversi ke format yang bisa dicetak
        bytes += generator.image(resizedImage);

      }
    } catch (e) {
      print('Gagal memuat logo: $e');
      // Tetap lanjutkan tanpa logo jika terjadi error
    }

    // Menambahkan teks dan informasi tiket lainnya
    bytes += generator.text("PT. MILA AKAS BERKAH SEJAHTERA",
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1, bold: true));
    bytes += generator.text("Probolinggo - Jawa Timur 67214", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("IG: akasmilasejahtera_official", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("WA: $noWhatsapp", styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Menambahkan kota keberangkatan dan tujuan
    bytes += generator.row([
      PosColumn(text: "$namaKotaAwal -", width: 6, styles: PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: " $namaKotaAkhir", width: 6, styles: PosStyles(align: PosAlign.left, bold: true)),
    ]);
    bytes += generator.text("$jenisTrayek-$kelasBus", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("$formattedDate", styles: PosStyles(align: PosAlign.center, bold: false));

    // Menambahkan informasi rit dan kategori tiket
    bytes += generator.row([
      PosColumn(text: "Rit-$selectedPilihRit", width: 3, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "Tiket $selectedKategoriTiket", width: 9, styles: PosStyles(align: PosAlign.right)),
    ]);

    // Menambahkan informasi pembeli jika ada
    if (namaPembeli.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: "$namaPembeli", width: 6, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: "$noTelepon", width: 6, styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    // Menambahkan informasi tagihan dan pembayaran
    bytes += generator.row([
      PosColumn(text: "$jumlahTiket Tiket", width: 3, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "Tagihan: $jumlahTagihanCetak", width: 9, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Bayar", width: 6, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "$jumlahBayarCetak", width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Kembalian", width: 6, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "$jumlahKembalianCetak", width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.hr();
    bytes += generator.qrcode("https://www.milaberkah.com/");
    bytes += generator.text('Barang hilang atau rusak resiko penumpang sendiri.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Tiket ini, bukti transaksi yang sah dan mohon simpan tiket ini selama perjalanan Anda.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Semoga Allah SWT melindungi kita dalam perjalanan ini.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.hr();

    return bytes;
  }

  void _calculateTagihan(
      String? selectedKategoriTiket,
      String? kelasBus,
      int jumlahTiket,
      String? selectedKotaBerangkat,
      String? selectedKotaTujuan) async {

    double jarakAwal = double.tryParse(selectedKotaBerangkat!.split(' - ')[1]) ?? 0;
    double jarakAkhir = double.tryParse(selectedKotaTujuan!.split(' - ')[1]) ?? 0;

    double selisihJarak = (jarakAwal - jarakAkhir).abs();

    // ----------------------------
    // HITUNG HARGA KANTOR
    // ----------------------------
    double hargaKantor = ((biayaPerkursi + marginKantor) / jarakPP) * selisihJarak * jumlahTiket;

    // ----------------------------
    // HITUNG HARGA TARIKAN (BEDA!)
    // ----------------------------
    double hargaTarikan = ((biayaPerkursi + marginTarikan) / jarakPP) * selisihJarak * jumlahTiket;

    // Kasus khusus gratis
    if (selectedKategoriTiket == 'gratis') {
      hargaKantor = 0;
      hargaTarikan = 0;
    }

    print("Hitung harga kantor: $hargaKantor");
    print("Hitung harga tarikan: $hargaTarikan");

    setState(() {
      // bulatkan nilai
      int hargaKantorBulat   = pembulatanRibuan(hargaKantor);
      int hargaTarikanBulat  = pembulatanRibuan(hargaTarikan);

      // tampilkan ke controller (tanpa desimal)
      hargaKantorController.text = formatter.format(hargaKantorBulat);
      tagihanController.text     = formatter.format(hargaTarikanBulat);

      jumlahTagihan = hargaTarikanBulat.toDouble();
    });

  }

  Future<void> _kirimKeBackendAPI(
      double hargaKantor,
      double totalTagihan,
      int jumlahTiket,
      String selectedPilihRit,
      String selectedKategoriTiket,
      String selectedKotaBerangkat,
      String selectedKotaTujuan,
      String namaPembeli,
      String noTelepon,
      String keteranganTagihan,
      String metodePembayaran,
      int paymentChannel,
      int biayaAdmin,
      ) async {

    double jarakAwal = double.tryParse(selectedKotaBerangkat.split(' - ')[1]) ?? 0;
    int idkotaAwal = int.tryParse(selectedKotaBerangkat.split(' - ')[0]) ?? 1;

    double jarakAkhir = double.tryParse(selectedKotaTujuan.split(' - ')[1]) ?? 0;
    int idkotaAkhir = int.tryParse(selectedKotaTujuan.split(' - ')[0]) ?? 1;

    double jumlahBayar = 0;
    double jumlahKembalian = 0;

    double selisihJarak = (jarakAwal - jarakAkhir).abs();

    print('saya disini: $hargaKantor ');

    List<Map<String, dynamic>> hargaKantorData = await databaseHelper.getCariHargaKantor(idkotaAwal, idkotaAkhir);

    if (hargaKantorData.isNotEmpty) {
      double hargaKantor = hargaKantorData[0]['harga_kantor'];
      double marginTarikan = hargaKantorData[0]['margin_tarikan'];
      print('1. value cariHargaKantor $kelasBus $jumlahTiket $idkotaAwal $idkotaAkhir : $hargaKantor $marginTarikan');
    } else {
      // Jika hargaKantorData kosong, tetapkan hargaKantor ke nilai default atau tangani kasus kosong
      double hargaKantor = 0; // atau nilai default yang sesuai
      print('Data Harga Kantor tidak ditemukan, menggunakan nilai default 0');
      print('2. value cariHargaKantor $kelasBus $jumlahTiket $idkotaAwal $idkotaAkhir : $hargaKantor');
    }

    if (hargaKantor == 0) {
      // Hitung jumlahTagihan
      // setState(() {
      //   hargaKantor = (hargaKantor * jumlahTiket).toDouble();
      // });
      if (kelasBus == 'Non Ekonomi') {
        hargaKantor = (((biayaPerkursi + marginKantor) / jarakPP) * selisihJarak * jumlahTiket);
        print('1.0 value calculate $kelasBus : $biayaPerkursi , $marginKantor , $jarakPP , $selisihJarak , $jumlahTiket , $jumlahTagihan');
      } else if (kelasBus == 'Ekonomi') {
        hargaKantor = (((biayaPerkursi + marginKantor) / jarakPP) * selisihJarak * jumlahTiket);
        print('2.0 value calculate $kelasBus $jumlahTiket $idkotaAwal $idkotaAkhir : $biayaPerkursi $marginKantor $marginTarikan $jarakPP $selisihJarak $jumlahTagihan');
      }
      print('2.1 value calculate $kelasBus $jumlahTiket $idkotaAwal $idkotaAkhir : $hargaKantor $marginTarikan');
      print("object : $hargaKantor , $jumlahTagihan , $jumlahBayar , $jumlahTiket , $selectedKotaBerangkat , $selectedKotaTujuan");

      if(selectedKategoriTiket=='gratis'){
        jumlahBayar = 0;
      } else {
        jumlahBayar = jumlahTagihan.toDouble();
      }

      // jumlahKembalian = (jumlahTagihan - jumlahBayar).toDouble().toInt();
      jumlahKembalian = (jumlahTagihan - jumlahBayar).abs();

      print("object : $jumlahKembalian ,$selectedKategoriTiket");

      DateTime now = DateTime.now();
      // Format tanggal dengan waktu
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      print('Formatted Date with Time: $formattedDate');

      print('══════════════════════════════════════════════════');
      print('║ DEBUG _kirimKeBackendAPI - PARAMETER YANG DIKIRIM');
      print('╠══════════════════════════════════════════════════');
      print('║ tanggalTransaksi: $formattedDate');
      print('║ hargaKantor: $hargaKantor');
      print('║ totalTagihan: $totalTagihan');
      print('║ jumlahTiket: $jumlahTiket');
      print('║ selectedPilihRit: $selectedPilihRit');
      print('║ selectedKategoriTiket: $selectedKategoriTiket');
      print('║ selectedKotaBerangkat: $selectedKotaBerangkat');
      print('║ selectedKotaTujuan: $selectedKotaTujuan');
      print('║ namaPembeli: $namaPembeli');
      print('║ noTelepon: $noTelepon');
      print('║ keteranganTagihan: $keteranganTagihan');
      print('║ metodePembayaran: $metodePembayaran');
      print('║ paymentChannel: $paymentChannel');
      print('║ biayaAdmin: $biayaAdmin');
      print('╚══════════════════════════════════════════════════');

      // Debug print nilai yang dihitung
      print('══════════════════════════════════════════════════');
      print('║ DEBUG _kirimKeBackendAPI - NILAI YANG DIHITUNG');
      print('╠══════════════════════════════════════════════════');
      print('║ jarakAwal: $jarakAwal');
      print('║ idkotaAwal: $idkotaAwal');
      print('║ jarakAkhir: $jarakAkhir');
      print('║ idkotaAkhir: $idkotaAkhir');
      print('║ selisihJarak: $selisihJarak');
      print('╚══════════════════════════════════════════════════');

      // Debug print sebelum menyimpan ke database
      print('══════════════════════════════════════════════════');
      print('║ DEBUG _kirimKeBackendAPI - DATA YANG AKAN DISIMPAN');
      print('╠══════════════════════════════════════════════════');
      print('║ no_pol: $noPol');
      print('║ id_bus: $idBus');
      print('║ id_user: $idUser');
      print('║ id_group: $idGroup');
      print('║ id_garasi: $idGarasi');
      print('║ id_company: $idCompany');
      print('║ jumlah_tiket: $jumlahTiket');
      print('║ kategori_tiket: $selectedKategoriTiket');
      print('║ rit: $selectedPilihRit');
      print('║ kota_berangkat: $idkotaAwal');
      print('║ kota_tujuan: $idkotaAkhir');
      print('║ nama_pembeli: $namaPembeli');
      print('║ no_telepon: $noTelepon');
      print('║ harga_kantor: $hargaKantor');
      print('║ jumlah_tagihan: $jumlahTagihan');
      print('║ nominal_bayar: $jumlahBayar');
      print('║ jumlah_kembalian: $jumlahKembalian');
      print('║ kode_trayek: $kodeTrayek');
      print('║ keterangan: $keteranganTagihan');
      print('╚══════════════════════════════════════════════════');

      try {
        double jarakAwal = double.tryParse(selectedKotaBerangkat.split(' - ')[1]) ?? 0;
        int idkotaAwal = int.tryParse(selectedKotaBerangkat.split(' - ')[0]) ?? 1;

        double jarakAkhir = double.tryParse(selectedKotaTujuan.split(' - ')[1]) ?? 0;
        int idkotaAkhir = int.tryParse(selectedKotaTujuan.split(' - ')[0]) ?? 1;

        double selisihJarak = (jarakAwal - jarakAkhir).abs();

        // Prepare request data
        Map<String, dynamic> requestData = {
          'tgl_transaksi': formattedDate,
          'kategori': selectedKategoriTiket,
          'rit': selectedPilihRit,
          'no_pol': noPol,
          'id_bus': idBus,
          'kode_trayek': kodeTrayek,
          'id_personil': idUser,
          'id_group': idGroup,
          'id_kota_berangkat': idkotaAwal.toString(),
          'id_kota_tujuan': idkotaAkhir.toString(),
          'jml_naik': jumlahTiket,
          'harga_kantor': hargaKantor,
          'pendapatan': jumlahTagihan,
          'nama_pelanggan': namaPembeli,
          'no_telepon': noTelepon,
          'keterangan': keteranganTagihan,
          'id_metode_bayar': paymentChannel,
          'payment_channel': paymentChannel,
          'biaya_admin': biayaAdmin,
        };

        // Debug print
        print('══════════════════════════════════════════════════');
        print('║ DATA YANG AKAN DIKIRIM KE API');
        print('╠══════════════════════════════════════════════════');
        requestData.forEach((key, value) {
          print('║ $key: $value');
        });
        print('╚══════════════════════════════════════════════════');

        // Get token from storage
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        // Make API request
        final response = await http.post(
          Uri.parse('https://apimila.sysconix.id/api/storeregulerfaspay'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestData),
        );

        print("📦 Raw response body: '${response.body}'");
        print("📦 Response headers: ${response.headers}");

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'SUCCESS') {
            print('✅ Data berhasil dikirim: ${response.body}');

            // TAMBAHKAN KODE INI UNTUK SIMPAN KE DATABASE LOKAL
            await _simpanKeDatabaseLokal(
              responseData: responseData,
              noPol: noPol,
              idBus: idBus,
              idUser: idUser,
              idGroup: idGroup,
              idGarasi: idGarasi,
              idCompany: idCompany,
              jumlahTiket: jumlahTiket,
              selectedKategoriTiket: selectedKategoriTiket,
              selectedPilihRit: selectedPilihRit,
              idkotaAwal: idkotaAwal,
              idkotaAkhir: idkotaAkhir,
              namaPembeli: namaPembeli,
              noTelepon: noTelepon,
              hargaKantor: hargaKantor,
              jumlahTagihan: jumlahTagihan,
              jumlahBayar: jumlahBayar,
              jumlahKembalian: jumlahKembalian,
              formattedDate: formattedDate,
              kodeTrayek: kodeTrayek,
              keteranganTagihan: keteranganTagihan,
              paymentChannel: paymentChannel,
            );

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Penjualan tiket berhasil disimpan. No Invoice: ${responseData['data']['invoice_id']}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            print('❌ Gagal menyimpan data: ${response.body}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan data: ${responseData['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print('❌ Error response: ${response.statusCode} - ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan (${response.statusCode})'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('❌ Exception: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } else {
      print('Data harga_kantor tidak ditemukan untuk kota asal: $idkotaAwal dan kota tujuan: $idkotaAkhir');
      if(selectedKategoriTiket=='gratis'){
        jumlahBayar = 0;
      } else {
        jumlahBayar = jumlahTagihan.toDouble();
      }

      // jumlahKembalian = (jumlahTagihan - jumlahBayar).toDouble().toInt();
      jumlahKembalian = (jumlahTagihan - jumlahBayar).abs();

      print("object : $jumlahKembalian ,$selectedKategoriTiket");

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd').format(now);

      print('══════════════════════════════════════════════════');
      print('║ DEBUG _kirimKeBackendAPI - PARAMETER YANG DIKIRIM');
      print('╠══════════════════════════════════════════════════');
      print('║ tanggalTransaksi: $formattedDate');
      print('║ hargaKantor: $hargaKantor');
      print('║ totalTagihan: $totalTagihan');
      print('║ jumlahTiket: $jumlahTiket');
      print('║ selectedPilihRit: $selectedPilihRit');
      print('║ selectedKategoriTiket: $selectedKategoriTiket');
      print('║ selectedKotaBerangkat: $selectedKotaBerangkat');
      print('║ selectedKotaTujuan: $selectedKotaTujuan');
      print('║ namaPembeli: $namaPembeli');
      print('║ noTelepon: $noTelepon');
      print('║ keteranganTagihan: $keteranganTagihan');
      print('║ metodePembayaran: $metodePembayaran');
      print('║ paymentChannel: $paymentChannel');
      print('║ biayaAdmin: $biayaAdmin');
      print('╚══════════════════════════════════════════════════');

      // Debug print nilai yang dihitung
      print('══════════════════════════════════════════════════');
      print('║ DEBUG _kirimKeBackendAPI - NILAI YANG DIHITUNG');
      print('╠══════════════════════════════════════════════════');
      print('║ jarakAwal: $jarakAwal');
      print('║ idkotaAwal: $idkotaAwal');
      print('║ jarakAkhir: $jarakAkhir');
      print('║ idkotaAkhir: $idkotaAkhir');
      print('║ selisihJarak: $selisihJarak');
      print('╚══════════════════════════════════════════════════');

      // Debug print sebelum menyimpan ke database
      print('══════════════════════════════════════════════════');
      print('║ DEBUG _kirimKeBackendAPI - DATA YANG AKAN DISIMPAN');
      print('╠══════════════════════════════════════════════════');
      print('║ no_pol: $noPol');
      print('║ id_bus: $idBus');
      print('║ id_user: $idUser');
      print('║ id_group: $idGroup');
      print('║ id_garasi: $idGarasi');
      print('║ id_company: $idCompany');
      print('║ jumlah_tiket: $jumlahTiket');
      print('║ kategori_tiket: $selectedKategoriTiket');
      print('║ rit: $selectedPilihRit');
      print('║ kota_berangkat: $idkotaAwal');
      print('║ kota_tujuan: $idkotaAkhir');
      print('║ nama_pembeli: $namaPembeli');
      print('║ no_telepon: $noTelepon');
      print('║ harga_kantor: $hargaKantor');
      print('║ jumlah_tagihan: $jumlahTagihan');
      print('║ nominal_bayar: $jumlahBayar');
      print('║ jumlah_kembalian: $jumlahKembalian');
      print('║ kode_trayek: $kodeTrayek');
      print('║ keterangan: $keteranganTagihan');
      print('╚══════════════════════════════════════════════════');

      try {
        double jarakAwal = double.tryParse(selectedKotaBerangkat.split(' - ')[1]) ?? 0;
        int idkotaAwal = int.tryParse(selectedKotaBerangkat.split(' - ')[0]) ?? 1;

        double jarakAkhir = double.tryParse(selectedKotaTujuan.split(' - ')[1]) ?? 0;
        int idkotaAkhir = int.tryParse(selectedKotaTujuan.split(' - ')[0]) ?? 1;

        double selisihJarak = (jarakAwal - jarakAkhir).abs();

        // Prepare request data
        Map<String, dynamic> requestData = {
          'tgl_transaksi': formattedDate,
          'kategori': selectedKategoriTiket,
          'rit': selectedPilihRit,
          'no_pol': noPol,
          'id_bus': idBus,
          'kode_trayek': kodeTrayek,
          'id_personil': idUser,
          'id_group': idGroup,
          'id_kota_berangkat': idkotaAwal.toString(),
          'id_kota_tujuan': idkotaAkhir.toString(),
          'jml_naik': jumlahTiket,
          'harga_kantor': hargaKantor,
          'pendapatan': jumlahTagihan,
          'nama_pelanggan': namaPembeli,
          'no_telepon': noTelepon,
          'keterangan': keteranganTagihan,
          'id_metode_bayar': paymentChannel,
          'payment_channel': paymentChannel,
          'biaya_admin': biayaAdmin,
        };

        // Debug print
        print('══════════════════════════════════════════════════');
        print('║ DATA YANG AKAN DIKIRIM KE API');
        print('╠══════════════════════════════════════════════════');
        requestData.forEach((key, value) {
          print('║ $key: $value');
        });
        print('╚══════════════════════════════════════════════════');

        // Get token from storage
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? token = prefs.getString('token');

        // Make API request
        final response = await http.post(
          Uri.parse('https://apimila.sysconix.id/api/storeregulerfaspay'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(requestData),
        );

        print("📦 Raw response body: '${response.body}'");
        print("📦 Response headers: ${response.headers}");

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == 'SUCCESS') {
            print('✅ Data berhasil dikirim: ${response.body}');

            // TAMBAHKAN KODE INI UNTUK SIMPAN KE DATABASE LOKAL
            await _simpanKeDatabaseLokal(
              responseData: responseData,
              noPol: noPol,
              idBus: idBus,
              idUser: idUser,
              idGroup: idGroup,
              idGarasi: idGarasi,
              idCompany: idCompany,
              jumlahTiket: jumlahTiket,
              selectedKategoriTiket: selectedKategoriTiket,
              selectedPilihRit: selectedPilihRit,
              idkotaAwal: idkotaAwal,
              idkotaAkhir: idkotaAkhir,
              namaPembeli: namaPembeli,
              noTelepon: noTelepon,
              hargaKantor: hargaKantor,
              jumlahTagihan: jumlahTagihan,
              jumlahBayar: jumlahBayar,
              jumlahKembalian: jumlahKembalian,
              formattedDate: formattedDate,
              kodeTrayek: kodeTrayek,
              keteranganTagihan: keteranganTagihan,
              paymentChannel: paymentChannel,
            );

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Penjualan tiket berhasil disimpan. No Invoice: ${responseData['data']['invoice_id']}'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            print('❌ Gagal menyimpan data: ${response.body}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan data: ${responseData['message']}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          print('❌ Error response: ${response.statusCode} - ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Terjadi kesalahan (${response.statusCode})'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        print('❌ Exception: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

  }

  // Fungsi baru untuk menyimpan ke database lokal
  Future<void> _simpanKeDatabaseLokal({
    required dynamic responseData,
    required String? noPol,
    required int idBus,
    required int idUser,
    required int idGroup,
    required int? idGarasi,
    required int idCompany,
    required int jumlahTiket,
    required String selectedKategoriTiket,
    required String selectedPilihRit,
    required int idkotaAwal,
    required int idkotaAkhir,
    required String namaPembeli,
    required String noTelepon,
    required double hargaKantor,
    required double jumlahTagihan,
    required double jumlahBayar,
    required double jumlahKembalian,
    required String formattedDate,
    required String? kodeTrayek,
    required String keteranganTagihan,
    required int paymentChannel,
  }) async {
    try {
      print('🛢️ Memulai proses penyimpanan ke database lokal...');

      // Dapatkan instance database
      Database database = await databaseHelper.database;

      // Cek apakah tabel sudah ada
      bool tableExists = await _isTableExists(database, 'penjualan_tiket');

      if (!tableExists) {
        print("ℹ️ Tabel penjualan_tiket tidak ditemukan, membuat tabel baru...");
        await database.execute('''
        CREATE TABLE IF NOT EXISTS penjualan_tiket (
          id INTEGER PRIMARY KEY,
          no_pol TEXT,
          id_bus INTEGER,
          id_user INTEGER,
          id_group INTEGER,
          id_garasi INTEGER,
          id_company INTEGER,
          jumlah_tiket INTEGER,
          kategori_tiket TEXT,
          rit TEXT,
          kota_berangkat TEXT,
          kota_tujuan TEXT,
          nama_pembeli TEXT,
          no_telepon TEXT,
          harga_kantor REAL,
          jumlah_tagihan REAL,
          nominal_bayar REAL,
          jumlah_kembalian REAL,
          tanggal_transaksi DATETIME,
          status TEXT,
          kode_trayek TEXT,
          keterangan TEXT,
          id_invoice TEXT,
          id_metode_bayar INTEGER,
          nominal_tagihan REAL,
          status_bayar INTEGER,
          trx_id TEXT,
          merchant_id TEXT,
          redirect_url TEXT
        )
      ''');
        print("✅ Tabel penjualan_tiket berhasil dibuat");
      }

      // Ekstrak data dari response Faspay
      final invoiceData = responseData['data']['faspay_response']['invoice'];
      final faspayResponse = responseData['data']['faspay_response']['faspay_response'];

      print('📦 Menyiapkan data untuk disimpan ke database lokal...');

      // Data yang akan disimpan
      Map<String, dynamic> dataToInsert = {
        'no_pol': noPol,
        'id_bus': idBus,
        'id_user': idUser,
        'id_group': idGroup,
        'id_garasi': idGarasi,
        'id_company': idCompany,
        'jumlah_tiket': jumlahTiket,
        'kategori_tiket': selectedKategoriTiket,
        'rit': selectedPilihRit,
        'kota_berangkat': idkotaAwal.toString(),
        'kota_tujuan': idkotaAkhir.toString(),
        'nama_pembeli': namaPembeli,
        'no_telepon': noTelepon,
        'harga_kantor': hargaKantor,
        'jumlah_tagihan': jumlahTagihan,
        'nominal_bayar': jumlahBayar,
        'jumlah_kembalian': jumlahKembalian,
        'tanggal_transaksi': formattedDate,
        'status': 'N',
        'kode_trayek': kodeTrayek,
        'keterangan': keteranganTagihan,
        'id_invoice': invoiceData['id_invoice'],
        'id_metode_bayar': paymentChannel,
        'nominal_tagihan': invoiceData['nominal_tagihan'],
        'status_bayar': invoiceData['status_bayar'],
        'trx_id': faspayResponse['trx_id'],
        'merchant_id': faspayResponse['merchant_id'],
        'redirect_url': faspayResponse['redirect_url'],
      };

      print('📝 Data yang akan disimpan:');
      dataToInsert.forEach((key, value) {
        print('$key: $value');
      });

      // Simpan ke database
      int insertedId = await database.insert('penjualan_tiket', dataToInsert);
      print('✅ Data berhasil disimpan dengan ID: $insertedId');

      // Cetak isi tabel untuk verifikasi
      await _printTableContents(database, 'penjualan_tiket');

      // Tutup koneksi database
      await databaseHelper.closeDatabase();
    } catch (e) {
      print('❌ Gagal menyimpan ke database lokal: $e');
      throw Exception('Gagal menyimpan ke database lokal: $e');
    }
  }

// Fungsi untuk mengecek apakah tabel ada
  Future<bool> _isTableExists(Database db, String tableName) async {
    try {
      List<Map> result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]
      );
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Error saat mengecek tabel: $e');
      return false;
    }
  }

// Fungsi untuk mencetak isi tabel
  Future<void> _printTableContents(Database db, String tableName) async {
    try {
      print('📋 Isi tabel $tableName:');
      List<Map> rows = await db.query(tableName);
      for (var row in rows) {
        print(row);
      }
    } catch (e) {
      print('❌ Gagal mencetak isi tabel: $e');
    }
  }

  Future<void> _kirimValue(double hargaKantor, double jumlahTagihan, int jumlahTiket, String selectedPilihRit, String selectedKategoriTiket, String selectedKotaBerangkat, String selectedKotaTujuan, String namaPembeli, String noTelepon, String keteranganTagihan) async {

    double jarakAwal = double.tryParse(selectedKotaBerangkat.split(' - ')[1]) ?? 0;
    int idkotaAwal = int.tryParse(selectedKotaBerangkat.split(' - ')[0]) ?? 1;

    double jarakAkhir = double.tryParse(selectedKotaTujuan.split(' - ')[1]) ?? 0;
    int idkotaAkhir = int.tryParse(selectedKotaTujuan.split(' - ')[0]) ?? 1;

    double jumlahBayar = 0;
    double jumlahKembalian = 0;

    double selisihJarak = (jarakAwal - jarakAkhir).abs();

    print('saya disini: $hargaKantor ');

    List<Map<String, dynamic>> hargaKantorData = await databaseHelper.getCariHargaKantor(idkotaAwal, idkotaAkhir);

    if (hargaKantorData.isNotEmpty) {
      double hargaKantor = hargaKantorData[0]['harga_kantor'];
      double marginTarikan = hargaKantorData[0]['margin_tarikan'];
      print('1. value cariHargaKantor $kelasBus $jumlahTiket $idkotaAwal $idkotaAkhir : $hargaKantor $marginTarikan');
    } else {
      // Jika hargaKantorData kosong, tetapkan hargaKantor ke nilai default atau tangani kasus kosong
      double hargaKantor = 0; // atau nilai default yang sesuai
      print('Data Harga Kantor tidak ditemukan, menggunakan nilai default 0');
      print('2. value cariHargaKantor $kelasBus $jumlahTiket $idkotaAwal $idkotaAkhir : $hargaKantor');
    }

    if (hargaKantor == 0) {
      // Hitung jumlahTagihan
      // setState(() {
      //   hargaKantor = (hargaKantor * jumlahTiket).toDouble();
      // });
      if (kelasBus == 'Non Ekonomi') {
        hargaKantor = (((biayaPerkursi + marginKantor) / jarakPP) * selisihJarak * jumlahTiket);
        print('1. value calculate $kelasBus : $biayaPerkursi , $marginKantor , $jarakPP , $selisihJarak , $jumlahTiket , $jumlahTagihan');
      } else if (kelasBus == 'Ekonomi') {
        hargaKantor = (((biayaPerkursi + marginKantor) / jarakPP) * selisihJarak * jumlahTiket);
        print('2.0 value calculate $kelasBus $jumlahTiket $idkotaAwal $idkotaAkhir : $biayaPerkursi $marginKantor $marginTarikan $jarakPP $selisihJarak $jumlahTagihan');
      }
      print('2.1 value calculate $kelasBus $jumlahTiket $idkotaAwal $idkotaAkhir : $hargaKantor $marginTarikan');
      print("object : $hargaKantor , $jumlahTagihan , $jumlahBayar , $jumlahTiket , $selectedKotaBerangkat , $selectedKotaTujuan");

      if(selectedKategoriTiket=='gratis'){
        jumlahBayar = 0;
      } else {
        jumlahBayar = jumlahTagihan.toDouble();
      }

      // jumlahKembalian = (jumlahTagihan - jumlahBayar).toDouble().toInt();
      jumlahKembalian = (jumlahTagihan - jumlahBayar).abs();

      print("object : $jumlahKembalian ,$selectedKategoriTiket");

      DateTime now = DateTime.now();
      // Format tanggal dengan waktu
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

      print('Formatted Date with Time: $formattedDate');

      Database database = await databaseHelper.database;
      bool tableExists = await isTableExists(database, 'penjualan_tiket');

      if (tableExists) {
        print("Tabel penjualan_tiket ada dalam database");
      } else {
        print("Tabel penjualan_tiket tidak ditemukan dalam database");
        await database.execute('''
        CREATE TABLE IF NOT EXISTS penjualan_tiket (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          no_pol TEXT,
          id_bus INTEGER,
          id_user INTEGER,
          id_group INTEGER,
          id_garasi INTEGER,
          id_company INTEGER,
          jumlah_tiket INTEGER,
          kategori_tiket TEXT,
          rit TEXT,
          kota_berangkat TEXT,
          kota_tujuan TEXT,
          nama_pembeli TEXT,
          no_telepon TEXT,
          harga_kantor REAL,
          jumlah_tagihan REAL,
          nominal_bayar REAL,
          jumlah_kembalian REAL,
          tanggal_transaksi TEXT,
          status TEXT,
          kode_trayek TEXT,
          keterangan TEXT
          fupload TEXT,
          file_name TEXT
        )
      ''');
        print("Tabel penjualan_tiket berhasil dibuat");
      }
      print("DEBUG FOTO LOCAL PATH: $fotoLocalPath");
      print("DEBUG FOTO FILE NAME: $fotoFileName");

      await database.insert(
        'penjualan_tiket',{
        'no_pol': noPol,
        'id_bus': idBus,
        'id_user': idUser,
        'id_group': idGroup,
        'id_garasi': idGarasi,
        'id_company': idCompany,
        'jumlah_tiket': jumlahTiket,
        'kategori_tiket': selectedKategoriTiket,
        'rit': selectedPilihRit,
        'kota_berangkat': idkotaAwal.toString(),
        'kota_tujuan': idkotaAkhir.toString(),
        'nama_pembeli': namaPembeli,
        'no_telepon': noTelepon,
        'harga_kantor': hargaKantor,
        'jumlah_tagihan': jumlahTagihan,
        'nominal_bayar': jumlahBayar,
        'jumlah_kembalian': jumlahKembalian,
        'tanggal_transaksi': formattedDate,
        'status': 'N',
        'kode_trayek': kodeTrayek,
        'keterangan': keteranganTagihan,
        'fupload': fotoLocalPath ?? '',   // path file disimpan
        'file_name': fotoFileName ?? '',  // nama file
      },
      );
      print('Data penjualan tiket berhasil disimpan:');
      printTableContents(database, 'penjualan_tiket');
      await databaseHelper.closeDatabase();
    } else {
      print('Data harga_kantor tidak ditemukan untuk kota asal: $idkotaAwal dan kota tujuan: $idkotaAkhir');
      if(selectedKategoriTiket=='gratis'){
        jumlahBayar = 0;
      } else {
        jumlahBayar = jumlahTagihan.toDouble();
      }

      // jumlahKembalian = (jumlahTagihan - jumlahBayar).toDouble().toInt();
      jumlahKembalian = (jumlahTagihan - jumlahBayar).abs();

      print("object : $jumlahKembalian ,$selectedKategoriTiket");

      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd').format(now);

      Database database = await databaseHelper.database;
      bool tableExists = await isTableExists(database, 'penjualan_tiket');

      if (tableExists) {
        print("Tabel penjualan_tiket ada dalam database");
      } else {
        print("Tabel penjualan_tiket tidak ditemukan dalam database");
        await database.execute('''
        CREATE TABLE IF NOT EXISTS penjualan_tiket (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          no_pol TEXT,
          id_bus INTEGER,
          id_user INTEGER,
          id_group INTEGER,
          id_garasi INTEGER,
          id_company INTEGER,
          jumlah_tiket INTEGER,
          kategori_tiket TEXT,
          rit TEXT,
          kota_berangkat TEXT,
          kota_tujuan TEXT,
          nama_pembeli TEXT,
          no_telepon TEXT,
          harga_kantor REAL,
          jumlah_tagihan REAL,
          nominal_bayar REAL,
          jumlah_kembalian REAL,
          tanggal_transaksi TEXT,
          status TEXT,
          kode_trayek TEXT,
          keterangan TEXT,
          fupload TEXT,
          file_name TEXT
        )
      ''');
        print("Tabel penjualan_tiket berhasil dibuat");
      }

      await database.insert(
        'penjualan_tiket',{
        'no_pol': noPol,
        'id_bus': idBus,
        'id_user': idUser,
        'id_group': idGroup,
        'id_garasi': idGarasi,
        'id_company': idCompany,
        'jumlah_tiket': jumlahTiket,
        'kategori_tiket': selectedKategoriTiket,
        'rit': selectedPilihRit,
        'kota_berangkat': idkotaAwal.toString(),
        'kota_tujuan': idkotaAkhir.toString(),
        'nama_pembeli': namaPembeli,
        'no_telepon': noTelepon,
        'harga_kantor': hargaKantor,
        'jumlah_tagihan': jumlahTagihan,
        'nominal_bayar': jumlahBayar,
        'jumlah_kembalian': jumlahKembalian,
        'tanggal_transaksi': formattedDate,
        'status': 'N',
        'kode_trayek': kodeTrayek,
        'keterangan': keteranganTagihan,
      },
      );
      print('Data penjualan tiket berhasil disimpan:');
      printTableContents(database, 'penjualan_tiket');
      await databaseHelper.closeDatabase();
    }

  }


  Future<bool> isTableExists(Database database, String tableName) async {
    List<Map<String, dynamic>> result = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
    );

    return result.isNotEmpty;
  }

  void printTableContents(Database database, String tableName) async {
    List<Map<String, dynamic>> result = await database.query(tableName);

    if (result.isNotEmpty) {
      print("Isi tabel $tableName:");

      for (Map<String, dynamic> row in result) {
        print(row);
      }
    } else {
      print("Tabel $tableName kosong");
    }
  }

  Future<void> _ambilFoto() async {
    final ImagePicker picker = ImagePicker();

    final XFile? foto = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 40,        // 0 - 100 (semakin kecil semakin kecil ukuran)
      maxWidth: 800,           // resize otomatis
      maxHeight: 800,
    );

    if (foto != null) {
      String fileName = "penumpang_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final directory = await getApplicationDocumentsDirectory();
      final folderPath = "${directory.path}/foto_penumpang";
      await Directory(folderPath).create(recursive: true);

      final String savedPath = "$folderPath/$fileName";

      // langsung copy hasil foto yg sudah terkompres
      await File(foto.path).copy(savedPath);

      setState(() {
        fotoPenumpang = foto;
        fotoLocalPath = savedPath;
        fotoFileName = fileName;
      });

      print("Foto tersimpan di: $savedPath");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 20, // ✅ Tambah jarak bawah
          ),
          child: Column(
            children: [
              SizedBox(height: 40.0),
              Text('$namaTrayek $jenisTrayek $kelasBus'),
              SizedBox(height: 16.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Form(
                  key: _formKey, // Add form key
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Kategori Tiket',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedKategoriTiket,
                        items: [
                          DropdownMenuItem<String>(
                            child: Text('Pilih'),
                            value: 'default',
                          ),
                          DropdownMenuItem<String>(
                            child: Text('Reguler'),
                            value: 'reguler',
                          ),
                          DropdownMenuItem<String>(
                            child: Text('Traveloka'),
                            value: 'traveloka',
                          ),
                          DropdownMenuItem<String>(
                            child: Text('Red Bus'),
                            value: 'red_bus',
                          ),
                          // DropdownMenuItem<String>(
                          //   child: Text('12GO'),
                          //   value: 'go_asia',
                          // ),
                          DropdownMenuItem<String>(
                            child: Text('Pnp.Operan'),
                            value: 'operan',
                          ),
                          DropdownMenuItem<String>(
                            child: Text('Pnp.Sepi'),
                            value: 'sepi',
                          ),
                          DropdownMenuItem<String>(
                            child: Text('Pnp.TNI'),
                            value: 'tni',
                          ),
                          DropdownMenuItem<String>(
                            child: Text('Pnp.Pelajar'),
                            value: 'pelajar',
                          ),
                          DropdownMenuItem<String>(
                            child: Text('Pnp.Gratis'),
                            value: 'gratis',
                          ),
                          DropdownMenuItem<String>(
                            child: Text('Langganan (LG)'),
                            value: 'langganan',
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedKategoriTiket = value ?? 'default';
                            _updateVisibility(selectedKategoriTiket);
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kategori Tiket harus diisi';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Pilih Rit',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedPilihRit,
                              items: [
                                DropdownMenuItem<String>(
                                  child: Text('Rit-1'),
                                  value: '1',
                                ),
                                DropdownMenuItem<String>(
                                  child: Text('Rit-2'),
                                  value: '2',
                                ),
                                DropdownMenuItem<String>(
                                  child: Text('Rit-3'),
                                  value: '3',
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedPilihRit = value ?? '1';
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return 'Pilih Rit harus diisi';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16.0),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Jml.Tiket',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 18),
                              onChanged: (value) {
                                if (value.isNotEmpty) {
                                  setState(() {
                                    jumlahTiket = int.tryParse(value) ?? 0;
                                  });
                                  _calculateTagihan(
                                    selectedKategoriTiket ?? '',
                                    kelasBus,
                                    jumlahTiket,
                                    selectedKotaBerangkat ?? '', // Handle null value
                                    selectedKotaTujuan ?? '', // Handle null value
                                  );
                                }
                              },
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Jumlah Tiket harus diisi';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isNamaPembeliVisible,
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Nama Pembeli',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.text,
                          onChanged: (value) {
                            setState(() {
                              namaPembeli = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama Langganan harus diisi';
                            }
                            return null;
                          },
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isNotlpPembeliVisible,
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'No.Telepon',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            setState(() {
                              noTelepon = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nomor Telepon harus diisi';
                            }
                            return null;
                          },
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isKotaBerangkatVisible,
                        child: DropdownButtonFormField(
                          decoration: InputDecoration(
                            labelText: 'Kota Berangkat',
                            border: OutlineInputBorder(),
                          ),
                          items: listKota.map((kota) {
                            String valueText =
                                '${kota['id_kota_tujuan']} - ${kota['jarak']}';
                            return DropdownMenuItem(
                              child: Text(kota['nama_kota']),
                              value: valueText,
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedKotaBerangkat = value;
                            });
                            _calculateTagihan(
                              selectedKategoriTiket ?? '',
                              kelasBus,
                              jumlahTiket,
                              selectedKotaBerangkat ?? '', // Handle null value
                              selectedKotaTujuan ?? '', // Handle null value
                            );
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Kota Berangkat harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isKotaTujuanVisible,
                        child: DropdownButtonFormField(
                          decoration: InputDecoration(
                            labelText: 'Kota Tujuan',
                            border: OutlineInputBorder(),
                          ),
                          items: listKota.map((kota) {
                            String valueText =
                                '${kota['id_kota_tujuan']} - ${kota['jarak']}';
                            return DropdownMenuItem(
                              child: Text(kota['nama_kota']),
                              value: valueText,
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedKotaTujuan = value;
                            });
                            _calculateTagihan(
                              selectedKategoriTiket ?? '',
                              kelasBus,
                              jumlahTiket,
                              selectedKotaBerangkat ?? '', // Handle null value
                              selectedKotaTujuan ?? '', // Handle null value
                            );
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Kota Tujuan harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isSarantagihanVisible,
                        child: TextFormField(
                          controller: sarantagihanController,
                          decoration: InputDecoration(
                            labelText: 'Tagihan',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 18),
                          enabled: false, // Set enabled to false
                          onChanged: (value) {},
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Tagihan harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isHargaKantorVisible,
                        child: TextFormField(
                          controller: hargaKantorController,
                          decoration: InputDecoration(
                            labelText: 'Harga Kantor',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 18),
                          enabled: false, // Set enabled to false
                          onChanged: (value) {
                            setState(() {
                              hargaKantor = double.tryParse(value) ?? 0.0;
                            });
                          },
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Harga Kantor harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isTagihanVisible,
                        child: TextFormField(
                          controller: tagihanController,
                          decoration: InputDecoration(
                            labelText: 'Harga Tarikan',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 18),
                          onChanged: (value) {
                            setState(() {
                              jumlahTagihan = double.tryParse(value) ?? 0.0;
                              _calculateKembalian(
                                  jumlahBayar.toDouble(), jumlahTagihan);
                            });
                          },
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Jumlah Tagihan harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isFotoVisible,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header dengan icon
                              Row(
                                children: [
                                  Icon(Icons.photo_camera, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Upload Foto Penumpang",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Konten utama
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Tombol Ambil Foto
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Colors.blue.shade50,
                                            Colors.blue.shade100,
                                          ],
                                        ),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _ambilFoto,
                                          borderRadius: BorderRadius.circular(10),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue[700],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  color: Colors.white,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                "Ambil Foto",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.blue[700],
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                "Kamera akan terbuka",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: 16),

                                  // Preview Foto
                                  Expanded(
                                    flex: 1,
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: fotoPenumpang == null
                                              ? Colors.grey.shade300
                                              : Colors.green.shade300,
                                          width: 1.5,
                                        ),
                                        color: fotoPenumpang == null
                                            ? Colors.grey.shade50
                                            : Colors.green.shade50,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: fotoPenumpang == null
                                          ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.photo,
                                            size: 40,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "Belum ada foto",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                          : ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          children: [
                                            Image.file(
                                              File(fotoPenumpang!.path),
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                            // Overlay dengan efek gradien
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withOpacity(0.1),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Badge konfirmasi di sudut
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.green.shade500,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 12,
                                                    ),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      "OK",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Status/Info tambahan
                              if (fotoPenumpang != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade600,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Foto penumpang berhasil diambil",
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  SizedBox(height: 16),
                      Visibility(
                        visible: isMetodePembayaranVisible,
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Metode Pembayaran',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedMetodePembayaran,
                          items: listMetodePembayaran.map((item) {
                            return DropdownMenuItem<String>(
                              value: item['id'].toString(),
                              child: Text(item['nama'] ?? 'Metode Tidak Dikenal'),
                            );
                          }).toList(),
                          // 2. Perbaikan pada bagian onChanged metode pembayaran
                          onChanged: (value) {
                            if (value == null) return;

                            print('[DEBUG] Metode pembayaran dipilih: $value');

                            var selected = listMetodePembayaran.firstWhere(
                                  (el) => el['id'].toString() == value,
                              orElse: () => {},
                            );

                            if (selected.isNotEmpty) {
                              print('[DEBUG] Data metode yang dipilih: $selected');
                              print('[DEBUG] Payment Channel: ${selected['payment_channel']}');

                              // Perbaikan parsing biaya_admin dengan penanganan persentase
                              dynamic rawBiayaAdmin = selected['biaya_admin'];
                              int parsedBiayaAdmin = 0;

                              if (rawBiayaAdmin != null) {
                                if (rawBiayaAdmin is int) {
                                  // Jika biaya_admin < 100, anggap sebagai persentase
                                  parsedBiayaAdmin = rawBiayaAdmin < 100
                                      ? (jumlahTagihan * rawBiayaAdmin / 100).round()
                                      : rawBiayaAdmin;
                                } else if (rawBiayaAdmin is double) {
                                  // Jika biaya_admin < 100.0, anggap sebagai persentase (baik 0.7% maupun 2.5%)
                                  if (rawBiayaAdmin < 100.0) {
                                    parsedBiayaAdmin = (jumlahTagihan * rawBiayaAdmin / 100).round();
                                    print('[PERHITUNGAN] Biaya admin: $jumlahTagihan * $rawBiayaAdmin% = $parsedBiayaAdmin');
                                  } else {
                                    parsedBiayaAdmin = rawBiayaAdmin.round();
                                  }
                                } else if (rawBiayaAdmin is String) {
                                  double? parsedValue = double.tryParse(rawBiayaAdmin);
                                  if (parsedValue != null) {
                                    parsedBiayaAdmin = parsedValue < 100.0
                                        ? (jumlahTagihan * parsedValue / 100).round()
                                        : parsedValue.round();
                                  }
                                }
                              }

                              print('[DEBUG] Raw biaya_admin: $rawBiayaAdmin (${rawBiayaAdmin.runtimeType})');
                              print('[DEBUG] Parsed biaya_admin: $parsedBiayaAdmin');

                              setState(() {
                                selectedMetodePembayaran = value;
                                biayaAdmin = parsedBiayaAdmin;
                                paymentChannel = selected['payment_channel'] != null
                                    ? int.tryParse(selected['payment_channel'].toString()) ?? 0
                                    : 0;

                                isTotalDenganAdminVisible = value != '1';
                              });

                              _updateTotalDenganBiayaAdmin();
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Metode Pembayaran harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isTotalDenganAdminVisible,
                        child: TextFormField(
                          controller: totalDenganAdminController,
                          decoration: InputDecoration(
                            labelText: 'Total Termasuk Biaya Admin',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          enabled: false,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isKeteranganVisible,
                        child: TextFormField(
                          controller: keteranganController,
                          decoration: InputDecoration(
                            labelText: 'Keterangan',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              keteranganTagihan = value;
                            });
                          },
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isJumlahBayarVisible,
                        child: TextFormField(
                          controller: bayarController,
                          decoration: InputDecoration(
                            labelText: 'Ketik Jumlah Bayar',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 18),
                          onChanged: (value) {
                            setState(() {
                              jumlahBayar = double.tryParse(value) ?? 0.0;
                            });
                            _calculateKembalian(jumlahBayar, jumlahTagihan);
                          },
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Jumlah Bayar harus diisi';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isJumlahKembalianVisible,
                        child: TextFormField(
                          controller: kembalianController,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Kembalian',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 18),
                          enabled: false, // Set enabled to false
                        ),
                      ),
                      SizedBox(height: 16.0),
                      Visibility(
                        visible: isTombolVisible,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  this.getBluetooth();
                                  // Cek apakah izin diberikan, jika tidak, minta izin.
                                  if (!await _checkBluetoothPermission()) {
                                    await _requestBluetoothPermission();
                                  }
                                },
                                child: Text('Set.Printer'),
                                style: ButtonStyle(
                                  minimumSize: WidgetStateProperty.all(
                                      Size(double.infinity, 48.0)),
                                  backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.pressed)) {
                                        return Colors.grey; // Warna abu-abu saat tombol ditekan
                                      } else {
                                        return Colors.blue; // Warna biru saat tombol tidak ditekan
                                      }
                                    },
                                  ),
                                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                      return Colors.white; // Warna teks putih
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10), // Spasi antara tombol
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    // Jika metode pembayaran bukan 1 (tunai), kirim ke API
                                    if (selectedMetodePembayaran != '1') {
                                      await _kirimKeBackendAPI(
                                        hargaKantor,
                                        totalTagihanPlusBiayaAdmin, // Menggunakan total dengan biaya admin
                                        jumlahTiket,
                                        selectedPilihRit,
                                        selectedKategoriTiket,
                                        selectedKotaBerangkat ?? '',
                                        selectedKotaTujuan ?? '',
                                        namaPembeli,
                                        noTelepon,
                                        keteranganTagihan,
                                        selectedMetodePembayaran ?? '', // Tambahkan parameter metode pembayaran
                                        paymentChannel, // Tambahkan parameter payment channel
                                        biayaAdmin, // Tambahkan parameter biaya admin
                                      );
                                    } else {
                                      // Jika metode pembayaran adalah tunai (1), lakukan proses biasa
                                      await _kirimValue(
                                        hargaKantor,
                                        jumlahTagihan,
                                        jumlahTiket,
                                        selectedPilihRit,
                                        selectedKategoriTiket,
                                        selectedKotaBerangkat ?? '',
                                        selectedKotaTujuan ?? '',
                                        namaPembeli,
                                        noTelepon,
                                        keteranganTagihan,
                                      ).then((_) {
                                        printTicket();
                                      });
                                    }
                                  }
                                },
                                child: Text('Simpan'),
                                style: ButtonStyle(
                                  minimumSize: WidgetStateProperty.all(
                                      Size(double.infinity, 48.0)),
                                  backgroundColor:
                                  WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                      if (states.contains(WidgetState.pressed)) {
                                        return Colors.grey; // Warna abu-abu saat tombol ditekan
                                      } else {
                                        return Colors.green; // Warna hijau saat tombol tidak ditekan
                                      }
                                    },
                                  ),
                                  foregroundColor: WidgetStateProperty.resolveWith<Color>(
                                        (Set<WidgetState> states) {
                                      return Colors.white; // Warna teks putih
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  void _updateVisibility(String selectedKategoriTiket) {
    // DEFAULT
    if (selectedKategoriTiket == 'default') {
      isHargaKantorVisible = false;
      isTombolVisible = false;
      isKotaBerangkatVisible = false;
      isKotaTujuanVisible = false;
      isSarantagihanVisible = false;
      isTagihanVisible = false;
      isJumlahBayarVisible = false;
      isJumlahKembalianVisible = false;
      isNamaPembeliVisible = false;
      isNotlpPembeliVisible = false;
      isKeteranganVisible = false;
      isMetodePembayaranVisible = false;
      isFotoVisible = false;
    }
    // ==============================
    // 1️⃣  KATEGORI TANPA FOTO
    // ==============================
    else if (selectedKategoriTiket == 'red_bus' ||
        selectedKategoriTiket == 'traveloka' ||
        selectedKategoriTiket == 'go_asia') {

      isFotoVisible = false; // ← WAJIB TIDAK ADA FOTO

      if (kelasBus == 'Ekonomi') {
        isHargaKantorVisible = true;
        isTombolVisible = true;
        isKotaBerangkatVisible = true;
        isKotaTujuanVisible = true;
        isSarantagihanVisible = false;
        isTagihanVisible = true;
        isJumlahBayarVisible = false;
        isJumlahKembalianVisible = false;
        isNamaPembeliVisible = true;
        isNotlpPembeliVisible = true;
        isKeteranganVisible = true;
        isMetodePembayaranVisible = false;
      } else if (kelasBus == 'Non Ekonomi') {
        isHargaKantorVisible = false;
        isTombolVisible = true;
        isKotaBerangkatVisible = true;
        isKotaTujuanVisible = true;
        isSarantagihanVisible = false;
        isTagihanVisible = true;
        isJumlahBayarVisible = false;
        isJumlahKembalianVisible = false;
        isNamaPembeliVisible = true;
        isNotlpPembeliVisible = true;
        isKeteranganVisible = true;
        isMetodePembayaranVisible = false;
      }
    }
    // ==============================
    // 2️⃣  KATEGORI WAJIB FOTO
    // ==============================
    else if (selectedKategoriTiket == 'operan' ||
        selectedKategoriTiket == 'sepi' ||
        selectedKategoriTiket == 'tni' ||
        selectedKategoriTiket == 'pelajar' ||
        selectedKategoriTiket == 'gratis') {

      isFotoVisible = true; // ← WAJIB ADA FOTO

      if (kelasBus == 'Ekonomi') {
        isHargaKantorVisible = true;
        isTombolVisible = true;
        isKotaBerangkatVisible = true;
        isKotaTujuanVisible = true;
        isSarantagihanVisible = false;
        isTagihanVisible = true;
        isJumlahBayarVisible = false;
        isJumlahKembalianVisible = false;
        isNamaPembeliVisible = true;
        isNotlpPembeliVisible = true;
        isKeteranganVisible = true;
        isMetodePembayaranVisible = false;
      } else if (kelasBus == 'Non Ekonomi') {
        isHargaKantorVisible = false;
        isTombolVisible = true;
        isKotaBerangkatVisible = true;
        isKotaTujuanVisible = true;
        isSarantagihanVisible = false;
        isTagihanVisible = true;
        isJumlahBayarVisible = false;
        isJumlahKembalianVisible = false;
        isNamaPembeliVisible = true;
        isNotlpPembeliVisible = true;
        isKeteranganVisible = true;
        isMetodePembayaranVisible = false;
      }
    }

    // ==============================
    // 3️⃣  KATEGORI REGULER
    // ==============================
    else if (selectedKategoriTiket == 'reguler' && kelasBus == 'Ekonomi') {
      isHargaKantorVisible = true;
      isTombolVisible = true;
      isKotaBerangkatVisible = true;
      isKotaTujuanVisible = true;
      isSarantagihanVisible = false;
      isTagihanVisible = true;
      isJumlahBayarVisible = false;
      isJumlahKembalianVisible = false;
      isNamaPembeliVisible = false;
      isNotlpPembeliVisible = false;
      isMetodePembayaranVisible = true;
      isFotoVisible = false;
    } else if (selectedKategoriTiket == 'reguler' && kelasBus == 'Non Ekonomi') {
      isHargaKantorVisible = false;
      isTombolVisible = true;
      isKotaBerangkatVisible = true;
      isKotaTujuanVisible = true;
      isSarantagihanVisible = true;
      isTagihanVisible = false;
      isJumlahBayarVisible = false;
      isJumlahKembalianVisible = false;
      isNamaPembeliVisible = false;
      isNotlpPembeliVisible = false;
      isMetodePembayaranVisible = true;
      isFotoVisible = false;
    }

    // ==============================
    // 4️⃣  KATEGORI LANGGANAN
    // ==============================
    else if (selectedKategoriTiket == 'langganan' && kelasBus == 'Ekonomi') {
      isHargaKantorVisible = true;
      isTombolVisible = true;
      isKotaBerangkatVisible = true;
      isKotaTujuanVisible = true;
      isSarantagihanVisible = false;
      isTagihanVisible = true;
      isJumlahBayarVisible = false;
      isJumlahKembalianVisible = false;
      isNamaPembeliVisible = false;
      isNotlpPembeliVisible = false;
      isMetodePembayaranVisible = true;
      isFotoVisible = true;
    } else if (selectedKategoriTiket == 'langganan' && kelasBus == 'Non Ekonomi') {
      isHargaKantorVisible = false;
      isTombolVisible = true;
      isKotaBerangkatVisible = true;
      isKotaTujuanVisible = true;
      isSarantagihanVisible = true;
      isTagihanVisible = true;
      isJumlahBayarVisible = false;
      isJumlahKembalianVisible = false;
      isNamaPembeliVisible = true;
      isNotlpPembeliVisible = true;
      isMetodePembayaranVisible = true;
      isFotoVisible = true;
    }
  }

}