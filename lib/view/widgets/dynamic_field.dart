import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/services/user_service.dart';
import 'package:mila_kru_reguler/view/widgets/single_field.dart';
import 'package:mila_kru_reguler/view/widgets/field_with_jumlah.dart';
import 'package:mila_kru_reguler/view/widgets/field_with_liter_solar.dart';
import 'package:mila_kru_reguler/view/widgets/image_upload_section.dart';

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
  int? idUser, idGroup, idCompany, idGarasi, idBus;
  String? noPol, kodeTrayek, namaTrayek, jenisTrayek, kelasBus;
  String? keydataPremiextra, keydataPremikru;
  double? premiExtra, persenPremikru;

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    final users = await _userService.getUsersRaw();

    if (!mounted || users.isEmpty) return;

    final u = users.first;

    setState(() {
      idUser = u['id_user'];
      idGroup = u['id_group'];
      idCompany = u['id_company'];
      idGarasi = u['id_garasi'];
      idBus = u['id_bus'];
      noPol = u['no_pol'];
      kodeTrayek = u['kode_trayek'];
      namaTrayek = u['nama_trayek'];
      jenisTrayek = u['jenis_trayek'];
      kelasBus = u['kelas_bus'];

      keydataPremiextra = u['keydata_premiextra'];
      premiExtra = (u['premi_extra'] as num?)?.toDouble();
      keydataPremikru = u['keydata_premikru'];
      persenPremikru = (u['persen_premikru'] as num?)?.toDouble();
    });
  }

  bool isNonEditable(TagTransaksi tag) {
    final name = tag.nama?.toLowerCase() ?? '';
    return name.contains("premi atas") ||
        name.contains("premi bawah") ||
        name.contains("pendapatan bersih") ||
        name.contains("pendapatan disetor");
  }

  @override
  Widget build(BuildContext context) {
    /// 🚫 ATURAN TAG YANG DISEMBUNYIKAN PER TRAYEK
    const Map<int, Set<String>> hiddenTagsByTrayek = {
      15: {
        '3471352901',
      },
      59: {
        '3471351002',
        '3471351001',
      },
    };

    final int tagId = widget.tag.id;
    final String? trayek = kodeTrayek;

    final bool shouldHideTag = trayek != null && hiddenTagsByTrayek.containsKey(tagId) && hiddenTagsByTrayek[tagId]!.contains(trayek);

    if (shouldHideTag) {
      print("=== [DEBUG] Tag ID $tagId disembunyikan | kodeTrayek=$trayek ===",);
      return const SizedBox.shrink();
    }

    print("=== [DEBUG] DynamicField Render === "
          "Tag ID: ${widget.tag.id}, Nama: ${widget.tag.nama}, "
          "kodeTrayek: $trayek",);

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
