import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/view/View_FormRekapTransaksi.dart';
import 'package:mila_kru_reguler/view/View_PremiKru.dart';
import '../main.dart';

class RekapTransaksi extends StatefulWidget {
  @override
  _RekapTransaksiState createState() => _RekapTransaksiState();
}
final _formKey = GlobalKey<FormState>();

class _RekapTransaksiState extends State<RekapTransaksi> with SingleTickerProviderStateMixin {
  bool isOnline = false;

  String token = '';
  String namaLengkap = '';
  List<dynamic> krubisData = [];
  late TabController _tabController;
  List<Map<String, dynamic>> listKota = [];
  List<Map<String, dynamic>> listKotaTerakhir = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  DatabaseHelper databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    String connectivityInfo =
    isOnline ? 'Terhubung ke Internet' : 'Tidak Terhubung ke Internet';
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        if (snapshot.hasData) {
          final SharedPreferences prefs = snapshot.data!;
          final int idUser = prefs.getInt('idUser') ?? 0;
          return Scaffold(
            appBar: AppBar(
              title: Text('Rekap Transaksi - $connectivityInfo'),
              automaticallyImplyLeading: true,
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Text(
                      'Form.Rekap',
                      style: TextStyle(fontSize: 18), // Tambahkan ukuran font pada Tab
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Premi Kru',
                      style: TextStyle(fontSize: 18), // Tambahkan ukuran font pada Tab
                    ),
                  ),
                ],
              ),

            ),
            drawer: buildDrawer(context, idUser),
            body: TabBarView(
              controller: _tabController,
              children: [
                FormRekapTransaksi(),
                PremiKru(),
              ],
            ),
          );
        }

        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}