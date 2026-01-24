import 'package:flutter/cupertino.dart';

class ValidationUtils {
  static String? validateRit(String? value) {
    if (value == null || value.isEmpty) {
      return 'Rit harus diisi';
    }
    return null;
  }

  static String? validateKmMasukGarasi(String? value) {
    if (value == null || value.isEmpty) {
      return 'KM masuk garasi harus diisi';
    }

    final km = double.tryParse(value);
    if (km == null) {
      return 'KM harus berupa angka';
    }

    if (km <= 0) {
      return 'KM harus lebih dari 0';
    }

    return null;
  }

  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }

    final numericValue = double.tryParse(value.replaceAll('.', '').replaceAll(',00', ''));
    if (numericValue == null) {
      return '$fieldName harus berupa angka';
    }

    return null;
  }

  static bool validateForm({
    required GlobalKey<FormState> formKey,
    required String ritValue,
  }) {
    if (ritValue.isEmpty) {
      return false;
    }

    return formKey.currentState?.validate() ?? false;
  }
}