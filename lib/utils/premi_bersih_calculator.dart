import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

// Pindahkan TagData ke luar class PremiBersihCalculator
class TagData {
  final int id;
  final String nama;
  final int nominal;
  final int jumlah;
  final int literSolar;
  final TagTransaksi tagTransaksi;

  TagData({
    required this.id,
    required this.nama,
    required this.nominal,
    required this.jumlah,
    required this.literSolar,
    required this.tagTransaksi,
  });

  @override
  String toString() {
    return 'TagData{id: $id, nama: $nama, nominal: $nominal, jumlah: $jumlah, literSolar: $literSolar}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nominal': nominal,
      'jumlah': jumlah,
      'literSolar': literSolar,
    };
  }
}

class PremiBersihCalculator {
  /// Mengumpulkan data dari semua kategori tag
  static Map<String, List<TagData>> collectAllTagData({
    required List<TagTransaksi> tagPendapatan,
    required List<TagTransaksi> tagPengeluaran,
    required List<TagTransaksi> tagPremi,
    required List<TagTransaksi> tagBersihSetoran,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
  }) {
    final pendapatanData = _collectTagData(tagPendapatan, controllers, jumlahControllers, literSolarControllers);
    final pengeluaranData = _collectTagData(tagPengeluaran, controllers, jumlahControllers, literSolarControllers);
    final premiData = _collectTagData(tagPremi, controllers, jumlahControllers, literSolarControllers);
    final bersihSetoranData = _collectTagData(tagBersihSetoran, controllers, jumlahControllers, literSolarControllers);

    return {
      'pendapatan': pendapatanData,
      'pengeluaran': pengeluaranData,
      'premi': premiData,
      'bersihSetoran': bersihSetoranData,
    };
  }

  /// Method utama untuk kalkulasi premi bersih
  static Map<String, dynamic> calculatePremiBersih({
    required List<TagTransaksi> tagPendapatan,
    required List<TagTransaksi> tagPengeluaran,
    required List<TagTransaksi> tagPremi,
    required List<TagTransaksi> tagBersihSetoran,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
  }) {
    final allData = collectAllTagData(
      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      controllers: controllers,
      jumlahControllers: jumlahControllers,
      literSolarControllers: literSolarControllers,
    );

    final pendapatanData = allData['pendapatan']!;
    final pengeluaranData = allData['pengeluaran']!;
    final premiData = allData['premi']!;

    // Kalkulasi total pendapatan
    final totalPendapatan = _calculateTotal(pendapatanData);

    // Kalkulasi total pengeluaran
    final totalPengeluaran = _calculateTotal(pengeluaranData);

    // Cari premi atas (ID 27) dan premi bawah (ID 32)
    final premiAtas = _findTagById(premiData, 27);
    final premiBawah = _findTagById(premiData, 32);

    // Kalkulasi pendapatan bersih
    final pendapatanBersih = totalPendapatan - totalPengeluaran;

    // Kalkulasi pendapatan disetor
    final pendapatanDisetor = pendapatanBersih - premiAtas.nominal - premiBawah.nominal;

    // Debug output
    _printDebugInfo(
      totalPendapatan,
      totalPengeluaran,
      pendapatanBersih,
      premiAtas,
      premiBawah,
      pendapatanDisetor,
    );

    return {
      'totalPendapatan': totalPendapatan,
      'totalPengeluaran': totalPengeluaran,
      'pendapatanBersih': pendapatanBersih,
      'premiAtas': premiAtas.nominal,
      'premiBawah': premiBawah.nominal,
      'pendapatanDisetor': pendapatanDisetor,
      'allData': allData,
    };
  }

  /// Update controllers untuk field yang dihitung otomatis
  static void updateAutoCalculatedFields({
    required Map<String, dynamic> calculationResult,
    required Map<int, TextEditingController> controllers,
  }) {
    final pendapatanBersih = calculationResult['pendapatanBersih'] as int;
    final pendapatanDisetor = calculationResult['pendapatanDisetor'] as int;

    // Update field pendapatan bersih (ID 60)
    final pendapatanBersihController = controllers[60];
    if (pendapatanBersihController != null) {
      pendapatanBersihController.text = pendapatanBersih.toString();
    }

    // Update field pendapatan disetor (ID 61)
    final pendapatanDisetorController = controllers[61];
    if (pendapatanDisetorController != null) {
      pendapatanDisetorController.text = pendapatanDisetor.toString();
    }
  }

  // ========== PRIVATE METHODS ==========

  static List<TagData> _collectTagData(
      List<TagTransaksi> tags,
      Map<int, TextEditingController> controllers,
      Map<int, TextEditingController> jumlahControllers,
      Map<int, TextEditingController> literSolarControllers,
      ) {
    return tags.map((tag) {
      final nominalController = controllers[tag.id];
      final jumlahController = jumlahControllers[tag.id];
      final literSolarController = literSolarControllers[tag.id];

      return TagData(
        id: tag.id,
        nama: tag.nama ?? 'Unknown',
        nominal: nominalController?.text.isNotEmpty == true
            ? int.tryParse(nominalController!.text) ?? 0
            : 0,
        jumlah: jumlahController?.text.isNotEmpty == true
            ? int.tryParse(jumlahController!.text) ?? 0
            : 0,
        literSolar: literSolarController?.text.isNotEmpty == true
            ? int.tryParse(literSolarController!.text) ?? 0
            : 0,
        tagTransaksi: tag,
      );
    }).toList();
  }

  static int _calculateTotal(List<TagData> dataList) {
    return dataList.fold<int>(0, (sum, data) => sum + data.nominal);
  }

  static TagData _findTagById(List<TagData> dataList, int id) {
    return dataList.firstWhere(
          (data) => data.id == id,
      orElse: () => _createEmptyTagData(),
    );
  }

  static TagData _createEmptyTagData() {
    return TagData(
      id: 0,
      nama: 'Unknown',
      nominal: 0,
      jumlah: 0,
      literSolar: 0,
      tagTransaksi: TagTransaksi(
        id: 0,
        kategoriTransaksi: '',
        nama: '',
      ),
    );
  }

  static void _printDebugInfo(
      int totalPendapatan,
      int totalPengeluaran,
      int pendapatanBersih,
      TagData premiAtas,
      TagData premiBawah,
      int pendapatanDisetor,
      ) {
    print('=== HASIL KALKULASI PREMI BERSIH ===');
    print('  Total Pendapatan: Rp$totalPendapatan');
    print('  Total Pengeluaran: Rp$totalPengeluaran');
    print('  Pendapatan Bersih: Rp$pendapatanBersih');
    print('  Premi Atas: Rp${premiAtas.nominal}');
    print('  Premi Bawah: Rp${premiBawah.nominal}');
    print('  Pendapatan Disetor: Rp$pendapatanDisetor');
    print('====================================');
  }
}