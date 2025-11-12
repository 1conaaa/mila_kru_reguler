import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/page/Home.dart';
import 'package:mila_kru_reguler/page/Login.dart';
import 'package:mila_kru_reguler/page/Logout.dart';
import 'package:mila_kru_reguler/page/PenjualanTiket.dart';
import 'package:mila_kru_reguler/page/RekapTransaksi.dart';
import 'package:mila_kru_reguler/page/BagasiBus.dart';
import 'package:mila_kru_reguler/page/LaporPerpal.dart';
import 'package:mila_kru_reguler/page/PengecekanBus.dart';
import 'package:mila_kru_reguler/page/manifest.dart';
import 'package:mila_kru_reguler/page/bluetooth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  // Inisialisasi WebView sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();
  final printerService = BluetoothPrinterService();
  printerService.checkConnection();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MILA BERKAH',
      debugShowCheckedModeBanner: false, // Menyembunyikan label debuga
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (BuildContext context) => Login(),
        '/': (BuildContext context) => Home(),
        '/penjualantiket': (BuildContext context) => PenjualanTiket(),
        '/rekaptransaksi': (BuildContext context) => RekapTransaksi(),
        '/bagasibus': (BuildContext context) => BagasiBus(),
        '/laporperpal': (BuildContext context) => LaporKondisiBus(),
        '/pengecekanbus': (BuildContext context) => PengecekanBus(),
        '/logout': (BuildContext context) => Logout(),
      },
    );
  }
}

Drawer buildDrawer(BuildContext context, int idUser) {
  return Drawer(
    child: ListView(
      children: <Widget>[
        ListTile(
          title: Text('Home'),
          leading: Icon(Icons.home),
          onTap: () {
            Navigator.pushNamed(context, '/');
          },
        ),
        Divider(),
        ListTile(
          title: Text('Penjualan Tiket'),
          leading: Icon(Icons.add_shopping_cart),
          onTap: () {
            Navigator.pushNamed(context, '/penjualantiket');
          },
        ),
        // const Divider(),
        // ListTile(
        //   title: const Text('Penumpang'),
        //   leading: const Icon(Icons.people_alt_outlined),
        //   onTap: () async {
        //     // 🔹 Ambil data dari SharedPreferences untuk dikirim ke ManifestPage
        //     SharedPreferences prefs = await SharedPreferences.getInstance();
        //     String idJadwalTrip = prefs.getString('idJadwalTrip') ?? '';
        //     String token = prefs.getString('token') ?? '';
        //
        //     if (idJadwalTrip.isNotEmpty && token.isNotEmpty) {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => ManifestPage(
        //             idJadwalTrip: idJadwalTrip,
        //             token: token,
        //           ),
        //         ),
        //       );
        //     } else {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(
        //           content: Text('Data jadwal atau token tidak ditemukan.'),
        //         ),
        //       );
        //     }
        //   },
        // ),
        Divider(),
        ListTile(
          title: Text('Rekap Transaksi'),
          leading: Icon(Icons.dock_outlined),
          onTap: () {
            Navigator.pushNamed(context, '/rekaptransaksi');
          },
        ),
        Divider(),
        ListTile(
          title: Text('Bagasi Bus'),
          leading: Icon(Icons.cases_sharp),
          onTap: () {
            Navigator.pushNamed(context, '/bagasibus');
          },
        ),
        Divider(),
        ListTile(
          title: Text('Pengecekan Bus'),
          leading: Icon(Icons.check_circle_outline),
          onTap: () {
            Navigator.pushNamed(context, '/pengecekanbus');
          },
        ),
        Divider(),
        ListTile(
          title: Text('Lapor Perpal'),
          leading: Icon(Icons.bus_alert_sharp),
          onTap: () {
            Navigator.pushNamed(context, '/laporperpal');
          },
        ),
        Divider(),
        ListTile(
          title: Text('Keluar'),
          leading: Icon(Icons.logout),
          onTap: () {
            Navigator.pushNamed(context, '/logout');
          },
        ),
      ],
    ),
  );
}
