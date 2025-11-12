import 'package:flutter/material.dart';

class LogoutSuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 16.0),
            Image.asset('assets/images/logo_mila.png',),
            SizedBox(height: 16.0),
            Text('Anda telah berhasil keluar.'),
            ElevatedButton(
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
