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

  DatabaseHelper databaseHelper = DatabaseHelper.instance;

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
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              title: Text('Rekap Transaksi - $connectivityInfo'),
              automaticallyImplyLeading: true,
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.yellowAccent,               // warna teks tab aktif
                unselectedLabelColor: Colors.black,       // warna teks tab tidak aktif
                labelStyle: TextStyle(fontSize: 18),      // style tab aktif
                unselectedLabelStyle: TextStyle(fontSize: 18), // style tab tidak aktif
                tabs: const [
                  Tab(text: 'Form.Rekap'),
                  Tab(text: 'Premi Kru'),
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