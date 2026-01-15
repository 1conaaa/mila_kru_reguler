import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/premi_harian_kru_model.dart';
import 'package:mila_kru_reguler/models/premi_posisi_kru_model.dart';
import 'package:mila_kru_reguler/models/setoranKru_model.dart';
import 'package:mila_kru_reguler/models/user.dart';
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:mila_kru_reguler/services/premi_harian_kru_service.dart';
import 'package:mila_kru_reguler/services/premi_posisi_kru_service.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';
import 'package:mila_kru_reguler/view/View_FormSetoran.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mila_kru_reguler/utils/premi_bersih_calculator.dart';

class FormRekapTransaksi extends StatefulWidget {
  @override
  _FormRekapTransaksiState createState() => _FormRekapTransaksiState();
}

class _FormRekapTransaksiState extends State<FormRekapTransaksi> {
  final TextEditingController _textController = TextEditingController(text: 'Hidden Value');
  final PremiPosisiKruService _premiService = PremiPosisiKruService(); // Inisialisasi service
  final bool _isHidden = true;
  final UserService _userService = UserService(); // Tambahkan ini

  double totalPendapatanBersih = 0.0; // Tambahkan ini

  String? selectedKotaBerangkat;
  String? selectedKotaTujuan;

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
  final _formKey = GlobalKey<FormState>();

  late String ritke = ''; // Initialize with an empty string
  late String pendapatanTiketReguler = ''; // Initialize with an empty string
  late String nilaiTiketReguler = ''; // Initialize with an empty string
  late String pendapatanTiketOnline = ''; // Initialize with an empty string
  late String nilaiTiketOnLine = ''; // Initialize with an empty string
  late String pendapatanBagasi = ''; // Initialize with an empty string
  late String banyakBarangBagasi = ''; // Initialize with an empty string
  late String pengeluaranTol = '';
  late String pengeluaranTpr = '';
  late String pengeluaranPerpal = '';
  late String nominalPremiExtra = '';
  late String nominalPremiKru = '';
  late String kmMasukGarasi = '';

  int jumlahTagihan = 0;
  int jumlahBayar = 0;

  TextEditingController ritController = TextEditingController();
  TextEditingController litersolarController = TextEditingController();
  TextEditingController kmMasukGarasiController = TextEditingController();
  TextEditingController nominalsolarController = TextEditingController();
  TextEditingController perbaikanController = TextEditingController();
  TextEditingController keteranganPerbaikanController = TextEditingController();
  TextEditingController nominalperbaikanController = TextEditingController();
  TextEditingController pendapatanTiketRegulerController = TextEditingController();
  TextEditingController jumlahTiketRegulerController = TextEditingController();
  TextEditingController pendapatanTiketNonRegulerController = TextEditingController();
  TextEditingController jumlahTiketOnLineController = TextEditingController();
  TextEditingController pendapatanBagasiController = TextEditingController();
  TextEditingController jumlahBarangBagasiController = TextEditingController();
  TextEditingController bagasiController = TextEditingController();
  TextEditingController tolController = TextEditingController();
  TextEditingController tprController = TextEditingController();
  TextEditingController perpalController = TextEditingController();

  TextEditingController premiExtraController = TextEditingController();
  TextEditingController persenPremikruController = TextEditingController();

  TextEditingController coaPendapatanBusController = TextEditingController();
  TextEditingController coaPengeluaranBusController = TextEditingController();
  TextEditingController coaUtangPremiController = TextEditingController();

  TextEditingController nominalPremiExtraController = TextEditingController();
  TextEditingController nominalPremiKruController = TextEditingController();
  TextEditingController nominalPendapatanBersihController = TextEditingController();
  TextEditingController nominalPendapatanDisetorController = TextEditingController();

