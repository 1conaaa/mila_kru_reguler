import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BusPerpalService {
  static final BusPerpalService instance = BusPerpalService._internal();
  BusPerpalService._internal();

  Future<void> insertBusPerpal({
    required int idBus,
    required String noPol,
    required int rit,
    required String kodeTrayek,
    required DateTime tglPerpal,
    required String lokasiPerpal,
    required String kategori,
    required String keterangan,
    required String status,
  }) async {
    final Database db = await DatabaseHelper.instance.database;

    await db.insert(
      't_bus_perpal',
      {
        'id_bus': idBus,
        'no_pol': noPol,
        'rit': rit,
        'kode_trayek': kodeTrayek,
        'tgl_perpal': tglPerpal.toIso8601String(),
        'lokasi_perpal': lokasiPerpal,
        'kategori': kategori,
        'keterangan': keterangan,
        'status': status,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('[BUS PERPAL] Data berhasil disimpan');

    // DEBUG: tampilkan isi tabel
    final List<Map<String, dynamic>> result =
    await db.query('t_bus_perpal');

    print('[BUS PERPAL] Isi seluruh tabel t_bus_perpal:');
    for (var row in result) {
      print(row);
    }
  }

  Future<void> clearAll() async {
    final Database db = await DatabaseHelper.instance.database;

    await db.delete('t_bus_perpal');

    print('[BUS PERPAL] Semua data berhasil dihapus');
  }
}