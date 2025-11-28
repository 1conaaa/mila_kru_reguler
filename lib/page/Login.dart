import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/api/ApiHelperMetodePembayaran.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/api/ApiHelperPremiPosisiKru.dart';
import 'package:mila_kru_reguler/api/ApiHelperKruBis.dart';
import 'package:mila_kru_reguler/api/ApiHelperListKota.dart';
import 'package:mila_kru_reguler/api/ApiHelperOperasiHarianBus.dart';
import 'package:mila_kru_reguler/api/ApiHelperInspectionItems.dart';
import 'package:mila_kru_reguler/api/ApiHelperJenisPaket.dart';
import 'package:mila_kru_reguler/api/ApiHelperUser.dart';
import 'package:mila_kru_reguler/api/ApiHelperTagTransaksi.dart';

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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Result'),
          content: Text(message),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Masuk'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    if (_isLoading || _isInitializing) return; // 🆕 Prevent login during initialization

    setState(() {
      _isLoading = true;
    });

    String username = _usernameController.text;
    String password = _passwordController.text;

    try {
      final response = await http.post(
        Uri.parse('https://apimila.milaberkah.com/api/login?username=$username&password=$password'),
        body: {
          'username': username,
          'password': password,
        },
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ApiResponseUser apiResponseUser = ApiResponseUser.fromJson(jsonDecode(response.body));
        if (apiResponseUser.success == 1) {
          // If login success, save the status to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          User user = apiResponseUser.user;
          await prefs.setString('token', apiResponseUser.token);
          await prefs.setInt('idGroup', user.idGroup);
          await prefs.setInt('idUser', user.idUser);
          await prefs.setInt('idCompany', user.idCompany);
          await prefs.setInt('idGarasi', user.idGarasi);
          await prefs.setInt('idBus', user.idBus);
          await prefs.setString('noPol', user.noPol);
          await prefs.setString('namaLengkap', user.namaLengkap);
          await prefs.setString('namaUser', user.namaUser);
          await prefs.setString('password', user.password);
          await prefs.setString('foto', user.foto);
          await prefs.setString('group_name', user.groupName);
          await prefs.setString('kode_trayek', user.kodeTrayek);
          await prefs.setString('namaTrayek', user.namaTrayek);
          await prefs.setString('rute', user.rute);
          await prefs.setString('jenisTrayek', user.jenisTrayek);
          await prefs.setString('kelasBus', user.kelasBus);
          await prefs.setString('premiExtra', user.premiExtra);
          await prefs.setString('keydataPremiextra', user.keydataPremiextra);
          await prefs.setString('keydataPremikru', user.keydataPremikru);
          await prefs.setString('persenPremikru', user.persenPremikru);
          await prefs.setString('idJadwalTrip', user.idJadwalTrip);
          await prefs.setString('tagTransaksiPendapatan', user.tagTransaksiPendapatan);
          await prefs.setString('tagTransaksiPengeluaran', user.tagTransaksiPengeluaran);
          await prefs.setString('coaPendapatanBus', user.coaPendapatanBus);
          await prefs.setString('coaPengeluaranBus', user.coaPengeluaranBus);
          await prefs.setString('coaUtangPremi', user.coaUtangPremi);
          await prefs.setString('noKontak', user.noKontak);
          await prefs.setString('persenSusukanKru', user.persenSusukanKru);

          // 🧩 Tambahkan print untuk memeriksa nilainya
          print("=== DATA TAG TRANSAKSI ===");
          print("Pendapatan: ${user.tagTransaksiPendapatan}");
          print("Pengeluaran: ${user.tagTransaksiPengeluaran}");
          print("COA Pendapatan: ${user.coaPendapatanBus}");
          print("COA Pengeluaran: ${user.coaPengeluaranBus}");
          print("COA Utang Premi: ${user.coaUtangPremi}");
          print("No Kontak: ${user.noKontak}");
          print("Persen Susukan Kru: ${user.persenSusukanKru}");
          print("===========================");

          try {
            await _userService.insertUser(user.toMap());
            print('User data saved successfully');
          } catch (e) {
            print('Error saving user data: $e');
          }

          Navigator.pushReplacementNamed(context, '/');

          _showDialog(
            context,
            'Salam ${user.namaLengkap}, Saat ini Anda berserta kru yang lain sudah terdaftar untuk bertugas hari ini pada Bis (${user.idBus})-${user.noPol} pada Trayek ${user.namaTrayek}, Selamat Bertugas. Bismillah.',
          );

          String token = apiResponseUser.token;
          int idBus = user.idBus;
          String noPol = user.noPol;
          int idGarasi = user.idGarasi;
          String namaTrayek = user.namaTrayek;
          String jenisTrayek = user.jenisTrayek;
          String kodeTrayek = user.kodeTrayek;
          String kelasbus = user.kelasBus;
          String keydataPremiextra = user.keydataPremiextra;
          String premiExtra = user.premiExtra;
          String keydataPremikru = user.keydataPremikru;
          String persenPremikru = user.persenPremikru;

          List<Map<String, dynamic>> penjualanData = await PenjualanTiketService.instance.getDataPenjualan();
          setState(() {
            listPenjualan = penjualanData;
          });

          if (listPenjualan.isEmpty) {
            print('Tidak ada data dalam tabel Penjualan Tiket.');
            await ApiHelperKruBis.requestKruBisAPI(token, idBus, noPol, idGarasi, context);
            await ApiHelperListKota.requestListKotaAPI(token, namaTrayek);

            List<String> kata = kelasbus.split(" ");
            int jumlahKata = kata.length;
            print("Jumlah kata dalam kelasBus: $jumlahKata");

            List<String> kataTerbaru = [];
            for (int i = 0; i < kata.length; i++) {
              if (i < kata.length - 1) {
                if (kata[i].endsWith("-") && kata[i + 1].startsWith("-")) {
                  String gabunganKata = kata[i] + kata[i + 1];
                  kataTerbaru.add(gabunganKata);
                  i++;
                } else {
                  kataTerbaru.add(kata[i]);
                }
              } else {
                kataTerbaru.add(kata[i]);
              }
            }

            jumlahKata = kataTerbaru.length;
            print("Jumlah kata setelah penggabungan: $jumlahKata");

            String kelasBus = kataTerbaru.join("");
            print("Kata-kata setelah penggabungan: $kelasBus");

            await ApiHelperMetodePembayaran.fetchAndStoreMetodePembayaran(token);
            await ApiHelperPremiPosisiKru.requestListPremiPosisiKruAPI(token, jenisTrayek, kelasBus);
            await ApiHelperOperasiHarianBus.addListOperasiHarianBusAPI(token, idBus, noPol, kodeTrayek);
            await ApiHelperInspectionItems.addListInspectionItemsAPI(token);
            await ApiHelperJenisPaket.addListJenisPaketAPI(token);
            await ApiHelperTagTransaksi.fetchAndStoreTagTransaksi(token);

          } else {
            print('Data ditemukan dalam tabel Penjualan Tiket.');
          }

        } else {
          _showDialog(context, 'Anda gagal melakukan login. Silakan coba lagi.');
        }
      } else {
        _showDialog(context, 'Anda gagal melakukan login. Silakan coba lagi.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
        title: Text('Aplikasi BIS MILA SEJAHTERA'),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.blue[700],
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
                    SizedBox(height: 20.0),
                    SizedBox(
                      width: 200.0,
                      height: 200.0,
                      child: Image.asset(
                        'assets/images/logo_mila.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: 16.0),
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
                                  backgroundColor: Colors.redAccent,
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
                'assets/images/logo_mila.png',
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