import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/models/user_data.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/database/database_helper.dart';
import '../main.dart';
import 'package:mila_kru_reguler/page/manifest.dart'; // 🔹 Halaman manifest
import 'package:mila_kru_reguler/api/ApiHelperKruBis.dart';

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
  String? noKontak;

  List<dynamic> notifikasiList = [];
  final UserService _userService = UserService();
  final DatabaseHelper databaseHelper = DatabaseHelper.instance;

  // 🆕 Tambahkan variabel untuk loading state
  bool _isInitialLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    loadKruBisData(context);
  }

  /// Fungsi khusus untuk memanggil ApiHelperKruBis
  Future<void> loadKruBisData(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // Ambil data SharedPreferences dan pastikan tidak null
    final token = prefs.getString('token') ?? '';
    final idBus = prefs.getInt('idBus') ?? 0;
    final noPol = prefs.getString('noPol') ?? '';
    final idGarasi = prefs.getInt('idGarasi') ?? 0;

    try {
      // Panggil API
      await ApiHelperKruBis.requestKruBisAPI(
        token,
        idBus,
        noPol,
        idGarasi,
        context,
      );
      debugPrint('✅ ApiHelperKruBis berhasil dipanggil');
    } catch (e) {
      debugPrint('❌ Error memanggil ApiHelperKruBis: $e');
    }
  }

  /// 🔹 Muat SharedPreferences dan panggil notifikasi
  Future<void> _loadPrefs() async {
    setState(() {
      _isInitialLoading = true;
    });

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
      noKontak = prefs.getString('noKontak') ?? '';
    });

    await _fetchAllData();
  }

  /// 🆕 Fungsi untuk mengambil semua data sekaligus
  Future<void> _fetchAllData() async {
    try {
      await Future.wait([
        _fetchNotifikasi(),
        _preloadUserData(),
        _preloadKruBisData(),
      ]);
    } catch (e) {
      debugPrint('❌ Error loading initial data: $e');
    } finally {
      setState(() {
        _isInitialLoading = false;
      });
    }
  }

  /// 🆕 Preload user data
  Future<void> _preloadUserData() async {
    try {
      await _userService.getAllUsersAsUserData();
    } catch (e) {
      debugPrint('❌ Error preloading user data: $e');
    }
  }

  /// 🆕 Preload kru bis data
  Future<void> _preloadKruBisData() async {
    try {
      await databaseHelper.initDatabase();
      await databaseHelper.queryKruBis();
      // await databaseHelper.closeDatabase();
    } catch (e) {
      debugPrint('❌ Error preloading kru bis data: $e');
    }
  }

  /// 🔹 Ambil data notifikasi dari API listnotifikasireguler
  Future<void> _fetchNotifikasi() async {
    if ((token ?? '').isEmpty || idJadwalTrip == null) {
      setState(() {
        notifikasiList = [];
      });
      return;
    }

    final uri = Uri.parse(
      'https://apimila.milaberkah.com/api/listnotifikasireguler',
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
          setState(() => notifikasiList = []);
        }
      } else {
        setState(() => notifikasiList = []);
      }
    } catch (e) {
      debugPrint('❌ Gagal mengambil notifikasi: $e');
      setState(() => notifikasiList = []);
    }
  }

  /// 🆕 Refresh data dengan loading indicator
  Future<void> _refreshData() async {
    // 🆕 Prevent refresh during initial loading
    if (_isInitialLoading) return;

    setState(() {
      _isRefreshing = true;
    });

    await _fetchNotifikasi();

    setState(() {
      _isRefreshing = false;
    });
  }

  /// 🆕 Handler untuk refresh yang aman
  Future<void> _handleRefresh() async {
    if (_isInitialLoading) {
      // Jika masih initial loading, jangan lakukan apa-apa
      return;
    }
    await _refreshData();
  }

  // Method untuk mendapatkan semua user data
  Future<List<UserData>> getAllUserData() async {
    try {
      return await _userService.getAllUsersAsUserData();
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  /// 🔹 Query kru bus lokal
  Future<List<Map<String, dynamic>>> _getKruBis() async {
    await databaseHelper.initDatabase();
    final kruBisData = await databaseHelper.queryKruBis();
    // await databaseHelper.closeDatabase();
    return kruBisData;
  }

  /// 🆕 Handler untuk notifikasi tap
  void _handleNotifikasiTap() {
    // 🆕 Prevent tap during initial loading
    if (_isInitialLoading) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManifestPage(
          idJadwalTrip: notifikasiList[0]['id_jadwal_trip'].toString(),
          token: token ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🆕 Tampilkan loading screen saat initial loading
    if (_isInitialLoading) {
      return _buildInitialLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        // 🆕 Nonaktifkan leading button selama loading
        automaticallyImplyLeading: !_isInitialLoading,
      ),
      // 🆕 Nonaktifkan drawer selama initial loading
      drawer: (_isInitialLoading || idUser == null) ? null : buildDrawer(context, idUser!),
      body: AbsorbPointer(
        // 🆕 Blokir semua interaksi selama initial loading
        absorbing: _isInitialLoading,
        child: Stack(
          children: [
            RefreshIndicator(
              // 🆕 PERBAIKAN: Gunakan fungsi yang tidak nullable
              onRefresh: _handleRefresh,
              child: SingleChildScrollView(
                physics: _isInitialLoading
                    ? const NeverScrollableScrollPhysics() // 🆕 Nonaktifkan scroll selama loading
                    : const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 🆕 Loading indicator untuk refresh
                    if (_isRefreshing)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: const LinearProgressIndicator(),
                      ),

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
                          child: AbsorbPointer(
                            // 🆕 Nonaktifkan interaksi card notifikasi selama loading
                            absorbing: _isInitialLoading,
                            child: ListTile(
                              leading: Icon(
                                Icons.notifications_active,
                                color: _isInitialLoading ? Colors.grey : Colors.orange,
                              ),
                              title: Text(
                                'Ada ${notifikasiList[0]['total_notifikasi']} Penumpang Baru!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isInitialLoading ? Colors.grey : Colors.black,
                                ),
                              ),
                              subtitle: Text(
                                'KLIK DI SINI untuk melihat manifest',
                                style: TextStyle(
                                  color: _isInitialLoading ? Colors.grey : null,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: _isInitialLoading ? Colors.grey : null,
                              ),
                              onTap: _isInitialLoading ? null : _handleNotifikasiTap, // 🆕 Nonaktifkan onTap selama loading
                            ),
                          ),
                        ),
                      ),

                    /// 🧍 Profil Akun
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4.0,
                        color: _isInitialLoading ? Colors.grey[100] : null, // 🆕 Ubah warna selama loading
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: AbsorbPointer(
                            // 🆕 Nonaktifkan interaksi selama loading
                            absorbing: _isInitialLoading,
                            child: FutureBuilder<List<UserData>>(
                              future: getAllUserData(),
                              builder: (BuildContext context, AsyncSnapshot<List<UserData>> snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(),
                                        SizedBox(height: 16),
                                        Text('Memuat data pengguna...'),
                                      ],
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return Column(
                                    children: [
                                      Icon(Icons.error, color: Colors.red, size: 40),
                                      SizedBox(height: 8),
                                      Text(
                                        'Gagal memuat data pengguna',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      SizedBox(height: 8),
                                      ElevatedButton(
                                        onPressed: _isInitialLoading ? null : _refreshData, // 🆕 Nonaktifkan tombol selama loading
                                        child: Text('Coba Lagi'),
                                      ),
                                    ],
                                  );
                                } else if (snapshot.hasData) {
                                  List<UserData> users = snapshot.data!;

                                  if (users.isEmpty) {
                                    return const Column(
                                      children: [
                                        Icon(Icons.person_off, size: 40),
                                        SizedBox(height: 8),
                                        Text('Tidak ada data pengguna.'),
                                      ],
                                    );
                                  }

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: users.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      UserData user = users[index];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Nomor Polisi: ${user.noPol}',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              color: _isInitialLoading ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            'Nama Trayek: ${user.namaTrayek}',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              color: _isInitialLoading ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            'Jenis Trayek: ${user.jenisTrayek}',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              color: _isInitialLoading ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 8.0),
                                          Text(
                                            'Kelas Bus: ${user.kelasBus}',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              color: _isInitialLoading ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 16.0),
                                          Text(
                                            'No.Whatsapp Bus: ${user.noKontak}',
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              color: _isInitialLoading ? Colors.grey : Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 16.0),
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
                    ),

                    /// 👥 Kru Bus
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 4.0,
                        color: _isInitialLoading ? Colors.grey[100] : null, // 🆕 Ubah warna selama loading
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: AbsorbPointer(
                            // 🆕 Nonaktifkan interaksi selama loading
                            absorbing: _isInitialLoading,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Kru BIS',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _isInitialLoading ? Colors.grey : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: _getKruBis(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Center(
                                        child: Column(
                                          children: [
                                            CircularProgressIndicator(),
                                            SizedBox(height: 16),
                                            Text('Memuat data kru...'),
                                          ],
                                        ),
                                      );
                                    } else if (snapshot.hasError) {
                                      return Column(
                                        children: [
                                          Icon(Icons.error, color: Colors.red, size: 40),
                                          SizedBox(height: 8),
                                          Text(
                                            'Gagal memuat data kru',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: _isInitialLoading ? null : _refreshData, // 🆕 Nonaktifkan tombol selama loading
                                            child: Text('Coba Lagi'),
                                          ),
                                        ],
                                      );
                                    } else if (snapshot.hasData) {
                                      final kruBisData = snapshot.data!;

                                      if (kruBisData.isEmpty) {
                                        return const Column(
                                          children: [
                                            Icon(Icons.people_outline, size: 40),
                                            SizedBox(height: 8),
                                            Text('Tidak ada data kru.'),
                                          ],
                                        );
                                      }

                                      return Column(
                                        children: kruBisData.map((krubis) {
                                          return Card(
                                            color: _isInitialLoading ? Colors.grey[50] : null,
                                            child: ListTile(
                                              title: Text(
                                                '${krubis['nama_lengkap']}',
                                                style: TextStyle(
                                                  color: _isInitialLoading ? Colors.grey : Colors.black,
                                                ),
                                              ),
                                              subtitle: Text(
                                                '${krubis['group_name']}',
                                                style: TextStyle(
                                                  color: _isInitialLoading ? Colors.grey : null,
                                                ),
                                              ),
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
                    ),
                  ],
                ),
              ),
            ),
            // 🆕 Overlay loading untuk mencegah interaksi
            if (_isInitialLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        strokeWidth: 4.0,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Menyiapkan aplikasi...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

  /// 🆕 Widget untuk menampilkan loading screen awal
  Widget _buildInitialLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beranda'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // 🆕 Nonaktifkan back button
      ),
      // 🆕 Nonaktifkan drawer selama loading
      drawer: null,
      body: AbsorbPointer(
        // 🆕 Blokir semua interaksi
        absorbing: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 120.0,
                height: 120.0,
                child: Image.asset(
                  'assets/images/mila_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                strokeWidth: 4.0,
              ),
              const SizedBox(height: 20),
              const Text(
                'Memuat Data...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Menyiapkan informasi beranda',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}