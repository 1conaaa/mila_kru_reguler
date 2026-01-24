import 'dart:core';
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
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';
import 'package:mila_kru_reguler/utils/controller_utils.dart';
import 'package:mila_kru_reguler/utils/image_upload_utils.dart';
import 'package:mila_kru_reguler/utils/permission_utils.dart';
import 'package:mila_kru_reguler/utils/dialog_utils.dart';
import 'package:mila_kru_reguler/utils/premi_bersih_calculator.dart';
import 'package:mila_kru_reguler/utils/save_rekap_utils.dart';
import 'package:mila_kru_reguler/utils/tag_loading_utils.dart';
import 'package:mila_kru_reguler/utils/validation_utils.dart';
import 'package:mila_kru_reguler/utils/debug_utils.dart';
import 'package:mila_kru_reguler/utils/form_reset_utils.dart';
import 'package:mila_kru_reguler/handlers/rekap_transaksi_handler.dart';
import 'package:mila_kru_reguler/services/rekap_transaksi_service.dart';
import 'package:mila_kru_reguler/view/widgets/rekap_transaksi_form.dart';
import 'package:mila_kru_reguler/view/widgets/image_upload_dialog.dart';
import 'package:mila_kru_reguler/view/widgets/progress_dialog.dart';
import 'package:mila_kru_reguler/models/calculation_result.dart';
import 'package:image_picker/image_picker.dart';


class FormRekapTransaksi extends StatefulWidget {
  @override
  _FormRekapTransaksiState createState() => _FormRekapTransaksiState();
}

