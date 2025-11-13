import 'package:sqflite/sqflite.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';

class PenjualanTiketService {
  // ✅ Singleton pattern agar bisa diakses seperti DatabaseHelper.instance
  PenjualanTiketService._privateConstructor();
  static final PenjualanTiketService instance = PenjualanTiketService._privateConstructor();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Database> get database async => await _dbHelper.database;

  /// Insert data penjualan tiket
  Future<void> insertPenjualanTiket(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('penjualan_tiket', data);
  }

  /// Menghapus seluruh data penjualan tiket
  Future<void> clearPenjualanTiket() async {
    final db = await database;
    await db.delete('penjualan_tiket');
  }

  /// Mendapatkan data penjualan berdasarkan status
  Future<List<Map<String, dynamic>>> getPenjualanByStatus(String status) async {
    final db = await database;
    return await db.query(
      'penjualan_tiket',
      where: 'status = ?',
      whereArgs: [status],
    );
  }

  /// Update status penjualan tiket berdasarkan ID
  Future<void> updatePenjualanStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'penjualan_tiket',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mengambil data penjualan terakhir (record terakhir)
  Future<List<Map<String, dynamic>>> getDataPenjualanTerakhir() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        a.id ||''|| a.tanggal_transaksi ||''|| a.id_bus ||''|| a.id_garasi ||''|| a.rit ||''|| a.kode_trayek AS noOrderTransaksi,
        a.rit, a.kota_berangkat, a.kota_tujuan, a.nama_pembeli, a.no_telepon,
        a.jumlah_tagihan, a.nominal_bayar, a.jumlah_kembalian, a.tanggal_transaksi
      FROM penjualan_tiket AS a
      ORDER BY a.id DESC LIMIT 1
    ''');
  }

  /// Mengambil seluruh data penjualan tiket (gabung dengan list_kota)
  Future<List<Map<String, dynamic>>> getDataPenjualan() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        a.*, 
        a.id AS idKota, 
        a.id || ' - ' || a.kategori_tiket || ' - ' || b.nama_kota || ' - ' || c.nama_kota AS rute_kota,
        c.nama_kota AS kota_tujuan
      FROM penjualan_tiket AS a
      LEFT JOIN list_kota AS b ON a.kota_berangkat = b.id_kota_tujuan
      LEFT JOIN list_kota AS c ON a.kota_tujuan = c.id_kota_tujuan
      GROUP BY a.kategori_tiket, b.nama_kota, c.nama_kota
      ORDER BY a.id DESC
    ''');
  }

  /// Mengambil daftar rute kota dari penjualan tiket
  Future<List<Map<String, dynamic>>> getRuteKota() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      a.*, 
      a.kategori_tiket || ' - ' || b.nama_kota || ' - ' || c.nama_kota AS rute_kota,
      c.nama_kota AS kota_tujuan
    FROM 
      penjualan_tiket AS a
      LEFT JOIN list_kota AS b ON a.kota_berangkat = b.id_kota_tujuan
      LEFT JOIN list_kota AS c ON a.kota_tujuan = c.id_kota_tujuan
    GROUP BY a.kategori_tiket || ' - ' || b.nama_kota || ' - ' || c.nama_kota AS rute_kota
    ORDER BY a.id DESC
  ''');
  }

  /// Mencari rute kota berdasarkan ID pencarian
  Future<List<Map<String, dynamic>>> getDataRuteKota(String searchQuery) async {
    final db = await database;
    String rawQuery;
    List<dynamic> arguments;

    if (searchQuery.isEmpty) {
      rawQuery = '''
        SELECT 
          a.*, 
          a.kategori_tiket || ' - ' || b.nama_kota || ' - ' || c.nama_kota AS rute_kota
        FROM penjualan_tiket AS a
        LEFT JOIN list_kota AS b ON a.kota_berangkat = b.id_kota_tujuan
        LEFT JOIN list_kota AS c ON a.kota_tujuan = c.id_kota_tujuan
        GROUP BY a.id
        ORDER BY a.id DESC
      ''';
      arguments = [];
    } else {
      List<String> pisahId = searchQuery.split('-');
      String id = pisahId[0];
      rawQuery = '''
        SELECT 
          a.*, 
          a.kategori_tiket || ' - ' || b.nama_kota || ' - ' || c.nama_kota AS rute_kota
        FROM penjualan_tiket AS a
        LEFT JOIN list_kota AS b ON a.kota_berangkat = b.id_kota_tujuan
        LEFT JOIN list_kota AS c ON a.kota_tujuan = c.id_kota_tujuan
        WHERE a.id >= ?
        ORDER BY a.id DESC
      ''';
      arguments = [id];
    }

    return await db.rawQuery(rawQuery, arguments);
  }



  /// Mengambil data invoice dari penjualan tiket
  Future<List<Map<String, dynamic>>> getInvoicePenjualan() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        a.*,
        b.nama_kota AS nama_kota_berangkat,
        c.nama_kota AS nama_kota_tujuan,
        d.*
      FROM penjualan_tiket AS a
      INNER JOIN list_kota AS b ON a.kota_berangkat = b.id_kota_tujuan
      INNER JOIN list_kota AS c ON a.kota_tujuan = c.id_kota_tujuan
      INNER JOIN m_metode_pembayaran d ON a.id_metode_bayar = d.payment_channel
      WHERE a.id_invoice IS NOT NULL AND a.id_invoice != ''
      GROUP BY a.id_invoice
      ORDER BY a.id DESC
    ''');
  }

  /// Update status pembayaran invoice
  Future<void> updateInvoiceStatus(String idInvoice, int statusBayar, String status) async {
    final db = await database;
    try {
      // Update status
      await db.update(
        'penjualan_tiket',
        {
          'status_bayar': statusBayar,
          'status': status,
        },
        where: 'id_invoice = ?',
        whereArgs: [idInvoice],
      );

      // Ambil dan print data setelah update
      final result = await db.query(
        'penjualan_tiket',
        where: 'id_invoice = ?',
        whereArgs: [idInvoice],
      );

      print('✅ Data penjualan_tiket setelah update untuk id_invoice $idInvoice:');
      for (var row in result) {
        print(row);
      }
    } catch (e) {
      print('❌ Error updating invoice status: $e');
      throw e;
    }
  }

  /// Mengambil total pendapatan reguler (ekonomi vs non-ekonomi)
  Future<Map<String, int>> getSumJumlahTagihanReguler(String? kelasBus) async {
    final db = await database;
    List<Map<String, dynamic>> result;

    if (kelasBus == 'Ekonomi') {
      result = await db.rawQuery('''
        SELECT SUM(x.total_tagihan) AS total_tagihan, SUM(x.jumlah_tiket) AS jumlah_tiket, SUM(x.rit) AS rit
        FROM (
          SELECT SUM(harga_kantor) AS total_tagihan, SUM(jumlah_tiket) AS jumlah_tiket, rit
          FROM penjualan_tiket
          WHERE kategori_tiket NOT IN ('red_bus', 'traveloka', 'go_asia', 'langganan', 'online') AND status = 'Y' AND id_metode_bayar = '1'
          GROUP BY rit
          UNION ALL
          SELECT SUM(nominal_bayar) AS total_tagihan, SUM(jumlah_tiket) AS jumlah_tiket, rit
          FROM penjualan_tiket
          WHERE kategori_tiket IN ('langganan') AND status = 'Y' AND id_metode_bayar = '1'
          GROUP BY rit
        ) x
      ''');
    } else if (kelasBus == 'Non Ekonomi') {
      result = await db.rawQuery('''
        SELECT SUM(jumlah_tagihan) AS total_tagihan, SUM(jumlah_tiket) AS jumlah_tiket, SUM(rit) AS rit
        FROM penjualan_tiket
        WHERE kategori_tiket NOT IN ('red_bus', 'traveloka', 'go_asia', 'online') AND status = 'Y' AND id_metode_bayar = '1'
      ''');
    } else {
      return {'rit': 0, 'totalPendapatanReguler': 0, 'jumlahTiketReguler': 0};
    }

    int rit = result.isNotEmpty ? result[0]['rit']?.toInt() ?? 0 : 0;
    int totalPendapatanReguler = result.isNotEmpty ? result[0]['total_tagihan']?.toInt() ?? 0 : 0;
    int jumlahTiketReguler = result.isNotEmpty ? result[0]['jumlah_tiket']?.toInt() ?? 0 : 0;

    return {
      'rit': rit,
      'totalPendapatanReguler': totalPendapatanReguler,
      'jumlahTiketReguler': jumlahTiketReguler,
    };
  }

  /// Mengambil total pendapatan non-reguler
  Future<Map<String, int>> getSumJumlahTagihanNonReguler(String? kelasBus) async {
    final db = await database;
    List<Map<String, dynamic>> result;

    if (kelasBus == 'Ekonomi') {
      result = await db.rawQuery('''
    SELECT SUM(x.total_tagihan) AS total_tagihan, 
           SUM(x.jumlah_tiket) AS jumlah_tiket, 
           SUM(x.rit) AS rit
    FROM (
      SELECT SUM(jumlah_tagihan) AS total_tagihan, 
             SUM(jumlah_tiket) AS jumlah_tiket, 
             rit
      FROM penjualan_tiket
      WHERE kategori_tiket IN ('red_bus','traveloka', 'go_asia', 'online') 
        AND status = 'Y'
      UNION ALL
      SELECT SUM(jumlah_tagihan) AS total_tagihan, 
             SUM(jumlah_tiket) AS jumlah_tiket, 
             rit
      FROM penjualan_tiket
      WHERE kategori_tiket NOT IN ('red_bus','traveloka', 'go_asia', 'online') 
        AND status = 'Y' 
        AND id_metode_bayar != '1'
    ) x
   ''');
    } else if (kelasBus == 'Non Ekonomi') {
      result = await db.rawQuery('''
    SELECT SUM(x.total_tagihan) AS total_tagihan, 
           SUM(x.jumlah_tiket) AS jumlah_tiket, 
           SUM(x.rit) AS rit
    FROM (
      SELECT SUM(jumlah_tagihan) AS total_tagihan, 
             SUM(jumlah_tiket) AS jumlah_tiket, 
             rit
      FROM penjualan_tiket
      WHERE kategori_tiket IN ('red_bus','traveloka', 'go_asia', 'online') 
        AND status = 'Y'
      UNION ALL
      SELECT SUM(jumlah_tagihan) AS total_tagihan, 
             SUM(jumlah_tiket) AS jumlah_tiket, 
             rit
      FROM penjualan_tiket
      WHERE kategori_tiket NOT IN ('red_bus','traveloka', 'go_asia', 'online') 
        AND status = 'Y' 
        AND id_metode_bayar != '1'
    ) x
   ''');
    } else {
      // Jika kelasBus tidak sesuai, kembalikan nilai default
      return {
        'rit': 0,
        'totalPendapatanReguler': 0,
        'jumlahTiketReguler': 0,
      };
    }

    int rit = result.isNotEmpty ? result[0]['rit']?.toInt() ?? 0 : 0;
    int totalPendapatanNonReguler = result.isNotEmpty ? result[0]['total_tagihan']?.toInt() ?? 0 : 0;
    int jumlahTiketOnLine = result.isNotEmpty ? result[0]['jumlah_tiket']?.toInt() ?? 0 : 0;
    print('Total Pendapatan Reguler: $totalPendapatanNonReguler'); // Cetak hasil
    return {
      'rit': rit,
      'totalPendapatanNonReguler': totalPendapatanNonReguler,
      'jumlahTiketOnLine': jumlahTiketOnLine,
    };
  }
}