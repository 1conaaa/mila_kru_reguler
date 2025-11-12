import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/page/logout_success_screen.dart';

class Logout extends StatelessWidget {
  Future<void> _clearData(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('token');
      prefs.remove('idGarasi');
      prefs.remove('idUser');
      prefs.remove('idBus');
      prefs.remove('noPol');
      prefs.remove('namaTrayek');
      prefs.remove('namaLengkap');
      prefs.remove('keydataPremiextra');
      prefs.remove('premiExtra');
      prefs.remove('keydataPremikru');
      prefs.remove('persenPremikru');

      DatabaseHelper databaseHelper = DatabaseHelper();
      await databaseHelper.initDatabase();
      await databaseHelper.clearUsersTable();
      await databaseHelper.clearKruBis();
      await databaseHelper.clearListKota();
      await databaseHelper.clearPenjualanTiket();
      await databaseHelper.clearResumeTransaksi();
      await databaseHelper.clearPremiHarianKru();
      await databaseHelper.clearPremiPosisiKru();
      await databaseHelper.clearInspectionItems();
      await databaseHelper.clearJenisPaket();
      await databaseHelper.clearOrderBagasi();
      await databaseHelper.clearOrderBagasiStatus();
      await databaseHelper.clearMetodePembayaran();
      await databaseHelper.clearTagTransaksi();
      await databaseHelper.closeDatabase();

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LogoutSuccessScreen()));
    } catch (e) {
      print('Error clearing data: $e');
      throw Exception('Gagal menghapus data pengguna.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700], // 🎨 Warna background biru muda
      body: Center(
        child: FutureBuilder(
          future: _clearData(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                color: Colors.blue, // warna indikator biru
              );
            } else if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              );
            } else {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16.0),
                  Image.asset(
                    'assets/images/logo_mila.png',
                    width: 150,
                    height: 150,
                  ),
                  const SizedBox(height: 24.0),
                  const Text(
                    'Anda telah berhasil keluar.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700], // tombol biru tua
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Masuk kembali',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

}
