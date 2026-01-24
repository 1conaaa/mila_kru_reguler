import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionUtils {
  static Future<void> requestCameraPermission({
    required Function(String, String) showPermissionDialog,
    required Function() showOpenSettingsDialog,
  }) async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      showPermissionDialog(
        'Izin Kamera Diperlukan',
        'Aplikasi membutuhkan izin kamera untuk mengambil foto bukti transaksi.',
      );
    }

    if (status.isPermanentlyDenied) {
      showOpenSettingsDialog();
    }
  }

  static Future<void> requestGalleryPermission({
    required Function(String, String) showPermissionDialog,
    required Function() showOpenSettingsDialog,
  }) async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        showPermissionDialog(
          'Izin Penyimpanan Diperlukan',
          'Aplikasi membutuhkan izin akses penyimpanan untuk memilih foto dari galeri.',
        );
      }

      if (status.isPermanentlyDenied) {
        showOpenSettingsDialog();
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      if (status.isDenied) {
        showPermissionDialog(
          'Izin Foto Diperlukan',
          'Aplikasi membutuhkan izin akses foto untuk memilih gambar dari galeri.',
        );
      }

      if (status.isPermanentlyDenied) {
        showOpenSettingsDialog();
      }
    }
  }

  static void showPermissionDialogWidget({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  static void showOpenSettingsDialogWidget({
    required BuildContext context,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Izin Diperlukan'),
          content: Text('Izin diperlukan untuk mengakses kamera dan galeri. Silakan buka pengaturan untuk memberikan izin.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }
}