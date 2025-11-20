import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/view/widgets/km_pulang_field.dart';
import 'package:mila_kru_reguler/view/widgets/kategori_section.dart';
import 'package:mila_kru_reguler/view/widgets/simpan_button.dart';

class ViewFormRekapTransaksi extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController kmMasukGarasiController;
  final List<TagTransaksi> tagPendapatan;
  final List<TagTransaksi> tagPengeluaran;
  final List<TagTransaksi> tagPremi;
  final List<TagTransaksi> tagBersihSetoran;
  final Map<int, TextEditingController> controllers;
  final Map<int, TextEditingController> jumlahControllers;
  final Map<int, TextEditingController> literSolarControllers;
  final Function(TagTransaksi, bool) onImageUpload;
  final Map<int, String> uploadedImages;
  final Function(TagTransaksi) onRemoveImage;
  final Function() onSimpan;
  final bool Function(TagTransaksi) isPengeluaran;
  final bool Function(TagTransaksi) requiresImage;
  final bool Function(TagTransaksi) requiresJumlah;
  final bool Function(TagTransaksi) requiresLiterSolar;
  final Function() onCalculatePremiBersih;
  final String? keydataPremiextra; // Tambahkan parameter ini

  ViewFormRekapTransaksi({
    Key? key,
    required this.formKey,
    required this.kmMasukGarasiController,
    required this.tagPendapatan,
    required this.tagPengeluaran,
    required this.tagPremi,
    required this.tagBersihSetoran,
    required this.controllers,
    required this.jumlahControllers,
    required this.literSolarControllers,
    required this.onImageUpload,
    required this.uploadedImages,
    required this.onRemoveImage,
    required this.onSimpan,
    required this.isPengeluaran,
    required this.requiresImage,
    required this.requiresJumlah,
    required this.requiresLiterSolar,
    required this.onCalculatePremiBersih,
    this.keydataPremiextra, // Tambahkan di constructor
  }) : super(key: key) {
    _debugConstructor();
  }

  void _debugConstructor() {
    print('=== DEBUG ViewFormRekapTransaksi Constructor ===');
    print('tagPendapatan: ${tagPendapatan.map((e) => '${e.id}-${e.nama}').toList()}');
    print('keydataPremiextra: $keydataPremiextra'); // Debug keydataPremiextra

    print('controllers content:');
    controllers.forEach((key, controller) {
      print('  $key: "${controller.text}"');
    });

    print('jumlahControllers content:');
    jumlahControllers.forEach((key, controller) {
      print('  $key: "${controller.text}"');
    });

    for (var tag in tagPendapatan) {
      print('Tag ${tag.id} (${tag.nama}):');
      print('  - controllers[${tag.id}]: "${controllers[tag.id]?.text}"');
      print('  - jumlahControllers[${tag.id}]: "${jumlahControllers[tag.id]?.text}"');
    }
  }

  // Tambahkan fungsi helper di class
  String _getKelasLayanan() {
    if (keydataPremiextra == null || keydataPremiextra!.isEmpty) {
      return '';
    }

    List<String> parts = keydataPremiextra!.split('_');
    if (parts.length >= 2) {
      return '${parts[0]}${parts[1]}'.toLowerCase();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    String kelasLayanan = _getKelasLayanan();

    print('=== [DEBUG] KELAS LAYANAN ===');
    print('keydataPremiextra: $keydataPremiextra');
    print('kelasLayanan: $kelasLayanan');
    print('=============================');

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 20,
        ),
        child: Column(
          children: [
            SizedBox(height: 40.0),
            Text(
              'Pencatatan Pendapatan & Pengeluaran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    SizedBox(height: 16.0),

                    // KM Pulang
                    KMPulangField(
                      controller: kmMasukGarasiController,
                    ),
                    SizedBox(height: 16.0),

                    // KATEGORI 1: PENDAPATAN
                    if (tagPendapatan.isNotEmpty)
                      KategoriSection(
                        title: 'Pendapatan',
                        color: Colors.blue,
                        tags: tagPendapatan,
                        showJumlah: true,
                        showLiterSolar: false,
                        controllers: controllers,
                        jumlahControllers: jumlahControllers,
                        literSolarControllers: literSolarControllers,
                        requiresImage: requiresImage,
                        requiresJumlah: requiresJumlah,
                        requiresLiterSolar: requiresLiterSolar,
                        onImageUpload: onImageUpload,
                        uploadedImages: uploadedImages,
                        onRemoveImage: onRemoveImage,
                        onFieldChanged: onCalculatePremiBersih,
                      ),

                    // KATEGORI 2: PENGELUARAN
                    if (tagPengeluaran.isNotEmpty)
                      KategoriSection(
                        title: 'Pengeluaran',
                        color: Colors.red,
                        tags: tagPengeluaran.where((tag) {
                          // Kondisi: jika kelasLayanan = 'akapekonomi', sembunyikan idTag 15
                          if (kelasLayanan.toLowerCase() == 'akapekonomi' && tag.id == 15) {
                            print('🚫 Menyembunyikan tag ID 15 (Biaya Tol) untuk kelasLayanan: $kelasLayanan');
                            return false;
                          }
                          return true;
                        }).toList(),
                        showJumlah: false,
                        showLiterSolar: true,
                        controllers: controllers,
                        jumlahControllers: jumlahControllers,
                        literSolarControllers: literSolarControllers,
                        requiresImage: requiresImage,
                        requiresJumlah: requiresJumlah,
                        requiresLiterSolar: requiresLiterSolar,
                        onImageUpload: onImageUpload,
                        uploadedImages: uploadedImages,
                        onRemoveImage: onRemoveImage,
                        onFieldChanged: onCalculatePremiBersih,
                      ),

                    // KATEGORI 3: PREMI
                    if (tagPremi.isNotEmpty)
                      KategoriSection(
                        title: 'Premi',
                        color: Colors.orange,
                        tags: tagPremi,
                        showJumlah: false,
                        showLiterSolar: false,
                        controllers: controllers,
                        jumlahControllers: jumlahControllers,
                        literSolarControllers: literSolarControllers,
                        requiresImage: requiresImage,
                        requiresJumlah: requiresJumlah,
                        requiresLiterSolar: requiresLiterSolar,
                        onImageUpload: onImageUpload,
                        uploadedImages: uploadedImages,
                        onRemoveImage: onRemoveImage,
                        onFieldChanged: onCalculatePremiBersih,
                      ),

                    // KATEGORI 4: BERSIH DAN SETORAN
                    if (tagBersihSetoran.isNotEmpty)
                      KategoriSection(
                        title: 'Bersih dan Setoran',
                        color: Colors.green,
                        tags: tagBersihSetoran,
                        showJumlah: false,
                        showLiterSolar: false,
                        controllers: controllers,
                        jumlahControllers: jumlahControllers,
                        literSolarControllers: literSolarControllers,
                        requiresImage: requiresImage,
                        requiresJumlah: requiresJumlah,
                        requiresLiterSolar: requiresLiterSolar,
                        onImageUpload: onImageUpload,
                        uploadedImages: uploadedImages,
                        onRemoveImage: onRemoveImage,
                        onFieldChanged: onCalculatePremiBersih,
                      ),

                    // Tombol Simpan
                    SimpanButton(onSimpan: onSimpan),

                    // Debug info (opsional, bisa dihapus di production)
                    if (kelasLayanan.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Kelas Layanan: $kelasLayanan',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}