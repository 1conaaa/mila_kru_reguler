import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:mila_kru_reguler/view/widgets/single_field.dart';
import 'package:mila_kru_reguler/view/widgets/field_with_jumlah.dart';
import 'package:mila_kru_reguler/view/widgets/field_with_liter_solar.dart';
import 'package:mila_kru_reguler/view/widgets/image_upload_section.dart';

num parseNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String && value.trim().isNotEmpty) {
    return num.tryParse(value) ?? 0;
  }
  return 0;
}

class DynamicField extends StatefulWidget {
  final TagTransaksi tag;
  final bool showJumlah;
  final bool showLiterSolar;

  final Map<int, TextEditingController> controllers;
  final Map<int, TextEditingController> jumlahControllers;
  final Map<int, TextEditingController> literSolarControllers;

  final bool Function(TagTransaksi) requiresImage;
  final bool Function(TagTransaksi) requiresJumlah;
  final bool Function(TagTransaksi) requiresLiterSolar;

  final Function(TagTransaksi, String) onFieldChanged;
  final Function(TagTransaksi, XFile) onImageUpload;
  final Function(TagTransaksi) onRemoveImage;

  final Map<int, String> uploadedImages;

  const DynamicField({
    super.key,
    required this.tag,
    required this.showJumlah,
    required this.showLiterSolar,
    required this.controllers,
    required this.jumlahControllers,
    required this.literSolarControllers,
    required this.requiresImage,
    required this.requiresJumlah,
    required this.requiresLiterSolar,
    required this.onFieldChanged,
    required this.onImageUpload,
    required this.uploadedImages,
    required this.onRemoveImage,
  });

  @override
  State<DynamicField> createState() => _DynamicFieldState();
}

class _DynamicFieldState extends State<DynamicField> {
  final UserService _userService = UserService();

  /// DATA USER
  String? kodeTrayek;
  Set<int> tagPengeluaranSet = {};

  /// TAG PENDAPATAN (HARUS SELALU TAMPIL)
  static const Set<int> tagPendapatanSet = {1, 2, 3, 71};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final users = await _userService.getUsersRaw();
    if (!mounted || users.isEmpty) return;

    final u = users.first;

    final rawTagPengeluaran = u['tag_transaksi_pengeluaran']?.toString() ?? '';

    final parsedSet = rawTagPengeluaran
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();

    setState(() {
      tagPengeluaranSet = parsedSet;
      kodeTrayek = u['kode_trayek']?.toString();
    });

    print("=== TAG PENGELUARAN AKTIF: $tagPengeluaranSet ===");
  }

  bool isNonEditable(TagTransaksi tag) {
    final name = tag.nama?.toLowerCase() ?? '';
    return name.contains('premi') || name.contains('bersih') || name.contains('disetor') || name.contains('susukan');
  }

  @override
  Widget build(BuildContext context) {
    /// 🔹 ATURAN KHUSUS TRAYEK
    const Map<int, Set<String>> hiddenTagsByTrayek = {
      15: {'3471352901','3471351002', '3471351001'},
      59: {'3471351002', '3471351001'},
    };

    final int tagId = widget.tag.id;
    final String? trayek = kodeTrayek;

    /// 1️⃣ FILTER TAG PENGELUARAN (BUKAN PENDAPATAN)
    if (!tagPendapatanSet.contains(tagId)) {
      if (tagPengeluaranSet.isNotEmpty &&
          !tagPengeluaranSet.contains(tagId)) {
        debugPrint(
          "=== [HIDE] Tag $tagId bukan bagian dari tagTransaksiPengeluaran ===",
        );
        return const SizedBox.shrink();
      }
    }

    /// 2️⃣ FILTER KHUSUS TRAYEK
    if (trayek != null &&
        hiddenTagsByTrayek[tagId]?.contains(trayek) == true) {
      debugPrint(
        "=== [HIDE] Tag $tagId disembunyikan oleh trayek $trayek ===",
      );
      return const SizedBox.shrink();
    }

    /// 3️⃣ RENDER FIELD
    return Column(
      children: [
        if (widget.showJumlah && widget.requiresJumlah(widget.tag))
          FieldWithJumlah(
            tag: widget.tag,
            controllers: widget.controllers,
            jumlahControllers: widget.jumlahControllers,
            readOnly: true,
            onChanged: widget.onFieldChanged,
          )
        else if (widget.showLiterSolar &&
            widget.requiresLiterSolar(widget.tag))
          FieldWithLiterSolar(
            tag: widget.tag,
            controllers: widget.controllers,
            literSolarControllers: widget.literSolarControllers,
            requiresLiterSolar: widget.requiresLiterSolar,
            readOnly: isNonEditable(widget.tag),
            onChanged: widget.onFieldChanged,
          )
        else if (widget.showJumlah)
            FieldWithJumlah(
              tag: widget.tag,
              controllers: widget.controllers,
              jumlahControllers: widget.jumlahControllers,
              readOnly: isNonEditable(widget.tag),
              onChanged: widget.onFieldChanged,
            )
          else
            SingleField(
              tag: widget.tag,
              controllers: widget.controllers,
              readOnly: isNonEditable(widget.tag),
              onChanged: widget.onFieldChanged,
            ),

        if (widget.requiresImage(widget.tag))
          ImageUploadSection(
            tag: widget.tag,
            uploadedImages: widget.uploadedImages,
            onImageUpload: widget.onImageUpload,
            onRemoveImage: widget.onRemoveImage,
          ),
      ],
    );
  }
}
