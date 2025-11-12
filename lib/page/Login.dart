import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mila_kru_reguler/api/ApiHelperMetodePembayaran.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/api/ApiHelperPremiPosisiKru.dart';
import 'package:mila_kru_reguler/api/ApiHelperKruBis.dart';
import 'package:mila_kru_reguler/api/ApiHelperListKota.dart';
import 'package:mila_kru_reguler/api/ApiHelperOperasiHarianBus.dart';
import 'package:mila_kru_reguler/api/ApiHelperInspectionItems.dart';
import 'package:mila_kru_reguler/api/ApiHelperJenisPaket.dart';
import 'package:mila_kru_reguler/api/ApiHelperUser.dart';

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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    setState(() {
      _isLoading = true;
    });

    String username = _usernameController.text;
    String password = _passwordController.text;

    final response = await http.post(
      Uri.parse('https://apimila.sysconix.id/api/login?username=$username&password=$password'),
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
        // prefs.setBool('isLoggedIn', true);
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

        DatabaseHelper databaseHelper = DatabaseHelper();
        try {
          await databaseHelper.initDatabase();
          await databaseHelper.insertUser(user.toMap());
          print('Data berhasil disimpan:');
          await databaseHelper.closeDatabase();
        } catch (e) {
          print('Error: $e');
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

        List<Map<String, dynamic>> penjualanData = await databaseHelper.getDataPenjualan();
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

        } else {
          print('Data ditemukan dalam tabel Penjualan Tiket.');
        }


      } else {
        _showDialog(context, 'Anda gagal melakukan login. Silakan coba lagi.');
      }
    } else {
      _showDialog(context, 'Anda gagal melakukan login. Silakan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aplikasi BIS MILA BERKAH'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            SizedBox(height: 20.0),
            SizedBox(
              width: 200.0, // Atur lebar logo
              height: 200.0, // Atur tinggi logo
              child: Image.asset(
                'assets/images/logo_mila.png',
                fit: BoxFit.contain, // Menyesuaikan gambar dalam ukuran yang ditentukan
              ),
            ),
            SizedBox(height: 16.0),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(), // Menambahkan border pada TextFormField
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your username';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.0), // Menambahkan jarak antar form field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(), // Menambahkan border pada TextFormField
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : Text(
                            'Masuk',
                            style: TextStyle(color: Colors.white), // Menambahkan properti style untuk warna teks
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
