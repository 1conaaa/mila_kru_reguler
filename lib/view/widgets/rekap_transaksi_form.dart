import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mila_kru_reguler/view/View_FormSetoran.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

class RekapTransaksiForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController kmMasukGarasiController;

  // 🔥 TAMBAHAN
  final TextEditingController nominalPersenSusukanController;

  final List<TagTransaksi> tagPendapatan;
  final List<TagTransaksi> tagPengeluaran;
  final List<TagTransaksi> tagPremi;
  final List<TagTransaksi> tagBersihSetoran;
  final List<TagTransaksi> tagSusukan;
  final Map<int, TextEditingController> controllers;
  final Map<int, TextEditingController> jumlahControllers;
  final Map<int, TextEditingController> literSolarControllers;
  final Function(TagTransaksi, XFile) onImageUpload;
  final Map<int, String> uploadedImages;
  final Function(TagTransaksi) onRemoveImage;
  final Function() onSimpan;
  final bool Function(TagTransaksi) isPengeluaran;
  final bool Function(TagTransaksi) requiresImage;
  final bool Function(TagTransaksi) requiresJumlah;
  final bool Function(TagTransaksi) requiresLiterSolar;
  final Function() onCalculatePremiBersih;
  final String? keydataPremiextra;

  const RekapTransaksiForm({
    Key? key,
    required this.formKey,
    required this.kmMasukGarasiController,

    // 🔥 WAJIB DI-CONSTRUCTOR
    required this.nominalPersenSusukanController,

    required this.tagPendapatan,
    required this.tagPengeluaran,
    required this.tagPremi,
    required this.tagBersihSetoran,
    required this.tagSusukan,
    required this.controllers,
    required this.jumlahControllers,
    required this.literSolarControllers,
    required this.onImageUpload,
    required this.uploadedImages,
    required this.onRemoveImage,
    required this.onSimpan,
    required this.isPengeluaran,
    required this.requiresImage,
    required this.requiresJumlah,
    required this.requiresLiterSolar,
    required this.onCalculatePremiBersih,
    this.keydataPremiextra,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewFormRekapTransaksi(
      formKey: formKey,
      kmMasukGarasiController: kmMasukGarasiController,

      // 🔥 TERUSKAN KE VIEW
      nominalPersenSusukanController: nominalPersenSusukanController,

      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      tagSusukan: tagSusukan,
      controllers: controllers,
      jumlahControllers: jumlahControllers,
      literSolarControllers: literSolarControllers,
      onImageUpload: onImageUpload,
      uploadedImages: uploadedImages,
      onRemoveImage: onRemoveImage,
      onSimpan: onSimpan,
      isPengeluaran: isPengeluaran,
      requiresImage: requiresImage,
      requiresJumlah: requiresJumlah,
      requiresLiterSolar: requiresLiterSolar,
      onCalculatePremiBersih: onCalculatePremiBersih,
      keydataPremiextra: keydataPremiextra,
    );
  }
}
