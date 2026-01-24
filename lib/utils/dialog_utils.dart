import 'package:flutter/material.dart';

class DialogUtils {
  static void showErrorDialog({
    required BuildContext context,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static void showUnsentDataDialog({
    required BuildContext context,
    required int dataCount,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Data Belum Dikirim'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Masih ada transaksi penjualan yang belum dikirim.'),
                SizedBox(height: 8),
                Text('Jumlah: $dataCount'),
                SizedBox(height: 8),
                Text('Silakan kirim data tersebut terlebih dahulu di menu:\n👉 Penjualan Tiket → Transaksi.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  static void showErrorSavingDialog({
    required BuildContext context,
    required String errorMessage,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text('Error saat menyimpan'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Terjadi error: $errorMessage'),
                SizedBox(height: 8),
                Text('Lihat console log untuk stack trace lengkap.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}