import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/PersenFeeOTA_model.dart';
import 'package:sqflite/sqflite.dart';

class PersenFeeOTAService {
  // Singleton
  static final PersenFeeOTAService _instance = PersenFeeOTAService._internal();
  factory PersenFeeOTAService() => _instance;
  PersenFeeOTAService._internal();

  final dbHelper = DatabaseHelper.instance;

  /// Insert data ke table m_persen_fee_ota
  Future<void> insertPersenFeeOTA(PersenFeeOTA fee) async {
    final db = await dbHelper.database;
    await db.insert(
      'm_persen_fee_ota',
      fee.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // update jika nama_organisasi sama
    );
  }

  /// Hapus semua data di table m_persen_fee_ota
  Future<void> clearPersenFeeOTA() async {
    final db = await dbHelper.database;
    await db.delete('m_persen_fee_ota');
  }

  /// Ambil semua data dari table m_persen_fee_ota
  Future<List<PersenFeeOTA>> getAllPersenFeeOTA() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'm_persen_fee_ota',
      columns: ['nama_organisasi', 'nilai_ota', 'is_persen'],
    );

    return result.map((map) => PersenFeeOTA.fromJson(map)).toList();
  }

  /// Ambil data berdasarkan nama_organisasi
  Future<PersenFeeOTA?> getPersenFeeOTAByNama(String namaOrganisasi) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'm_persen_fee_ota',
      columns: ['nama_organisasi', 'nilai_ota', 'is_persen'],
      where: 'nama_organisasi = ?',
      whereArgs: [namaOrganisasi],
    );

    if (result.isNotEmpty) {
      return PersenFeeOTA.fromJson(result.first);
    }
    return null;
  }

  /// Update data berdasarkan nama_organisasi
  Future<void> updatePersenFeeOTA(PersenFeeOTA fee) async {
    final db = await dbHelper.database;
    await db.update(
      'm_persen_fee_ota',
      fee.toMap(),
      where: 'nama_organisasi = ?',
      whereArgs: [fee.namaOrganisasi],
    );
  }

  /// Hapus data berdasarkan nama_organisasi
  Future<void> deletePersenFeeOTA(String namaOrganisasi) async {
    final db = await dbHelper.database;
    await db.delete(
      'm_persen_fee_ota',
      where: 'nama_organisasi = ?',
      whereArgs: [namaOrganisasi],
    );
  }

  /// Ambil daftar nama_organisasi
  Future<List<String>> getPersenFeeOTAList() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'm_persen_fee_ota',
      columns: ['nama_organisasi'],
      orderBy: 'nama_organisasi ASC',
    );

    return result.map((row) => row['nama_organisasi'].toString()).toList();
  }
}
