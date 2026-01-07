import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/api/ApiHelperMetodePembayaran.dart';
import 'package:mila_kru_reguler/api/ApiPersenPremiKru..dart';
import 'package:mila_kru_reguler/models/user.dart';
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/api/ApiHelperPremiPosisiKru.dart';
import 'package:mila_kru_reguler/api/ApiHelperKruBis.dart';
import 'package:mila_kru_reguler/api/ApiHelperListKota.dart';
import 'package:mila_kru_reguler/api/ApiHelperOperasiHarianBus.dart';
import 'package:mila_kru_reguler/api/ApiHelperJenisPaket.dart';
import 'package:mila_kru_reguler/api/ApiHelperUser.dart';
import 'package:mila_kru_reguler/api/ApiHelperTagTransaksi.dart';
import 'package:mila_kru_reguler/api/ApiHelperRuteTrayekUrutan.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  List<Map<String, dynamic>> listPenjualan = [];

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isInitializing = false; // 🆕 Tambahkan flag untuk initial loading
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkInitialData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 🆕 Fungsi untuk mengecek data awal
  Future<void> _checkInitialData() async {
    setState(() {
      _isInitializing = true;
    });

    // Simulasikan proses inisialisasi awal
    await Future.delayed(Duration(seconds: 2)); // Opsional: hapus delay ini jika tidak perlu

    setState(() {
      _isInitializing = false;
    });
  }

  void _showDialog(BuildContext context, String message) {
    print("[DEBUG] ================= SHOW DIALOG =================");
    print("[DEBUG] Time        : ${DateTime.now()}");
    print("[DEBUG] Context     : $context");
    print("[DEBUG] Message     : $message");
    print("[DEBUG] =================================================");

    try {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          print("[DEBUG] AlertDialog builder dipanggil");
          print("[DEBUG] dialogContext: $dialogContext");

          return AlertDialog(
            title: const Text('Login Result'),
            content: Text(message),
            actions: <Widget>[
              ElevatedButton(
                onPressed: () {
                  print("[DEBUG] Tombol 'Masuk' ditekan");
                  print("[DEBUG] Menutup dialog...");
                  Navigator.pop(dialogContext);
                  print("[DEBUG] Dialog ditutup.");
                },
                child: const Text('Masuk'),
              ),
            ],
          );
        },
      ).catchError((e, stack) {
        print("[ERROR] showDialog gagal!");
        print("[ERROR] Pesan   : $e");
        print("[ERROR] Stack   : $stack");
      });
    } catch (e, stack) {
      print("[FATAL ERROR] Terjadi error pada _showDialog()");
      print("[FATAL] Pesan : $e");
      print("[FATAL] Stack : $stack");
    }
  }

  Future<void> _login() async {
    if (_isLoading || _isInitializing) return;

    setState(() => _isLoading = true);

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    try {
      print("=== DEBUG LOGIN API ===");
      print("Username : $username");
      print("Password : (disembunyikan)");
      print("====================================");

      final response = await http.post(
        Uri.parse('https://apimila.milaberkah.com/api/login'),
        body: {
          'username': username,
          'password': password,
        },
      );

      print("Status Code : ${response.statusCode}");
      print("Raw Body    : ${response.body}");
      print("====================================");

      // ===== PARSE JSON DENGAN TRY/CATCH =====
      ApiResponseUser apiResponseUser;
      try {
        apiResponseUser = ApiResponseUser.fromJson(jsonDecode(response.body));
      } catch (e) {
        print("[ERROR] Parsing JSON gagal: $e");
        setState(() => _isLoading = false);
        _showDialog(context, "Login gagal: Username atau password salah!");
        return;
      }

      // ===== CEK LOGIN SUCCESS =====
      if (apiResponseUser.success != 1) {
        setState(() => _isLoading = false);
        _showDialog(context, 'Username atau password salah.');
        return;
      }

      // ===== CEK JADWAL TUGAS =====
      User user = apiResponseUser.user;
      if (user.idBus == null || user.idBus == 0) {
        setState(() => _isLoading = false);
        _showDialog(
          context,
          'Login berhasil, tetapi Anda belum dijadwalkan bertugas. Silakan hubungi admin.',
        );
        return;
      }

      // ===== SIMPAN DATA SHARED PREFERENCES =====
      SharedPreferences prefs = await SharedPreferences.getInstance();
      print("=== DEBUG: Menyimpan Data SharedPreferences ===");

      Map<String, dynamic> dataUserToSave = {
        "token": apiResponseUser.token,
        "idGroup": user.idGroup,
        "idUser": user.idUser,
        "idCompany": user.idCompany,
        "idGarasi": user.idGarasi,
        "idBus": user.idBus,
        "noPol": user.noPol ?? "",
        "namaLengkap": user.namaLengkap ?? "",
        "namaUser": user.namaUser ?? "",
        "foto": user.foto ?? "",
        "group_name": user.groupName ?? "",
        "kode_trayek": user.kodeTrayek ?? "",
        "namaTrayek": user.namaTrayek ?? "",
        "rute": user.rute ?? "",
        "jenisTrayek": user.jenisTrayek ?? "",
        "kelasBus": user.kelasBus ?? "",
        "premiExtra": user.premiExtra ?? "",
        "keydataPremiextra": user.keydataPremiextra ?? "",
        "keydataPremikru": user.keydataPremikru ?? "",
        "persenPremikru": user.persenPremikru ?? "",
        "idJadwalTrip": user.idJadwalTrip ?? "",
        "tagTransaksiPendapatan": user.tagTransaksiPendapatan ?? "",
        "tagTransaksiPengeluaran": user.tagTransaksiPengeluaran ?? "",
        "coaPendapatanBus": user.coaPendapatanBus ?? "",
        "coaPengeluaranBus": user.coaPengeluaranBus ?? "",
        "coaUtangPremi": user.coaUtangPremi ?? "",
        "noKontak": user.noKontak ?? "",
        "persenSusukanKru": user.persenSusukan ?? "",
        "hargaBatas": user.hargaBatas ?? "",
      };

      for (var entry in dataUserToSave.entries) {
        print("[DEBUG] Simpan ${entry.key} = ${entry.value}");
        if (entry.value is int) {
          await prefs.setInt(entry.key, entry.value);
        } else {
          await prefs.setString(entry.key, entry.value.toString());
        }
      }

      await prefs.setBool('isLoggedIn', true);
      print("[DEBUG] isLoggedIn diset ke true");

      // ===== SIMPAN USER KE SQLITE =====
      try {
        await _userService.insertUser(user.toMap());
        print('[SUCCESS] User data saved to SQLite');
      } catch (e) {
        print('[ERROR] Gagal simpan ke SQLite: $e');
      }

      setState(() => _isLoading = false);

      // ===== PINDAH HALAMAN =====
      Navigator.pushReplacementNamed(context, '/');

      // ===== TAMPILKAN DIALOG SELAMAT TUGAS =====
      _showDialog(
        context,
        'Salam ${user.namaLengkap}, Anda sudah terdaftar bertugas pada Bis (${user.idBus})-${user.noPol} '
            'Trayek ${user.namaTrayek}. Selamat bertugas. Bismillah.',
      );

      // ===== LOAD DATA LANJUTAN =====
      String token = apiResponseUser.token;
      int idBus = user.idBus;
      int idGarasi = user.idGarasi;
      String noPol = user.noPol ?? "";
      String namaTrayek = user.namaTrayek ?? "";
      String jenisTrayek = user.jenisTrayek ?? "";
      String kodeTrayek = user.kodeTrayek ?? "";
      String kelasBusRaw = user.kelasBus ?? "";

      List<Map<String, dynamic>> penjualanData =
      await PenjualanTiketService.instance.getDataPenjualan();
      setState(() => listPenjualan = penjualanData);

      if (listPenjualan.isEmpty) {
        print('Tidak ada data penjualan, memuat dari API...');

        await ApiHelperKruBis.requestKruBisAPI(token, idBus, noPol, idGarasi, context);
        ApiHelperPersenPremiKru.requestListPersenPremiAPI(token, kodeTrayek);
        await ApiHelperListKota.requestListKotaAPI(token, kodeTrayek);
        await ApiHelperRuteTrayekUrutan.requestRuteTrayekUrutanAPI(token, kodeTrayek);

        // Perbaikan kelasBus
        List<String> kata = kelasBusRaw.split(" ");
        List<String> kataFix = [];
        for (int i = 0; i < kata.length; i++) {
          if (i < kata.length - 1 && kata[i].endsWith("-") && kata[i + 1].startsWith("-")) {
            kataFix.add(kata[i] + kata[i + 1]);
            i++;
          } else {
            kataFix.add(kata[i]);
          }
        }
        String kelasBusFinal = kataFix.join("");

        await ApiHelperMetodePembayaran.fetchAndStoreMetodePembayaran(token);
        await ApiHelperPremiPosisiKru.requestListPremiPosisiKruAPI(token, jenisTrayek, kelasBusFinal);
        await ApiHelperOperasiHarianBus.addListOperasiHarianBusAPI(token, idBus, noPol, kodeTrayek);
        // await ApiHelperInspectionItems.addListInspectionItemsAPI(token);
        await ApiHelperJenisPaket.addListJenisPaketAPI(token);
        await ApiHelperTagTransaksi.fetchAndStoreTagTransaksi(token);
      } else {
        print('Data penjualan ditemukan, tidak memuat ulang API.');
      }

    } catch (e) {
      print("[EXCEPTION] $e");
      setState(() => _isLoading = false);
      _showDialog(context, 'Terjadi kesalahan: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    // 🆕 Tampilkan loading screen saat initializing
    if (_isInitializing) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber[400],
        title: Text('MILABUS Kru'),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: AbsorbPointer(
        // 🆕 Blokir semua input selama loading
        absorbing: _isLoading,
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 10.0),
                    SizedBox(
                      width: 300.0,
                      height: 300.0,
                      child: Image.asset(
                        'assets/images/mila_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your username';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16.0),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value!.isEmpty) {
                                  return 'Please enter your password';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 20.0),
                            Center(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF0101),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 14),
                                ),
                                child: _isLoading
                                    ? CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                    : Text(
                                  'Masuk',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 🆕 Overlay loading semi-transparent
            if (_isLoading)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 4.0,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Sedang memproses login...',
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

  // 🆕 Widget untuk menampilkan loading screen awal
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150.0,
              height: 150.0,
              child: Image.asset(
                'assets/images/mila_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 4.0,
            ),
            SizedBox(height: 20),
            Text(
              'Menyiapkan Aplikasi...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Harap tunggu sebentar',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}