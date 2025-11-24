import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

class FieldWithLiterSolar extends StatelessWidget {
  final TagTransaksi tag;
  final Map<int, TextEditingController> controllers;
  final Map<int, TextEditingController> literSolarControllers;
  final bool Function(TagTransaksi) requiresLiterSolar;
  final Function(TagTransaksi, String) onChanged;

  /// Tambahkan opsi readOnly agar konsisten dengan aturan non-editable
  final bool readOnly;

  const FieldWithLiterSolar({
    Key? key,
    required this.tag,
    required this.controllers,
    required this.literSolarControllers,
    required this.requiresLiterSolar,
    required this.onChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final literController = literSolarControllers[tag.id];
    final nominalController = controllers[tag.id];

    return Column(
      children: [
        Row(
          children: [
            // ======= LITER SOLAR (SELALU EDITABLE JIKA DIBUTUHKAN) =======
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: literController,
                readOnly: readOnly, // Ikut readOnly kalau tag termasuk non-editable
                decoration: InputDecoration(
                  labelText: 'Liter Solar',
                  border: OutlineInputBorder(),
                  suffixText: 'L',
                  filled: readOnly,
                  fillColor: readOnly ? Colors.grey[100] : null,
                ),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (!readOnly) onChanged(tag, value);
                },
                validator: (value) {
                  if (value != null &&
                      value.isEmpty &&
                      requiresLiterSolar(tag)) {
                    return 'Liter Solar harus diisi';
                  }
                  return null;
                },
              ),
            ),

            const SizedBox(width: 8),

            // ======= NOMINAL =======
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: nominalController,
                readOnly: readOnly,
                decoration: InputDecoration(
                  labelText: tag.nama ?? 'Nominal',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                  filled: readOnly,
                  fillColor: readOnly ? Colors.grey[100] : null,
                ),
                textAlign: TextAlign.right,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  if (!readOnly) onChanged(tag, value);
                },
                validator: (value) {
                  if (value != null && value.isEmpty) {
                    return 'Nominal harus diisi';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
