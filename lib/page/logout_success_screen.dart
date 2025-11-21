import 'package:flutter/material.dart';

class LogoutSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700], // ✅ Tambahkan warna background di sini
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 16.0),
            Image.asset(
              'assets/images/logo_mila.png',
              width: 350,
            ),
            SizedBox(height: 16.0),
            Text(
              'Anda telah berhasil keluar.',
              style: TextStyle(
                color: Colors.white, // ✅ Teks jadi putih agar kontras dengan background biru
                fontSize: 18,
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, // tombol putih
                foregroundColor: Colors.black, // teks tombol biru
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text('Masuk kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
