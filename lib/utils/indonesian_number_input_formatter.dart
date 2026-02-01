import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class IndonesianNumberInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter =
  NumberFormat.decimalPattern('id_ID');

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Kalau kosong, biarkan
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Hapus titik
    final cleanText = newValue.text.replaceAll('.', '');

    final int? value = int.tryParse(cleanText);
    if (value == null) {
      return oldValue;
    }

    final formatted = _formatter.format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}
