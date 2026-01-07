import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';
import 'package:mila_kru_reguler/services/persen_premi_kru_service.dart';
import 'package:mila_kru_reguler/services/premi_posisi_kru_service.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/services/tag_transaksi_service.dart';
import 'package:mila_kru_reguler/page/logout_success_screen.dart';
import 'package:mila_kru_reguler/services/premi_harian_kru_service.dart';

class Logout extends StatelessWidget {
  Future<void> _clearData(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // ✅ Reset flag login
      await prefs.setBool('isLoggedIn', false);

      // Optional: clear data lain
      // prefs.clear(); // jika ingin clear semua key

      DatabaseHelper databaseHelper = DatabaseHelper.instance;
      await databaseHelper.initDatabase();

      // Inisialisasi services
      final penjualanTiketService = PenjualanTiketService.instance;
      final premiHarianKruService = PremiHarianKruService();
      final setoranKruService = SetoranKruService();
      final premiPosisiKruService = PremiPosisiKruService();
      final tagService = TagTransaksiService();
      final userService = UserService();
      final persenPremiKruService = PersenPremiKruService.instance;

      await userService.clearUsersTable();
      await databaseHelper.clearKruBis();
      await databaseHelper.clearListKota();
      await databaseHelper.clearRuteTrayekUrutan();
      await penjualanTiketService.clearPenjualanTiket();
      await databaseHelper.clearResumeTransaksi();
      await premiHarianKruService.clearPremiHarianKru();
      await setoranKruService.clearSetoran();
      await premiPosisiKruService.clearPremiPosisiKru();
      await databaseHelper.clearInspectionItems();
      await databaseHelper.clearJenisPaket();
      await databaseHelper.clearOrderBagasi();
      await databaseHelper.clearOrderBagasiStatus();
      await databaseHelper.clearMetodePembayaran();
      await tagService.clearTagTransaksi();
      await persenPremiKruService.clearTable();

      await databaseHelper.closeDatabase();

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => LogoutSuccessScreen()));
    } catch (e) {
      print('Error clearing data: $e');
      throw Exception('Gagal menghapus data pengguna.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: Center(
        child: FutureBuilder(
          future: _clearData(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                color: Colors.blueAccent,
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
                    'assets/images/mila_logo.png',
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
                      backgroundColor: Colors.blue[700],
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