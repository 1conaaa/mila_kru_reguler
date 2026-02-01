import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/utils/indonesian_number_input_formatter.dart';

class FieldWithJumlah extends StatelessWidget {
  final TagTransaksi tag;
  final Map<int, TextEditingController> controllers;
  final Map<int, TextEditingController> jumlahControllers;
  final Function(TagTransaksi, String) onChanged;

  // ➕ Tambahkan parameter readOnly
  final bool readOnly;

  const FieldWithJumlah({
    Key? key,
    required this.tag,
    required this.controllers,
    required this.jumlahControllers,
    required this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final jumlahController = jumlahControllers[tag.id];
    final nominalController = controllers[tag.id];

    return Column(
      children: [
        Row(
          children: [
            // Kolom Jumlah (selalu readOnly)
            Expanded(
              flex: 2,
              child: IgnorePointer(
                child: TextFormField(
                  controller: jumlahController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ),

            SizedBox(width: 8),

            // Kolom Nominal (readOnly / editable)
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: nominalController,
                readOnly: readOnly,                  // ← LOCK FIELD
                decoration: InputDecoration(
                  labelText: tag.nama ?? 'Nominal',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  filled: readOnly,                  // beri warna bila dikunci
                  fillColor: readOnly ? Colors.grey[100] : null,
                ),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,IndonesianNumberInputFormatter(),
                ],
                onChanged: (value) {
                  if (!readOnly) onChanged(tag, value);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
