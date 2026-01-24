import 'package:flutter/material.dart';
import 'dart:io';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

class ImageUploadDialog extends StatelessWidget {
  final TagTransaksi tag;
  final File imageFile;
  final VoidCallback onRemoveImage;
  final VoidCallback onConfirm;

  const ImageUploadDialog({
    Key? key,
    required this.tag,
    required this.imageFile,
    required this.onRemoveImage,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Preview Gambar - ${tag.nama}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.file(
            imageFile,
            width: 250,
            height: 250,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 16),
          const Text(
            'Gambar berhasil diupload',
            style: TextStyle(color: Colors.green),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            onRemoveImage();
            Navigator.of(context).pop(); // tutup dialog
          },
          child: const Text('Hapus'),
        ),
        TextButton(
          onPressed: () {
            onConfirm();                 // simpan / update state
            Navigator.of(context).pop(); // TUTUP DIALOG SAJA
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
