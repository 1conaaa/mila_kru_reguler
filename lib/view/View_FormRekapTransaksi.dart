import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/setoranKru_model.dart';
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';
import 'package:mila_kru_reguler/view/View_FormSetoran.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:mila_kru_reguler/utils/premi_bersih_calculator.dart';

class FormRekapTransaksi extends StatefulWidget {
  @override
  _FormRekapTransaksiState createState() => _FormRekapTransaksiState();
}

class _FormRekapTransaksiState extends State<FormRekapTransaksi> {
  final TextEditingController _textController = TextEditingController(text: 'Hidden Value');
  final bool _isHidden = true;

  String? selectedKotaBerangkat;
  String? selectedKotaTujuan;

  int idUser = 0;
  int idGroup = 0;
  int idCompany = 0;
  int? idGarasi;
  int idBus = 0;
  String? noPol;
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

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();

    _loadTagTransaksi(); // Load data tag transaksi
    _loadLastRekapTransaksi();
  }

  void _handleCalculatePremiBersih() {
    final result = PremiBersihCalculator.calculatePremiBersih(
      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      controllers: _controllers,
      jumlahControllers: _jumlahControllers,
      literSolarControllers: _literSolarControllers,
    );

    // Update field yang dihitung otomatis
    PremiBersihCalculator.updateAutoCalculatedFields(
      calculationResult: result,
      controllers: _controllers,
    );
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
    List<Map<String, dynamic>> users = await databaseHelper.queryUsers();
    if (users.isNotEmpty) {
      Map<String, dynamic> firstUser = users[0];
      setState(() {
        idUser = firstUser['id_user'];
        idGroup = firstUser['id_group'];
        idCompany = firstUser['id_company'];
        idGarasi = firstUser['id_garasi'];
        idBus = firstUser['id_bus'];
        noPol = firstUser['no_pol'];
        namaTrayek = firstUser['nama_trayek'];
        jenisTrayek = firstUser['jenis_trayek'];
        kelasBus = firstUser['kelas_bus'];
        keydataPremiextra = firstUser['keydataPremiextra'];
        premiExtra = firstUser['premiExtra'];
        premiExtraController.text = premiExtra!;
        keydataPremikru = firstUser['keydataPremikru'];
        persenPremikru = firstUser['persenPremikru'];
        persenPremikruController.text = persenPremikru!;
      });
      print('premi pe $premiExtra , pt $persenPremikru $namaTrayek');
      print('premi persen kru $keydataPremikru');
    }
  }

  // Fungsi untuk memuat data tag transaksi
  Future<void> _loadTagTransaksi() async {
    await databaseHelper.initDatabase();

    List<Map<String, dynamic>> users = await databaseHelper.queryUsers();
    if (users.isEmpty) return;

    Map<String, dynamic> firstUser = users[0];
    String? tagPendapatanStr = firstUser['tagTransaksiPendapatan'];
    String? tagPengeluaranStr = firstUser['tagTransaksiPengeluaran'];

    print("Tag Pendapatan dari prefs: $tagPendapatanStr");
    print("Tag Pengeluaran dari prefs: $tagPengeluaranStr");

    if (tagPendapatanStr != null && tagPengeluaranStr != null) {
      List<int> idPendapatan = tagPendapatanStr.split(',').map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();
      List<int> idPengeluaran = tagPengeluaranStr.split(',').map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();

      await databaseHelper.initDatabase();

      List<TagTransaksi> allTags = await TagTransaksiService().getTagTransaksiByIds([...idPendapatan, ...idPengeluaran]);

      // Kelompokkan berdasarkan kategori_transaksi
      for (var tag in allTags) {
        // Handle tipe data kategoriTransaksi dengan aman
        int kategori = 2; // default ke Pengeluaran
        if (tag.kategoriTransaksi != null) {
          if (tag.kategoriTransaksi is int) {
            kategori = tag.kategoriTransaksi as int;
          } else if (tag.kategoriTransaksi is String) {
            kategori = int.tryParse(tag.kategoriTransaksi as String) ?? 2;
          } else if (tag.kategoriTransaksi is double) {
            kategori = (tag.kategoriTransaksi as double).toInt();
          }
        }

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

        // Inisialisasi controller untuk nominal
        _controllers[tag.id] = TextEditingController();
        // Inisialisasi controller untuk jumlah
        _jumlahControllers[tag.id] = TextEditingController();
        // Inisialisasi controller untuk liter solar
        _literSolarControllers[tag.id] = TextEditingController();
      }

      // Setelah semua controller dibuat, panggil _loadLastRekapTransaksi
      // untuk mengisi data pendapatan ke controller
      await _loadLastRekapTransaksi();

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
      totalPendapatanRegulerValue =
          (hasilReguler['totalPendapatanReguler'] ?? 0).toDouble();
      jumlahTiketRegulerValue =
          (hasilReguler['jumlahTiketReguler'] ?? 0).toInt();

      // ―――― Non Reguler / Online ――――
      totalPendapatanNonRegulerValue =
          (hasilNonReguler['totalPendapatanNonReguler'] ?? 0).toDouble();
      jumlahTiketOnlineValue =
          (hasilNonReguler['jumlahTiketOnLine'] ?? 0).toInt();

      // ―――― Bagasi ――――
      totalPendapatanBagasiValue =
          (hasilBagasi['totalPendapatanBagasi'] ?? 0).toDouble();
      jumlahBarangBagasiValue =
          (hasilBagasi['jumlahBarangBagasi'] ?? 0).toInt();
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
  // Fungsi untuk handle upload gambar
  Future<void> _onImageUpload(TagTransaksi tag, bool fromCamera) async {
    try {
      // Cek dan minta izin
      if (fromCamera) {
        await _requestCameraPermission();
      } else {
        await _requestGalleryPermission();
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
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

        // Tampilkan preview gambar
        _showImagePreview(tag, imageFile);

        print('Gambar berhasil diupload untuk ${tag.nama}: ${image.path}');
      }
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

      List<Map<String, dynamic>> penjualanData =
      await PenjualanTiketService.instance.getPenjualanByStatus('N');

      print('STEP 1 RESULT: ditemukan ${penjualanData.length} baris (status N)');
      progress.value = '1/5 — Ditemukan ${penjualanData.length} transaksi belum dikirim';
      await Future.delayed(Duration(milliseconds: 150));

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

  void _calculatePremiBersih(
      TextEditingController pendapatanTiketRegulerController,
      TextEditingController pendapatanTiketNonRegulerController,
      TextEditingController pendapatanBagasiController,
      TextEditingController tolController,
      TextEditingController tprController,
      TextEditingController perpalController,
      TextEditingController litersolarController,
      TextEditingController nominalsolarController,
      TextEditingController perbaikanController,
      TextEditingController premiExtraController,
      TextEditingController persenPremikruController,
      ) {
    // Debug awal
    print('=== Hitung Premi Bersih ===');
    print('RegulerCtrl: ${pendapatanTiketRegulerController.text}');
    print('NonRegulerCtrl: ${pendapatanTiketNonRegulerController.text}');
    print('BagasiCtrl: ${pendapatanBagasiController.text}');

    // Parse input pendapatan
    double nominalTiketReguler = double.tryParse(
      pendapatanTiketRegulerController.text.replaceAll('.', '').replaceAll(',00', ''),
    ) ??
        0.0;

    double nominalTiketOnline = double.tryParse(
      pendapatanTiketNonRegulerController.text.replaceAll('.', '').replaceAll(',00', ''),
    ) ??
        0.0;

    double pendapatanBagasi = double.tryParse(
      pendapatanBagasiController.text.replaceAll('.', '').replaceAll(',00', ''),
    ) ??
        0.0;

    print('Nominal Reguler: $nominalTiketReguler');
    print('Nominal Online: $nominalTiketOnline');
    print('Nominal Bagasi: $pendapatanBagasi');

    // Parse input pengeluaran
    double pengeluaranTol = double.tryParse(tolController.text) ?? 0.0;
    double pengeluaranTpr = double.tryParse(tprController.text) ?? 0.0;
    double pengeluaranPerpal = double.tryParse(perpalController.text) ?? 0.0;
    double literSolar = double.tryParse(litersolarController.text) ?? 0.0;
    double nominalSolar = double.tryParse(nominalsolarController.text) ?? 0.0;
    double perbaikan = double.tryParse(perbaikanController.text) ?? 0.0;

    double pendKeseluruhan = nominalTiketReguler + nominalTiketOnline + pendapatanBagasi;

    double pengOprs = pengeluaranPerpal + pengeluaranTpr + pengeluaranTol + nominalSolar;
    double pengLain = pengOprs + perbaikan;

    // Persentase Premi
    double persenPremiExtra =
        (double.tryParse(premiExtraController.text.replaceAll('%', '')) ?? 0.0) / 100;

    double persenPremiKruCtrl =
    (double.tryParse(persenPremikruController.text.replaceAll('%', '')) ?? 0.0);

    double persenPremiKru = (persenPremiKruCtrl -
        (double.tryParse(premiExtraController.text.replaceAll('%', '')) ?? 0.0)) /
        100;

    print('Persen Premi Extra: $persenPremiExtra');
    print('Persen Premi Kru: $persenPremiKru');
    print("Trayek: $namaTrayek");

  }



  bool _isPengeluaran(TagTransaksi tag) {
    return tagPengeluaran.any((pengeluaran) => pengeluaran.id == tag.id);
  }

  @override
  Widget build(BuildContext context) {
    // Debug sebelum membuat widget
    print('=== FINAL CHECK SEBELUM BUILD WIDGET ===');
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
    );
  }

  Future<void> _simpanValueRekap() async {
    final setoranService = SetoranKruService();
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    try {
      List<Map<String, dynamic>> users = await databaseHelper.queryUsers();
      if (users.isEmpty) {
        print('Tidak ada data user');
        return;
      }

      Map<String, dynamic> firstUser = users[0];
      String coaPendapatanBus = firstUser['coaPendapatanBus'] ?? '';
      String coaPengeluaranBus = firstUser['coaPengeluaranBus'] ?? '';
      String coaUtangPremi = firstUser['coaUtangPremi'] ?? '';

      print('COA Data xxx:');
      print('- Pendapatan Bus: $coaPendapatanBus');
      print('- Pengeluaran Bus: $coaPengeluaranBus');
      print('- Utang Premi: $coaUtangPremi');

      print('=== MULAI SIMPAN REKAP ===');
      print('Tanggal Transaksi: $formattedDate');
      print('KM Pulang: ${kmMasukGarasiController.text}');
      print('Rit: ${ritController.text}');
      print('No. Pol: $noPol');
      print('Id Bus: $idBus, Kode Trayek: $namaTrayek');
      print('Id Personil: $idUser, Id Group: $idGroup');

      // Loop untuk simpan pendapatan
      for (var tag in tagPendapatan) {
        final valueText = _controllers[tag.id]?.text ?? '0';
        final nilai = double.tryParse(valueText.replaceAll(',', '')) ?? 0;

        print('--- Pendapatan ---');
        print('Tag ID: ${tag.id}, Nama Tag: ${tag.nama}, Nilai: $nilai');

        final setoran = SetoranKru(
          tglTransaksi: formattedDate,
          kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
          rit: ritController.text,
          noPol: noPol ?? '',
          idBus: idBus,
          kodeTrayek: namaTrayek ?? '',
          idPersonil: idUser,
          idGroup: idGroup,
          jumlah: 1,
          idTransaksi: null,
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

        print('Menyimpan setoran pendapatan: $setoran');
        await setoranService.insertSetoran(setoran);
        print('Selesai insert pendapatan tag ID: ${tag.id}');
      }

      // Loop untuk simpan pengeluaran
      for (var tag in tagPengeluaran) {
        final valueText = _controllers[tag.id]?.text ?? '0';
        final nilai = double.tryParse(valueText.replaceAll(',', '')) ?? 0;

        print('--- Pengeluaran ---');
        print('Tag ID: ${tag.id}, Nama Tag: ${tag.nama}, Nilai: $nilai');

        final setoran = SetoranKru(
          tglTransaksi: formattedDate,
          kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
          rit: ritController.text,
          noPol: noPol ?? '',
          idBus: idBus,
          kodeTrayek: namaTrayek ?? '',
          idPersonil: idUser,
          idGroup: idGroup,
          jumlah: 1,
          idTransaksi: null,
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

        print('Menyimpan setoran pengeluaran: $setoran');
        await setoranService.insertSetoran(setoran);
        print('Selesai insert pengeluaran tag ID: ${tag.id}');
      }

      // Loop untuk simpan pengeluaran
      for (var tag in tagPremi) {
        final valueText = _controllers[tag.id]?.text ?? '0';
        final nilai = double.tryParse(valueText.replaceAll(',', '')) ?? 0;

        print('--- PREMI ---');
        print('Tag ID: ${tag.id}, Nama Tag: ${tag.nama}, Nilai: $nilai');

        final setoran = SetoranKru(
          tglTransaksi: formattedDate,
          kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
          rit: ritController.text,
          noPol: noPol ?? '',
          idBus: idBus,
          kodeTrayek: namaTrayek ?? '',
          idPersonil: idUser,
          idGroup: idGroup,
          jumlah: 1,
          idTransaksi: null,
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

        print('Menyimpan Premi : $setoran');
        await setoranService.insertSetoran(setoran);
        print('Selesai insert premi tag ID: ${tag.id}');
      }

      for (var tag in tagBersihSetoran) {
        final valueText = _controllers[tag.id]?.text ?? '0';
        final nilai = double.tryParse(valueText.replaceAll(',', '')) ?? 0;

        print('--- BERSIH SETORAN ---');
        print('Tag ID: ${tag.id}, Nama Tag: ${tag.nama}, Nilai: $nilai');

        final setoran = SetoranKru(
          tglTransaksi: formattedDate,
          kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
          rit: ritController.text,
          noPol: noPol ?? '',
          idBus: idBus,
          kodeTrayek: namaTrayek ?? '',
          idPersonil: idUser,
          idGroup: idGroup,
          jumlah: 1,
          idTransaksi: null,
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

        print('Menyimpan bersih setoran: $setoran');
        await setoranService.insertSetoran(setoran);
        print('Selesai insert bersih setoran tag ID: ${tag.id}');
      }

      print('=== SELESAI SIMPAN REKAP ===');

      // Beri feedback ke user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data rekap berhasil disimpan')),
      );

      // Reset form jika perlu
      _controllers.forEach((key, controller) => controller.clear());
      kmMasukGarasiController.clear();

    } catch (e, stackTrace) {
      print('Error menyimpan data rekap: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data rekap')),
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

  }

  void _kirimValueRekap() {}

}