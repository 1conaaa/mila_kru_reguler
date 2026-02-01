import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/utils/indonesian_number_input_formatter.dart';


class SingleField extends StatelessWidget {
  final TagTransaksi tag;
  final Map<int, TextEditingController> controllers;
  final Function(TagTransaksi, String) onChanged;
  final bool readOnly;

  const SingleField({
    Key? key,
    required this.tag,
    required this.controllers,
    required this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controllers[tag.id],
        decoration: InputDecoration(
          labelText: tag.nama ?? 'Field ${tag.id}',
          border: OutlineInputBorder(),
          prefixText: 'Rp ',
          filled: readOnly,
          fillColor: readOnly ? Colors.grey[200] : null,
        ),
        textAlign: TextAlign.right,
        keyboardType: TextInputType.number,
        readOnly: readOnly,
        enabled: !readOnly,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          IndonesianNumberInputFormatter(), // ✅ FORMAT RIBUAN
        ],
        onChanged: (value) => onChanged(tag, value),
        validator: (value) {
          if (value!.isEmpty) return '${tag.nama} harus diisi';
          return null;
        },
      ),
    );
  }
}

