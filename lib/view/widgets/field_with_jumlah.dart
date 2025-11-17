import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

class FieldWithJumlah extends StatelessWidget {
  final TagTransaksi tag;
  final Map<int, TextEditingController> controllers;
  final Map<int, TextEditingController> jumlahControllers;
  final Function(TagTransaksi, String) onChanged;

  const FieldWithJumlah({
    Key? key,
    required this.tag,
    required this.controllers,
    required this.jumlahControllers,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final jumlahController = jumlahControllers[tag.id];
    final nominalController = controllers[tag.id];

    return Column(
      children: [
        Row(
          children: [
            // Kolom Jumlah - READ ONLY (tampil aktif)
            Expanded(
              flex: 2,
              child: IgnorePointer(
                // Blok semua interaksi user
                child: TextFormField(
                  controller: jumlahController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => onChanged(tag, value),
                ),
              ),
            ),
            SizedBox(width: 8),

            // Kolom Nominal - READ ONLY (tampil aktif)
            Expanded(
              flex: 3,
              child: IgnorePointer(
                // Blok semua interaksi user
                child: TextFormField(
                  controller: nominalController,
                  decoration: InputDecoration(
                    labelText: tag.nama ?? 'Nominal',
                    border: OutlineInputBorder(),
                    prefixText: 'Rp ',
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) => onChanged(tag, value),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
      ],
    );
  }
}