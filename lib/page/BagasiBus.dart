import 'package:flutter/material.dart';
import 'package:kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kru_reguler/view/View_FormBagasiBus.dart';
import 'package:kru_reguler/view/View_HistoryBagasiBus.dart';

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
              title: Text('Bagasi Bus'),
              automaticallyImplyLeading: true,
              bottom: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    child: Text('Form Bagasi',style: TextStyle(fontSize: 18)),
                  ),
                  Tab(
                    child: Text('History Bagasi',style: TextStyle(fontSize: 18)),
                  ),
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