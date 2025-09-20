import 'package:flutter/material.dart';
import 'package:kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kru_reguler/view/View_PenjualanTiket.dart';
import 'package:kru_reguler/view/View_HistoryTransaksi.dart';
import 'package:kru_reguler/view/View_HistoryPembayaran.dart';

import '../main.dart';

class PenjualanTiket extends StatefulWidget {
  @override
  _PenjualanTiketState createState() => _PenjualanTiketState();
}
final _formKey = GlobalKey<FormState>();

class _PenjualanTiketState extends State<PenjualanTiket> with SingleTickerProviderStateMixin {
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
    _tabController = TabController(length: 3, vsync: this);
  }

  DatabaseHelper databaseHelper = DatabaseHelper();

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
              title: Text('Penjualan Tiket'),
              automaticallyImplyLeading: true,
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Text('Penjualan',style: TextStyle(fontSize: 18)),
                  ),
                  Tab(
                    child: Text('Non-Tunai',style: TextStyle(fontSize: 18)),
                  ),
                  Tab(
                    child: Text('Transaksi',style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
            drawer: buildDrawer(context, idUser),
            body: TabBarView(
              controller: _tabController,
              children: [
                PenjualanForm(),
                HistoryPembayaran(),
                HistroyTransaksi(),
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