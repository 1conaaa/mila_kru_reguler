import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/page/manifest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mila_kru_reguler/page/Home.dart';
import 'package:mila_kru_reguler/page/Login.dart';
import 'package:mila_kru_reguler/page/Logout.dart';
import 'package:mila_kru_reguler/page/PenjualanTiket.dart';
import 'package:mila_kru_reguler/page/RekapTransaksi.dart';
import 'package:mila_kru_reguler/page/BagasiBus.dart';
import 'package:mila_kru_reguler/page/LaporPerpal.dart';
import 'package:mila_kru_reguler/page/PengecekanBus.dart';
import 'package:mila_kru_reguler/page/bluetooth_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => BluetoothPrinterService()..checkConnection(),
        ),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BUS MILA SEJAHTERA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
        ),
      ),
      initialRoute: isLoggedIn ? '/' : '/login',
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
  final themeColor = Colors.deepOrange;

  return Drawer(
    child: Container(
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header Drawer dengan tema
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeColor,
                  themeColor.shade700,
                  themeColor.shade900,
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_bus_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'BUS MILA SEJAHTERA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Items dengan icon setema
          _buildDrawerItem(
            context: context,
            title: 'Home',
            icon: Icons.home_rounded,
            route: '/',
            themeColor: themeColor,
          ),

          _buildDrawerItem(
            context: context,
            title: 'Penjualan Tiket',
            icon: Icons.add_shopping_cart_rounded,
            route: '/penjualantiket',
            themeColor: themeColor,
          ),

          _buildDrawerItem(
            context: context,
            title: 'Penumpang',
            icon: Icons.people_alt_rounded,
            themeColor: themeColor,
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              final int? idJadwalTripInt = prefs.getInt('idJadwalTrip');
              final String idJadwalTrip = idJadwalTripInt?.toString() ?? '';
              String token = prefs.getString('token') ?? '';

              if (idJadwalTrip.isNotEmpty && token.isNotEmpty) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ManifestPage(
                        idJadwalTrip: idJadwalTrip,
                        token: token,
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data jadwal atau token tidak ditemukan.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),

          _buildDrawerItem(
            context: context,
            title: 'Rekap Transaksi',
            icon: Icons.receipt_rounded,
            route: '/rekaptransaksi',
            themeColor: themeColor,
          ),

          _buildDrawerItem(
            context: context,
            title: 'Bagasi Bus',
            icon: Icons.luggage_rounded,
            route: '/bagasibus',
            themeColor: themeColor,
          ),

          _buildDrawerItem(
            context: context,
            title: 'Pengecekan Bus',
            icon: Icons.check_circle_rounded,
            route: '/pengecekanbus',
            themeColor: themeColor,
          ),

          _buildDrawerItem(
            context: context,
            title: 'Lapor Perpal',
            icon: Icons.warning_rounded,
            route: '/laporperpal',
            themeColor: themeColor,
          ),

          const Divider(thickness: 1, height: 20),

          // Tombol Logout dengan styling khusus
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () => _showLogoutDialog(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Keluar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Keluar dari aplikasi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

// Helper widget untuk item drawer
Widget _buildDrawerItem({
  required BuildContext context,
  required String title,
  required IconData icon,
  String? route,
  VoidCallback? onTap,
  required Color themeColor,
}) {
  return ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: themeColor,
        size: 22,
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: Icon(
      Icons.chevron_right_rounded,
      color: Colors.grey.shade400,
      size: 20,
    ),
    onTap: () {
      if (route != null) {
        Navigator.pushNamed(context, route);
      } else if (onTap != null) {
        onTap();
      }
    },
  );
}

// Helper function untuk logout dialog
void _showLogoutDialog(BuildContext context) async {
  final bool? confirmLogout = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      final themeColor = Colors.deepOrange;

      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Konfirmasi Keluar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Apakah Anda yakin ingin keluar dari aplikasi?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Keluar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );

  if (confirmLogout == true && context.mounted) {
    Navigator.pushNamed(context, '/logout');
  }
}