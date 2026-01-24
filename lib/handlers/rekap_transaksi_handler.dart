import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/services/penjualan_tiket_service.dart';

class RekapTransaksiHandler {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final PenjualanTiketService _penjualanService = PenjualanTiketService.instance;

  Future<Map<String, dynamic>> loadLastRekapData(String? kelasBus) async {
    await _databaseHelper.initDatabase();

    final hasilReguler = await _penjualanService.getSumJumlahTagihanReguler(kelasBus);
    final hasilNonReguler = await _penjualanService.getSumJumlahTagihanNonReguler(kelasBus);
    final hasilBagasi = await _databaseHelper.getSumJumlahPendapatanBagasi(kelasBus);

    return {
      'reguler': {
        'totalPendapatanReguler': (hasilReguler['totalPendapatanReguler'] ?? 0).toDouble(),
        'jumlahTiketReguler': (hasilReguler['jumlahTiketReguler'] ?? 0).toInt(),
      },
      'nonReguler': {
        'totalPendapatanNonReguler': (hasilNonReguler['totalPendapatanNonReguler'] ?? 0).toDouble(),
        'jumlahTiketOnLine': (hasilNonReguler['jumlahTiketOnLine'] ?? 0).toInt(),
      },
      'bagasi': {
        'totalPendapatanBagasi': (hasilBagasi['totalPendapatanBagasi'] ?? 0).toDouble(),
        'jumlahBarangBagasi': (hasilBagasi['jumlahBarangBagasi'] ?? 0).toInt(),
      },
    };
  }

  Future<String?> getLastRitValue() async {
    final List<String> ritList = await _penjualanService.getRitFromPenjualanTiket();
    return await _penjualanService.getLastRitFromPenjualanTiket();
  }

  Future<List<Map<String, dynamic>>> checkUnsentTransactions() async {
    return await _penjualanService.getPenjualanByStatus('N');
  }

  Future<List<Map<String, dynamic>>> getKruBisData() async {
    return await _databaseHelper.getKruBis();
  }

  Future<bool> isTableExists(String tableName) async {
    final database = await _databaseHelper.database;
    List<Map<String, dynamic>> result = await database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
    );
    return result.isNotEmpty;
  }
}