class _FormRekapTransaksiState
    extends State<FormRekapTransaksi>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController(text: 'Hidden Value');
  final PremiPosisiKruService _premiService = PremiPosisiKruService();
  final bool _isHidden = true;
  final UserService _userService = UserService();
  final RekapTransaksiHandler _rekapHandler = RekapTransaksiHandler();
  final RekapTransaksiService _rekapService = RekapTransaksiService();

  double totalPendapatanBersih = 0.0;
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

  late String ritke = '';
  late String pendapatanTiketReguler = '';
  late String nilaiTiketReguler = '';
  late String pendapatanTiketOnline = '';
  late String nilaiTiketOnLine = '';
  late String pendapatanBagasi = '';
  late String banyakBarangBagasi = '';
  late String pengeluaranTol = '';
  late String pengeluaranTpr = '';
  late String pengeluaranPerpal = '';
  late String nominalPremiExtra = '';
  late String nominalPremiKru = '';
  late String kmMasukGarasi = '';
  late List<TagTransaksi> visibleTabs;
  late final TagTransaksiService _tagService;
  late TabController _tabController;
  late String kelasLayanan;

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

  Map<int, TextEditingController> _controllers = {};
  Map<int, TextEditingController> _jumlahControllers = {};
  Map<int, TextEditingController> _literSolarControllers = {};
  Map<int, String> _uploadedImages = {};
  Map<int, File?> _imageFiles = {};

  List<TagTransaksi> tagPendapatan = [];
  List<TagTransaksi> tagPengeluaran = [];
  List<TagTransaksi> tagPremi = [];
  List<TagTransaksi> tagBersihSetoran = [];

  User? _user;

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper.instance;
    _loadTagTransaksi();
    _loadLastRekapTransaksi();
    _getUserData();
  }

  Future<void> _initTags() async {
    final tagMap = await TagLoadingUtils.loadTagTransactions(
      userService: _userService,
      tagTransaksiService: _tagService,
    );

    visibleTabs = TagLoadingUtils.buildVisibleTabs(
      pendapatan: tagMap['pendapatan'] ?? [],
      pengeluaran: tagMap['pengeluaran'] ?? [],
      premi: tagMap['premi'] ?? [],
      bersihSetoran: tagMap['bersihSetoran'] ?? [],
      kelasLayanan: kelasLayanan,
    );

    _tabController = TabController(
      length: visibleTabs.length, // 🔥 SUDAH PASTI BENAR
      vsync: this,
    );

    setState(() {});
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
      final calculationResult = _rekapService.calculatePremiBersih(
        tagPendapatan: tagPendapatan,
        tagPengeluaran: tagPengeluaran,
        tagPremi: tagPremi,
        tagBersihSetoran: tagBersihSetoran,
        controllers: _controllers,
        jumlahControllers: _jumlahControllers,
        literSolarControllers: _literSolarControllers,
        userData: _user!,
      );

      _rekapService.updateAutoCalculatedFields(
        calculationResult: calculationResult,
        controllers: _controllers,
        userData: _user!,
      );
    }
  }

  void _isiControllerPendapatan() {
    ControllerUtils.fillIncomeControllers(
      controllers: _controllers,
      jumlahControllers: _jumlahControllers,
      totalPendapatanRegulerValue: totalPendapatanRegulerValue,
      jumlahTiketRegulerValue: jumlahTiketRegulerValue,
      totalPendapatanNonRegulerValue: totalPendapatanNonRegulerValue,
      jumlahTiketOnlineValue: jumlahTiketOnlineValue,
      totalPendapatanBagasiValue: totalPendapatanBagasiValue,
      jumlahBarangBagasiValue: jumlahBarangBagasiValue,
    );
  }

  Future<void> _getUserData() async {
    try {
      List<Map<String, dynamic>> users = await _userService.getUsersRaw();
      print('=== [DEBUG] DATABASE QUERY RESULTS ===');
      print('Number of users: ${users.length}');

      if (users.isNotEmpty) {
        Map<String, dynamic> firstUser = users[0];

        print('=== [DEBUG] PREMI FIELDS (CAMEL CASE) ===');
        print('premiExtra: ${firstUser['premiExtra']}');
        print('persenPremikru: ${firstUser['persenPremikru']}');
        print('keydataPremiextra: ${firstUser['keydataPremiextra']}');
        print('keydataPremikru: ${firstUser['keydataPremikru']}');

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

          coaPendapatanBusController.text = firstUser['coa_pendapatan_bus']?.toString() ?? '';

          coaPengeluaranBusController.text = firstUser['coa_pengeluaran_bus']?.toString() ?? '';

          coaUtangPremiController.text = firstUser['coa_utang_premi']?.toString() ?? '';
        });

        print('=== [DEBUG] AFTER UserData.fromMap ===');
        print('UserData object: $_user');
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _user = User.empty();
      });
    }
  }

  Future<void> _loadTagTransaksi() async {
    await databaseHelper.initDatabase();

    tagPendapatan.clear();
    tagPengeluaran.clear();
    tagPremi.clear();
    tagBersihSetoran.clear();

    _controllers.clear();
    _jumlahControllers.clear();
    _literSolarControllers.clear();

    final tagData = await TagLoadingUtils.loadTagTransactions(
      userService: _userService,
      tagTransaksiService: TagTransaksiService(),
    );

    tagPendapatan = tagData['pendapatan']!;
    tagPengeluaran = tagData['pengeluaran']!;
    tagPremi = tagData['premi']!;
    tagBersihSetoran = tagData['bersihSetoran']!;

    // Initialize controllers
    FormResetUtils.initializeControllers(
      tags: [...tagPendapatan, ...tagPengeluaran, ...tagPremi, ...tagBersihSetoran],
      controllers: _controllers,
      jumlahControllers: _jumlahControllers,
      literSolarControllers: _literSolarControllers,
    );

    debugPrint('Jumlah tag pendapatan: ${tagPendapatan.length}');
    debugPrint('Jumlah tag pengeluaran: ${tagPengeluaran.length}');
    debugPrint('Jumlah tag premi: ${tagPremi.length}');
    debugPrint('Jumlah tag bersih/setoran: ${tagBersihSetoran.length}');

    await _loadLastRekapTransaksi();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadLastRekapTransaksi() async {
    await databaseHelper.initDatabase();
    await _getUserData();

    final rekapData = await _rekapHandler.loadLastRekapData(kelasBus);

    print("=== DEBUG Rekap ===");
    print("Reguler: ${rekapData['reguler']}");
    print("Non Reguler: ${rekapData['nonReguler']}");
    print("Bagasi: ${rekapData['bagasi']}");

    setState(() {
      totalPendapatanRegulerValue = rekapData['reguler']['totalPendapatanReguler'];
      jumlahTiketRegulerValue = rekapData['reguler']['jumlahTiketReguler'];
      totalPendapatanNonRegulerValue = rekapData['nonReguler']['totalPendapatanNonReguler'];
      jumlahTiketOnlineValue = rekapData['nonReguler']['jumlahTiketOnLine'];
      totalPendapatanBagasiValue = rekapData['bagasi']['totalPendapatanBagasi'];
      jumlahBarangBagasiValue = rekapData['bagasi']['jumlahBarangBagasi'];
    });

    print("=== Nilai Setelah setState ===");
    print("Reguler Pendapatan: $totalPendapatanRegulerValue");
    print("Reguler Tiket: $jumlahTiketRegulerValue");
    print("NonReg Pendapatan: $totalPendapatanNonRegulerValue");
    print("Online Tiket: $jumlahTiketOnlineValue");
    print("Bagasi Pendapatan: $totalPendapatanBagasiValue");
    print("Bagasi Barang: $jumlahBarangBagasiValue");

    _isiControllerPendapatan();
  }

  bool _requiresJumlah(TagTransaksi tag) {
    return ControllerUtils.requiresQuantity(tag, tagPendapatan);
  }

  bool _requiresLiterSolar(TagTransaksi tag) {
    return ControllerUtils.requiresLiterSolar(tag);
  }

  bool _requiresImage(TagTransaksi tag) {
    return ControllerUtils.requiresImage(tag);
  }

  Future<void> _onImageUpload(TagTransaksi tag, XFile image) async {
    await ImageUploadUtils.onImageUpload(
      tag: tag,
      image: image,
      setImageFile: (File imageFile) {
        setState(() {
          _imageFiles[tag.id] = imageFile;
        });
      },
      setUploadedImage: (String path) {
        setState(() {
          _uploadedImages[tag.id] = path;
        });
      },
      context: context,
      showImagePreview: _showImagePreview,
      showErrorDialog: _showErrorDialog,
    );
  }

  Future<void> _requestCameraPermission() async {
    await PermissionUtils.requestCameraPermission(
      showPermissionDialog: _showPermissionDialog,
      showOpenSettingsDialog: _showOpenSettingsDialog,
    );
  }

  Future<void> _requestGalleryPermission() async {
    await PermissionUtils.requestGalleryPermission(
      showPermissionDialog: _showPermissionDialog,
      showOpenSettingsDialog: _showOpenSettingsDialog,
    );
  }

  void _showPermissionDialog(String title, String message) {
    PermissionUtils.showPermissionDialogWidget(
      context: context,
      title: title,
      message: message,
    );
  }

  void _showOpenSettingsDialog() {
    PermissionUtils.showOpenSettingsDialogWidget(context: context);
  }

  void _showImagePreview(TagTransaksi tag, File imageFile) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return ImageUploadDialog(
          tag: tag,
          imageFile: imageFile,
          onRemoveImage: () {
            _removeImage(tag);
          },
          onConfirm: () {
            int total = 0;
          },
        );
      },
    );
  }


  void _showErrorDialog(String message) {
    DialogUtils.showErrorDialog(context: context, message: message);
  }

  void _removeImage(TagTransaksi tag) {
    ImageUploadUtils.removeImage(
      tag: tag,
      removeImageFile: (int id) {
        setState(() {
          _imageFiles.remove(id);
        });
      },
      removeUploadedImage: (int id) {
        setState(() {
          _uploadedImages.remove(id);
        });
      },
      context: context,
    );
  }

  void _onSimpanPressed() async {
    // 1️⃣ Buat notifier progress (TIDAK pakai Provider)
    final ValueNotifier<String> progressMessage =
    ValueNotifier<String>('Memulai pengecekan...');

    // 2️⃣ Tampilkan ProgressDialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProgressDialog(
        title: 'Proses Simpan — Debug',
        messageNotifier: progressMessage,
        isDismissible: true, // debug only
      ),
    );

    try {
      // ================= STEP 1 =================
      DebugUtils.printSaveProgress(
          'STEP 1', 'Memanggil getPenjualanByStatus(\'N\')');

      progressMessage.value =
      '1/5 — Mengecek transaksi penjualan yang belum dikirim...';
      await Future.delayed(const Duration(milliseconds: 200));

      final List<Map<String, dynamic>> penjualanData =
      await _rekapHandler.checkUnsentTransactions();

      DebugUtils.printSaveProgress(
          'STEP 1 RESULT',
          'ditemukan ${penjualanData.length} baris (status N)');

      progressMessage.value =
      '1/5 — Ditemukan ${penjualanData.length} transaksi belum dikirim';
      await Future.delayed(const Duration(milliseconds: 150));

      // ================= STEP 1a =================
      DebugUtils.printSaveProgress(
          'STEP 1a', 'Mendapatkan nilai rit dari penjualan tiket...');
      progressMessage.value = '1a/5 — Mendapatkan data rit...';

      final String? lastRit = await _rekapHandler.getLastRitValue();
      if (lastRit != null && lastRit.isNotEmpty) {
        ritController.text = lastRit;
        debugPrint('✅ Rit controller diisi otomatis: $lastRit');
      }

      // Jika ada transaksi belum terkirim → STOP
      if (penjualanData.isNotEmpty) {
        Navigator.of(context).pop(); // tutup ProgressDialog
        progressMessage.dispose();

        DialogUtils.showUnsentDataDialog(
          context: context,
          dataCount: penjualanData.length,
        );
        return;
      }

      // ================= STEP 2 =================
      DebugUtils.printSaveProgress('STEP 2', 'Validasi form');
      progressMessage.value = '2/5 — Memvalidasi form...';
      await Future.delayed(const Duration(milliseconds: 150));

      final bool isValid = ValidationUtils.validateForm(
        formKey: _formKey,
        ritValue: ritController.text,
      );

      DebugUtils.printSaveProgress('STEP 2 RESULT', 'isValid = $isValid');

      if (!isValid) {
        progressMessage.value =
        '2/5 — Form tidak valid. Periksa input.';
        await Future.delayed(const Duration(milliseconds: 200));

        Navigator.of(context).pop();
        progressMessage.dispose();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form belum valid — periksa isian yang wajib.'),
          ),
        );
        return;
      }

      // ================= STEP 3–4 =================
      progressMessage.value = '3/5 — Menyimpan data rekap...';
      await _simpanValueRekap();

      // ================= STEP 5 =================
      DebugUtils.printSaveProgress('STEP 5', 'Selesai menyimpan rekap');
      progressMessage.value = '5/5 — Selesai menyimpan rekap.';
      await Future.delayed(const Duration(milliseconds: 250));

      Navigator.of(context).pop();
      progressMessage.dispose();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data rekap berhasil disimpan (debug).'),
        ),
      );
    } catch (e, st) {
      debugPrint('❌ ERROR di _onSimpanPressed: $e');
      debugPrintStack(stackTrace: st);

      try {
        Navigator.of(context).pop();
      } catch (_) {}

      progressMessage.dispose();

      DialogUtils.showErrorSavingDialog(
        context: context,
        errorMessage: e.toString(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan data rekap.'),
        ),
      );
    }
  }


  bool _isPengeluaran(TagTransaksi tag) {
    return ControllerUtils.isExpense(tag, tagPengeluaran);
  }

  @override
  Widget build(BuildContext context) {
    DebugUtils.printControllerValues(_controllers);

    return RekapTransaksiForm(
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

  Future<void> _simpanValueRekap() async {
    final setoranService = SetoranKruService();
    final premiService = PremiPosisiKruService();
    final premiHarianService = PremiHarianKruService();
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    try {
      String kelasLayanan = _rekapService.getKelasLayanan(keydataPremiextra);

      DebugUtils.printSaveProgress('=== [DEBUG] KELAS LAYANAN ===','keydataPremiextra: $keydataPremiextra, kelasLayanan: $kelasLayanan');

      List<Map<String, dynamic>> users = await _userService.getUsersRaw();
      if (users.isEmpty) {
        print('Tidak ada data user');
        return;
      }

      Map<String, dynamic> firstUser = users[0];

      DebugUtils.printSaveProgress('=== MULAI SIMPAN REKAP ===','Tanggal Transaksi: $formattedDate, KM Pulang: ${kmMasukGarasiController.text}');

      final ritValue = ritController.text;
      if (ritValue.isEmpty) {
        print('❌ Error: Rit harus diisi');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rit harus diisi')),
        );
        return;
      }

      final idTransaksi = _rekapService.generateTransactionId(idUser);
      DebugUtils.printSaveProgress('🆔 ID Transaksi Generated', idTransaksi);

      List<SetoranKru> semuaSetoran = [];

      // Collect income setoran
      semuaSetoran.addAll(SaveRekapUtils.collectIncomeSetoran(
        tagPendapatan: tagPendapatan,
        controllers: _controllers,
        jumlahControllers: _jumlahControllers,
        formattedDate: formattedDate,
        kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
        ritValue: ritValue,
        noPol: noPol,
        idBus: idBus,
        kodeTrayek: kodeTrayek,
        idUser: idUser,
        idGroup: idGroup,
        idTransaksi: idTransaksi,
        coaPendapatan: coaPendapatanBusController.text.trim(),
      ));

      // Collect expense setoran
      semuaSetoran.addAll(SaveRekapUtils.collectExpenseSetoran(
        tagPengeluaran: tagPengeluaran,
        controllers: _controllers,
        literSolarControllers: _literSolarControllers,
        uploadedImages: _uploadedImages,
        formattedDate: formattedDate,
        kmPulang: double.tryParse(kmMasukGarasiController.text) ?? 0,
        ritValue: ritValue,
        noPol: noPol,
        idBus: idBus,
        kodeTrayek: kodeTrayek,
        idUser: idUser,
        idGroup: idGroup,
        idTransaksi: idTransaksi,
        coaPengeluaran: coaPengeluaranBusController.text,
      ));

      // ... (collect premi dan bersih setoran)

      final calculationResult = _rekapService.calculatePremiBersih(
        tagPendapatan: tagPendapatan,
        tagPengeluaran: tagPengeluaran,
        tagPremi: tagPremi,
        tagBersihSetoran: tagBersihSetoran,
        controllers: _controllers,
        jumlahControllers: _jumlahControllers,
        literSolarControllers: _literSolarControllers,
        userData: _user!,
      );

      DebugUtils.printCalculationResults(
        nominalPremiKru: calculationResult.nominalPremiKru,
        nominalPremiExtra: calculationResult.nominalPremiExtra,
        pendapatanBersih: calculationResult.pendapatanBersih,
        pendapatanDisetor: calculationResult.pendapatanDisetor,
        totalPendapatan: calculationResult.totalPendapatan,
        totalPengeluaran: calculationResult.totalPengeluaran,
        sisaPendapatan: calculationResult.sisaPendapatan,
        tolAdjustment: calculationResult.tolAdjustment,
      );

      final List<PremiPosisiKru> premiList = await premiService.getAllPremiPosisiKru();
      final List<Map<String, dynamic>> kruBisList = await _rekapHandler.getKruBisData();

      final premiHarianList = await SaveRekapUtils.calculateDailyPremi(
        kruBisList: kruBisList,
        premiList: premiList,
        kodeTrayek: kodeTrayek ?? '',
        idTransaksi: idTransaksi,
        pendapatanBersih: calculationResult.pendapatanBersih,
        nominalPremiKru: calculationResult.nominalPremiKru,
        normalizePositionName: _rekapService.normalizePositionName,
      );

      if (premiHarianList.isNotEmpty) {
        try {
          await premiHarianService.insertBulkPremiHarianKru(premiHarianList);
          print('✅ ${premiHarianList.length} data premi harian kru berhasil disimpan');
        } catch (e) {
          print('❌ Gagal menyimpan premi harian kru: $e');
        }
      }

      print('--- DETAIL SETORAN YANG AKAN DISIMPAN ---');
      for (var i = 0; i < semuaSetoran.length; i++) {
        final setoran = semuaSetoran[i];
        print('$i. ${setoran.idTagTransaksi}: Rp${setoran.nilai} (jumlah: ${setoran.jumlah})');
      }

      await setoranService.simpanSetoranLengkap(
        setoranList: semuaSetoran,
        nominalPremiKru: calculationResult.nominalPremiKru,
        tanggalTransaksi: formattedDate,
        rit: ritValue,
        noPol: noPol ?? '',
        idBus: idBus,
        kodeTrayek: kodeTrayek ?? '',
      );

      print('=== SELESAI SIMPAN REKAP ===');
      print('✅ Setoran dasar: ${semuaSetoran.length} transaksi');
      print('✅ Premi harian kru: ${premiHarianList.length} data');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data rekap berhasil disimpan - ${semuaSetoran.length} transaksi setoran + ${premiHarianList.length} premi kru')),
      );

      FormResetUtils.resetAllControllers(
        controllers: _controllers,
        jumlahControllers: _jumlahControllers,
        literSolarControllers: _literSolarControllers,
        additionalControllers: [
          kmMasukGarasiController,
          ritController,
        ],
      );

    } catch (e, stackTrace) {
      print('❌ Error menyimpan data rekap: $e');
      print(stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan data rekap: ${e.toString()}')),
      );
    }
  }
}