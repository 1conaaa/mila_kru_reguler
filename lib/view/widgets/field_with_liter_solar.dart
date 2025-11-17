import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

class FieldWithLiterSolar extends StatelessWidget {
  final TagTransaksi tag;
  final Map<int, TextEditingController> controllers;
  final Map<int, TextEditingController> literSolarControllers;
  final bool Function(TagTransaksi) requiresLiterSolar;
  final Function(TagTransaksi, String) onChanged;

  const FieldWithLiterSolar({
    Key? key,
    required this.tag,
    required this.controllers,
    required this.literSolarControllers,
    required this.requiresLiterSolar,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Liter Solar
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: literSolarControllers[tag.id],
                decoration: InputDecoration(
                  labelText: 'Liter Solar',
                  border: OutlineInputBorder(),
                  suffixText: 'L',
                ),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => onChanged(tag, value),
                validator: (value) {
                  if (value!.isEmpty && requiresLiterSolar(tag)) {
                    return 'Liter Solar harus diisi';
                  }
                  return null;
                },
              ),
            ),

            SizedBox(width: 8),

            // Nominal
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: controllers[tag.id],
                decoration: InputDecoration(
                  labelText: tag.nama ?? 'Nominal',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) => onChanged(tag, value),
                validator: (value) {
                  if (value!.isEmpty) return 'Nominal harus diisi';
                  return null;
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
