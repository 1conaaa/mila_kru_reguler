import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    _loadLastRekapTransaksi();
    _loadTagTransaksi(); // Load data tag transaksi
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

      setState(() {});
    }
  }

  Future<void> _loadLastRekapTransaksi() async {
    await databaseHelper.initDatabase();
    await _getUserData();

    // Ambil data dari PenjualanTiketService (reguler & non-reguler)
    final penjualanService = PenjualanTiketService.instance;

    final hasilReguler = await penjualanService.getSumJumlahTagihanReguler(kelasBus);
    final hasilNonReguler = await penjualanService.getSumJumlahTagihanNonReguler(kelasBus);

    // Ambil data bagasi tetap dari DatabaseHelper (sesuai permintaan)
    final hasilBagasi = await databaseHelper.getSumJumlahPendapatanBagasi(kelasBus);

    // Ambil nilai aman dengan fallback ke 0 jika null
    final int ritValue = (hasilReguler['rit'] ?? 0);
    final int totalPendapatanRegulerValue = (hasilReguler['totalPendapatanReguler'] ?? 0);
    final int jumlahTiketRegulerValue = (hasilReguler['jumlahTiketReguler'] ?? 0);

    final int totalPendapatanNonRegulerValue = (hasilNonReguler['totalPendapatanNonReguler'] ?? 0);
    final int jumlahTiketOnLineValue = (hasilNonReguler['jumlahTiketOnLine'] ?? 0);

    final int totalPendapatanBagasiValue = (hasilBagasi['totalPendapatanBagasi'] ?? 0);
    final int jumlahBarangBagasiValue = (hasilBagasi['jumlahBarangBagasi'] ?? 0);

    // Convert ke string untuk UI
    final String ritkeStr = ritValue.toString();
    final String pendapatanTiketRegulerStr = totalPendapatanRegulerValue.toString();
    final String nilaiTiketRegulerStr = jumlahTiketRegulerValue.toString();

    final String pendapatanTiketOnlineStr = totalPendapatanNonRegulerValue.toString();
    final String nilaiTiketOnLineStr = jumlahTiketOnLineValue.toString();

    final String pendapatanBagasiStr = totalPendapatanBagasiValue.toString();
    final String banyakBarangBagasiStr = jumlahBarangBagasiValue.toString();

    setState(() {
      ritke = ritkeStr;
      pendapatanTiketReguler = pendapatanTiketRegulerStr;
      nilaiTiketReguler = nilaiTiketRegulerStr;
      pendapatanTiketOnline = pendapatanTiketOnlineStr;
      nilaiTiketOnLine = nilaiTiketOnLineStr;
      pendapatanBagasi = pendapatanBagasiStr;
      banyakBarangBagasi = banyakBarangBagasiStr;
    });

    ritController.text = ritkeStr;

    // Update controllers (formatting aman: fallback 0)
    ritController.text = ritkeStr;

    pendapatanTiketRegulerController.text =
        formatter.format(totalPendapatanRegulerValue);
    jumlahTiketRegulerController.text = nilaiTiketRegulerStr;

    pendapatanTiketNonRegulerController.text =
        formatter.format(totalPendapatanNonRegulerValue);
    jumlahTiketOnLineController.text = nilaiTiketOnLineStr;

    pendapatanBagasiController.text =
        formatter.format(totalPendapatanBagasiValue);
    jumlahBarangBagasiController.text = banyakBarangBagasiStr;

    // Tutup database jika memang ingin menutup
    await databaseHelper.closeDatabase();

    // Logging
    print('cetak pendapatan tiket reguler $pendapatanTiketReguler $nilaiTiketReguler');
    print('cetak pendapatan tiket non reguler $pendapatanTiketOnline $nilaiTiketOnLine');
    print('cetak pendapatan bagasi $pendapatanBagasi $banyakBarangBagasi');
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
    List<Map<String, dynamic>> penjualanData = await PenjualanTiketService.instance.getPenjualanByStatus('N');
    if (penjualanData.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Data Belum Dikirim'),
            content: Text(
              'Masih ada transaksi penjualan yang belum dikirim.\n\n'
                  'Silakan kirim data tersebut terlebih dahulu di menu:\n'
                  '👉 Penjualan Tiket → Transaksi.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
              ),
            ],
          );
        },
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      await _simpanValueRekap();
    }
  }

  bool _isPengeluaran(TagTransaksi tag) {
    return tagPengeluaran.any((pengeluaran) => pengeluaran.id == tag.id);
  }

  @override
  Widget build(BuildContext context) {
    return ViewFormRekapTransaksi(
      formKey: _formKey,
      kmMasukGarasiController: kmMasukGarasiController,
      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      controllers: _controllers,
      jumlahControllers: _jumlahControllers,
      literSolarControllers: _literSolarControllers, // Tambahkan parameter baru
      onImageUpload: _onImageUpload, // Sekarang menerima 2 parameter
      uploadedImages: _uploadedImages, // Tambahkan status upload
      onRemoveImage: _removeImage, // Tambahkan fungsi hapus
      onSimpan: _onSimpanPressed,
      isPengeluaran: _isPengeluaran,
      requiresImage: _requiresImage,
      requiresJumlah: _requiresJumlah,
      requiresLiterSolar: _requiresLiterSolar, // Tambahkan parameter baru
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

      print('COA Data:');
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