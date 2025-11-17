import 'package:flutter/material.dart';

class KMPulangField extends StatelessWidget {
  final TextEditingController controller;

  const KMPulangField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'KM Pulang',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixText: ' ',
              prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
            ),
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            enabled: true,
            style: TextStyle(fontSize: 18),
            validator: (value) {
              if (value!.isEmpty) {
                return 'KM Masuk Garasi harus diisi';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}