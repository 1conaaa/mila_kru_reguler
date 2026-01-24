import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

class FormResetUtils {
  static void resetAllControllers({
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
    required List<TextEditingController> additionalControllers,
  }) {
    // Reset semua controller berdasarkan tag
    controllers.forEach((key, controller) => controller.clear());
    jumlahControllers.forEach((key, controller) => controller.clear());
    literSolarControllers.forEach((key, controller) => controller.clear());

    // Reset controller tambahan
    for (var controller in additionalControllers) {
      controller.clear();
    }

    print('✅ Form berhasil direset');
  }

  static void clearImageFiles({
    required Map<int, File?> imageFiles,
    required Map<int, String> uploadedImages,
  }) {
    imageFiles.clear();
    uploadedImages.clear();
  }

  static void initializeControllers({
    required List<TagTransaksi> tags,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
  }) {
    for (final tag in tags) {
      controllers.putIfAbsent(tag.id, () => TextEditingController());
      jumlahControllers.putIfAbsent(tag.id, () => TextEditingController());
      literSolarControllers.putIfAbsent(tag.id, () => TextEditingController());
    }
  }
}