import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// Untuk Uint8List
import 'package:flutter/services.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class FormBagasiBus extends StatefulWidget {
  @override
  _FormBagasiBusState createState() => _FormBagasiBusState();
}

class _FormBagasiBusState extends State<FormBagasiBus> {
  List<Map<String, dynamic>> jenisPaket = [];
  Map<int, String?> selectedItems = {}; // Untuk menyimpan status dropdown
  Map<int, String> deskripsi = {}; // Untuk menyimpan komentar dari TextField
  Map<int, double> persen = {}; // Untuk menyimpan nilai persen sebagai double
  String? selectedJenisPaket; // Ubah tipe data menjadi String?
  final UserService _userService = UserService(); // Tambahkan ini

  // Definisikan variabel yang belum ada
  int qtyBarang = 0;
  String? selectedKotaBerangkat;
  String? selectedKotaTujuan;

  late int idUser;
  int idGroup = 0;
  int idCompany = 0;
  int? idGarasi;
  int idBus = 0;
  String? noPol;
  late String token;

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
  double tagihan = 0;
  double jumlahTagihan = 0;
  double biayakm = 0;
  double biayaperjalanan = 0;
  double qtyPersen = 0;
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
  late String keterangan = ''; // Initialize with an empty string

  get hasBluetoothPermission => null;
  List availableBluetoothDevices = [];

  //image picker
  File? _image; // Untuk menyimpan file gambar yang diambil
  final ImagePicker _picker = ImagePicker();

  // Tambahkan ini untuk mengubah gambar menjadi base64
  String? _base64Image;
  String? _fileName;

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  List<Map<String, dynamic>> listKota = [];

  final TextEditingController _namaPengirimController = TextEditingController();
  final TextEditingController _noTlpPengirimController = TextEditingController();
  final TextEditingController _namaPenerimaController = TextEditingController();
  final TextEditingController _noTlpPenerimaController = TextEditingController();
  final TextEditingController _qtyBarangController = TextEditingController();
  final TextEditingController _hargaKmController = TextEditingController();
  final TextEditingController _keteranganController = TextEditingController();

