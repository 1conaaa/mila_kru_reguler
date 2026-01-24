import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';

class ImageUploadUtils {
  static Future<void> onImageUpload({
    required TagTransaksi tag,
    required XFile image,
    required Function(File) setImageFile,
    required Function(String) setUploadedImage,
    required BuildContext context,
    required Function(TagTransaksi, File) showImagePreview,
    required Function(String) showErrorDialog,
  }) async {
    try {
      File imageFile = File(image.path);

      if (await imageFile.length() > 5 * 1024 * 1024) {
        showErrorDialog('Ukuran gambar terlalu besar. Maksimal 5MB.');
        return;
      }

      setImageFile(imageFile);
      setUploadedImage(image.path);

      print('=== DEBUG IMAGE UPLOAD ===');
      print('Tag ID        : ${tag.id}');
      print('Nama Tag      : ${tag.nama}');
      print('Image Path    : ${image.path}');
      print('File Exists   : ${imageFile.existsSync()}');
      print('===========================');

      await SetoranKruService().updateFilePath(tag.id, image.path);
      showImagePreview(tag, imageFile);
      print('Gambar berhasil diupload untuk ${tag.nama}: ${image.path}');
    } catch (e) {
      print('Error upload gambar: $e');
      showErrorDialog('Gagal mengupload gambar: $e');
    }
  }

  static void removeImage({
    required TagTransaksi tag,
    required Function(int) removeImageFile,
    required Function(int) removeUploadedImage,
    required BuildContext context,
  }) {
    removeImageFile(tag.id);
    removeUploadedImage(tag.id);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Gambar untuk ${tag.nama} telah dihapus'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}