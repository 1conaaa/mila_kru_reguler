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

    if (!mounted) return;
    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse('https://apimila.milaberkah.com/api/login'),
        body: {
          'username': username,
          'password': password,
        },
      );

      ApiResponseUser api;
      try {
        api = ApiResponseUser.fromJson(jsonDecode(response.body));
      } catch (_) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showDialog(context, 'Username atau password salah.');
        return;
      }

      if (api.success != 1) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showDialog(context, 'Username atau password salah.');
        return;
      }

      final user = api.user;

      if (user.idBus == 0) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        _showDialog(
          context,
          'Login berhasil, tetapi Anda belum dijadwalkan bertugas.',
        );
        return;
      }

      // ================= SIMPAN DATA =================
      final prefs = await SharedPreferences.getInstance();

      final dataUserToSave = {
        "token": api.token,
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

      for (final e in dataUserToSave.entries) {
        final value = e.value;

        if (value is int) {
          await prefs.setInt(e.key, value);
        } else if (value is bool) {
          await prefs.setBool(e.key, value);
        } else if (value is double) {
          await prefs.setDouble(e.key, value);
        } else {
          await prefs.setString(e.key, value?.toString() ?? '');
        }
      }


      await prefs.setBool('isLoggedIn', true);

      try {
        await _userService.insertUser(user.toMap());
      } catch (_) {}

      // ================= LOAD DATA LANJUTAN (BACKGROUND) =================
      _loadInitialDataAfterLogin(api, user);

      if (!mounted) return;
      setState(() => _isLoading = false);

      // ================= PINDAH HALAMAN + KIRIM PESAN =================
      Navigator.pushReplacementNamed(
        context,
        '/',
        arguments: {
          'welcomeMessage':
          'Salam ${user.namaLengkap}, Anda sudah terdaftar bertugas pada Bis '
              '(${user.idBus})-${user.noPol} Trayek ${user.namaTrayek}. '
              'Selamat bertugas. Bismillah.',
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showDialog(context, 'Terjadi kesalahan jaringan.');
    }
  }


  Future<void> _loadInitialDataAfterLogin(
      ApiResponseUser api,
      User user,
      ) async {
    final String token = api.token;
    final int idBus = user.idBus;
    final int idGarasi = user.idGarasi;
    final String noPol = user.noPol ?? "";
    final String jenisTrayek = user.jenisTrayek ?? "";
    final String kodeTrayek = user.kodeTrayek ?? "";
    final String kelasBusRaw = user.kelasBus ?? "";

    try {
      // ===== CEK DATA LOKAL =====
      final penjualanData =
      await PenjualanTiketService.instance.getDataPenjualan();

      if (penjualanData.isNotEmpty) {
        print('[INIT] Data penjualan lokal ditemukan, skip load API');
        return;
      }

      print('[INIT] Tidak ada data penjualan, memuat data awal dari API...');

      // ===== API 1: Kru Bis (PENTING) =====
      try {
        await ApiHelperKruBis.requestKruBisAPI(
          token,
          idBus,
          noPol,
          idGarasi,
          context,
        );
      } catch (e) {
        print('[WARN] KruBis gagal: $e');
      }

      // ===== API 2: Persen Premi Kru (OPSIONAL) =====
      try {
        await ApiHelperPersenPremiKru.requestListPersenPremiAPI(
          token,
          kodeTrayek,
        );
      } catch (e) {
        print('[WARN] PersenPremiKru gagal: $e');
      }

      // ===== API 3: Kota =====
      try {
        await ApiHelperListKota.requestListKotaAPI(
          token,
          kodeTrayek,
        );
      } catch (e) {
        print('[WARN] ListKota gagal: $e');
      }

      // ===== API 4: Rute Trayek =====
      try {
        await ApiHelperRuteTrayekUrutan.requestRuteTrayekUrutanAPI(
          token,
          kodeTrayek,
        );
      } catch (e) {
        print('[WARN] RuteTrayekUrutan gagal: $e');
      }

      // ===== NORMALISASI KELAS BUS =====
      final List<String> kata = kelasBusRaw.split(' ');
      final List<String> kataFix = [];

      for (int i = 0; i < kata.length; i++) {
        if (i < kata.length - 1 &&
            kata[i].endsWith('-') &&
            kata[i + 1].startsWith('-')) {
          kataFix.add(kata[i] + kata[i + 1]);
          i++;
        } else {
          kataFix.add(kata[i]);
        }
      }

      final String kelasBusFinal = kataFix.join('');
      print('[INIT] kelasBusFinal = $kelasBusFinal');

      // ===== API 5: Metode Pembayaran =====
      try {
        await ApiHelperMetodePembayaran.fetchAndStoreMetodePembayaran(token);
      } catch (e) {
        print('[WARN] MetodePembayaran gagal: $e');
      }

      // ===== API 6: Premi Posisi Kru (RAWAN ERROR) =====
      try {
        await ApiHelperPremiPosisiKru.requestListPremiPosisiKruAPI(
          token,
          jenisTrayek,
          kelasBusFinal,
        );
      } catch (e) {
        print('[WARN] PremiPosisiKru gagal: $e');
      }

      // ===== API 7: Operasi Harian Bus =====
      try {
        await ApiHelperOperasiHarianBus.addListOperasiHarianBusAPI(
          token,
          idBus,
          noPol,
          kodeTrayek,
        );
      } catch (e) {
        print('[WARN] OperasiHarianBus gagal: $e');
      }

      // ===== API 8: Jenis Paket =====
      try {
        await ApiHelperJenisPaket.addListJenisPaketAPI(token);
      } catch (e) {
        print('[WARN] JenisPaket gagal: $e');
      }

      // ===== API 9: Tag Transaksi =====
      try {
        await ApiHelperTagTransaksi.fetchAndStoreTagTransaksi(token);
      } catch (e) {
        print('[WARN] TagTransaksi gagal: $e');
      }

      print('[INIT] Load initial data selesai (best effort)');

    } catch (e, st) {
      // ❌ TIDAK BOLEH CRASH
      print('[FATAL] Error load initial data');
      print(e);
      print(st);
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