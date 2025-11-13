import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

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
  final Map<int, String> uploadedImages; // Ganti dari _uploadedImages
  final Function(TagTransaksi) onRemoveImage;
  final Function() onSimpan;
  final bool Function(TagTransaksi) isPengeluaran;
  final bool Function(TagTransaksi) requiresImage;
  final bool Function(TagTransaksi) requiresJumlah;
  final bool Function(TagTransaksi) requiresLiterSolar;

  const ViewFormRekapTransaksi({
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
    required this.uploadedImages, // Parameter yang benar
    required this.onRemoveImage,
    required this.onSimpan,
    required this.isPengeluaran,
    required this.requiresImage,
    required this.requiresJumlah,
    required this.requiresLiterSolar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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

                    // KM Pulang (tetap statis)
                    _buildKMPulangField(),
                    SizedBox(height: 16.0),

                    // KATEGORI 1: PENDAPATAN
                    if (tagPendapatan.isNotEmpty)
                      _buildKategoriSection(
                        title: 'Pendapatan',
                        color: Colors.blue,
                        tags: tagPendapatan,
                        showJumlah: true,
                        showLiterSolar: false,
                      ),

                    // KATEGORI 2: PENGELUARAN
                    if (tagPengeluaran.isNotEmpty)
                      _buildKategoriSection(
                        title: 'Pengeluaran',
                        color: Colors.red,
                        tags: tagPengeluaran,
                        showJumlah: false,
                        showLiterSolar: true,
                      ),

                    // KATEGORI 3: PREMI
                    if (tagPremi.isNotEmpty)
                      _buildKategoriSection(
                        title: 'Premi',
                        color: Colors.orange,
                        tags: tagPremi,
                        showJumlah: false,
                        showLiterSolar: false,
                      ),

                    // KATEGORI 4: BERSIH DAN SETORAN
                    if (tagBersihSetoran.isNotEmpty)
                      _buildKategoriSection(
                        title: 'Bersih dan Setoran',
                        color: Colors.green,
                        tags: tagBersihSetoran,
                        showJumlah: false,
                        showLiterSolar: false,
                      ),

                    // Tombol Simpan
                    _buildSimpanButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKMPulangField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: kmMasukGarasiController,
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

  Widget _buildKategoriSection({
    required String title,
    required Color color,
    required List<TagTransaksi> tags,
    required bool showJumlah,
    required bool showLiterSolar,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16.0),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 8.0),
        ...tags.map((tag) => _buildDynamicField(
          tag: tag,
          showJumlah: showJumlah,
          showLiterSolar: showLiterSolar,
        )).toList(),
      ],
    );
  }

  Widget _buildDynamicField({
    required TagTransaksi tag,
    required bool showJumlah,
    required bool showLiterSolar,
  }) {
    return Column(
      children: [
        // Tampilkan field dengan layout yang sesuai
        if (showJumlah && requiresJumlah(tag))
          _buildFieldWithJumlah(tag)
        else if (showLiterSolar && requiresLiterSolar(tag))
          _buildFieldWithLiterSolar(tag)
        else if (showJumlah)
            _buildFieldWithJumlah(tag)
          else
            _buildSingleField(tag),

        // Upload gambar untuk pengeluaran tertentu
        if (requiresImage(tag))
          _buildImageUploadSection(tag),
      ],
    );
  }

  Widget _buildSingleField(TagTransaksi tag) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controllers[tag.id],
        decoration: InputDecoration(
          labelText: tag.nama ?? 'Field ${tag.id}',
          border: OutlineInputBorder(),
          alignLabelWithHint: true,
          prefixText: 'Rp ',
          prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
        ),
        textAlign: TextAlign.right,
        style: TextStyle(fontSize: 18),
        keyboardType: TextInputType.number,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly
        ],
        validator: (value) {
          if (value!.isEmpty) {
            return '${tag.nama} harus diisi';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildFieldWithJumlah(TagTransaksi tag) {
    return Column(
      children: [
        Row(
          children: [
            // Kolom Jumlah (kiri)
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: jumlahControllers[tag.id],
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (value) {
                  if (value!.isEmpty && requiresJumlah(tag)) {
                    return 'Jumlah harus diisi';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 8.0),
            // Kolom Nominal (kanan)
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: controllers[tag.id],
                decoration: InputDecoration(
                  labelText: tag.nama ?? 'Nominal',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                ),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Nominal harus diisi';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0),
      ],
    );
  }

  Widget _buildFieldWithLiterSolar(TagTransaksi tag) {
    return Column(
      children: [
        Row(
          children: [
            // Kolom Liter Solar (kiri)
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: literSolarControllers[tag.id],
                decoration: InputDecoration(
                  labelText: 'Liter Solar',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  suffixText: 'L',
                  suffixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                ),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (value) {
                  if (value!.isEmpty && requiresLiterSolar(tag)) {
                    return 'Liter Solar harus diisi';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 8.0),
            // Kolom Nominal (kanan)
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: controllers[tag.id],
                decoration: InputDecoration(
                  labelText: tag.nama ?? 'Nominal',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixText: 'Rp ',
                  prefixStyle: TextStyle(textBaseline: TextBaseline.alphabetic),
                ),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 18),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Nominal harus diisi';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0),
      ],
    );
  }

  Widget _buildImageUploadSection(TagTransaksi tag) {
    final bool hasImage = uploadedImages.containsKey(tag.id); // Gunakan uploadedImages bukan _uploadedImages

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kiri: Tombol upload
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Upload Bukti ${tag.nama}:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                ElevatedButton.icon(
                  onPressed: () => onImageUpload(tag, true),
                  icon: Icon(Icons.camera_alt),
                  label: Text('Ambil Foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                SizedBox(height: 8.0),
                ElevatedButton.icon(
                  onPressed: () => onImageUpload(tag, false),
                  icon: Icon(Icons.photo_library),
                  label: Text('Pilih dari Galeri'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                if (hasImage) ...[
                  SizedBox(height: 8.0),
                  OutlinedButton.icon(
                    onPressed: () => onRemoveImage(tag),
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Hapus Gambar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ],
            ),
          ),

          SizedBox(width: 16.0),

          // Kanan: Preview gambar
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: hasImage ? Colors.green : Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: hasImage
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 40),
                SizedBox(height: 4),
                Text(
                  'Gambar\nTerupload',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
                : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera, color: Colors.grey, size: 40),
                SizedBox(height: 4),
                Text(
                  'Belum Ada\nGambar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpanButton() {
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