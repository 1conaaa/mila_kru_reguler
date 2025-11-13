import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';

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

  // Variabel baru untuk data dinamis
  List<TagTransaksi> tagPendapatan = [];
  List<TagTransaksi> tagPengeluaran = [];
  Map<int, TextEditingController> _controllers = {};

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
        // if(namaTrayek == 'YOGYAKARTA - BANYUWANGI'){
        //   persenPremikru = '0%';
        // } else {
        persenPremikru = firstUser['persenPremikru'];
        // }
        persenPremikruController.text = persenPremikru!;
      });
      print('premi pe $premiExtra , pt $persenPremikru $namaTrayek');
    }
  }

  // Fungsi untuk memuat data tag transaksi
  Future<void> _loadTagTransaksi() async {
    await databaseHelper.initDatabase();

    // Ambil data user yang aktif
    List<Map<String, dynamic>> users = await databaseHelper.queryUsers();
    if (users.isEmpty) return; // Tidak ada user

    Map<String, dynamic> firstUser = users[0];
    // Ambil tag transaksi dari database user
    String? tagPendapatanStr = firstUser['tagTransaksiPendapatan'];
    String? tagPengeluaranStr = firstUser['tagTransaksiPengeluaran'];

    print("Tag Pendapatan dari prefs: $tagPendapatanStr");
    print("Tag Pengeluaran dari prefs: $tagPengeluaranStr");

    if (tagPendapatanStr != null && tagPengeluaranStr != null) {
      List<int> idPendapatan = tagPendapatanStr.split(',').map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();
      List<int> idPengeluaran = tagPengeluaranStr.split(',').map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();

      await databaseHelper.initDatabase();

      // Gunakan TagTransaksiService untuk ambil data
      tagPendapatan = await TagTransaksiService().getTagTransaksiByIds(idPendapatan);
      tagPengeluaran = await TagTransaksiService().getTagTransaksiByIds(idPengeluaran);

      // Inisialisasi controller untuk setiap tag
      for (var tag in [...tagPendapatan, ...tagPengeluaran]) {
        _controllers[tag.id] = TextEditingController();
      }

      setState(() {});
    }
  }

  Future<void> _loadLastRekapTransaksi() async {
    await databaseHelper.initDatabase();
    await _getUserData();

    Map<String, int> rit = await databaseHelper.getSumJumlahTagihanReguler(kelasBus);
    print('rit $kelasBus , $rit');
    Map<String, int> totalPendapatanReguler = await databaseHelper.getSumJumlahTagihanReguler(kelasBus);
    Map<String, int> jumlahTiketReguler = await databaseHelper.getSumJumlahTagihanReguler(kelasBus);

    Map<String, int> totalPendapatanNonReguler = await databaseHelper.getSumJumlahTagihanNonReguler(kelasBus);
    Map<String, int> jumlahTiketOnLine = await databaseHelper.getSumJumlahTagihanNonReguler(kelasBus);

    Map<String, int> totalPendapatanBagasi = await databaseHelper.getSumJumlahPendapatanBagasi(kelasBus);
    Map<String, int> jumlahBarangBagasi = await databaseHelper.getSumJumlahPendapatanBagasi(kelasBus);

    setState(() {
      ritke = rit['rit'].toString();
      pendapatanTiketReguler = totalPendapatanReguler['totalPendapatanReguler'].toString();
      nilaiTiketReguler = jumlahTiketReguler['jumlahTiketReguler'].toString();
      pendapatanTiketOnline = totalPendapatanNonReguler['totalPendapatanNonReguler'].toString();
      nilaiTiketOnLine = jumlahTiketOnLine['jumlahTiketOnLine'].toString();
      pendapatanBagasi = totalPendapatanBagasi['totalPendapatanBagasi'].toString();
      banyakBarangBagasi = jumlahBarangBagasi['jumlahBarangBagasi'].toString();
    });

    ritController.text = ritke;

    String formattedPendapatanTiketReguler = formatter.format(totalPendapatanReguler['totalPendapatanReguler']);
    pendapatanTiketRegulerController.text = formattedPendapatanTiketReguler;
    jumlahTiketRegulerController.text = nilaiTiketReguler;

    String formattedPendapatanTiketOnLine = formatter.format(totalPendapatanNonReguler['totalPendapatanNonReguler']);
    pendapatanTiketNonRegulerController.text = formattedPendapatanTiketOnLine;
    jumlahTiketOnLineController.text = nilaiTiketOnLine;

    String formattedPendapatanBagasi = formatter.format(totalPendapatanBagasi['totalPendapatanBagasi']);
    pendapatanBagasiController.text = formattedPendapatanBagasi;
    jumlahBarangBagasiController.text = banyakBarangBagasi;

    await databaseHelper.closeDatabase();
    print('cetak pendapatan tiket reguler $pendapatanTiketReguler $nilaiTiketReguler');
    print('cetak pendapatan tiket non reguler $pendapatanTiketOnline $nilaiTiketOnLine');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 20,
        ),
        child: Column(
          children: [
            SizedBox(height: 40.0),
            Text('Pencatatan Pendapatan & Pengeluaran'),
            SizedBox(height: 16.0),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    SizedBox(height: 16.0),

                    // KM Pulang (tetap statis)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: kmMasukGarasiController,
                            decoration: InputDecoration(
                              labelText: 'KM Pulang',
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                              prefixText: ' ',
                              prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                            ),
                            textAlign: TextAlign.right,
                            keyboardType: TextInputType.number,
                            enabled: true,
                            style: TextStyle(fontSize: 18),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'KM Masuk Garasi harus diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),

                    // FORM PENDAPATAN DINAMIS
                    if (tagPendapatan.isNotEmpty) ...[
                      SizedBox(height: 16.0),
                      Text(
                        'Pendapatan Lainnya',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      ...tagPendapatan.map((tag) => _buildDynamicField(tag)).toList(),
                    ],

                    // FORM PENGELUARAN DINAMIS
                    if (tagPengeluaran.isNotEmpty) ...[
                      SizedBox(height: 16.0),
                      Text(
                        'Pengeluaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      ...tagPengeluaran.map((tag) => _buildDynamicField(tag)).toList(),
                    ],

                    // Tombol Simpan
                    SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              List<Map<String, dynamic>> penjualanData =
                              await databaseHelper.getPenjualanByStatus('N');

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
                                _simpanValueRekap();
                              }
                            },
                            child: Text('Simpan'),
                            style: ButtonStyle(
                              minimumSize: WidgetStateProperty.all(Size(double.infinity, 48.0)),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.0),
                      ],
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

  Widget _buildDynamicField(TagTransaksi tag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers[tag.id],
        decoration: InputDecoration(
          labelText: tag.nama ?? 'Field ${tag.id}',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
          prefixText: _isPengeluaran(tag) ? 'Rp ' : 'Rp ',
          prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
        ),
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 18),
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
        validator: (value) {
          if (value!.isEmpty) {
            return '${tag.nama} harus diisi';
          }
          return null;
        },
      ),
    );
  }

  bool _isPengeluaran(TagTransaksi tag) {
    return tagPengeluaran.any((pengeluaran) => pengeluaran.id == tag.id);
  }

  Future<void> _simpanValueRekap() async {

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