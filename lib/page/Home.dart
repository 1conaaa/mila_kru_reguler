import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/database/database_helper.dart';
import '../main.dart';
import 'package:mila_kru_reguler/page/manifest.dart'; // 🔹 Halaman manifest

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isOnline = false;
  int? idUser;
  int? idGarasi;
  int idBus = 0;
  String? noPol;
  String? idJadwalTrip;
  String? namaTrayek;
  String? token;
  String? namaLengkap;

  List<dynamic> notifikasiList = [];

  final DatabaseHelper databaseHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  /// 🔹 Muat SharedPreferences dan panggil notifikasi
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getInt('idUser') ?? 0;
      idGarasi = prefs.getInt('idGarasi');
      idBus = prefs.getInt('idBus') ?? 0;
      noPol = prefs.getString('noPol');
      idJadwalTrip = prefs.getString('idJadwalTrip');
      token = prefs.getString('token') ?? '';
      namaTrayek = prefs.getString('namaTrayek') ?? '';
      namaLengkap = prefs.getString('namaLengkap') ?? '';
    });

    await _fetchNotifikasi();
  }

  /// 🔹 Ambil data notifikasi dari API listnotifikasireguler
  Future<void> _fetchNotifikasi() async {
    if ((token ?? '').isEmpty || idJadwalTrip == null) return;

    final uri = Uri.parse(
      'https://apibis.iconaaa.net/api/listnotifikasireguler',
    ).replace(queryParameters: {
      'id_jadwal_trip': idJadwalTrip ?? '',
      'id_bus': idBus.toString(),
      'no_pol': noPol ?? '',
    });

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      debugPrint('⬅️ [NOTIF] Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          setState(() => notifikasiList = jsonData);
          debugPrint('✅ Notifikasi berhasil diambil: ${jsonData.length} item');
        } else {
          debugPrint('⚠️ Format JSON tidak sesuai (bukan List)');
        }
      }
    } catch (e) {
      debugPrint('❌ Gagal mengambil notifikasi: $e');
    }
  }

  /// 🔹 Query user lokal
  Future<List<Map<String, dynamic>>> _getUserData() async {
    await databaseHelper.initDatabase();
    final users = await databaseHelper.queryUsers();
    await databaseHelper.closeDatabase();
    return users;
  }

  /// 🔹 Query kru bus lokal
  Future<List<Map<String, dynamic>>> _getKruBis() async {
    await databaseHelper.initDatabase();
    final kruBisData = await databaseHelper.queryKruBis();
    await databaseHelper.closeDatabase();
    return kruBisData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      drawer: idUser == null ? null : buildDrawer(context, idUser!),
      body: RefreshIndicator(
        onRefresh: _fetchNotifikasi,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 8),

              /// 🔔 Card Notifikasi Trip
              if (notifikasiList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Colors.amber.shade100,
                    elevation: 3.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active,
                          color: Colors.orange),
                      title: Text(
                        'Ada ${notifikasiList[0]['total_notifikasi']} Penumpang Baru!',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('KLIK DI SINI untuk melihat manifest'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManifestPage(
                              idJadwalTrip: notifikasiList[0]['id_jadwal_trip']
                                  .toString(),
                              token: token ?? '',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              /// 🧍 Profil Akun
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

              /// 👥 Kru Bus
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Kru BIS',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getKruBis(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return const Text('Gagal memuat data kru.');
                            } else if (snapshot.hasData) {
                              final kruBisData = snapshot.data!;
                              return Column(
                                children: kruBisData.map((krubis) {
                                  return Card(
                                    child: ListTile(
                                      title:
                                      Text('${krubis['nama_lengkap']}'),
                                      subtitle:
                                      Text('${krubis['group_name']}'),
                                    ),
                                  );
                                }).toList(),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
