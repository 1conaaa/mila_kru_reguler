import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:mila_kru_reguler/services/rit_user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:provider/provider.dart';
import 'package:mila_kru_reguler/page/bluetooth_service.dart';
import 'package:permission_handler/permission_handler.dart';

class FormBagasiBus extends StatefulWidget {
  @override
  _FormBagasiBusState createState() => _FormBagasiBusState();
}

class _FormBagasiBusState extends State<FormBagasiBus> {
  List<Map<String, dynamic>> jenisPaket = [];
  Map<int, String?> selectedItems = {};
  Map<int, String> deskripsi = {};
  Map<int, double> persen = {};
  String? selectedJenisPaket;
  final UserService _userService = UserService();

  bool _isLoading = false;
  bool _isPrinterConnected = false;
  bool _isCheckingPrinter = true;
  bool _isSubmitting = false;

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

  late String namaPembeli = '';
  late String noTelepon = '';
  late String keterangan = '';

  get hasBluetoothPermission => null;
  List availableBluetoothDevices = [];

  File? _image;
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;
  String? _fileName;

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
    _refreshData();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPrinterConnection();
    });
  }

  @override
  void dispose() {
    _namaPengirimController.dispose();
    _noTlpPengirimController.dispose();
    _namaPenerimaController.dispose();
    _noTlpPenerimaController.dispose();
    _qtyBarangController.dispose();
    _hargaKmController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Menyimpan data...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _hideLoading() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _connectPrinter() async {
    final printer = context.read<BluetoothPrinterService>();
    final devices = await printer.bluetooth.getBondedDevices();

    if (devices.isEmpty) {
      Fluttertoast.showToast(msg: "Tidak ada printer Bluetooth yang dipasangkan");
      return;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Pilih Printer Bluetooth"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: devices.length,
            itemBuilder: (_, i) {
              final device = devices[i];
              return ListTile(
                title: Text(device.name ?? "Printer"),
                subtitle: Text(device.address ?? ""),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await printer.connect(device);
                    await _checkPrinterConnection();
                    Fluttertoast.showToast(msg: "Terhubung ke ${device.name}");
                  } catch (e) {
                    Fluttertoast.showToast(msg: "Gagal connect printer: ${e.toString()}");
                    await _checkPrinterConnection();
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _checkPrinterConnection() async {
    setState(() {
      _isCheckingPrinter = true;
    });

    try {
      final printer = context.read<BluetoothPrinterService>();
      final isConnected = await printer.checkConnection();
      final selectedDevice = printer.selectedDevice;

      setState(() {
        _isPrinterConnected = isConnected && selectedDevice != null;
        _isCheckingPrinter = false;
      });
    } catch (e) {
      setState(() {
        _isPrinterConnected = false;
        _isCheckingPrinter = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _getJenisPaket();
      await _getListKota();
      await _getUserData();
      await _getListKotaTerakhir();

      if (mounted) {
        setState(() {
          // Set nilai default ke 0 dengan format Rupiah
          _hargaKmController.text = formatRupiah.format(0);
          tagihan = 0;
        });
      }
    } catch (e) {
      print('Error in _refreshData: $e');
      if (mounted) {
        Fluttertoast.showToast(msg: "Gagal memuat data: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _ambilGambar(bool fromCamera) async {
    await _requestPermission();

    final pickedFile = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

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

  Future<File?> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      final resizedImage = img.copyResize(image, width: 800);
      final compressedBytes = img.encodeJpg(resizedImage, quality: 75);

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
    setState(() => _isLoading = true);
    _showLoading();

    DateTime now = DateTime.now();
    String formattedIdOrder = DateFormat('yyyyMMddHHmmss').format(now);
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final dbHelper = DatabaseHelper.instance;
    Database db = await dbHelper.database;

    final int ritAktif = await RitUserService.instance.getActiveRit();
    double jumlahTagihan = tagihan;

    if (_image != null) {
      File? compressedImage = await compressImage(_image!);
      if (compressedImage != null) {
        _fileName = compressedImage.path.split('/').last;
        final bytes = await compressedImage.readAsBytes();
        _base64Image = base64Encode(bytes);
      } else {
        Fluttertoast.showToast(msg: "Gagal mengkompres gambar");
        return;
      }
    }

    try {
      await db.insert('t_order_bagasi', {
        'tgl_order': formattedDate,
        'id_jenis_paket': idjenisPaket,
        'id_order': '${idBus}${idUser}${formattedIdOrder}',
        'rit': ritAktif,
        'id_bus': idBus,
        'no_pol': noPol,
        'kode_trayek': kodeTrayek,
        'id_personil': idUser,
        'id_group': idGroup,
        'id_kota_berangkat': idkotaAwal,
        'id_kota_tujuan': idkotaAkhir,
        'qty_barang': _qtyBarangController.text,
        'harga_km': jumlahTagihan,
        'jml_harga': jumlahTagihan,
        'nama_pengirim': _namaPengirimController.text,
        'no_tlp_pengirim': _noTlpPengirimController.text,
        'nama_penerima': _namaPenerimaController.text,
        'no_tlp_penerima': _noTlpPenerimaController.text,
        'keterangan': _keteranganController.text,
        'fupload': _base64Image,
        'file_name': _fileName,
        'status': 'N',
      });

      Fluttertoast.showToast(msg: "Data berhasil disimpan");
      await _refreshData();

      if (mounted) {
        _resetForm();
      }
    } catch (error) {
      print("Error inserting data: $error");
      Fluttertoast.showToast(msg: "Gagal menyimpan data");
    } finally {
      _hideLoading();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLastKotaTerakhir() async {
    await _getUserData();
    await _getListKotaTerakhir();
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
          marginKantor = kotaTerakhir['margin_kantor'] != null ? (kotaTerakhir['margin_kantor'] as num).toDouble() : 0.0;
          marginTarikan = kotaTerakhir['margin_tarikan'] != null ? (kotaTerakhir['margin_tarikan'] as num).toDouble() : 0.0;
        });
      }
    } catch (e) {
      print('Error retrieving kota terakhir: $e');
    }
  }

  Future<void> _getUserData() async {
    try {
      List<Map<String, dynamic>> users = await _userService.getUsersRaw();

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
    } catch (e) {
      print('Error saat mengambil data: $e');
    }
  }

  Future<int> getActiveRit() async {
    final int ritAktif = await RitUserService.instance.getActiveRit();
    return ritAktif;
  }

  Future<void> _getListKota({int? rit}) async {
    try {
      final int ritDigunakan = rit ?? await getActiveRit();
      await databaseHelper.initDatabase();
      List<Map<String, dynamic>> kotaData = await databaseHelper.getRuteTrayekUrutan(ritDigunakan);
      await databaseHelper.closeDatabase();

      if (mounted) {
        setState(() {
          listKota = kotaData;
        });
      }
    } catch (e) {
      print('Error saat mengambil data rute: $e');
    }
  }

  Future<void> _getJenisPaket() async {
    await databaseHelper.initDatabase();
    List<Map<String, dynamic>> items = await databaseHelper.getAllJenisPaket();
    await databaseHelper.closeDatabase();
    setState(() {
      jenisPaket = items;
      if (items.isNotEmpty) {
        selectedJenisPaket = '${items[0]['id']} - ${items[0]['persen']} - ${items[0]['harga_paket']}';
      }
    });
  }

  String getCurrentDateTime() {
    final now = DateTime.now();
    String jamMenit = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    String tanggalBulanTahun = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    return "$jamMenit $tanggalBulanTahun"; // tanpa koma
  }


  Future<List<int>> getTicketBagasi() async {
    final prefs = await SharedPreferences.getInstance();
    String noWhatsapp = prefs.getString('noKontak') ?? '0822-3490-9090';

    List<Map<String, dynamic>> lastTransaksi = await DatabaseHelper.instance.getDataTransaksiBagasiTerakhir();

    String noOrderTransaksiTerakhir = lastTransaksi.isNotEmpty ? lastTransaksi[0]['id_order'] : '';
    String kotaBerangkat = lastTransaksi.isNotEmpty ? lastTransaksi[0]['kota_berangkat'] : '';
    String noPol = lastTransaksi.isNotEmpty ? lastTransaksi[0]['no_pol'] : '';
    String kotaTujuan = lastTransaksi.isNotEmpty ? lastTransaksi[0]['kota_tujuan'] : '';
    String namaPengirim = lastTransaksi.isNotEmpty ? lastTransaksi[0]['nama_pengirim'] : '';
    String noTeleponPengirim = lastTransaksi.isNotEmpty ? lastTransaksi[0]['no_tlp_pengirim'] : '';
    String jenisPaket = lastTransaksi.isNotEmpty ? lastTransaksi[0]['jenis_paket'] : '';
    String namaPenerima = lastTransaksi.isNotEmpty ? lastTransaksi[0]['nama_penerima'] : '';
    String noTeleponPenerima = lastTransaksi.isNotEmpty ? lastTransaksi[0]['no_tlp_penerima'] : '';
    double jumlahTagihan = lastTransaksi.isNotEmpty ? lastTransaksi[0]['jml_harga'] : 0.0;
    String jumlahTagihanCetak = formatter.format(jumlahTagihan);
    // TAMBAHKAN baris ini:
    String formattedDateTime = getCurrentDateTime(); // Hasil: "14:30, 29 Mei 2026"

    int qtyBarang = lastTransaksi.isNotEmpty ? lastTransaksi[0]['qty_barang'] : 0;
    String keterangan = lastTransaksi.isNotEmpty ? lastTransaksi[0]['keterangan'] : '';

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.reset();

    try {
      final ByteData logoData = await rootBundle.load('assets/images/icon_mila.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final img.Image? image = img.decodeImage(logoBytes);

      if (image != null) {
        final img.Image resizedImage = img.copyResize(image, width: 380);
        bytes += generator.image(resizedImage, align: PosAlign.center);
      }
    } catch (e) {
      print('Gagal memuat logo bagasi: $e');
    }

    bytes += generator.text(
      "PT. MILA AKAS BERKAH SEJAHTERA",
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size1,
        width: PosTextSize.size1,
        bold: true,
      ),
    );
    bytes += generator.text(
      "Probolinggo - Jawa Timur 67214",
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      "IG: akasmilasejahtera_official",
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      "WA: $noWhatsapp",
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(
        text: kotaBerangkat,
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
      PosColumn(
        text: " - $kotaTujuan",
        width: 6,
        styles: PosStyles(align: PosAlign.left, bold: true),
      ),
    ]);
    bytes += generator.text(
      noOrderTransaksiTerakhir,
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      formattedDateTime,
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      "No.Pol: $noPol",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      "Pengirim: $namaPengirim",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      "Telepon: $noTeleponPengirim",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      "Penerima: $namaPenerima",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      "Telepon: $noTeleponPenerima",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      "Jumlah Barang: $qtyBarang ($jenisPaket)",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      "Biaya : $jumlahTagihanCetak",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.text(
      "Keterangan: $keterangan",
      styles: PosStyles(align: PosAlign.left),
    );
    bytes += generator.hr();
    bytes += generator.qrcode("https://www.milaberkah.com/");
    bytes += generator.text(
      'Semoga selamat sampai tujuan.',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();
    bytes += generator.feed(4);

    return bytes;
  }


  void _calculateTagihan(int qtyBarang, String? selectedJenisPaket) {
    if (selectedJenisPaket != null && qtyBarang > 0) {
      try {
        List<String> parts = selectedJenisPaket.split(' - ');
        double hargaPaket = double.tryParse(parts[2]) ?? 0.0;
        double jumlahTagihan = hargaPaket * qtyBarang;

        setState(() {
          tagihan = jumlahTagihan;
          _hargaKmController.text = formatRupiah.format(jumlahTagihan);
        });
      } catch (e) {
        print('Error calculating tagihan: $e');
      }
    } else if (qtyBarang == 0) {
      setState(() {
        tagihan = 0;
        _hargaKmController.text = formatRupiah.format(0); // Gunakan format Rupiah
      });
    }
  }

  void _resetForm() {
    _namaPengirimController.clear();
    _noTlpPengirimController.clear();
    _namaPenerimaController.clear();
    _noTlpPenerimaController.clear();
    _qtyBarangController.clear();
    _keteranganController.clear();

    setState(() {
      selectedKotaBerangkat = null;
      selectedKotaTujuan = null;
      _image = null;
      _base64Image = null;
      _fileName = null;
      qtyBarang = 0;
      tagihan = 0;

      // Reset ke nilai 0 dengan format Rupiah
      _hargaKmController.text = formatRupiah.format(0);

      if (jenisPaket.isNotEmpty) {
        selectedJenisPaket = '${jenisPaket[0]['id']} - ${jenisPaket[0]['persen']} - ${jenisPaket[0]['harga_paket']}';
      }
    });

    // Fokus ke field pertama setelah reset
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _onHargaKmChanged(String value) {
    // Hapus semua karakter non-digit
    String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanValue.isEmpty) {
      // Biarkan kosong sementara, jangan set nilai apapun
      // User sedang menghapus semua angka
      return;
    }

    double newTagihan = double.tryParse(cleanValue) ?? 0;

    setState(() {
      tagihan = newTagihan;
    });

    // Format ulang text dengan format Rupiah
    String formatted = formatRupiah.format(newTagihan);
    if (_hargaKmController.text != formatted) {
      _hargaKmController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _onHargaKmEditingComplete() {
    // Saat selesai edit, cek apakah field kosong
    if (_hargaKmController.text.isEmpty ||
        _hargaKmController.text == 'Rp ' ||
        _hargaKmController.text == 'Rp' ||
        _hargaKmController.text == 'Rp 0') {

      // Jika kosong dan ada qty barang, hitung ulang dari qty
      if (qtyBarang > 0 && selectedJenisPaket != null) {
        _calculateTagihan(qtyBarang, selectedJenisPaket!);
      } else {
        // Jika tidak ada qty, set ke 0
        setState(() {
          tagihan = 0;
          _hargaKmController.text = formatRupiah.format(0);
        });
      }
    } else if (tagihan == 0 && qtyBarang > 0 && selectedJenisPaket != null) {
      // Jika tagihan 0 tapi ada qty, hitung ulang
      _calculateTagihan(qtyBarang, selectedJenisPaket!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Form Bagasi Bus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Printer Status Card
              _buildPrinterStatusCard(),
              const SizedBox(height: 20),

              // Form Sections
              _buildSectionCard(
                title: 'Informasi Pengirim',
                icon: Icons.person,
                children: [
                  _buildTextField(
                    controller: _namaPengirimController,
                    label: 'Nama Pengirim',
                    icon: Icons.badge,
                    // validator: (value) => value?.isEmpty ?? true ? 'Nama pengirim harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _noTlpPengirimController,
                    label: 'No. Telepon Pengirim',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    // validator: (value) => value?.isEmpty ?? true ? 'No. telepon harus diisi' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                title: 'Informasi Penerima',
                icon: Icons.person_outline,
                children: [
                  _buildTextField(
                    controller: _namaPenerimaController,
                    label: 'Nama Penerima',
                    icon: Icons.badge,
                    // validator: (value) => value?.isEmpty ?? true ? 'Nama penerima harus diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _noTlpPenerimaController,
                    label: 'No. Telepon Penerima',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    // validator: (value) => value?.isEmpty ?? true ? 'No. telepon harus diisi' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                title: 'Detail Barang',
                icon: Icons.inventory,
                children: [
                  _buildTextField(
                    controller: _qtyBarangController,
                    label: 'Jumlah Barang',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        int newQty = int.tryParse(value) ?? 0;
                        setState(() {
                          qtyBarang = newQty;
                        });
                        // Selalu hitung ulang dari qty barang
                        if (selectedJenisPaket != null) {
                          _calculateTagihan(newQty, selectedJenisPaket!);
                        }
                      } else {
                        setState(() {
                          qtyBarang = 0;
                          tagihan = 0;
                          _hargaKmController.text = formatRupiah.format(0);
                        });
                      }
                    },
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Jumlah barang harus diisi';
                      if (int.tryParse(value!) == null) return 'Jumlah harus angka';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    value: selectedJenisPaket,
                    items: jenisPaket.map((item) {
                      return DropdownMenuItem<String>(
                        value: '${item['id']} - ${item['persen']} - ${item['harga_paket']}',
                        child: Text(
                          '${item['jenis_paket']} - ${formatRupiah.format(item['harga_paket'])}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                    label: 'Jenis Paket',
                    icon: Icons.category,
                    onChanged: (value) {
                      setState(() {
                        selectedJenisPaket = value;
                      });
                      // Selalu hitung ulang dari qty barang
                      if (qtyBarang > 0 && value != null) {
                        _calculateTagihan(qtyBarang, value);
                      } else if (qtyBarang == 0) {
                        setState(() {
                          tagihan = 0;
                          _hargaKmController.text = formatRupiah.format(0);
                        });
                      }
                    },
                    validator: (value) => value == null ? 'Pilih jenis paket' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                title: 'Rute Perjalanan',
                icon: Icons.route,
                children: [
                  _buildDropdownField(
                    value: selectedKotaBerangkat,
                    items: listKota.map((kota) {
                      return DropdownMenuItem<String>(
                        value: '${kota['id_kota_berangkat']} - ${kota['jarak']}',
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(kota['nama_kota']),
                          ],
                        ),
                      );
                    }).toList(),
                    label: 'Kota Keberangkatan',
                    icon: Icons.departure_board,
                    onChanged: (value) {
                      setState(() {
                        selectedKotaBerangkat = value;
                      });
                    },
                    validator: (value) => value == null ? 'Pilih kota keberangkatan' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(
                    value: selectedKotaTujuan,
                    items: listKota.map((kota) {
                      return DropdownMenuItem<String>(
                        value: '${kota['id_kota_berangkat']} - ${kota['jarak']}',
                        child: Row(
                          children: [
                            const Icon(Icons.location_city, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(kota['nama_kota']),
                          ],
                        ),
                      );
                    }).toList(),
                    label: 'Kota Tujuan',
                    icon: Icons.tour,
                    onChanged: (value) {
                      setState(() {
                        selectedKotaTujuan = value;
                      });
                    },
                    validator: (value) => value == null ? 'Pilih kota tujuan' : null,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildSectionCard(
                title: 'Pembayaran & Keterangan',
                icon: Icons.payment,
                children: [
                  _buildTextField(
                    controller: _hargaKmController,
                    label: 'Total Tagihan',
                    icon: Icons.price_change,
                    keyboardType: TextInputType.number,
                    readOnly: false,
                    suffix: const Text('  Rupiah'),
                    onChanged: _onHargaKmChanged, // Gunakan method baru
                    onEditingComplete: _onHargaKmEditingComplete, // Tambahkan ini
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // Hanya menerima angka
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _keteranganController,
                    label: 'Keterangan (Opsional)',
                    icon: Icons.description,
                    maxLines: 2,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Image Section
              _buildImageSection(),
              const SizedBox(height: 24),

              // Submit Button
              _buildSubmitButton(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrinterStatusCard() {
    if (_isCheckingPrinter) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Memeriksa koneksi printer...',
                style: TextStyle(color: Colors.blue[700]),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isPrinterConnected ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isPrinterConnected ? Colors.green[200]! : Colors.orange[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isPrinterConnected ? Icons.print : Icons.print_disabled,
            color: _isPrinterConnected ? Colors.green : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPrinterConnected ? "Printer Siap Digunakan" : "Printer Belum Terhubung",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _isPrinterConnected ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                if (!_isPrinterConnected)
                  Text(
                    "Hubungkan printer Bluetooth untuk mencetak tiket",
                    style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                  ),
              ],
            ),
          ),
          if (!_isPrinterConnected)
            ElevatedButton(
              onPressed: _connectPrinter,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Hubungkan"),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.blue[700], size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onEditingComplete, // Tambahkan parameter ini
    int maxLines = 1,
    bool readOnly = false,
    Widget? suffix,
    List<TextInputFormatter>? inputFormatters, // Tambahkan parameter ini
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[400], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: suffix != null ? Padding(
          padding: const EdgeInsets.only(right: 12),
          child: suffix,
        ) : null,
      ),
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete, // Tambahkan ini
      maxLines: maxLines,
      readOnly: readOnly,
      inputFormatters: inputFormatters, // Tambahkan ini
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue[400], size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
    );
  }

  Widget _buildImageSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: Colors.blue[700], size: 22),
                const SizedBox(width: 8),
                Text(
                  'Dokumentasi Barang',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _ambilGambar(true),
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Kamera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _ambilGambar(false),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeri'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_image != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _image!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _image = null;
                        _base64Image = null;
                        _fileName = null;
                      });
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 10,
        top: 8,
        left: 0,
        right: 0,
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () async {
          // ==================================================
          // 🔥 VALIDASI 1: PRINTER HARUS TERHUBUNG
          // ==================================================
          if (!_isPrinterConnected) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("❌ Printer belum terhubung. Silakan hubungkan printer terlebih dahulu."),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          // ==================================================
          // 🔥 VALIDASI 2: FOTO WAJIB DIUNGAH
          // ==================================================
          if (_image == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("📸 Foto barang wajib diunggah. Silakan ambil foto terlebih dahulu."),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          // ==================================================
          // 🔥 VALIDASI 3: FORM HARUS VALID
          // ==================================================
          if (!_formKey.currentState!.validate()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("⚠️ Harap lengkapi semua data yang diperlukan."),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          // ==================================================
          // 🔥 VALIDASI 4: DROPDOWN TIDAK BOLEH NULL
          // ==================================================
          if (selectedKotaBerangkat == null ||
              selectedKotaTujuan == null ||
              selectedJenisPaket == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("⚠️ Harap pilih kota keberangkatan, kota tujuan, dan jenis paket."),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          // ==================================================
          // 🔥 SEMUA VALIDASI TERPENUHI, PROSES SIMPAN & PRINT
          // ==================================================
          setState(() => _isSubmitting = true);

          int idkotaAwal = int.tryParse(selectedKotaBerangkat!.split(' - ')[0]) ?? 1;
          int idkotaAkhir = int.tryParse(selectedKotaTujuan!.split(' - ')[0]) ?? 1;
          int idjenisPaket = int.tryParse(selectedJenisPaket!.split(' - ')[0]) ?? 1;

          try {
            // 1️⃣ Simpan data ke database (termasuk foto)
            await _submitForm(idjenisPaket, idkotaAwal, idkotaAkhir);

            // 2️⃣ Cetak tiket bagasi
            final printer = context.read<BluetoothPrinterService>();
            final bytes = await getTicketBagasi();
            await printer.printBytes(bytes);

            // 3️⃣ Beri notifikasi sukses
            Fluttertoast.showToast(
              msg: "✅ Data tersimpan & tiket dicetak",
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );

            // 4️⃣ Reset form untuk transaksi berikutnya
            _resetForm();

          } catch (e) {
            print("Error during submit/print: $e");
            Fluttertoast.showToast(
              msg: "❌ Gagal simpan / cetak: $e",
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          } finally {
            setState(() => _isSubmitting = false);
          }
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 54),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, size: 20),
            SizedBox(width: 8),
            Text(
              'Simpan & Cetak Tiket',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
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