  late DatabaseHelper databaseHelper;
  TextEditingController sarantagihanController = TextEditingController();
  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: ' ');

  double get totalPendapatanReguler => 00;

  double totalPendapatanRegulerValue = 00;
  int jumlahTiketRegulerValue = 0;

  double totalPendapatanNonRegulerValue = 00;
  int jumlahTiketOnlineValue = 0;

  double totalPendapatanBagasiValue = 00;
  int jumlahBarangBagasiValue = 0;

  get persenPremiExtra => null;
  get existingDataId => null;

  // Variabel untuk data dinamis
  Map<int, TextEditingController> _controllers = {};
  Map<int, TextEditingController> _jumlahControllers = {};
  Map<int, TextEditingController> _literSolarControllers = {};

  // Variabel untuk menyimpan path gambar per tag
  Map<int, String> _uploadedImages = {};
  Map<int, File?> _imageFiles = {};


  // Kelompokkan tag berdasarkan kategori
  List<TagTransaksi> tagPendapatan = [];
  List<TagTransaksi> tagPengeluaran = [];
  List<TagTransaksi> tagPremi = [];
  List<TagTransaksi> tagBersihSetoran = [];

  // Tambahkan deklarasi userData
  User? _user;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper.instance;
    _loadTagTransaksi(); // Load data tag transaksi
    _loadLastRekapTransaksi();
    _getUserData(); // Load user data
  }

  void _handleCalculatePremiBersih() {
    if (_user == null) {
      print('User data belum tersedia, menggunakan kalkulasi tanpa user data');
      final result = PremiBersihCalculator.calculatePremiBersihWithoutUser(
        tagPendapatan: tagPendapatan,
        tagPengeluaran: tagPengeluaran,
        tagPremi: tagPremi,
        tagBersihSetoran: tagBersihSetoran,
        controllers: _controllers,
        jumlahControllers: _jumlahControllers,
        literSolarControllers: _literSolarControllers,
      );

      PremiBersihCalculator.updateAutoCalculatedFieldsWithoutUser(
        calculationResult: result,
        controllers: _controllers,
      );
    } else {
      print('Menggunakan user data untuk kalkulasi: $_user');
      final result = PremiBersihCalculator.calculatePremiBersih(
        tagPendapatan: tagPendapatan,
        tagPengeluaran: tagPengeluaran,
        tagPremi: tagPremi,
        tagBersihSetoran: tagBersihSetoran,
        controllers: _controllers,
        jumlahControllers: _jumlahControllers,
        literSolarControllers: _literSolarControllers,
        userData: _user!, // Gunakan userData yang sudah ada
      );

      PremiBersihCalculator.updateAutoCalculatedFields(
        calculationResult: result,
        controllers: _controllers,
        userData: _user!,
      );
    }
  }

  // TAMBAHKAN FUNGSI INI di dalam class _FormRekapTransaksiState
  void _isiControllerPendapatan() {
    print('=== MENGISI CONTROLLER PENDAPATAN ===');

    // Isi data untuk Pendapatan Tiket Reguler (tag 1)
    if (_controllers.containsKey(1)) {
      _controllers[1]!.text = totalPendapatanRegulerValue.toInt().toString();
      print('✓ _controllers[1] diisi: ${totalPendapatanRegulerValue.toInt()}');
    }
    if (_jumlahControllers.containsKey(1)) {
      _jumlahControllers[1]!.text = jumlahTiketRegulerValue.toString();
      print('✓ _jumlahControllers[1] diisi: $jumlahTiketRegulerValue');
    }

    // Isi data untuk Pendapatan Tiket OTA (tag 2)
    if (_controllers.containsKey(2)) {
      _controllers[2]!.text = totalPendapatanNonRegulerValue.toInt().toString();
      print('✓ _controllers[2] diisi: ${totalPendapatanNonRegulerValue.toInt()}');
    }
    if (_jumlahControllers.containsKey(2)) {
      _jumlahControllers[2]!.text = jumlahTiketOnlineValue.toString();
      print('✓ _jumlahControllers[2] diisi: $jumlahTiketOnlineValue');
    }

    // Isi data untuk Pendapatan Bagasi (tag 3)
    if (_controllers.containsKey(3)) {
      _controllers[3]!.text = totalPendapatanBagasiValue.toInt().toString();
      print('✓ _controllers[3] diisi: ${totalPendapatanBagasiValue.toInt()}');
    }
    if (_jumlahControllers.containsKey(3)) {
      _jumlahControllers[3]!.text = jumlahBarangBagasiValue.toString();
      print('✓ _jumlahControllers[3] diisi: $jumlahBarangBagasiValue');
    }

    print('=== SELESAI MENGISI CONTROLLER ===');
  }

  Future<void> _getUserData() async {
    try {
      // GUNAKAN UserService instead of databaseHelper
      List<Map<String, dynamic>> users = await _userService.getUsersRaw();


      print('=== [DEBUG] DATABASE QUERY RESULTS ===');
      print('Number of users: ${users.length}');

      if (users.isNotEmpty) {
        Map<String, dynamic> firstUser = users[0];

        // Debug field premi dengan camelCase
        print('=== [DEBUG] PREMI FIELDS (CAMEL CASE) ===');
        print('premiExtra: ${firstUser['premiExtra']}');
        print('persenPremikru: ${firstUser['persenPremikru']}');
        print('keydataPremiextra: ${firstUser['keydataPremiextra']}');
        print('keydataPremikru: ${firstUser['keydataPremikru']}');

        print('coaPendapatanBus = ${firstUser['coaPendapatanBus']}');
        print('coaPengeluaranBus = ${firstUser['coaPengeluaranBus']}');
        print('coaUtangPremi = ${firstUser['coaUtangPremi']}');

        setState(() {
          _user = User.fromMap(firstUser);

          idUser = firstUser['id_user'] ?? 0;
          idGroup = firstUser['id_group'] ?? 0;
          idCompany = firstUser['id_company'] ?? 0;
          idGarasi = firstUser['id_garasi'];
          idBus = firstUser['id_bus'] ?? 0;

          noPol = firstUser['no_pol']?.toString();
          namaTrayek = firstUser['nama_trayek']?.toString();
          kodeTrayek = firstUser['kode_trayek']?.toString();
          jenisTrayek = firstUser['jenis_trayek']?.toString();
          kelasBus = firstUser['kelas_bus']?.toString();

          keydataPremiextra = firstUser['keydata_premiextra']?.toString();
          premiExtra = firstUser['premi_extra']?.toString();
          premiExtraController.text = premiExtra ?? '0';

          keydataPremikru = firstUser['keydata_premikru']?.toString();
          persenPremikru = firstUser['persen_premikru']?.toString();
          persenPremikruController.text = persenPremikru ?? '0';

          // 🔥 FIX UTAMA (ANTI CRASH)
          coaPendapatanBusController.text =
              firstUser['coa_pendapatan_bus']?.toString() ?? '';

          coaPengeluaranBusController.text =
              firstUser['coa_pengeluaran_bus']?.toString() ?? '';

          coaUtangPremiController.text =
              firstUser['coa_utang_premi']?.toString() ?? '';
        });


        print('=== [DEBUG] AFTER UserData.fromMap ===');
        print('UserData object: $_user');

      } else {
        setState(() {
          _user = User.empty();
        });
        print('No user data found, using empty data');
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _user = User.empty();
      });
    }
  }

  // Fungsi untuk memuat data tag transaksi
  Future<void> _loadTagTransaksi() async {
    // Pastikan DB siap (cukup sekali)
    await databaseHelper.initDatabase();

    // Reset data agar tidak dobel
    tagPendapatan.clear();
    tagPengeluaran.clear();
    tagPremi.clear();
    tagBersihSetoran.clear();

    _controllers.clear();
    _jumlahControllers.clear();
    _literSolarControllers.clear();

    // Ambil user dari SQLite
    final users = await _userService.getUsersRaw();
    if (users.isEmpty) {
      debugPrint('[WARN] User kosong');
      return;
    }

    final firstUser = users.first;

    // Ambil tag dari kolom user (SQLite)
    final String? tagPendapatanStr =
    firstUser['tag_transaksi_pendapatan']?.toString();
    final String? tagPengeluaranStr =
    firstUser['tag_transaksi_pengeluaran']?.toString();

    debugPrint("Tag Pendapatan dari DB: $tagPendapatanStr");
    debugPrint("Tag Pengeluaran dari DB: $tagPengeluaranStr");

    if ((tagPendapatanStr == null || tagPendapatanStr.isEmpty) &&
        (tagPengeluaranStr == null || tagPengeluaranStr.isEmpty)) {
      debugPrint('[WARN] Tag pendapatan & pengeluaran kosong');
      return;
    }

    // Parse ID tag
    List<int> idPendapatan = tagPendapatanStr
        ?.split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((id) => id > 0)
        .toList() ??
        [];

    List<int> idPengeluaran = tagPengeluaranStr
        ?.split(',')
        .map((e) => int.tryParse(e.trim()) ?? 0)
        .where((id) => id > 0)
        .toList() ??
        [];

    final List<int> allIds = {...idPendapatan, ...idPengeluaran}.toList();
    if (allIds.isEmpty) {
      debugPrint('[WARN] Tidak ada ID tag valid');
      return;
    }

    // Ambil data tag dari DB
    final allTags =
    await TagTransaksiService().getTagTransaksiByIds(allIds);

    for (final tag in allTags) {
      int kategori = int.tryParse(
        tag.kategoriTransaksi?.toString() ?? '2',
      ) ?? 2;

      switch (kategori) {
        case 1:
          tagPendapatan.add(tag);
          break;
        case 2:
          tagPengeluaran.add(tag);
          break;
        case 3:
          tagPremi.add(tag);
          break;
        case 4:
          tagBersihSetoran.add(tag);
          break;
        default:
          tagPengeluaran.add(tag);
      }

      _controllers.putIfAbsent(tag.id, () => TextEditingController());
      _jumlahControllers.putIfAbsent(tag.id, () => TextEditingController());
      _literSolarControllers.putIfAbsent(tag.id, () => TextEditingController());
    }


    debugPrint('Jumlah tag pendapatan: ${tagPendapatan.length}');
    debugPrint('Jumlah tag pengeluaran: ${tagPengeluaran.length}');
    debugPrint('Jumlah tag premi: ${tagPremi.length}');
    debugPrint('Jumlah tag bersih/setoran: ${tagBersihSetoran.length}');

    // Isi controller dari transaksi terakhir (kalau ada)
    await _loadLastRekapTransaksi();

    if (mounted) {
      setState(() {});
    }
  }


  Future<void> _loadLastRekapTransaksi() async {
    await databaseHelper.initDatabase();
    await _getUserData();

    // ambil instance service secara lokal
    final penjualanService = PenjualanTiketService.instance;

    // 1. Ambil semua data terlebih dahulu
    final hasilReguler = await penjualanService.getSumJumlahTagihanReguler(kelasBus);
    final hasilNonReguler = await penjualanService.getSumJumlahTagihanNonReguler(kelasBus);
    final hasilBagasi = await databaseHelper.getSumJumlahPendapatanBagasi(kelasBus);

    print("=== DEBUG Rekap ===");
    print("Reguler: $hasilReguler");
    print("Non Reguler: $hasilNonReguler");
    print("Bagasi: $hasilBagasi");

    // 2. Isi nilai dalam setState setelah variabel siap
    setState(() {
      // ―――― Reguler ――――
      totalPendapatanRegulerValue = (hasilReguler['totalPendapatanReguler'] ?? 0).toDouble();
      jumlahTiketRegulerValue = (hasilReguler['jumlahTiketReguler'] ?? 0).toInt();

      // ―――― Non Reguler / Online ――――
      totalPendapatanNonRegulerValue = (hasilNonReguler['totalPendapatanNonReguler'] ?? 0).toDouble();
      jumlahTiketOnlineValue = (hasilNonReguler['jumlahTiketOnLine'] ?? 0).toInt();

      // ―――― Bagasi ――――
      totalPendapatanBagasiValue = (hasilBagasi['totalPendapatanBagasi'] ?? 0).toDouble();
      jumlahBarangBagasiValue = (hasilBagasi['jumlahBarangBagasi'] ?? 0).toInt();
    });

    print("=== Nilai Setelah setState ===");
    print("Reguler Pendapatan: $totalPendapatanRegulerValue");
    print("Reguler Tiket: $jumlahTiketRegulerValue");
    print("NonReg Pendapatan: $totalPendapatanNonRegulerValue");
    print("Online Tiket: $jumlahTiketOnlineValue");
    print("Bagasi Pendapatan: $totalPendapatanBagasiValue");
    print("Bagasi Barang: $jumlahBarangBagasiValue");

    // 3. ISI CONTROLLER dengan data yang sudah dihitung
    _isiControllerPendapatan();
  }

  bool _requiresJumlah(TagTransaksi tag) {
    // Untuk semua tag pendapatan, tampilkan kolom jumlah
    if (tagPendapatan.any((pendapatan) => pendapatan.id == tag.id)) {
      return true;
    }

    // Untuk pengeluaran tertentu yang membutuhkan jumlah
    List<String> tagsWithJumlah = ['Biaya Solar']; // Anda bisa tambahkan lainnya
    return tagsWithJumlah.contains(tag.nama);
  }

  // Tambahkan fungsi untuk menentukan kebutuhan liter solar
  bool _requiresLiterSolar(TagTransaksi tag) {
    List<String> tagsWithLiterSolar = ['Biaya Solar'];
    return tagsWithLiterSolar.contains(tag.nama);
  }

  // Fungsi untuk menentukan apakah tag memerlukan upload gambar
  bool _requiresImage(TagTransaksi tag) {
    List<String> tagsWithImage = [
      'Biaya Solar',
      'Biaya Perbaikan',
      'Biaya Tol',
      'Biaya Operasional Surabaya'
    ];
    return tagsWithImage.contains(tag.nama);
  }

  // Fungsi untuk handle upload gambar
  Future<void> _onImageUpload(TagTransaksi tag, XFile image) async {
    try {
      File imageFile = File(image.path);

      // Validasi ukuran file (max 5MB)
      if (await imageFile.length() > 5 * 1024 * 1024) {
        _showErrorDialog('Ukuran gambar terlalu besar. Maksimal 5MB.');
        return;
      }

      setState(() {
        _imageFiles[tag.id] = imageFile;
        _uploadedImages[tag.id] = image.path;
      });

      // 🔍 Tambahkan debug untuk memastikan file masuk lokal
      print('=== DEBUG IMAGE UPLOAD ===');
      print('Tag ID        : ${tag.id}');
      print('Nama Tag      : ${tag.nama}');
      print('Image Path    : ${image.path}');
      print('File Exists   : ${imageFile.existsSync()}');
      print('File Size     : ${(imageFile.lengthSync() / 1024).toStringAsFixed(2)} KB');
      print('===========================');

      // Simpan ke database lokal / API
      await SetoranKruService().updateFilePath(
        tag.id,        // idTagTransaksis
        image.path,    // foto path
      );

      // Tampilkan preview
      _showImagePreview(tag, imageFile);

      print('Gambar berhasil diupload untuk ${tag.nama}: ${image.path}');
    } catch (e) {
      print('Error upload gambar: $e');
      _showErrorDialog('Gagal mengupload gambar: $e');
    }
  }


  // Fungsi untuk meminta izin kamera
  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      _showPermissionDialog(
          'Izin Kamera Diperlukan',
          'Aplikasi membutuhkan izin kamera untuk mengambil foto bukti transaksi.'
      );
    }

    if (status.isPermanentlyDenied) {
      _showOpenSettingsDialog();
    }
  }

  // Fungsi untuk meminta izin galeri
  Future<void> _requestGalleryPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        _showPermissionDialog(
            'Izin Penyimpanan Diperlukan',
            'Aplikasi membutuhkan izin akses penyimpanan untuk memilih foto dari galeri.'
        );
      }

      if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog();
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isDenied) {
        _showPermissionDialog(
            'Izin Foto Diperlukan',
            'Aplikasi membutuhkan izin akses foto untuk memilih gambar dari galeri.'
        );
      }

      if (status.isPermanentlyDenied) {
        _showOpenSettingsDialog();
      }
    }
  }

  // Dialog untuk meminta izin
  void _showPermissionDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  // Dialog untuk membuka pengaturan
  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Izin Diperlukan'),
          content: Text('Izin diperlukan untuk mengakses kamera dan galeri. Silakan buka pengaturan untuk memberikan izin.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  // Tampilkan preview gambar
  void _showImagePreview(TagTransaksi tag, File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Preview Gambar - ${tag.nama}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(
                imageFile,
                width: 250,
                height: 250,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 16),
              Text(
                'Gambar berhasil diupload',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Hapus gambar jika user tidak setuju
                setState(() {
                  _imageFiles.remove(tag.id);
                  _uploadedImages.remove(tag.id);
                });
                Navigator.pop(context);
              },
              child: Text('Hapus'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Tampilkan error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menghapus gambar yang sudah diupload
  void _removeImage(TagTransaksi tag) {
    setState(() {
      _imageFiles.remove(tag.id);
      _uploadedImages.remove(tag.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gambar untuk ${tag.nama} telah dihapus'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _onSimpanPressed() async {
    final ValueNotifier<String> progress = ValueNotifier<String>('Memulai pengecekan...');
    // Tampilkan dialog progres (tidak dismissible)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Proses Simpan — Debug'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: progress,
                  builder: (context, value, child) {
                    return Text(value);
                  },
                ),
                SizedBox(height: 12),
                LinearProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Jangan tutup otomatis kecuali proses selesai; tetap beri opsi kalau memang ingin membatalkan
                Navigator.of(context).pop();
              },
              child: Text('Tutup (Debug)'),
            ),
          ],
        );
      },
    );

    try {
      // STEP 1: cek transaksi penjualan belum dikirim
      print('STEP 1: Memanggil getPenjualanByStatus(\'N\')');
      progress.value = '1/5 — Mengecek transaksi penjualan yang belum dikirim...';
      await Future.delayed(Duration(milliseconds: 200)); // beri waktu UI update

      List<Map<String, dynamic>> penjualanData = await PenjualanTiketService.instance.getPenjualanByStatus('N');

      print('STEP 1 RESULT: ditemukan ${penjualanData.length} baris (status N)');
      progress.value = '1/5 — Ditemukan ${penjualanData.length} transaksi belum dikirim';
      await Future.delayed(Duration(milliseconds: 150));

      // STEP 1a: Dapatkan nilai rit dari penjualan tiket
      print('STEP 1a: Mendapatkan nilai rit dari penjualan tiket...');
      progress.value = '1a/5 — Mendapatkan data rit...';

      final List<String> ritList = await PenjualanTiketService.instance.getRitFromPenjualanTiket();
      final String? lastRit = await PenjualanTiketService.instance.getLastRitFromPenjualanTiket();

      print('STEP 1a RESULT:');
      print('  - Daftar rit: $ritList');
      print('  - Rit terakhir: $lastRit');

      // Auto-fill rit controller jika ada rit terakhir
      if (lastRit != null && lastRit.isNotEmpty) {
        ritController.text = lastRit;
        print('✅ Rit controller diisi otomatis: $lastRit');
      }

      if (penjualanData.isNotEmpty) {
        // Print sample data ke log (maks 5 baris)
        final sampleCount = penjualanData.length > 5 ? 5 : penjualanData.length;
        print('=== SAMPLE DATA (first $sampleCount) ===');
        for (int i = 0; i < sampleCount; i++) {
          print('Row ${i + 1}: ${penjualanData[i]}');
        }
        print('=======================================');

        // Tutup dialog progress sebelum menampilkan alert
        Navigator.of(context).pop();

        // Tampilkan dialog yang menjelaskan ada data yang belum dikirim
        showDialog(
          context: context,
          builder: (BuildContext ctx) {
            return AlertDialog(
              title: Text('Data Belum Dikirim'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text('Masih ada transaksi penjualan yang belum dikirim.'),
                    SizedBox(height: 8),
                    Text('Jumlah: ${penjualanData.length}'),
                    SizedBox(height: 8),
                    Text('Silakan kirim data tersebut terlebih dahulu di menu:\n👉 Penjualan Tiket → Transaksi.'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Tutup'),
                ),
              ],
            );
          },
        );
        return;
      }

      // STEP 2: validasi form
      print('STEP 2: Validasi form');
      progress.value = '2/5 — Memvalidasi form...';
      await Future.delayed(Duration(milliseconds: 150));

      final isValid = _formKey.currentState?.validate() ?? false;
      print('STEP 2 RESULT: isValid = $isValid');

      if (!isValid) {
        progress.value = '2/5 — Form tidak valid. Periksa input.';
        await Future.delayed(Duration(milliseconds: 200));

        // Tutup dialog progres dan beri feedback
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form belum valid — periksa isian yang wajib.')),
        );
        return;
      }

      // STEP 3: persiapan menyimpan (log nilai penting)
      print('STEP 3: Persiapan menyimpan— membaca controller dan state saat ini');
      progress.value = '3/5 — Menyiapkan data untuk disimpan...';
      await Future.delayed(Duration(milliseconds: 150));

      // Contoh logging elemen yang penting (rit, km, noPol)
      print('DEBUG: ritController=${ritController.text}');
      print('DEBUG: kmMasukGarasiController=${kmMasukGarasiController.text}');
      print('DEBUG: noPol=$noPol, idBus=$idBus, idUser=$idUser, idGroup=$idGroup');

      // STEP 4: panggil fungsi penyimpanan utama
      print('STEP 4: Memanggil _simpanValueRekap()');
      progress.value = '4/5 — Menyimpan rekap (proses dapat memakan waktu)...';
      await Future.delayed(Duration(milliseconds: 150));

      // Biarkan _simpanValueRekap() berjalan; jika ingin debug di dalamnya,
      // tambah progress update / callback di fungsi tersebut.
      await _simpanValueRekap();

      // STEP 5: selesai
      print('STEP 5: Selesai menyimpan rekap');
      progress.value = '5/5 — Selesai menyimpan rekap.';
      await Future.delayed(Duration(milliseconds: 250));

      // Tutup dialog progres
      Navigator.of(context).pop();

      // Feedback sukses
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data rekap berhasil disimpan (debug).')),
      );
    } catch (e, st) {
      // Tampilkan error dengan rincian di log dan UI
      print('ERROR di _onSimpanPressed: $e');
      print(st);

      // Tutup dialog progres jika masih terbuka
      try {
        Navigator.of(context).pop();
      } catch (_) {}

      // Tampilkan dialog error
      showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text('Error saat menyimpan'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text('Terjadi error: $e'),
                  SizedBox(height: 8),
                  Text('Lihat console log untuk stack trace lengkap.'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Tutup'),
              ),
            ],
          );
        },
      );

      // Juga tunjukkan SnackBar singkat
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data rekap.')),
      );
    }
  }

  bool _isPengeluaran(TagTransaksi tag) {
    return tagPengeluaran.any((pengeluaran) => pengeluaran.id == tag.id);
  }

  @override
  Widget build(BuildContext context) {
    // Debug sebelum membuat widget
    print('=== FINAL CHECK SEBELUM BUILD WIDGET x===');
    print('_controllers[1]: "${_controllers[1]?.text}"');
    print('_jumlahControllers[1]: "${_jumlahControllers[1]?.text}"');
    print('_controllers[2]: "${_controllers[2]?.text}"');
    print('_jumlahControllers[2]: "${_jumlahControllers[2]?.text}"');
    print('_controllers[3]: "${_controllers[3]?.text}"');
    print('_jumlahControllers[3]: "${_jumlahControllers[3]?.text}"');

    return ViewFormRekapTransaksi(
      formKey: _formKey,
      kmMasukGarasiController: kmMasukGarasiController,
      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      controllers: _controllers,
      jumlahControllers: _jumlahControllers,
      literSolarControllers: _literSolarControllers,
      onImageUpload: _onImageUpload,
      uploadedImages: _uploadedImages,
      onRemoveImage: _removeImage,
      onSimpan: _onSimpanPressed,
      isPengeluaran: _isPengeluaran,
      requiresImage: _requiresImage,
      requiresJumlah: _requiresJumlah,
      requiresLiterSolar: _requiresLiterSolar,
      onCalculatePremiBersih: _handleCalculatePremiBersih,
      keydataPremiextra: keydataPremiextra,
    );
  }

  String _getKelasLayanan() {
    if (keydataPremiextra == null || keydataPremiextra!.isEmpty) {
      return '';
    }

    List<String> parts = keydataPremiextra!.split('_');
    if (parts.length >= 2) {
      return '${parts[0]}${parts[1]}'.toLowerCase();
    }
    return '';
  }

  Future<void> _simpanValueRekap() async {
    final setoranService = SetoranKruService();
    final premiService = PremiPosisiKruService();
    final premiHarianService = PremiHarianKruService(); // Service untuk premi harian
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    try {
      String kelasLayanan = _getKelasLayanan();

      print('=== [DEBUG] KELAS LAYANAN ===');
      print('keydataPremiextra: $keydataPremiextra');
      print('kelasLayanan: $kelasLayanan');
      print('=============================');

      List<Map<String, dynamic>> users = await _userService.getUsersRaw();

      if (users.isEmpty) {
        print('Tidak ada data user');
        return;
      }

      Map<String, dynamic> firstUser = users[0];

      print('=== MULAI SIMPAN REKAP ===');
      print('Tanggal Transaksi: $formattedDate');
      print('KM Pulang: ${kmMasukGarasiController.text}');

      print('DEBUG RIT _simpanValueRekap: ritController=${ritController.text}');

      // DEBUG: Cek nilai rit
      final ritValue = ritController.text;
      if (ritValue.isEmpty) {
        print('❌ Error: Rit harus diisi');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rit harus diisi')),
        );
        return;
      }

      print('Rit: $ritValue');
      print('No. Pol: $noPol');
      print('Id Bus: $idBus, Kode Trayek: $kodeTrayek, Nama Trayek: $namaTrayek');
      print('Id Personil: $idUser, Id Group: $idGroup');

      // 1. GENERATE ID TRANSAKSI dengan format: BUS.MMYYYY.milisecond.idUser
      final monthYear = DateFormat('MMyyyy').format(now);
      final milliseconds = now.millisecondsSinceEpoch;
      final idTransaksi = 'BUS.$monthYear.$milliseconds.$idUser';
      print('🆔 ID Transaksi Generated: $idTransaksi');

      // Kumpulkan semua setoran dasar terlebih dahulu
      List<SetoranKru> semuaSetoran = [];

      // 2. Kumpulkan setoran pendapatan
      for (var tag in tagPendapatan) {
        final valueText = _controllers[tag.id]?.text ?? '0';
        final jumlahText = _jumlahControllers[tag.id]?.text ?? '0';

        final cleanValue = valueText.replaceAll('.', '').replaceAll(',00', '');
        final nilai = double.tryParse(cleanValue) ?? 0;

        final jumlah = int.tryParse(jumlahText.replaceAll('.', '')) ?? 0;

        final coaPendapatan = coaPendapatanBusController.text.trim();

        // Hanya simpan jika nilai > 0 atau jumlah > 0
        if (nilai > 0 || jumlah > 0) {
          print('--- Pendapatan ---');
          print('COA: $coaPendapatan');
          print('Tag ID: ${tag.id}, Nama Tag: ${tag.nama}');
          print('Nilai: $nilai, Jumlah: $jumlah');

          final setoran = SetoranKru(
            tglTransaksi: formattedDate,
            kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
            rit: ritValue,
            noPol: noPol ?? '',
            idBus: idBus,
            kodeTrayek: kodeTrayek ?? '',
            idPersonil: idUser,
            idGroup: idGroup,
            jumlah: jumlah,               // ⬅️ DIISI dari jumlahControllers
            idTransaksi: idTransaksi,
            coa: coaPendapatan,
            nilai: nilai,                 // ⬅️ pendapatan
            idTagTransaksi: tag.id,
            status: 'N',
            keterangan: null,
            fupload: null,
            fileName: null,
            updatedAt: formattedDate,
            createdAt: formattedDate,
          );

          semuaSetoran.add(setoran);
          print('✅ Ditambahkan: ${tag.nama}');
        }
      }

      // 3. Kumpulkan setoran pengeluaran
      for (var tag in tagPengeluaran) {
        double nilai = 0;
        int jumlah = 1;
        String? keterangan = null;
        final coaPengeluaran = coaPengeluaranBusController.text;

        final fotoPath = _uploadedImages[tag.id];
        final fotoName = fotoPath != null ? fotoPath.split('/').last : null;

        print('--------------------------------------------------');
        print('🔍 CEK DATA TAG: ${tag.nama} (ID: ${tag.id})');
        print('📸 Foto Path: $fotoPath');
        print('📄 Foto Name: $fotoName');
        print('--------------------------------------------------');

        if (tag.id == 16) {
          // ---------------------------------------------
          //           BIAYA SOLAR
          // ---------------------------------------------
          final nominalSolarText = _controllers[tag.id]?.text ?? '0';
          final nominalSolar = double.tryParse(
              nominalSolarText.replaceAll('.', '').replaceAll(',00', '')) ??
              0;

          final literSolarText = _literSolarControllers[tag.id]?.text ?? '0';
          final literSolar = double.tryParse(literSolarText) ?? 0;

          print('--- BIAYA SOLAR (TAG 16) ---');
          print('Nominal Text: $nominalSolarText');
          print('Nominal Solar: $nominalSolar');
          print('Liter Solar Text: $literSolarText');
          print('Liter Solar Parsed: $literSolar');

          nilai = nominalSolar;
          jumlah = literSolar.toInt();
          keterangan = literSolar > 0 ? 'Solar: $literSolar liter' : null;

          print('HASIL → Nilai: $nilai | Jumlah: $jumlah | Ket: $keterangan');

        } else {
          // ---------------------------------------------
          //           BIAYA LAINNYA
          // ---------------------------------------------
          final valueText = _controllers[tag.id]?.text ?? '0';
          nilai = double.tryParse(valueText.replaceAll('.', '').replaceAll(',00', '')) ?? 0;

          print('--- BIAYA LAINNYA ---');
          print('coa Pengeluaran: $coaPengeluaran');
          print('Value Text: $valueText');
          print('Nilai Parsed: $nilai');
        }

        // ---------------------------------------------
        //           FILTER: hanya nilai > 0
        // ---------------------------------------------
        if (nilai > 0) {

          print('📌 AKAN DISIMPAN → ${tag.nama}');
          print('  • Nilai: $nilai');
          print('  • Jumlah: $jumlah');
          print('  • Keterangan: $keterangan');
          print('  • Foto Path: $fotoPath');
          print('  • Foto Name: $fotoName');

          final setoran = SetoranKru(
            tglTransaksi: formattedDate,
            kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
            rit: ritValue,
            noPol: noPol ?? '',
            idBus: idBus,
            kodeTrayek: kodeTrayek ?? '',
            idPersonil: idUser,
            idGroup: idGroup,
            jumlah: jumlah,
            idTransaksi: idTransaksi,
            coa: coaPengeluaran ?? '',
            nilai: nilai,
            idTagTransaksi: tag.id,
            status: 'N',
            keterangan: keterangan,
            fupload: fotoPath,
            fileName: fotoName,
            updatedAt: formattedDate,
            createdAt: formattedDate,
          );

          semuaSetoran.add(setoran);
          print('✅ Pengeluaran disimpan: ${tag.nama}');
          print('--------------------------------------------------\n');

        } else {
          print('⚠️ SKIP → ${tag.nama} (nilai = 0)');
          print('--------------------------------------------------\n');
        }
      }

      // 4. Kumpulkan setoran premi (dengan perbaikan COA 32 dan 27)
      for (var tag in tagPremi) {
        String coaPremi = '';

        final valueText = _controllers[tag.id]?.text ?? '0';
        final nilai = double.tryParse(
            valueText.replaceAll('.', '').replaceAll(',00', '')
        ) ?? 0;

        if (nilai <= 0) {
          print('⚠️ Skip premi ${tag.nama} - nilai 0');
          continue;
        }

        print('--- PREMI ---');
        print('Tag ID: ${tag.id}, Nama Tag: ${tag.nama}, Nilai: $nilai');

        // === PERBAIKAN UTAMA ===
        if (tag.id == 32) {
          coaPremi = (coaUtangPremiController.text).trim();
          print('[PREMI 32] COA Utang Premi: "$coaPremi"');
        }
        else if (tag.id == 27) {
          coaPremi = (coaPengeluaranBusController.text).trim();
          print('[PREMI 27] COA Pengeluaran Bus: "$coaPremi"');
        }

        // Validasi COA
        if (coaPremi.isEmpty) {
          print('❌ ERROR: COA untuk tag premi ${tag.id} tidak boleh kosong!');
          print('   Pastikan controller di UI sudah terisi sebelum simpan.');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('COA premi ${tag.id} belum terisi!')),
          );
          continue; // mencegah data premi invalid masuk DB
        }

        print('COA FINAL yang dikirim ke SetoranKru: $coaPremi');
        // ========================

        final setoran = SetoranKru(
          tglTransaksi: formattedDate,
          kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
          rit: ritValue,
          noPol: noPol ?? '',
          idBus: idBus,
          kodeTrayek: kodeTrayek ?? '',
          idPersonil: idUser,
          idGroup: idGroup,
          jumlah: 0,
          idTransaksi: idTransaksi,
          coa: coaPremi,
          nilai: nilai,
          idTagTransaksi: tag.id,
          status: 'N',
          keterangan: null,
          fupload: null,
          fileName: null,
          updatedAt: formattedDate,
          createdAt: formattedDate,
        );

        semuaSetoran.add(setoran);
        print('✅ Premi ditambahkan: ${tag.nama}');
      }


      // 5. Kumpulkan setoran bersih setoran
      for (var tag in tagBersihSetoran) {
        final valueText = _controllers[tag.id]?.text ?? '0';
        final nilai = double.tryParse(valueText.replaceAll('.', '').replaceAll(',00', '')) ?? 0;

        // Hanya simpan jika nilai > 0
        if (nilai > 0) {
          totalPendapatanBersih += nilai;
          print('--- BERSIH SETORAN ---');
          print('Tag ID: ${tag.id}, Nama Tag: ${tag.nama}, Nilai: $nilai');

          final setoran = SetoranKru(
            tglTransaksi: formattedDate,
            kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
            rit: ritValue,
            noPol: noPol ?? '',
            idBus: idBus,
            kodeTrayek: kodeTrayek ?? '',
            idPersonil: idUser,
            idGroup: idGroup,
            jumlah: 0,
            idTransaksi: idTransaksi, // Gunakan ID transaksi yang digenerate
            coa: null,
            nilai: nilai,
            idTagTransaksi: tag.id,
            status: 'N',
            keterangan: null,
            fupload: null,
            fileName: null,
            updatedAt: formattedDate,
            createdAt: formattedDate,
          );

          semuaSetoran.add(setoran);
          print('✅ Bersih Setoran ditambahkan: ${tag.nama}');
        } else {
          print('⚠️ Skip bersih setoran ${tag.nama} - nilai 0');
        }
      }

      // 6. Dapatkan hasil kalkulasi lengkap dari PremiBersihCalculator
      print('--- MENDAPATKAN HASIL KALKULASI PREMI BERSIH ---');
      final calculationResult = PremiBersihCalculator.calculatePremiBersih(
        tagPendapatan: tagPendapatan,
        tagPengeluaran: tagPengeluaran,
        tagPremi: tagPremi,
        tagBersihSetoran: tagBersihSetoran,
        controllers: _controllers,
        jumlahControllers: _jumlahControllers,
        literSolarControllers: _literSolarControllers,
        userData: _user!,
      );

