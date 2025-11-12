import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';

class PremiKru extends StatefulWidget {
  @override
  _PremiKruState createState() => _PremiKruState();
}

class _PremiKruState extends State<PremiKru> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> listPremiHarianKru = [];
  List<Map<String, dynamic>> listResumeTransaksi = [];
  late Future<List<Map<String, dynamic>>> resumeTransaksi; // Initialize as late
  bool _isPushingData = false;
  double _pushDataProgress = 0.0;
  double _uploadProgress = 0.0;

  NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp');

  get id_bus => null;

  get id_transaksi => null;

  get idTransaksiGenerated => null;

  @override
  void initState() {
    super.initState();
    resumeTransaksi = databaseHelper.queryResumeTransaksi(); // Initialize the variable here
    _getListPremiKru();
    _getResumeTransaksi();
    _loadLastPremiKru();
  }

  void _updateUploadProgress(double progress) {
    setState(() {
      _uploadProgress = progress;
    });
  }

  Future<void> _loadLastPremiKru() async {
    await databaseHelper.initDatabase();
    await _getListPremiKru();
    await databaseHelper.closeDatabase();
  }

  Future<void> _getListPremiKru() async {
    List<Map<String, dynamic>> premiKruData = await databaseHelper.getPremiHarianKru();
    setState(() {
      listPremiHarianKru = premiKruData;
    });
    if (listPremiHarianKru.isEmpty) {
      print('Tidak ada data dalam tabel Premi Harian Kru.');
    } else {
      print('Data ditemukan dalam tabel Premi Harian Kru.');
    }
  }

  void _getResumeTransaksi() async {
    List<Map<String, dynamic>> resumeData = await databaseHelper.queryResumeTransaksi();
    setState(() {
      listResumeTransaksi = resumeData;
    });
    // print('cek resume : $resumeData');
    if (listResumeTransaksi.isEmpty) {
      print('Tidak ada data dalam tabel resume_transaksi.');
    } else {
      print('Data ditemukan dalam tabel resume_transaksi.');
    }

    if (listResumeTransaksi.isNotEmpty) {
      List<String> keys = [];

      for (var item in listResumeTransaksi) {
        item.forEach((key, value) {
          keys.add(key);
          // print('$key: $value');
        });
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('id_resume', item['id']);
        await prefs.setInt('id_user_login', item['id_user']);
        print('id user ${item['id_user']}');
        await prefs.setInt('id_bus', item['id_bus']);
        await prefs.setString('no_pol', item['no_pol']);
        await prefs.setInt('id_group', item['id_group']);
        await prefs.setInt('id_garasi', item['id_garasi']);
        await prefs.setInt('id_company', item['id_company']);
        // await prefs.setString('kode_trayek', item['kode_trayek']);
        await prefs.setInt('jumlah_tiket', item['jumlah_tiket']);
        await prefs.setDouble('km_masuk_garasi', item['km_masuk_garasi']);

        String pendapatanRegulerFormatted = listResumeTransaksi[0]['pendapatan_reguler'].replaceAll('.', '');
        pendapatanRegulerFormatted = pendapatanRegulerFormatted.replaceAll(',', '.');
        double pendapatan_reguler = double.parse(pendapatanRegulerFormatted);
        await prefs.setDouble('pendapatan_reguler', pendapatan_reguler);

        String pendapatanOnlineFormatted = listResumeTransaksi[0]['pendapatan_online'].replaceAll('.', '');
        pendapatanOnlineFormatted = pendapatanOnlineFormatted.replaceAll(',', '.');
        double pendapatan_online = double.parse(pendapatanOnlineFormatted);
        await prefs.setDouble('pendapatan_online', pendapatan_online);

        await prefs.setDouble('pendapatan_bagasi_perusahaan', item['pendapatan_bagasi_perusahaan']);
        await prefs.setDouble('pendapatan_bagasi_kru', item['pendapatan_bagasi_kru']);
        await prefs.setDouble('biaya_perbaikan', item['biaya_perbaikan']);
        await prefs.setString('keterangan_perbaikan', item['keterangan_perbaikan']);
        await prefs.setDouble('biaya_tol', item['biaya_tol']);
        await prefs.setDouble('biaya_tpr', item['biaya_tpr']);
        await prefs.setDouble('liter_solar', item['liter_solar']);
        await prefs.setDouble('biaya_solar', item['biaya_solar']);
        await prefs.setDouble('biaya_perpal', item['biaya_perpal']);

        String biaya_premi_extraFormatted = listResumeTransaksi[0]['biaya_premi_extra'].replaceAll('.', '');
        biaya_premi_extraFormatted = biaya_premi_extraFormatted.replaceAll(',', '.');
        double biaya_premi_extra = double.parse(biaya_premi_extraFormatted);
        await prefs.setDouble('biaya_premi_extra', biaya_premi_extra);

        String biaya_premi_disetorFormatted = listResumeTransaksi[0]['biaya_premi_disetor'].replaceAll('.', '');
        biaya_premi_disetorFormatted = biaya_premi_disetorFormatted.replaceAll(',', '.');
        double biaya_premi_disetor = double.parse(biaya_premi_disetorFormatted);
        await prefs.setDouble('biaya_premi_disetor', biaya_premi_disetor);

        String pendapatan_bersihFormatted = listResumeTransaksi[0]['pendapatan_bersih'].replaceAll('.', '');
        pendapatan_bersihFormatted = pendapatan_bersihFormatted.replaceAll(',', '.');
        double pendapatan_bersih = double.parse(pendapatan_bersihFormatted);
        await prefs.setDouble('pendapatan_bersih', pendapatan_bersih);

        String pendapatan_disetorFormatted = listResumeTransaksi[0]['pendapatan_disetor'].replaceAll('.', '');
        pendapatan_disetorFormatted = pendapatan_disetorFormatted.replaceAll(',', '.');
        double pendapatan_disetor = double.parse(pendapatan_disetorFormatted);
        await prefs.setDouble('pendapatan_disetor', pendapatan_disetor);

        await prefs.setString('tanggal_transaksi', item['tanggal_transaksi']);

      }

    }

  }

  void _pushDataPremiHarianKru() async {

    if (_selectedDate != null) {
      // Mulai proses pengiriman data
      // Mulai proses pengiriman data
      String tanggal_transaksi = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      print("Data dikirim untuk tanggal: $tanggal_transaksi");

      setState(() {
        _isPushingData = true;
        _uploadProgress = 0.0;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      await databaseHelper.initDatabase();
      int id_user_login = await prefs.getInt('id_user_login') ?? 0;
      print('id_user_login $id_user_login');
      int id_group = await prefs.getInt('id_group') ?? 0;
      int id_bus = await prefs.getInt('id_bus') ?? 0;
      String no_pol = await prefs.getString('no_pol') ?? '';
      int id_garasi = await prefs.getInt('id_garasi') ?? 0;
      int id_company = await prefs.getInt('id_company') ?? 0;
      // String kode_trayek = await prefs.getString('kode_trayek') ?? '';
      int jumlah_tiket = await prefs.getInt('jumlah_tiket') ?? 0;
      double km_masuk_garasi = await prefs.getDouble('km_masuk_garasi') ?? 0;
      double pendapatan_reguler = await prefs.getDouble('pendapatan_reguler') ?? 0;
      double pendapatan_online = await prefs.getDouble('pendapatan_online') ?? 0;
      double pendapatan_bagasi_perusahaan = await prefs.getDouble('pendapatan_bagasi_perusahaan') ?? 0;
      double pendapatan_bagasi_kru = await prefs.getDouble('pendapatan_bagasi_kru') ?? 0;
      double biaya_perbaikan = await prefs.getDouble('biaya_perbaikan') ?? 0;
      String keterangan_perbaikan = await prefs.getString('keterangan_perbaikan') ?? '';
      double biaya_tol = await prefs.getDouble('biaya_tol') ?? 0;
      double biaya_tpr = await prefs.getDouble('biaya_tpr') ?? 0;
      double liter_solar = await prefs.getDouble('liter_solar') ?? 0;
      double biaya_solar = await prefs.getDouble('biaya_solar') ?? 0;
      double biaya_perpal = await prefs.getDouble('biaya_perpal') ?? 0;
      double biaya_premi_extra = await prefs.getDouble('biaya_premi_extra') ?? 0;
      double biaya_premi_disetor = await prefs.getDouble('biaya_premi_disetor') ?? 0;
      double pendapatan_bersih = await prefs.getDouble('pendapatan_bersih') ?? 0;
      double pendapatan_disetor = await prefs.getDouble('pendapatan_disetor') ?? 0;
      // String tanggal_transaksi = await prefs.getString('tanggal_transaksi') ?? '';


      print('object : $pendapatan_reguler ,  $_selectedDate');
      try {
        // Mendapatkan id_transaksi terakhir dari table t_transaksi_detail
        String apiUrlLastId = 'https://apimila.sysconix.id/api/lastidtransaksi';
        String queryParamsLastId = '?kode_transaksi=KEUBIS';

        String apiUrlWithParamsqueryParamsLastId = apiUrlLastId + queryParamsLastId;
        final responseLastId = await http.get(
          Uri.parse(apiUrlWithParamsqueryParamsLastId),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        print("object $apiUrlWithParamsqueryParamsLastId");
        if (responseLastId.statusCode == 200 || responseLastId.statusCode == 201) {
          final jsonResponseLastId = json.decode(responseLastId.body);

          print('json response $jsonResponseLastId');
          if (jsonResponseLastId != null && jsonResponseLastId['success'] == true) {
            final lastid = jsonResponseLastId['lastid'];
            final kode_transaksi = jsonResponseLastId['kode_transaksi'];
            if (lastid != null) {
              final idTransaksi = lastid['id_transaksi'];
              await prefs.setString('idTransaksi', idTransaksi);
              print('ID Transaksi: $idTransaksi');

              String idTransaksiSubstring = idTransaksi.substring(6);
              int idTransaksiNumber = int.parse(idTransaksiSubstring);
              int idtransaksi = idTransaksiNumber + 1;
              String idTransaksiGenerated = 'KEUBIS' + idtransaksi.toString();

              print('1.ID Transaksi Generate: $idTransaksiGenerated');

              // Lanjutkan dengan mengirim data premi harian kru ke server
              await _sendPremiHarianKruData(tanggal_transaksi,idTransaksiGenerated, token);
              await _sendResumeTransaksi(tanggal_transaksi,idTransaksiGenerated, token);
            } else {
              print('Error: \'kode_transaksi\' bernilai null atau tidak ada dalam respons JSON.');
              int idTransaksiNumber = 0;
              int idtransaksi = idTransaksiNumber + 1;
              String idTransaksiGenerated = 'KEUBIS' + idtransaksi.toString();

              print('2.ID Transaksi Generate: $idTransaksiGenerated');

              // Lanjutkan dengan mengirim data premi harian kru ke server
              await _sendPremiHarianKruData(tanggal_transaksi,idTransaksiGenerated, token);
              await _sendResumeTransaksi(tanggal_transaksi,idTransaksiGenerated, token);

            }
          } else {
            print('2. Tidak ada data  resume transaksi dengan status \'N\'');
          }

        } else {
          print('Gagal menampilkan data. Status code: ${responseLastId.statusCode}');
        }

      } catch (e) {
        print('Terjadi kesalahan saat menampilkan data: $e');
      } finally {
        await databaseHelper.closeDatabase();
      }
      setState(() {
        _isPushingData = false;
        _pushDataProgress = 0.0;
      });
    } else {
      // Tampilkan pesan jika tanggal belum dipilih
      print("Silakan pilih tanggal terlebih dahulu.");
      // Tampilkan pesan jika tanggal belum dipilih
      _showAlertDialog(context, "Silakan pilih tanggal terlebih dahulu.");
    }

  }

  Future<void> _sendPremiHarianKruData(String tanggal_transaksi,String idTransaksiGenerated, String? token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String noPol = await prefs.getString('noPol') ?? '';
    String kodeTrayek = await prefs.getString('kode_trayek') ?? '';

    List<Map<String, dynamic>> premiKruData = await databaseHelper.getPremiHarianKruByStatus('N');

    if (premiKruData.isNotEmpty) {
      print('premi kru :$premiKruData');
      // Kirim data penjualan ke server
      int idBus = await prefs.getInt('idBus') ?? 0;
      String apiUrl = 'https://apimila.sysconix.id/api/premihariankru';

      int totalDataPremiKru = premiKruData.length;
      int dataSent = 0;
      for (var row in premiKruData) {
        int id_user = row['id_user'];
        int id_group = row['id_group'];
        String nama_kru = row['nama_kru'];
        double persen_premi_disetor = row['persen_premi_disetor'];
        double nominal_premi_disetor = row['nominal_premi_disetor'];
        String tanggal_simpan = row['tanggal_simpan'];
        String status = row['status'];

        double progress = dataSent / totalDataPremiKru;
        _updateUploadProgress(progress);

        String queryParams = '?id_transaksi=${Uri.encodeFull(idTransaksiGenerated)}'
            '&no_pol=${Uri.encodeFull(noPol)}'
            '&id_bus=$idBus'
            '&kode_trayek=${Uri.encodeFull(kodeTrayek)}'
            '&id_personil=$id_user'
            '&id_group=$id_group'
            '&persen=$persen_premi_disetor'
            '&nominal=$nominal_premi_disetor'
            '&tgl_transaksi=${Uri.encodeFull(tanggal_simpan)}';

        String apiUrlWithParams = apiUrl + queryParams;
        print('object 1 : $apiUrlWithParams');
        try {
          final response = await http.post(Uri.parse(apiUrlWithParams),
            headers: {
              'Authorization': 'Bearer $token',
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            int id = row['id'];
            await databaseHelper.updatePremiHarianKruStatus(id, 'Y');
            print('Berhasil mengirim data premi harian kru. Status code: ${response.statusCode}');
            dataSent++;
            double progress = dataSent / totalDataPremiKru;
            setState(() {
              _pushDataProgress = progress;
            });
          } else {
            print('Gagal mengirim data premi harian kru. Status code: ${response.statusCode}');
          }
        } catch (e) {
          print('Terjadi kesalahan saat mengirim data premi harian kru: $e');
        }
        dataSent++;
      }
      await _getListPremiKru();
    } else {
      print('Tidak ada data premi harian kru dengan status \'N\'');
    }
  }

  Future<void> _sendResumeTransaksi(String tanggal_transaksi,String idTransaksiGenerated, String? token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String noPol = await prefs.getString('noPol') ?? '';
    String kodeTrayek = await prefs.getString('kode_trayek') ?? '';
    // String tanggal_transaksi = await prefs.getString('tanggal_transaksi') ?? '';
    int id_bus = await prefs.getInt('id_bus') ?? 0;
    int id_user_login = await prefs.getInt('id_user_login') ?? 0;
    int id_group = await prefs.getInt('id_group') ?? 0;
    int id_garasi = await prefs.getInt('id_garasi') ?? 0;
    int id_company = await prefs.getInt('id_company') ?? 0;
    double km_masuk_garasi = await prefs.getDouble('km_masuk_garasi') ?? 0;
    int jumlah_tiket = await prefs.getInt('jumlah_tiket') ?? 0;
    double pendapatan_reguler = await prefs.getDouble('pendapatan_reguler') ?? 0;
    double pendapatan_online = await prefs.getDouble('pendapatan_online') ?? 0;
    double pendapatan_bagasi_perusahaan = await prefs.getDouble('pendapatan_bagasi_perusahaan') ?? 0;
    double pendapatan_bagasi_kru = await prefs.getDouble('pendapatan_bagasi_kru') ?? 0;
    double biaya_perbaikan = await prefs.getDouble('biaya_perbaikan') ?? 0;
    String keterangan_perbaikan = await prefs.getString('keterangan_perbaikan') ?? '';
    double biaya_tol = await prefs.getDouble('biaya_tol') ?? 0;
    double biaya_tpr = await prefs.getDouble('biaya_tpr') ?? 0;
    double liter_solar = await prefs.getDouble('liter_solar') ?? 0;
    double biaya_solar = await prefs.getDouble('biaya_solar') ?? 0;
    double biaya_perpal = await prefs.getDouble('biaya_perpal') ?? 0;
    double biaya_premi_extra = await prefs.getDouble('biaya_premi_extra') ?? 0;
    double biaya_premi_disetor = await prefs.getDouble('biaya_premi_disetor') ?? 0;
    double pendapatan_bersih = await prefs.getDouble('pendapatan_bersih') ?? 0;
    double pendapatan_disetor = await prefs.getDouble('pendapatan_disetor') ?? 0;

    String apiUrlResumeTransaksi = 'https://apimila.sysconix.id/api/resumesetoranbisharian';
    String queryParamsResumeTransaksi = '?tgl_transaksi=${Uri.encodeFull(tanggal_transaksi)}'
        '&id_transaksi=${Uri.encodeFull(idTransaksiGenerated)}'
        '&no_pol=${Uri.encodeFull(noPol)}'
        '&id_bus=$id_bus'
        '&kode_trayek=${Uri.encodeFull(kodeTrayek)}'
        '&id_personil=$id_user_login'
        '&id_group=$id_group'
        '&id_garasi=$id_garasi'
        '&id_company=$id_company'
        '&km_pulang=$km_masuk_garasi'
        '&jumlah_tiket=$jumlah_tiket'
        '&pendapatan=$pendapatan_reguler'
        '&tiket_online=$pendapatan_online'
        '&bagasi=$pendapatan_bagasi_perusahaan'
        '&bagasi_kru=$pendapatan_bagasi_kru'
        '&perbaikan=$biaya_perbaikan'
        '&keterangan_perbaikan=${Uri.encodeFull(keterangan_perbaikan)}'
        '&tol=$biaya_tol'
        '&tpr=$biaya_tpr'
        '&liter_solar=$liter_solar'
        '&solar=$biaya_solar'
        '&perpal=$biaya_perpal'
        '&premi_extra=$biaya_premi_extra'
        '&premi_disetor=$biaya_premi_disetor'
        '&setoran=$pendapatan_disetor'
        '&bersih=$pendapatan_bersih';

    String apiUrlWithParamsResumeTransaksi = apiUrlResumeTransaksi + queryParamsResumeTransaksi;
    print('object 2 : $apiUrlWithParamsResumeTransaksi');
    try {
      final response = await http.post(
        Uri.parse(apiUrlWithParamsResumeTransaksi),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        int id = await prefs.getInt('id_resume') ?? 0;
        await databaseHelper.updateResumeTransaksiStatus(id, 'Y');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengirim data resume transaksi. Status code: ${response.statusCode}'),
            duration: Duration(seconds: 2), // Durasi tampilan SnackBar
          ),
        );
        await databaseHelper.clearPenjualanTiket();
        await databaseHelper.clearResumeTransaksi();
        await databaseHelper.clearPremiHarianKru();
      } else {
        print('Gagal mengirim data  resume transaksi. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Terjadi kesalahan saat mengirim data resume transaksi: $e');
    }
  }

  DateTime? _selectedDate;

  // Fungsi untuk menampilkan Date Picker dan memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate)
      setState(() {
        _selectedDate = pickedDate;
      });
  }

  void _showAlertDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pemberitahuan"),
          content: Text(message),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    // Menambahkan LinearProgressIndicator atau CircularProgressIndicator
    if (_isPushingData) {
      return Stack(
        children: [
          Container(
            color: Colors.grey.withOpacity(0.5), // Latar belakang abu-abu transparan
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(value: _uploadProgress),
                  SizedBox(height: 16),
                  Text("Sedang mengirim data..."),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // Tampilkan widget lain jika tidak sedang mengirim data
      return Scaffold(
        appBar: AppBar(
          title: Text('Data Premi Disetor Harian Kru'),
          automaticallyImplyLeading: false, // Menghilangkan icon arrow back
          actions: [
            IconButton(
              icon: Icon(Icons.calendar_today),
              onPressed: () {
                _selectDate(context);
              },
              tooltip: 'Pilih Tanggal',
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                _pushDataPremiHarianKru();
              },
              tooltip: 'Kirim Data',
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: [
                    DataColumn(
                      label: Expanded(
                        child: Center(
                          child: Text('Kru', style: TextStyle(fontSize: 18)),
                        ),
                      ), // Lebarkan kolom "Kru" dengan menggunakan Expanded
                    ),
                    DataColumn(
                      label: Expanded(
                        child: Center(
                          child: Text('%', style: TextStyle(fontSize: 18)),
                        ),
                      ), // Lebarkan kolom "Kru" dengan menggunakan Expanded
                    ),
                    DataColumn(
                      label: Center(
                        child: Text('Nominal', style: TextStyle(fontSize: 18)), // Ubah ukuran font menjadi 18
                      ),
                      numeric: true, // Mengaktifkan rata kanan pada kolom
                    ),
                    DataColumn(
                      label: Center(
                        child: Text('Status', style: TextStyle(fontSize: 18)), // Ubah ukuran font menjadi 18
                      ),
                    ),
                  ],
                  rows: listPremiHarianKru.map(
                        (item) => DataRow(
                      cells: [
                        DataCell(
                          Text(
                            item['nama_kru'].toString(),
                            style: TextStyle(fontSize: 16), // Ubah ukuran font menjadi 16
                          ),
                        ),
                        DataCell(
                          Text(
                            item['persen_premi'].toString(),
                            style: TextStyle(fontSize: 16), // Ubah ukuran font menjadi 16
                          ),
                        ),
                        DataCell(
                          Text(
                            formatter.format(item['nominal_premi_disetor']),
                            style: TextStyle(fontSize: 16), // Ubah ukuran font menjadi 16
                          ),
                        ),
                        DataCell(
                          Text(
                            item['status'].toString(),
                            style: TextStyle(fontSize: 16), // Ubah ukuran font menjadi 16
                          ),
                        ),
                      ],
                    ),
                  ).toList(),
                ),
              ),
              SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: resumeTransaksi,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(), // Display a progress indicator while loading the data
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'), // Display an error message if there's an error
                    );
                  } else if (snapshot.hasData) {
                    List<Map<String, dynamic>> resumeData = snapshot.data!;
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
                            itemCount: resumeData.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Padding(
                                  padding: EdgeInsets.only(left: 20.0),
                                  child: Text(
                                    'Data Rekap Pendapatan Pengeluaran Harian:',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: EdgeInsets.only(left: 20.0), // Menggeser ke kanan sebanyak 20 piksel
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 20),
                                      Text('ID User: ${resumeData[index]['id_user'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Status: ${resumeData[index]['status'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Nomor Polisi: ${resumeData[index]['no_pol'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Kode Trayek: ${resumeData[index]['kode_trayek'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('KM Masuk Garasi: ${resumeData[index]['km_masuk_garasi'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Jumlah Tiket: ${resumeData[index]['jumlah_tiket'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Pendapatan Reguler: ${resumeData[index]['pendapatan_reguler'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Pendapatan Online: ${resumeData[index]['pendapatan_online'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Pendapatan Bagasi Perusahaan: ${resumeData[index]['pendapatan_bagasi_perusahaan'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Pendapatan Bagasi Kru: ${resumeData[index]['pendapatan_bagasi_kru'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Perbaikan: ${resumeData[index]['biaya_perbaikan'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Keterangan Perbaikan: ${resumeData[index]['keterangan_perbaikan'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Tol: ${resumeData[index]['biaya_tol'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Operasi Harian Bus: ${resumeData[index]['biaya_tpr'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Liter Solar: ${resumeData[index]['liter_solar'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Solar: ${resumeData[index]['biaya_solar'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Perpal: ${resumeData[index]['biaya_perpal'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Premi Extra: ${resumeData[index]['biaya_premi_extra'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Premi Disetor: ${resumeData[index]['biaya_premi_disetor'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Pendapatan Bersih: ${resumeData[index]['pendapatan_bersih'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Pendapatan Disetor: ${resumeData[index]['pendapatan_disetor'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Tanggal Transaksi: ${resumeData[index]['tanggal_transaksi'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                      Text('Status: ${resumeData[index]['status'].toString()}', style: TextStyle(fontSize: 18)),
                                      SizedBox(height: 10),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: Text('No data available'), // Display a message when there's no data
                    );
                  }
                },
              ),

            ],
          ),
        ),
      );
    }
  }



}
