import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/view/View_FormBagasiBus.dart';
import 'package:mila_kru_reguler/view/View_HistoryBagasiBus.dart';

import '../main.dart';

class BagasiBus extends StatefulWidget {
  @override
  _BagasiBusState createState() => _BagasiBusState();
}
final _formKey = GlobalKey<FormState>();

class _BagasiBusState extends State<BagasiBus> with SingleTickerProviderStateMixin {
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
              title: Text('Bagasi Bus'),
              automaticallyImplyLeading: true,
              bottom: TabBar(
                controller: _tabController,
                labelColor: Colors.yellowAccent,                     // Warna teks tab aktif
                unselectedLabelColor: Colors.black,            // Warna teks tab tidak aktif
                labelStyle: const TextStyle(fontSize: 18),     // Style untuk tab aktif
                unselectedLabelStyle: const TextStyle(fontSize: 18), // Style untuk tab tidak aktif
                tabs: const [
                  Tab(text: 'Form Bagasi'),
                  Tab(text: 'History Bagasi'),
                ],
              ),
            ),
            drawer: buildDrawer(context, idUser),
            body: TabBarView(
              controller: _tabController,
              children: [
                FormBagasiBus(),
                HistoryBagasiBus(),
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