// Ekstrak semua nilai yang diperlukan dari calculationResult
      final double nominalPremiKru = (calculationResult['nominalPremiKru'] as double?) ?? 0.0;
      final double nominalPremiExtra = (calculationResult['nominalPremiExtra'] as double?) ?? 0.0;
      final double pendapatanBersih = (calculationResult['pendapatanBersih'] as double?) ?? 0.0;
      final double pendapatanDisetor = (calculationResult['pendapatanDisetor'] as double?) ?? 0.0;
      final double totalPendapatan = (calculationResult['totalPendapatan'] as double?) ?? 0.0;
      final double totalPengeluaran = (calculationResult['totalPengeluaran'] as double?) ?? 0.0;
      final double sisaPendapatan = (calculationResult['sisaPendapatan'] as double?) ?? 0.0;
      final double tolAdjustment = (calculationResult['tolAdjustment'] as double?) ?? 0.0;

// Debug output untuk memverifikasi nilai
      print('=== HASIL KALKULASI YANG DIEKSTRAK ===');
      print('📊 Nominal Premi Kru: $nominalPremiKru');
      print('📊 Nominal Premi Extra: $nominalPremiExtra');
      print('💰 Pendapatan Bersih: $pendapatanBersih');
      print('💰 Pendapatan Disetor: $pendapatanDisetor');
      print('💰 Total Pendapatan: $totalPendapatan');
      print('💰 Total Pengeluaran: $totalPengeluaran');
      print('💰 Sisa Pendapatan: $sisaPendapatan');
      print('💰 Tol Adjustment: $tolAdjustment');
      print('====================================');

      print('=== MENJALANKAN SIMPAN SETORAN LENGKAP ===');
      print('Total setoran dasar: ${semuaSetoran.length}');
      print('Nominal Premi Kru: $nominalPremiKru');

      // 7. Ambil data premi posisi kru dan kru bis untuk perhitungan
      final List<PremiPosisiKru> premiList = await premiService.getAllPremiPosisiKru();
      final List<Map<String, dynamic>> kruBisList = await databaseHelper.getKruBis();

      // DEBUG: Validasi data yang didapat
      print('=== DEBUG DATA PREMI DAN KRU ===');
      print('📊 Jumlah premi posisi kru: ${premiList.length}');
      print('📊 Jumlah data kru bis: ${kruBisList.length}');

      if (premiList.isEmpty) {
        print('❌ CRITICAL: premiList KOSONG - tidak bisa menghitung premi kru');
      } else {
        print('✅ Data premi tersedia:');
        for (var i = 0; i < premiList.length; i++) {
          final premi = premiList[i];
          print('   $i. ${premi.namaPremi} - ${premi.persenPremi}');
        }
      }

      if (kruBisList.isEmpty) {
        print('❌ CRITICAL: kruBisList KOSONG - tidak ada kru untuk hitung premi');
      } else {
        print('✅ Data kru bis tersedia:');
        for (var kru in kruBisList) {
          print('   - ${kru['nama_lengkap']} sebagai ${kru['group_name']}');
        }
      }
      print('=== END DEBUG DATA ===');

      // 8. HITUNG DAN SIMPAN PREMI HARIAN KRU ke table premi_harian_kru
      print('--- HITUNG DAN SIMPAN PREMI HARIAN KRU ---');
      List<PremiHarianKru> premiHarianList = [];

      // Fungsi helper untuk normalisasi nama posisi
      String _normalizePositionName(String positionName) {
        final normalized = positionName.toLowerCase().trim();

        // Mapping manual untuk berbagai kemungkinan penulisan
        final mapping = {
          'supir': 'supir',
          'driver': 'supir',
          'sopir': 'supir',
          'kernet': 'kernet',
          'kenek': 'kernet',
          'asisten': 'kernet',
          'kondektur': 'kondektur',
          'kondek': 'kondektur',
          'pramugara': 'kondektur',
        };

        return mapping[normalized] ?? normalized;
      }

      for (var kru in kruBisList) {
        final int idPersonil = kru['id_personil'];
        final int idGroup = kru['id_group'];
        final String namaLengkap = kru['nama_lengkap'];
        final String groupName = kru['group_name'];

        print('🔍 Proses kru: $namaLengkap ($groupName)');

        // PERBAIKAN: Gunakan matching yang case-insensitive dengan helper function
        PremiPosisiKru? premiKru;
        try {
          final normalizedGroupName = _normalizePositionName(groupName);

          premiKru = premiList.firstWhere(
                (premi) {
              final premiName = (premi.namaPremi ?? '').toLowerCase().trim();

              // Debug matching process
              print('   🔄 Mencocokkan: "$premiName" dengan "$normalizedGroupName" (dari "$groupName")');

              return premiName == normalizedGroupName;
            },
          );
        } catch (e) {
          print('   ⚠️ Premi tidak ditemukan untuk "$groupName"');

          // Tampilkan daftar premi yang tersedia untuk membantu debugging
          print('   📋 Daftar premi tersedia:');
          for (var p in premiList) {
            print('      - "${p.namaPremi}" (${p.persenPremi})');
          }
          continue;
        }

        print('   ✅ Premi ditemukan: ${premiKru.namaPremi} - ${premiKru.persenPremi}');

        final String persenPremiStr = (premiKru.persenPremi ?? '0').toString();
        final double persenPremi = double.tryParse(persenPremiStr.replaceAll('%', '').replaceAll(' ', '')) ?? 0.0;

        // Hitung nominal premi harian
        final double nominalPremiHarian = (pendapatanBersih * persenPremi) / 100;
        print('rumus premi harian : $pendapatanBersih x $persenPremi');

        print('   📊 Perhitungan premi harian:');
        print('      - Persen premi: $persenPremi%');
        print('      - Nominal premi kru: $nominalPremiKru');
        print('      - Hasil: $nominalPremiHarian');

        // Simpan ke premi_harian_kru
        if (nominalPremiHarian > 0) {
          final premiHarian = PremiHarianKru(
            idTransaksi: int.tryParse(idTransaksi.replaceAll('BUS.', '')) ?? 0,
            kodeTrayek: kodeTrayek, // ✅ FIX UTAMA
            idJenisPremi: 1,        // ✅ WAJIB (karena Anda query pakai ini)
            idUser: idPersonil,
            idGroup: idGroup,
            persenPremiDisetor: persenPremi,
            nominalPremiDisetor: nominalPremiHarian,
            tanggalSimpan: formattedDate,
            status: 'N',
          );

          print('   🧾 Data premi yang akan disimpan:');
          print('      - id_transaksi : ${premiHarian.idTransaksi}');
          print('      - kode_trayek  : ${premiHarian.kodeTrayek}');
          print('      - id_jenis     : ${premiHarian.idJenisPremi}');
          print('      - id_user      : ${premiHarian.idUser}');
          print('      - id_group     : ${premiHarian.idGroup}');
          print('      - persen       : ${premiHarian.persenPremiDisetor}');
          print('      - nominal      : ${premiHarian.nominalPremiDisetor}');

          premiHarianList.add(premiHarian);
          print('   ✅ Premi harian disiapkan untuk $namaLengkap: Rp$nominalPremiHarian');
        } else {
          print('   ⚠️ Premi harian 0 untuk $namaLengkap, tidak disimpan');
        }
      }

      // 9. Simpan semua data premi harian kru
      if (premiHarianList.isNotEmpty) {
        try {
          print('================ VALIDASI DATA SEBELUM INSERT ================');

          for (var i = 0; i < premiHarianList.length; i++) {
            final p = premiHarianList[i];
            print('➡️ Row #${i + 1}');
            print('   kode_trayek  : ${p.kodeTrayek}');
            print('   id_jenis     : ${p.idJenisPremi}');
          }

          await premiHarianService.insertBulkPremiHarianKru(premiHarianList);
          print('✅ ${premiHarianList.length} data premi harian kru berhasil disimpan');
        } catch (e) {
          print('❌ Gagal menyimpan premi harian kru: $e');
        }
      } else {
        print('⚠️ Tidak ada data premi harian kru yang disimpan');
      }

      // Debug: tampilkan semua setoran yang akan disimpan
      print('--- DETAIL SETORAN YANG AKAN DISIMPAN ---');

      print('--- DETAIL SETORAN YANG AKAN DISIMPAN ---');
      for (var i = 0; i < semuaSetoran.length; i++) {
        final setoran = semuaSetoran[i];
        // final label = setoran.idTagTransaksi == 15 ? ' - Biaya Tol (DIHITUNG OTOMATIS)' : '';
        // print('$i. ${setoran.idTagTransaksi}: Rp${setoran.nilai} (jumlah: ${setoran.jumlah})$label');
        print('$i. ${setoran.idTagTransaksi}: Rp${setoran.nilai} (jumlah: ${setoran.jumlah})');
      }

      print('=== INFORMASI PERHITUNGAN ===');
      print('Sisa Pendapatan: Rp$sisaPendapatan');
      // print('Biaya Tol: Rp$biayaTol');

      // 10. Gunakan simpanSetoranLengkap untuk menyimpan semua data setoran (TANPA premi posisi kru)
      await setoranService.simpanSetoranLengkap(
        setoranList: semuaSetoran,
        nominalPremiKru: nominalPremiKru,
        tanggalTransaksi: formattedDate,
        rit: ritValue,
        noPol: noPol ?? '',
        idBus: idBus,
        kodeTrayek: kodeTrayek ?? '',
      );

      print('=== SELESAI SIMPAN REKAP ===');
      print('✅ Setoran dasar: ${semuaSetoran.length} transaksi');
      print('✅ Premi harian kru: ${premiHarianList.length} data');

      // Beri feedback ke user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data rekap berhasil disimpan - ${semuaSetoran.length} transaksi setoran + ${premiHarianList.length} premi kru')),
      );

      // Reset form jika perlu
      _controllers.forEach((key, controller) => controller.clear());
      _jumlahControllers.forEach((key, controller) => controller.clear());
      _literSolarControllers.forEach((key, controller) => controller.clear());
      kmMasukGarasiController.clear();
      ritController.clear();

      print('✅ Form berhasil direset');

    } catch (e, stackTrace) {
      print('❌ Error menyimpan data rekap: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data rekap: ${e.toString()}')),
      );
    }
  }

  Future<bool> isTableExists(Database database, String tableName) async {
    List<Map<String, dynamic>> result = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
    );
    return result.isNotEmpty;
  }

  void printTableContents(Database database, String tableName) async {
    // Implementation if needed
  }

  void _kirimValueRekap() {
    // Implementation if needed
  }
}