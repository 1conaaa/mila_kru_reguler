import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kru_reguler/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

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

  @override
  void initState() {
    super.initState();
    databaseHelper = DatabaseHelper();
    _loadLastRekapTransaksi();
    bagasiController = TextEditingController();
    kmMasukGarasiController = TextEditingController();
    tolController = TextEditingController();
    tprController = TextEditingController();
    perpalController = TextEditingController();
    litersolarController = TextEditingController();
    nominalsolarController = TextEditingController();
    perbaikanController = TextEditingController();
    keteranganPerbaikanController = TextEditingController();
    nominalperbaikanController = TextEditingController();

    nominalPremiExtraController = TextEditingController();
    nominalPremiKruController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    String selectedKategoriTiket = 'reguler';
    return SafeArea( // ✅ Lindungi konten dari area status & navbar
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
                  key: _formKey, // Add form key
                  child: Column(
                    children: [
                      SizedBox(height: 16.0),
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
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: jumlahTiketRegulerController,
                                  decoration: InputDecoration(
                                    labelText: 'Tiket Reguler',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                    prefixText: ' ',
                                    prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                                  ),
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  enabled: false,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              SizedBox(width: 16.0),
                              Expanded(
                                child: TextFormField(
                                  controller: pendapatanTiketRegulerController,
                                  decoration: InputDecoration(
                                    labelText: 'Pendapatan Tiket Reguler',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                    prefixText: 'Rp ',
                                    prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                                  ),
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  enabled: false,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: jumlahTiketOnLineController,
                                  decoration: InputDecoration(
                                    labelText: 'Tiket On Line',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                    prefixText: ' ',
                                    prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                                  ),
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  enabled: false,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              SizedBox(width: 16.0),  // Perbaikan jarak horizontal
                              Expanded(
                                child: TextFormField(
                                  controller: pendapatanTiketNonRegulerController,
                                  decoration: InputDecoration(
                                    labelText: 'Pendapatan Tiket Online',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                    prefixText: 'Rp ',
                                    prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                                  ),
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  enabled: false,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: jumlahBarangBagasiController,
                                  decoration: InputDecoration(
                                    labelText: 'Jml.Barang Bagasi',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                    prefixText: ' ',
                                    prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                                  ),
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  enabled: false,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                              SizedBox(width: 16.0),  // Konsistensi jarak horizontal
                              Expanded(
                                child: TextFormField(
                                  controller: pendapatanBagasiController,
                                  decoration: InputDecoration(
                                    labelText: 'Pendapatan Bagasi',
                                    border: OutlineInputBorder(),
                                    alignLabelWithHint: true,
                                    prefixText: 'Rp ',
                                    prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                                  ),
                                  textAlign: TextAlign.right,
                                  keyboardType: TextInputType.number,
                                  enabled: false,
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                        ],
                      ),

                      TextFormField(
                        controller: tolController,
                        decoration: InputDecoration(
                          labelText: 'Pengeluaran TOL',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                              textBaseline: TextBaseline.alphabetic),
                        ),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 18),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          setState(() {
                            pengeluaranTol = value;
                          });
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Pengeluaran Tol harus diisi';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: tprController,
                        decoration: InputDecoration(
                          labelText: 'Pengeluaran Operasional Harian',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                              textBaseline: TextBaseline.alphabetic),
                        ),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 18),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          setState(() {
                            pengeluaranTpr = value;
                          });
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Pengeluaran Operasional harus diisi';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: perpalController,
                        decoration: InputDecoration(
                          labelText: 'Pengeluaran Perpal',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                              textBaseline: TextBaseline.alphabetic),
                        ),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 18),
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: (value) {
                          setState(() {
                            pengeluaranPerpal = value;
                          });
                        },
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Pengeluaran Perpal harus diisi';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: litersolarController,
                              decoration: InputDecoration(
                                labelText: 'Jumlah Liter Solar',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                                prefixText: ' ',
                                prefixStyle: TextStyle(
                                    textBaseline: TextBaseline.alphabetic),
                              ),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 18),
                              keyboardType: TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                              ],
                              onChanged: (value) {},
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Jumlah Liter Solar harus diisi';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16.0),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: nominalsolarController,
                              decoration: InputDecoration(
                                labelText: 'Nominal Solar',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                                prefixText: 'Rp ',
                                prefixStyle: TextStyle(
                                    textBaseline: TextBaseline.alphabetic),
                              ),
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 18),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  jumlahTagihan = int.tryParse(value) ?? 0;
                                });
                              },
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Jumlah Nominal Solar harus diisi';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: perbaikanController,
                        decoration: InputDecoration(
                          labelText: 'Pengeluaran Perbaikan',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                              textBaseline: TextBaseline.alphabetic),
                        ),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 18),
                        // Align the input text to the right
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _calculatePremiBersih(
                              pendapatanTiketRegulerController,pendapatanTiketNonRegulerController,pendapatanBagasiController,tolController,tprController,perpalController,litersolarController,nominalsolarController,perbaikanController,premiExtraController,persenPremikruController);
                        },
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Pengeluaran Perbaikan harus diisi';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextField(
                        controller: keteranganPerbaikanController,
                        decoration: InputDecoration(
                          labelText: 'Keterangan Perbaikan',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(fontSize: 18),
                        maxLines: 3, // Atau atur jumlah baris yang diinginkan
                        onChanged: (value) {
                          setState(() {
                          });
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: nominalPremiExtraController,
                        decoration: InputDecoration(
                          labelText: 'Premi Extra $premiExtra',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                              textBaseline: TextBaseline.alphabetic),
                        ),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 18),
                        keyboardType: TextInputType.text,
                        enabled: false,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: nominalPremiKruController,
                        decoration: InputDecoration(
                          labelText: 'Premi Disetor $persenPremikru',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                              textBaseline: TextBaseline.alphabetic),
                        ),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 18),
                        keyboardType: TextInputType.text,
                        enabled: false,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: nominalPendapatanBersihController,
                        decoration: InputDecoration(
                          labelText: 'Pendapatan Bersih',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                              textBaseline: TextBaseline.alphabetic),
                        ),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 18),
                        // Align the input text to the right
                        keyboardType: TextInputType.text,
                        enabled: false,
                        // Set enabled to false
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 16.0),
                      TextFormField(
                        controller: nominalPendapatanDisetorController,
                        decoration: InputDecoration(
                          labelText: 'Pendapatan Disetor',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                          prefixText: 'Rp ',
                          prefixStyle: TextStyle(
                              textBaseline: TextBaseline.alphabetic),
                        ),
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 18),
                        keyboardType: TextInputType.text,
                        enabled: false,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) _simpanValueRekap();
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
    print('Bagasi 0: $pendapatanTiketRegulerController');
    print('Bagasi 0: $pendapatanTiketNonRegulerController');
    print('Bagasi 0: $pendapatanBagasiController');
    // Dapatkan nilai dari controller menggunakan `.text`
    double kmMasukGarasi = double.tryParse(kmMasukGarasiController.text) ?? 0.0;
    String pendapatanTiketReguler = pendapatanTiketRegulerController.text.replaceAll('.', '').replaceAll(',00', '');
    String pendapatanTiketOnline = pendapatanTiketNonRegulerController.text.replaceAll('.', '').replaceAll(',00', '');
    String pendapatanBagasiNew = pendapatanBagasiController.text.replaceAll('.', '').replaceAll(',00', '');
    double nominalTiketReguler = double.tryParse(pendapatanTiketReguler) ?? 0.0;
    print('Bagasi 1: $nominalTiketReguler');
    double nominalTiketOnLine = double.tryParse(pendapatanTiketOnline) ?? 0.0;
    print('Bagasi 1: $nominalTiketOnLine');
    double pendapatanBagasi = double.tryParse(pendapatanBagasiNew) ?? 0.0;
    print('Bagasi 1: $pendapatanBagasi');

    double pengeluaranTol = double.tryParse(tolController.text) ?? 0.0;
    double pengeluaranTpr = double.tryParse(tprController.text) ?? 0.0;
    double pengeluaranPerpal = double.tryParse(perpalController.text) ?? 0.0;
    double litersolar = double.tryParse(litersolarController.text) ?? 0.0;
    double nominalsolar = double.tryParse(nominalsolarController.text) ?? 0.0;
    double perbaikan = double.tryParse(perbaikanController.text) ?? 0.0;

    var pend_keseluruhan = nominalTiketReguler + nominalTiketOnLine + pendapatanBagasi;

    var peng_oprs = pengeluaranPerpal + pengeluaranTpr + pengeluaranTol + nominalsolar;
    var peng_lain = peng_oprs + perbaikan;

    String premiExtra = premiExtraController.text.replaceAll('%', '');
    double persenPremiExtra = (double.tryParse(premiExtra) ?? 0.0)/100;
    print('Value 1: $persenPremiExtra');

    String premiKru = persenPremikruController.text.replaceAll('%', '');
    double persenPremiKru = ((double.tryParse(premiKru) ?? 0.0)-(double.tryParse(premiExtra) ?? 0.0))/100;
    print('Value 1: $persenPremiKru');

    print("nama trayek $namaTrayek");

    switch (kelasBus) {
      case 'Ekonomi':
        switch (jenisTrayek){
          case 'AKDP':
            switch (namaTrayek){
              case 'JEMBER - KALIANGET':
                var nominalPremiExtra = (nominalTiketReguler-(peng_oprs-pengeluaranTol))*(persenPremiExtra);
                if (nominalPremiExtra<=0) {
                  nominalPremiExtra = 0;
                }else{
                  nominalPremiExtra = nominalPremiExtra;
                }
                var nominalPremiKru = (nominalTiketReguler-(peng_oprs-pengeluaranTol))*(persenPremiKru);
                if (nominalPremiKru<=0) {
                  nominalPremiKru = 0;
                }else{
                  nominalPremiKru = nominalPremiKru;
                }
                var pend_bersih = pend_keseluruhan-(peng_lain+nominalPremiExtra+nominalPremiKru);
                var pend_disetor = pend_bersih+nominalsolar+nominalPremiKru;
                if (pend_bersih<=0) {
                  pend_bersih = 0;
                  pend_disetor = 0;
                }else{
                  pend_bersih = pend_bersih;
                  pend_disetor = pend_disetor;
                }

                nominalPremiExtraController.text = formatter.format(nominalPremiExtra);
                nominalPremiKruController.text = formatter.format(nominalPremiKru);
                nominalPendapatanBersihController.text = formatter.format(pend_bersih);
                nominalPendapatanDisetorController.text = formatter.format(pend_disetor);
                debugPrint('AKDP Ekonomi $namaTrayek Premi Bersih: $nominalPremiExtra  $nominalPremiKru $pend_bersih $pend_disetor');
                break;
              case 'AMBULU - PONOROGO':
                var nominalPremiExtra = (nominalTiketReguler-(peng_oprs))*(persenPremiExtra);
                if (nominalPremiExtra<=0) {
                  nominalPremiExtra = 0;
                }else{
                  nominalPremiExtra = nominalPremiExtra;
                }
                var nominalPremiKru = (nominalTiketReguler-(peng_oprs))*(persenPremiKru);
                if (nominalPremiKru<=0) {
                  nominalPremiKru = 0;
                }else{
                  nominalPremiKru = nominalPremiKru;
                }
                var pend_bersih = pend_keseluruhan-(peng_lain+nominalPremiExtra+nominalPremiKru);
                var pend_disetor = pend_bersih+nominalsolar+nominalPremiKru;
                if (pend_bersih<=0) {
                  pend_bersih = 0;
                  pend_disetor = 0;
                }else{
                  pend_bersih = pend_bersih;
                  pend_disetor = pend_disetor;
                }
                nominalPremiExtraController.text = formatter.format(nominalPremiExtra);
                nominalPremiKruController.text = formatter.format(nominalPremiKru);
                nominalPendapatanBersihController.text = formatter.format(pend_bersih);
                nominalPendapatanDisetorController.text = formatter.format(pend_disetor);
                debugPrint('AKDP Ekonomi $namaTrayek Premi Bersih: $nominalPremiExtra  $nominalPremiKru $pend_bersih $pend_disetor');
                break;
            }
            break;
          case 'AKAP':
            switch (namaTrayek){
              case 'YOGYAKARTA - BANYUWANGI':
                var nominalPremiExtra = ((nominalTiketReguler + nominalTiketOnLine) - (peng_oprs - pengeluaranTol)) * (persenPremiExtra);
                if (nominalPremiExtra<=0) {
                  nominalPremiExtra = 0;
                }else{
                  nominalPremiExtra = nominalPremiExtra;
                }
                var nominalPremiKru = ((nominalTiketReguler + nominalTiketOnLine) - (peng_oprs - pengeluaranTol)) * (persenPremiKru);
                // var nominalPremiKru = 0;
                if (nominalPremiKru<=0) {
                  nominalPremiKru = 0;
                }else{
                  nominalPremiKru = nominalPremiKru;
                }

                var pend_bersih = (pend_keseluruhan)-((peng_lain-pengeluaranTol)+nominalPremiExtra);
                debugPrint('AKAP Ekonomi $namaTrayek Pend.Bersih: $pend_bersih  $pend_keseluruhan $peng_lain $pengeluaranTol $nominalPremiExtra');
                var pend_disetor = (pend_bersih+nominalsolar+nominalPremiKru)-(nominalTiketOnLine);
                debugPrint('AKAP Ekonomi $namaTrayek Pend.Disetor: $pend_disetor $pend_bersih  $nominalsolar $nominalPremiKru $nominalTiketOnLine');
                if (pend_bersih<=0) {
                  pend_bersih = 0;
                  pend_disetor = 0;
                }else{
                  if(pend_bersih < 2500000){
                    pengeluaranTol = 140000;
                  }else if(pend_bersih > 2500000){
                    pengeluaranTol = 270000;
                  }
                  pend_bersih = pend_bersih;
                  pend_disetor = pend_disetor;
                }
                nominalPremiExtraController.text = formatter.format(pengeluaranTol);
                nominalPremiExtraController.text = formatter.format(nominalPremiExtra);
                nominalPremiKruController.text = formatter.format(nominalPremiKru);
                nominalPendapatanBersihController.text = formatter.format(pend_bersih);
                nominalPendapatanDisetorController.text = formatter.format(pend_disetor);
                debugPrint('AKAP Ekonomi $namaTrayek Premi Bersih: $nominalPremiExtra  $nominalPremiKru $pend_bersih $pend_disetor');
                break;
            }
            break;
        }
        break;
      case 'Non Ekonomi':
        switch (jenisTrayek){
          case 'AKDP':
            switch (namaTrayek){
              case 'CADANGAN':
              case 'CADANGAN NON EKONOMI':
              case 'JEMBER - SURABAYA':
              case 'SURABAYA - JEMBER':
                var nominalPremiExtra = ((nominalTiketReguler+nominalTiketOnLine)-peng_oprs)*(persenPremiExtra);
                if (nominalPremiExtra<=0) {
                  nominalPremiExtra = 0;
                }else{
                  nominalPremiExtra = nominalPremiExtra;
                }
                var nominalPremiKru = ((nominalTiketReguler+nominalTiketOnLine)-peng_oprs)*(persenPremiKru);
                if (nominalPremiKru<=0) {
                  nominalPremiKru = 0;
                }else{
                  nominalPremiKru = nominalPremiKru;
                }
                var nominalsolar = 0;
                var pend_bersih = (pend_keseluruhan-peng_lain)-(nominalPremiExtra+nominalPremiKru);
                var pend_disetor = (pend_bersih+nominalsolar+nominalPremiKru)-nominalTiketOnLine;
                if (pend_bersih<=0) {
                  pend_bersih = 0;
                  pend_disetor = 0;
                }else{
                  pend_bersih = pend_bersih;
                  pend_disetor = pend_disetor;
                }
                nominalPremiExtraController.text = formatter.format(nominalPremiExtra);
                nominalPremiKruController.text = formatter.format(nominalPremiKru);
                nominalPendapatanBersihController.text = formatter.format(pend_bersih);
                nominalPendapatanDisetorController.text = formatter.format(pend_disetor);
                debugPrint('AKDP Non Ekonomi $namaTrayek Premi Bersih: $nominalPremiExtra  $nominalPremiKru $pend_bersih $pend_disetor');
                break;
            }
            break;
          case 'AKAP':
            break;
        }
        break;
    }

  }

  Future<void> _simpanValueRekap() async {
    final String kmMasukGarasi = kmMasukGarasiController.text;
    final String rit = ritController.text;
    final String jumlahTiketReguler = jumlahTiketRegulerController.text;
    final String jumlahTiketOnLine = jumlahTiketOnLineController.text;
    final String pendapatanTiketReguler = pendapatanTiketRegulerController.text;
    final String pendapatanTiketNonReguler = pendapatanTiketNonRegulerController.text;
    final String bagasi = pendapatanBagasiController.text;
    final String tol = tolController.text;
    final String tpr = tprController.text;
    final String perpal = perpalController.text;
    final String literSolar = litersolarController.text;
    final String nominalSolar = nominalsolarController.text;
    final String perbaikan = perbaikanController.text;
    final String keteranganPerbaikan = keteranganPerbaikanController.text;
    final String premiExtra = nominalPremiExtraController.text;
    final String premiKru = nominalPremiKruController.text;
    final String pendapatanBersih = nominalPendapatanBersihController.text;
    final String pendapatanDisetor = nominalPendapatanDisetorController.text;

    // Nilai bagasi yang diberikan
    // String bagasi = "18.000,00";

// Bersihkan format bagasi dari pemisah ribuan dan ubah koma menjadi titik
    String cleanbagasi = bagasi.replaceAll('.', '').replaceAll(',', '.');

// Parsing nilai bagasi menjadi double
    double bagasiParse = double.tryParse(cleanbagasi) ?? 0.0;

// Hitung bagian perusahaan (60%) dan kru (40%)
//     double bagasiPerusahaan = bagasiParse * (60 / 100);
//     double bagasiKru = bagasiParse * (40 / 100);

    double bagasiPerusahaan = bagasiParse;
    double bagasiKru = bagasiParse;

// Output hasil
    print("Total Bagasi: $bagasiParse");
    print("Bagasi Perusahaan (60%): $bagasiPerusahaan");
    print("Bagasi Kru (40%): $bagasiKru");


    int totalTiket = int.parse(jumlahTiketReguler) + int.parse(jumlahTiketOnLine);
    print('Total Tiket: $totalTiket');

    DateTime now = DateTime.now(); // Mendapatkan tanggal sekarang
    String formattedDate = DateFormat('yyyy-MM-dd').format(now); // Format tanggal sesuai kebutuhan (contoh: "2023-06-06")

    Database database = await databaseHelper.database;
    bool tableExists = await isTableExists(database, 'resume_transaksi');
    if (tableExists) {
      print("Tabel resume_transaksi ada dalam database");
    } else {
      print("Tabel resume_transaksi tidak ditemukan dalam database");
      await database.execute('''
    CREATE TABLE IF NOT EXISTS resume_transaksi (id INTEGER PRIMARY KEY,no_pol TEXT,id_bus INTEGER,id_user INTEGER,id_group INTEGER,id_garasi INTEGER,id_company INTEGER,jumlah_tiket INTEGER,km_masuk_garasi REAL,kode_trayek TEXT,pendapatan_reguler REAL,pendapatan_online REAL,pendapatan_bagasi_perusahaan REAL,pendapatan_bagasi_kru REAL,biaya_perbaikan REAL,keterangan_perbaikan TEXT,biaya_tol REAL,biaya_tpr REAL,biaya_solar REAL,liter_solar REAL,biaya_perpal REAL,biaya_premi_extra REAL,biaya_premi_disetor REAL,pendapatan_bersih REAL,pendapatan_disetor REAL,tanggal_transaksi TEXT,status TEXT,UNIQUE (no_pol, id_bus, id_user, id_group, id_garasi, id_company, tanggal_transaksi))
  ''');
      print("Tabel resume_transaksi berhasil dibuat");
    }

    List<Map<String, Object?>> existingData = await database.rawQuery('''
  SELECT * FROM resume_transaksi
  WHERE no_pol = ? AND id_bus = ? AND id_user = ? AND id_group = ? AND id_garasi = ? AND id_company = ? AND tanggal_transaksi = ?
''', [noPol, idBus, idUser, idGroup, idGarasi, idCompany, formattedDate]);

    if (existingData.isNotEmpty) {
      int existingDataId = existingData[0]['id'] as int;
      await database.update(
        'resume_transaksi',
        {
          'jumlah_tiket': totalTiket,'km_masuk_garasi': kmMasukGarasi,'kode_trayek': namaTrayek,'pendapatan_reguler': pendapatanTiketReguler,'pendapatan_online': pendapatanTiketNonReguler,'pendapatan_bagasi_perusahaan': bagasiPerusahaan,'pendapatan_bagasi_kru': bagasiKru,'biaya_perbaikan': perbaikan,'keterangan_perbaikan':keteranganPerbaikan,'biaya_tol': tol,'biaya_tpr': tpr,'biaya_solar': nominalSolar,'liter_solar': literSolar,'biaya_perpal': perpal,'biaya_premi_extra': premiExtra,'biaya_premi_disetor': premiKru,'pendapatan_bersih': pendapatanBersih,'pendapatan_disetor': pendapatanDisetor,'status': 'N',
        },
        where: 'id = ?',
        whereArgs: [existingDataId],
      );
      print('Data resume pendapatan dan pengeluaran berhasil diperbarui:');
      // print('ID: $existingDataId');
    } else {
      // Data does not exist, perform an insert
      await database.insert(
        'resume_transaksi',
        {
          'no_pol': noPol,'id_bus': idBus,'id_user': idUser,'id_group': idGroup,'id_garasi': idGarasi,'id_company': idCompany,'jumlah_tiket': totalTiket,'km_masuk_garasi': kmMasukGarasi,
          'kode_trayek': namaTrayek,'pendapatan_reguler': pendapatanTiketReguler,'pendapatan_online':pendapatanTiketNonReguler,'pendapatan_bagasi_perusahaan': bagasiPerusahaan,'pendapatan_bagasi_kru': bagasiKru,'biaya_perbaikan': perbaikan,'keterangan_perbaikan': keteranganPerbaikan,'biaya_tol': tol,'biaya_tpr': tpr,'biaya_solar':nominalSolar,'liter_solar': literSolar,'biaya_perpal': perpal,'biaya_premi_extra': premiExtra,'biaya_premi_disetor': premiKru,'pendapatan_bersih': pendapatanBersih,'pendapatan_disetor':pendapatanDisetor,'tanggal_transaksi': formattedDate,'status': 'N',
        },
      );
      print('Data resume pendapatan dan pengeluaran berhasil disimpan:');
    }

    printTableContents(database, 'resume_transaksi');
    int existingDataId = existingData[0]['id'] as int;
    print('ID: $existingDataId');
    List<Map<String, dynamic>> masterPremiKru = await databaseHelper.getMasterPremiKru();

// Cetak data dari query
    print('Data Master Premi Kru:');
    int rowCount = masterPremiKru.length;
    print('Jumlah baris data master Premi Kru: $rowCount');
    await databaseHelper.clearPremiHarianKru();
    for (var row in masterPremiKru) {
      int id_group = row['id_group'];
      int id_personil = row['id_personil'];
      String nama_lengkap = row['nama_lengkap'];
      String group_name = row['group_name'];
      String persen_premi = row['persen_premi'];
      String pisahPersenKru = persen_premi.replaceAll('%', '');
      double persenPerKru = (double.tryParse(pisahPersenKru) ?? 0.0)/100;

      String premiExtra = premiExtraController.text.replaceAll('%', '');
      double persenPremiExtra = (double.tryParse(premiExtra) ?? 0.0)/100;
      // print('Premi Persen Extra 1: $persenPremiExtra');

      String persenPremiKru = persenPremikruController.text.replaceAll('%', '');
      double sisaPersenPremiKru = ((double.tryParse(persenPremiKru) ?? 0.0)-(double.tryParse(premiExtra) ?? 0.0))/100;
      // print('Premi Persen Disetor 2: $sisaPersenPremiKru , $persenPremiKru , $premiExtra');

      String valueString = premiKru;
      // Hapus karakter non-digit (koma dan titik)
      String cleanValueString = valueString.replaceAll(RegExp('[^0-9]'), '');
      // Ubah string menjadi double
      double valueDouble = double.parse(cleanValueString) / 100;
      // print('Nilai double: $valueDouble');
      double nominalPremiPerKru = (persenPerKru/sisaPersenPremiKru)*valueDouble;
      print('Field 2: $id_group , $id_personil , $nama_lengkap , $group_name , $persenPerKru , $nominalPremiPerKru');
      await database.insert(
        'premi_harian_kru',
        {
          'id_transaksi': 1,
          'id_user': id_personil,
          'id_group': id_group,
          'persen_premi_disetor': persenPerKru,
          'nominal_premi_disetor': nominalPremiPerKru,
          'tanggal_simpan': formattedDate,
          'status': 'N',
        },
      );
    }

    printTableContents(database, 'premi_harian_kru');
    await databaseHelper.closeDatabase();
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

  void _kirimValueRekap() {}

}