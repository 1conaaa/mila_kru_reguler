import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:sqflite/sqflite.dart';

class TagTransaksiService {
  // Singleton
  static final TagTransaksiService _instance = TagTransaksiService._internal();
  factory TagTransaksiService() => _instance;
  TagTransaksiService._internal();

  final dbHelper = DatabaseHelper.instance;

  /// Insert data ke table m_tag_transaksi
  Future<void> insertTagTransaksi(TagTransaksi tag) async {
    final db = await dbHelper.database;
    await db.insert(
      'm_tag_transaksi',
      tag.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // update jika id sama
    );
  }

  /// Hapus semua data di table m_tag_transaksi
  Future<void> clearTagTransaksi() async {
    final db = await dbHelper.database;
    await db.delete('m_tag_transaksi');
  }

  /// Ambil semua data dari table m_tag_transaksi
  Future<List<TagTransaksi>> getAllTagTransaksi() async {
    final db = await dbHelper.database;
    final result = await db.query(
      'm_tag_transaksi',
      columns: ['id', 'kategori_transaksi', 'nama'],
    );

    return result.map((map) => TagTransaksi.fromMap(map)).toList();
  }

  /// Ambil data berdasarkan kategori (pendapatan / pengeluaran)
  Future<List<String>> getTagTransaksiList(String kategori) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'm_tag_transaksi',
      columns: ['nama'],
      where: 'kategori_transaksi = ?',
      whereArgs: [kategori],
      orderBy: 'nama ASC',
    );

    // Ambil field 'nama' dari hasil query
    return result.map((row) => row['nama'].toString()).toList();
  }

  /// Ambil data berdasarkan id
  Future<TagTransaksi?> getTagTransaksiById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'm_tag_transaksi',
      columns: ['id', 'kategori_transaksi', 'nama'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return TagTransaksi.fromMap(result.first);
    }
    return null;
  }

  /// Update data berdasarkan id
  Future<void> updateTagTransaksi(TagTransaksi tag) async {
    final db = await dbHelper.database;
    await db.update(
      'm_tag_transaksi',
      tag.toMap(),
      where: 'id = ?',
      whereArgs: [tag.id],
    );
  }

  /// Hapus data berdasarkan id
  Future<void> deleteTagTransaksi(int id) async {
    final db = await dbHelper.database;
    await db.delete(
      'm_tag_transaksi',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
