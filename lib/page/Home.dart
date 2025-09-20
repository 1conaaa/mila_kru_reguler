import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:kru_reguler/database/database_helper.dart';

import '../main.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isOnline = false;
  late int idUser;
  int? idGarasi;
  int idBus = 0;
  String? noPol;
  late String namaTrayek;
  late String token;
  late String namaLengkap;

  get krubisData => null;

  DatabaseHelper databaseHelper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> _getUserData() async {
    await databaseHelper.initDatabase();
    List<Map<String, dynamic>> users = await databaseHelper.queryUsers();
    await databaseHelper.closeDatabase();
    print('object home : $users');
    return users;
  }

  Future<List<Map<String, dynamic>>> _getKruBis() async {
    await databaseHelper.initDatabase();
    List<Map<String, dynamic>> kruBisData = await databaseHelper.queryKruBis();
    await databaseHelper.closeDatabase();
    return kruBisData;
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        idUser = prefs.getInt('idUser') ?? 0;
        idGarasi = prefs.getInt('idGarasi');
        idBus = prefs.getInt('idBus') ?? 0;
        noPol = prefs.getString('noPol');
        token = prefs.getString('token') ?? '';
        namaTrayek = prefs.getString('namaTrayek') ?? '';
        namaLengkap = prefs.getString('namaLengkap') ?? '';
      });

    });
    // _showDialog('Salam $idGarasi, $noPol, $idBus');
  }

  Future<void> _fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    print('Token: $token');

    final response = await http.get(
      Uri.parse(
          'https://apibis.iconaaa.net/api/krubis?id_bus=$idBus&no_pol=$noPol&id_garasi=$idGarasi'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      String responseBody = response.body;
      Map<String, dynamic> parsedResponse = jsonDecode(responseBody);

      int success = parsedResponse['success'];
      var krubis = parsedResponse['krubis'];
      int jumlahBaris = krubis.length;
      print('Jumlah Baris Data: $jumlahBaris');

      setState(() {
        var krubisData = krubis;
      });
    } else {
      // Gagal mendapatkan data dari API
      // Menangani kesalahan atau kegagalan sesuai kebutuhan Anda
      print('Api gagal: $krubisData');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Beranda'),
      ),
      drawer: buildDrawer(context, idUser),
      body: Column(
        children: [
          SizedBox(height: 16.0),
          Text(
            'Profil Akun',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.0),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getUserData(),
                  builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (snapshot.hasError) {
                      return Text('Failed to fetch user data from database.');
                    } else if (snapshot.hasData) {
                      List<Map<String, dynamic>> users = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (BuildContext context, int index) {
                          Map<String, dynamic> user = users[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama Lengkap: ${user['nama_lengkap']}',
                                style: TextStyle(fontSize: 16.0),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'ID Bus: ${user['id_bus']}',
                                style: TextStyle(fontSize: 16.0),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'Nomor Polisi: ${user['no_pol']}',
                                style: TextStyle(fontSize: 16.0),
                              ),
                              SizedBox(height: 8.0),
                              Text(
                                'Nama Trayek: ${user['nama_trayek']}',
                                style: TextStyle(fontSize: 16.0),
                              ),
                              SizedBox(height: 16.0),
                            ],
                          );
                        },
                      );
                    } else {
                      return Container();
                    }
                  },
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Kru BIS',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    SizedBox(height: 20.0),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _getKruBis(),
                      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Failed to fetch user data from database.');
                        } else if (snapshot.hasData) {
                          List<Map<String, dynamic>> kruBisData = snapshot.data!;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: kruBisData.length,
                            itemBuilder: (BuildContext context, int index) {
                              Map<String, dynamic> krubis = kruBisData[index];
                              return Card(
                                elevation: 2.0,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${krubis['group_name']}',
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      '${krubis['nama_lengkap']}',
                                      style: TextStyle(fontSize: 16.0),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }
                        return Container();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  void _showDialog(String s) {}
}
