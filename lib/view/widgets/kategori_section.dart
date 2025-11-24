import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'dynamic_field.dart';

class KategoriSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<TagTransaksi> tags;
  final bool showJumlah;
  final bool showLiterSolar;
  final Map<int, TextEditingController> controllers;
  final Map<int, TextEditingController> jumlahControllers;
  final Map<int, TextEditingController> literSolarControllers;
  final bool Function(TagTransaksi) requiresImage;
  final bool Function(TagTransaksi) requiresJumlah;
  final bool Function(TagTransaksi) requiresLiterSolar;
  final Function(TagTransaksi, XFile) onImageUpload;
  final Map<int, String> uploadedImages;
  final Function(TagTransaksi) onRemoveImage;
  final Function()? onFieldChanged; // Tambahkan parameter ini

  const KategoriSection({
    Key? key,
    required this.title,
    required this.color,
    required this.tags,
    required this.showJumlah,
    required this.showLiterSolar,
    required this.controllers,
    required this.jumlahControllers,
    required this.literSolarControllers,
    required this.requiresImage,
    required this.requiresJumlah,
    required this.requiresLiterSolar,
    required this.onImageUpload,
    required this.uploadedImages,
    required this.onRemoveImage,
    this.onFieldChanged, // Jadikan optional
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.0),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 8.0),
        ...tags.map((tag) => DynamicField(
          key: ValueKey(tag.id),
          tag: tag,
          showJumlah: showJumlah,
          showLiterSolar: showLiterSolar,
          controllers: controllers,
          jumlahControllers: jumlahControllers,
          literSolarControllers: literSolarControllers,
          requiresImage: requiresImage,
          requiresJumlah: requiresJumlah,
          requiresLiterSolar: requiresLiterSolar,
          onImageUpload: onImageUpload,
          uploadedImages: uploadedImages,
          onRemoveImage: onRemoveImage,
          onFieldChanged: (TagTransaksi changedTag, String value) {
            print("DEBUG: KategoriSection → Field changed for ${changedTag.nama}");
            if (onFieldChanged != null) {
              onFieldChanged!();
            }
          },
        )).toList(),
      ],
    );
  }
}