import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {
  final String title;
  final ValueNotifier<String> messageNotifier;
  final bool isDismissible;

  const ProgressDialog({
    Key? key,
    this.title = 'Proses Simpan',
    required this.messageNotifier,
    this.isDismissible = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<String>(
              valueListenable: messageNotifier,
              builder: (context, value, child) {
                return Text(value);
              },
            ),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: isDismissible
          ? [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup (Debug)'),
        ),
      ]
          : null,
    );
  }
}
