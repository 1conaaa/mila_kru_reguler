import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/view/widgets/single_field.dart';
import 'package:mila_kru_reguler/view/widgets/field_with_jumlah.dart';
import 'package:mila_kru_reguler/view/widgets/field_with_liter_solar.dart';
import 'package:mila_kru_reguler/view/widgets/image_upload_section.dart';

class DynamicField extends StatelessWidget {
  final TagTransaksi tag;
  final bool showJumlah;
  final bool showLiterSolar;

  final Map<int, TextEditingController> controllers;
  final Map<int, TextEditingController> jumlahControllers;
  final Map<int, TextEditingController> literSolarControllers;

  final bool Function(TagTransaksi) requiresImage;
  final bool Function(TagTransaksi) requiresJumlah;
  final bool Function(TagTransaksi) requiresLiterSolar;

  final Function(TagTransaksi, String) onFieldChanged;
  final Function(TagTransaksi, XFile) onImageUpload;
  final Function(TagTransaksi) onRemoveImage;

  final Map<int, String> uploadedImages;

  const DynamicField({
    Key? key,
    required this.tag,
    required this.showJumlah,
    required this.showLiterSolar,
    required this.controllers,
    required this.jumlahControllers,
    required this.literSolarControllers,
    required this.requiresImage,
    required this.requiresJumlah,
    required this.requiresLiterSolar,
    required this.onFieldChanged,
    required this.onImageUpload,
    required this.uploadedImages,
    required this.onRemoveImage,
  }) : super(key: key);

  bool isNonEditable(TagTransaksi tag) {
    final name = tag.nama?.toLowerCase() ?? '';

    return name.contains("premi atas") ||
        name.contains("premi bawah") ||
        name.contains("pendapatan bersih") ||
        name.contains("pendapatan disetor");
  }

  @override
  Widget build(BuildContext context) {
    /// 🚫 SEMBUNYIKAN TAG ID = 15
    if (tag.id == 15) {
      print("=== [DEBUG] Tag ID 15 disembunyikan ===");
      return const SizedBox.shrink();
    }

    print(
        "=== [DEBUG] DynamicField Render === Tag ID: ${tag.id}, Nama: ${tag.nama}");

    return Column(
      children: [
        // PRIORITAS JUMLAH
        if (showJumlah && requiresJumlah(tag))
          FieldWithJumlah(
            tag: tag,
            controllers: controllers,
            jumlahControllers: jumlahControllers,
            readOnly: true,
            onChanged: (TagTransaksi changedTag, String value) {
              print(
                  "DEBUG: FieldWithJumlah changed → Tag ${changedTag.id}, Value: $value");
              onFieldChanged(changedTag, value);
            },
          )

        // PRIORITAS LITER SOLAR
        else if (showLiterSolar && requiresLiterSolar(tag))
          FieldWithLiterSolar(
            tag: tag,
            controllers: controllers,
            literSolarControllers: literSolarControllers,
            requiresLiterSolar: requiresLiterSolar,
            readOnly: isNonEditable(tag),
            onChanged: (TagTransaksi changedTag, String value) {
              print(
                  "DEBUG: FieldWithLiterSolar changed → Tag ${changedTag.id}, Value: $value");
              onFieldChanged(changedTag, value);
            },
          )

        // DEFAULT JUMLAH
        else if (showJumlah)
            FieldWithJumlah(
              tag: tag,
              controllers: controllers,
              jumlahControllers: jumlahControllers,
              readOnly: isNonEditable(tag),
              onChanged: (TagTransaksi changedTag, String value) {
                print(
                    "DEBUG: Default FieldWithJumlah → Tag ${changedTag.id}, Value: $value");
                onFieldChanged(changedTag, value);
              },
            )

          // DEFAULT SINGLE FIELD
          else
            SingleField(
              tag: tag,
              controllers: controllers,
              readOnly: isNonEditable(tag),
              onChanged: (TagTransaksi changedTag, String value) {
                print(
                    "DEBUG: SingleField changed → Tag ${changedTag.id}, Value: $value");
                onFieldChanged(changedTag, value);
              },
            ),

        // IMAGE UPLOAD
        if (requiresImage(tag))
          ImageUploadSection(
            tag: tag,
            onImageUpload: (TagTransaksi t, XFile isUploaded) {
              print("DEBUG: Image uploaded → Tag ${t.id}");
              onImageUpload(t, isUploaded);
            },
            uploadedImages: uploadedImages,
            onRemoveImage: (TagTransaksi t) {
              print("DEBUG: Image removed → Tag ${t.id}");
              onRemoveImage(t);
            },
          ),
      ],
    );
  }
}
