import 'package:flutter/material.dart';

class SimpanButton extends StatelessWidget {
  final Function() onSimpan;

  const SimpanButton({
    Key? key,
    required this.onSimpan,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16.0),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: onSimpan,
                child: Text('Simpan'),
                style: ButtonStyle(
                  minimumSize: WidgetStateProperty.all(Size(double.infinity, 48.0)),
                  backgroundColor: WidgetStateProperty.all(Colors.green),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                ),
              ),
            ),
            SizedBox(width: 16.0),
          ],
        ),
      ],
    );
  }
}