  DatabaseHelper databaseHelper = DatabaseHelper.instance;
  final formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );


  @override
  void initState() {
    super.initState();
    _getJenisPaket();
    _getListKota();
    _loadLastKotaTerakhir();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        idUser = prefs.getInt('idUser') ?? 0;
        idGarasi = prefs.getInt('idGarasi');
        idBus = prefs.getInt('idBus') ?? 0;
        noPol = prefs.getString('noPol');
        kodeTrayek = prefs.getString('kode_trayek');
        token = prefs.getString('token') ?? '';
      });
    });
  }

  @override
  void dispose() {
    // Putuskan koneksi printer saat dispose
    if (_isConnected) {
      _bluetooth.disconnect();
    }
    super.dispose();
  }

  // Fungsi untuk mengambil gambar dari kamera atau galeri
  Future<void> _ambilGambar(bool fromCamera) async {
    // Memastikan izin sudah diberikan sebelum melanjutkan
    await _requestPermission();

    final pickedFile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Menyimpan file gambar yang diambil
      });
    }
  }

  // Fungsi untuk meminta izin akses kamera dan galeri
  Future<void> _requestPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }

    var storageStatus = await Permission.storage.status;
    if (!storageStatus.isGranted) {
      await Permission.storage.request();
    }
  }

  /// Kompresi gambar menggunakan library 'image'
  Future<File?> compressImage(File file) async {
    try {
      // Baca file asli sebagai byte
      final bytes = await file.readAsBytes();

      // Decode gambar ke format image dari package 'image'
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Resize atau ubah ukuran jika perlu (misalnya max width 800px)
      final resizedImage = img.copyResize(image, width: 800);

      // Encode ulang ke JPG dengan kualitas tertentu
      final compressedBytes = img.encodeJpg(resizedImage, quality: 75);

      // Simpan file hasil kompresi ke temporary directory
      final tempDir = await getTemporaryDirectory();
      final outPath = p.join(tempDir.path, '${DateTime.now().millisecondsSinceEpoch}_compressed.jpg');
      final compressedFile = await File(outPath).writeAsBytes(compressedBytes);

      return compressedFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<void> _submitForm(int idjenisPaket, int idkotaAwal, int idkotaAkhir) async {
    DateTime now = DateTime.now();
    String formattedIdOrder = DateFormat('yyyyMMddHHmmss').format(now);
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final dbHelper = DatabaseHelper.instance;
    Database db = await dbHelper.database;

    // Hitung jumlahTagihan dari controller
    double jumlahTagihan = double.tryParse(_hargaKmController.text) ?? 0.0;

    // Jika gambar diambil, kompres gambar terlebih dahulu
    if (_image != null) {
      // Mengkompres gambar
      File? compressedImage = await compressImage(_image!);
      if (compressedImage != null) {
        // Mengambil path gambar dan nama file
        _fileName = compressedImage.path.split('/').last;
        final bytes = await compressedImage.readAsBytes();
        _base64Image = base64Encode(bytes);  // Konversi gambar terkompresi ke base64
      } else {
        Fluttertoast.showToast(msg: "Gagal mengkompres gambar");
        return;
      }
    }

    // Simpan data ke database
    try {
      await db.insert('t_order_bagasi', {
        'tgl_order': formattedDate,
        'id_jenis_paket': idjenisPaket,
        'id_order': '${idBus}${idUser}${formattedIdOrder}',
        'rit': 0,
        'id_bus': idBus,
        'no_pol': noPol,
        'kode_trayek': kodeTrayek,
        'id_personil': idUser,
        'id_group': idGroup,
        'id_kota_berangkat': idkotaAwal,
        'id_kota_tujuan': idkotaAkhir,
        'qty_barang': _qtyBarangController.text,
        'harga_km': jumlahTagihan, // Gunakan jumlahTagihan yang sudah dihitung
        'jml_harga': jumlahTagihan.toString(), // Simpan sebagai string
        'nama_pengirim': _namaPengirimController.text,
        'no_tlp_pengirim': _noTlpPengirimController.text,
        'nama_penerima': _namaPenerimaController.text,
        'no_tlp_penerima': _noTlpPenerimaController.text,
        'keterangan': _keteranganController.text,
        'fupload': _base64Image,
        'file_name': _fileName,
        'status': 'N',
      });


      String toastMessage = "Data berhasil disimpan:\n"
          "Nama Pengirim: ${_namaPengirimController.text}\n"
          "No. Telp Pengirim: ${_noTlpPengirimController.text}\n"
          "Nama Penerima: ${_namaPenerimaController.text}\n"
          "No. Telp Penerima: ${_noTlpPenerimaController.text}\n"
          "Qty Barang: ${_qtyBarangController.text}\n"
          "Jenis Paket: $idjenisPaket\n"
          "Kota Berangkat: $idkotaAwal\n"
          "Kota Tujuan: $idkotaAkhir\n"
          "Kota Trayek: $kodeTrayek\n"
          "Tagihan: ${_hargaKmController.text}\n"
          "Keterangan: ${_keteranganController.text}\n";
      if (_image != null) {
        toastMessage += "Gambar berhasil diunggah: $_fileName\n";
      } else {
        toastMessage += "Tidak ada gambar yang diunggah.\n";
      }

      Fluttertoast.showToast(msg: toastMessage);
    } catch (error) {
      print("Error inserting data: $error");
      Fluttertoast.showToast(msg: "Gagal menyimpan data");
    }

    Navigator.pop(context); // Kembali ke halaman sebelumnya
  }

  Future<void> _loadLastKotaTerakhir() async {
    await databaseHelper.initDatabase();
    await _getListKota();
    await _getUserData();
    await _getListKotaTerakhir();
    await databaseHelper.closeDatabase();

    // Set initial value for tagihanController
    _hargaKmController.text = formatter.format(jumlahTagihan);
  }


  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

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

  Future<void> _getUserData() async {
    try {
      // GUNAKAN UserService instead of databaseHelper
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
    }catch (e) {
      print('Error saat mengambil data: $e');
    }

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
      }
    } catch (e) {
      print('Error saat mengambil data: $e');
    }
  }

  Future<void> _getJenisPaket() async {
    await databaseHelper.initDatabase();
    List<Map<String, dynamic>> items = await databaseHelper.getAllJenisPaket();
    await databaseHelper.closeDatabase();
    setState(() {
      jenisPaket = items;
      // Optional: Set default value jika ada data
      if (items.isNotEmpty) {
        selectedJenisPaket = '${items[0]['id']} - ${items[0]['persen']} - ${items[0]['harga_paket']}';
      }
    });
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
      await _bluetooth.connect(device);

      setState(() {
        _isConnected = true;
        _selectedDevice = device;
      });

      Fluttertoast.showToast(msg: "Terhubung ke printer ${device.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal terhubung ke printer: ${e.toString()}");
      setState(() {
        _isConnected = false;
        _selectedDevice = null;
      });
    }
  }

  Future<void> printTicket() async {
    if (!_isConnected || _selectedDevice == null) {
      Fluttertoast.showToast(msg: "Printer belum terhubung");
      return;
    }

    try {
      final bytes = await getTicketBagasi();
      // Konversi List<int> ke Uint8List
      await _bluetooth.writeBytes(Uint8List.fromList(bytes));
      Fluttertoast.showToast(msg: "Tiket berhasil dicetak");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error mencetak: ${e.toString()}");
    }
  }

  Future<List<int>> getTicketBagasi() async {
    // Ambil SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    String noWhatsapp = prefs.getString('noKontak') ?? '0822-3490-9090'; // Default value jika tidak ada

    List<Map<String, dynamic>> lastTransaksi = await DatabaseHelper.instance.getDataTransaksiBagasiTerakhir();
    String noOrderTransaksiTerakhir = lastTransaksi.isNotEmpty ? lastTransaksi[0]['id_order'] : '';
    String kotaBerangkat = lastTransaksi.isNotEmpty ? lastTransaksi[0]['kota_berangkat'] : '';
    String noPol = lastTransaksi.isNotEmpty ? lastTransaksi[0]['no_pol'] : '';
    String kotaTujuan = lastTransaksi.isNotEmpty ? lastTransaksi[0]['kota_tujuan'] : '';
    String namaPengirim = lastTransaksi.isNotEmpty ? lastTransaksi[0]['nama_pengirim'] : '';
    String noTeleponPengirim = lastTransaksi.isNotEmpty ? lastTransaksi[0]['no_tlp_pengirim'] : '';

    String namaPenerima = lastTransaksi.isNotEmpty ? lastTransaksi[0]['nama_penerima'] : '';
    String noTeleponPenerima = lastTransaksi.isNotEmpty ? lastTransaksi[0]['no_tlp_penerima'] : '';

    double jumlahTagihan = lastTransaksi.isNotEmpty ? lastTransaksi[0]['jml_harga'] : 0.0;
    String jumlahTagihanCetak = formatter.format(jumlahTagihan);

    String tanggalTransaksi = lastTransaksi.isNotEmpty ? lastTransaksi[0]['tgl_order'] : '';
    var dateParts = tanggalTransaksi.split('-');
    var formattedDate = dateParts[2] + '-' + dateParts[1] + '-' + dateParts[0];

    int qtyBarang = lastTransaksi.isNotEmpty ? lastTransaksi[0]['qty_barang'] : 0;
    String keterangan = lastTransaksi.isNotEmpty ? lastTransaksi[0]['keterangan'] : '';

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.reset();

    bytes += generator.text("PT. MILA AKAS BERKAH SEJAHTERA",
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1, bold: true));
    bytes += generator.text("Probolinggo - Jawa Timur 67214", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("IG: akasmilasejahtera_official", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("WA: $noWhatsapp", styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: "$kotaBerangkat",width: 6,styles: PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: " $kotaTujuan", width: 6, styles: PosStyles(align: PosAlign.left, bold: true)),
    ]);
    bytes += generator.text("$noOrderTransaksiTerakhir", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("$formattedDate", styles: PosStyles(align: PosAlign.center, bold: false));

    bytes += generator.row([
      PosColumn(text: "No.Pol: $noPol", width: 12, styles: PosStyles(align: PosAlign.left)),
    ]);
    bytes += generator.row([
      PosColumn(text: "Paket: $keterangan", width: 12, styles: PosStyles(align: PosAlign.left)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Pengirim: $namaPengirim",width: 12,styles: PosStyles(align: PosAlign.left,)),
    ]);
    bytes += generator.row([
      PosColumn(text: "Telepon: $noTeleponPengirim", width: 12, styles: PosStyles(align: PosAlign.left)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Penerima: $namaPenerima",width: 12,styles: PosStyles(align: PosAlign.left,)),
    ]);
    bytes += generator.row([
      PosColumn(text: "Telepon: $noTeleponPenerima", width: 12, styles: PosStyles(align: PosAlign.left)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Jumlah Barang: $qtyBarang paket",width: 12,styles: PosStyles(align: PosAlign.left,)),
    ]);
    bytes += generator.row([
      PosColumn(text: "Biaya : $jumlahTagihanCetak", width: 12, styles: PosStyles(align: PosAlign.left)),
    ]);

    bytes += generator.hr();
    // bytes += generator.qrcode("$noOrderTransaksiTerakhir");
    bytes += generator.qrcode("https://www.milaberkah.com/");

    bytes += generator.text('Semoga Allah SWT melindungi kita dalam perjalanan ini.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.hr();

    return bytes;
  }

  void _calculateTagihan(int qtyBarang, String? selectedJenisPaket) {
    if (selectedJenisPaket != null) {
      try {
        // Parsing ID jenis paket dan harga paket
        List<String> parts = selectedJenisPaket.split(' - ');
        int idJenisPaket = int.tryParse(parts[0]) ?? 1;
        double hargaPaket = double.tryParse(parts[2]) ?? 0.0; // harga_paket ada di index 2

        print('ID Jenis Paket: $idJenisPaket');
        print('Harga Paket: $hargaPaket');
        print('Qty Barang: $qtyBarang');

        // Hitung jumlah tagihan langsung dari harga paket × quantity
        double jumlahTagihan = hargaPaket * qtyBarang;

        setState(() {
          _hargaKmController.text = jumlahTagihan.toStringAsFixed(0);
        });

        print('Jumlah Tagihan: $jumlahTagihan');

      } catch (e) {
        print('Error calculating tagihan: $e');
        setState(() {
          _hargaKmController.text = '0';
        });
      }
    } else {
      print('Jenis paket belum dipilih');
      setState(() {
        _hargaKmController.text = '0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // biar layout bergeser saat keyboard muncul
      appBar: AppBar(
        title: Text('Form Bagasi Bus'),
        actions: [
          IconButton(
            icon: Icon(
              _isConnected ? Icons.print : Icons.print_disabled,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: () {
              if (_isConnected) {
                printTicket();
              } else {
                getBluetooth();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // padding bawah memperhitungkan keyboard (viewInsets) dan system padding (nav bar)
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).padding.bottom +
                20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _namaPengirimController,
                      decoration: InputDecoration(labelText: 'Nama Pengirim'),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: _noTlpPengirimController,
                      decoration: InputDecoration(labelText: 'No. Telp Pengirim'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _namaPenerimaController,
                      decoration: InputDecoration(labelText: 'Nama Penerima'),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: _noTlpPenerimaController,
                      decoration: InputDecoration(labelText: 'No. Telp Penerima'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: _qtyBarangController,
                decoration: InputDecoration(labelText: 'Qty Barang'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      qtyBarang = int.tryParse(value) ?? 0;
                    });
                    if (qtyBarang > 0 && selectedJenisPaket != null) {
                      _calculateTagihan(qtyBarang, selectedJenisPaket!);
                    }
                  }
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Pilih Jenis Paket'),
                value: selectedJenisPaket,
                items: jenisPaket.map((item) {
                  String combinedValue =
                      '${item['id']} - ${item['persen']} - ${item['harga_paket']}';
                  String displayText =
                      '${item['jenis_paket']} - Rp ${NumberFormat('#,###').format(item['harga_paket'])}';
                  return DropdownMenuItem<String>(
                    value: combinedValue,
                    child: Text(displayText),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedJenisPaket = newValue;
                  });
                  if (qtyBarang > 0 && newValue != null) {
                    _calculateTagihan(qtyBarang, newValue);
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return 'Harap pilih jenis paket';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Kota Berangkat'),
                items: listKota.map((kota) {
                  String valueText = '${kota['id_kota_tujuan']} - ${kota['jarak']}';
                  return DropdownMenuItem<String>(
                    child: Text(kota['nama_kota']),
                    value: valueText,
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedKotaBerangkat = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Kota Berangkat harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Kota Tujuan'),
                items: listKota.map((kota) {
                  String valueText = '${kota['id_kota_tujuan']} - ${kota['jarak']}';
                  return DropdownMenuItem<String>(
                    child: Text(kota['nama_kota']),
                    value: valueText,
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedKotaTujuan = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Kota Tujuan harus diisi';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: _keteranganController,
                onChanged: (value) {
                  setState(() {
                    keterangan = value;
                  });
                },
                decoration: InputDecoration(labelText: 'Keterangan'),
                maxLines: 1,
              ),
              SizedBox(height: 20),
              TextField(
                controller: _hargaKmController,
                decoration: InputDecoration(
                  labelText: 'Tagihan',
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  RupiahInputFormatter(),
                ],
                textAlign: TextAlign.center,
                onChanged: (value) {
                  setState(() {
                    final angka = value.replaceAll(RegExp(r'[^0-9]'), '');
                    tagihan = double.tryParse(angka) ?? 0.0;
                  });
                },
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _ambilGambar(true),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt),
                            SizedBox(width: 8),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // (Jika mau, bisa aktifkan tombol gallery lagi)
                    ],
                  ),
                  SizedBox(width: 20),
                  if (_image != null)
                    Image.file(
                      _image!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        this.getBluetooth();
                        if (!await _checkBluetoothPermission()) {
                          await _requestBluetoothPermission();
                        }
                      },
                      child: Text('Set.Printer'),
                      style: ButtonStyle(
                        minimumSize: WidgetStateProperty.all(Size(double.infinity, 48.0)),
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.grey;
                            } else {
                              return Colors.blue;
                            }
                          },
                        ),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedKotaBerangkat != null &&
                            selectedKotaTujuan != null &&
                            selectedJenisPaket != null) {
                          int idkotaAwal =
                              int.tryParse(selectedKotaBerangkat!.split(' - ')[0]) ?? 1;
                          int idkotaAkhir =
                              int.tryParse(selectedKotaTujuan!.split(' - ')[0]) ?? 1;
                          int idjenisPaket =
                              int.tryParse(selectedJenisPaket!.split(' - ')[0]) ?? 1;

                          print('cek nilai: $idkotaAwal , $idkotaAkhir , $idjenisPaket');

                          _submitForm(
                            idjenisPaket,
                            idkotaAwal,
                            idkotaAkhir,
                          ).then((_) {
                            printTicket();
                          }).catchError((error) {
                            print("Error during submit form: $error");
                          });
                        }
                      },
                      child: Text('Simpan'),
                      style: ButtonStyle(
                        minimumSize: WidgetStateProperty.all(Size(double.infinity, 48.0)),
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                              (Set<WidgetState> states) {
                            if (states.contains(WidgetState.pressed)) {
                              return Colors.grey;
                            } else {
                              return Colors.green;
                            }
                          },
                        ),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    final number = NumberFormat.decimalPattern('id').format(int.parse(digits));

    return TextEditingValue(
      text: number,
      selection: TextSelection.collapsed(offset: number.length),
    );
  }
}
