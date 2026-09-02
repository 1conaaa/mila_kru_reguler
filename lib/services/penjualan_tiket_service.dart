import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/models/PersenFeeOTA_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
        a.*, 
        a.is_turun,
        a.kategori_tiket || ' - ' || b.nama_kota || ' - ' || c.nama_kota AS rute_kota
      FROM penjualan_tiket AS a
      LEFT JOIN list_kota AS b ON a.kota_berangkat = b.id_kota_tujuan
      LEFT JOIN list_kota AS c ON a.kota_tujuan = c.id_kota_tujuan
      ORDER BY a.id DESC;
    ''');
  }

  Future<List<Map<String, dynamic>>> getDataPenjualan() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      a.*,
      a.kategori_tiket || ' - ' ||
      (
        SELECT nama_kota
        FROM list_kota
        WHERE id_kota_tujuan = a.kota_berangkat
        LIMIT 1
      ) || ' - ' ||
      (
        SELECT nama_kota
        FROM list_kota
        WHERE id_kota_tujuan = a.kota_tujuan
        LIMIT 1
      ) AS rute_kota
    FROM penjualan_tiket a
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
  /// Mengambil total pendapatan reguler (ekonomi vs non-ekonomi)
  Future<Map<String, int>> getSumJumlahTagihanReguler(String? kelasBus) async {
    final db = await database;
    List<Map<String, dynamic>> result;

    if (kelasBus == 'Ekonomi') {
      result = await db.rawQuery('''
      SELECT SUM(x.total_tagihan) AS total_tagihan, SUM(x.jumlah_tiket) AS jumlah_tiket, SUM(x.rit) AS rit
      FROM (
        SELECT SUM(jumlah_tagihan) AS total_tagihan, SUM(jumlah_tiket) AS jumlah_tiket, rit
        FROM penjualan_tiket
        WHERE kategori_tiket NOT IN ('red_bus', 'traveloka', 'go_asia', 'langganan', 'operan','sepi','tni','pelajar', 'online') 
          AND status = 'Y' 
          AND id_metode_bayar = '1'
          AND (is_batal IS NULL OR is_batal = 0)  -- ✅ TAMBAHKAN
        GROUP BY rit
        UNION ALL
        SELECT SUM(nominal_bayar) AS total_tagihan, SUM(jumlah_tiket) AS jumlah_tiket, rit
        FROM penjualan_tiket
        WHERE kategori_tiket IN ('langganan','sepi','tni','pelajar') 
          AND status = 'Y' 
          AND id_metode_bayar = '1'
          AND (is_batal IS NULL OR is_batal = 0)  -- ✅ TAMBAHKAN
        GROUP BY rit
      ) x
    ''');
    } else if (kelasBus == 'Non Ekonomi') {
      result = await db.rawQuery('''
      SELECT SUM(jumlah_tagihan) AS total_tagihan, SUM(jumlah_tiket) AS jumlah_tiket, SUM(rit) AS rit
      FROM penjualan_tiket
      WHERE kategori_tiket NOT IN ('red_bus', 'traveloka', 'go_asia', 'online') 
        AND status = 'Y' 
        AND id_metode_bayar = '1'
        AND (is_batal IS NULL OR is_batal = 0)  -- ✅ TAMBAHKAN
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

  Future<Map<String, int>> getSumJumlahTagihanOperan(String? kelasBus) async {
    final db = await database;
    List<Map<String, dynamic>> result;

    if (kelasBus == 'Ekonomi') {
      result = await db.rawQuery('''
      SELECT SUM(x.total_tagihan) AS total_tagihan, SUM(x.jumlah_tiket) AS jumlah_tiket, SUM(x.rit) AS rit
      FROM (
        SELECT SUM(nominal_bayar) AS total_tagihan, SUM(jumlah_tiket) AS jumlah_tiket, rit
        FROM penjualan_tiket
        WHERE kategori_tiket IN ('operan') 
          AND status = 'Y' 
          AND id_metode_bayar = '1'
          AND (is_batal IS NULL OR is_batal = 0)  -- ✅ TAMBAHKAN
        GROUP BY rit
      ) x
    ''');
    } else if (kelasBus == 'Non Ekonomi') {
      result = await db.rawQuery('''
      SELECT SUM(jumlah_tagihan) AS total_tagihan, SUM(jumlah_tiket) AS jumlah_tiket, SUM(rit) AS rit
      FROM penjualan_tiket
      WHERE kategori_tiket NOT IN ('red_bus', 'traveloka', 'go_asia', 'online') 
        AND status = 'Y' 
        AND id_metode_bayar = '1'
        AND (is_batal IS NULL OR is_batal = 0)  -- ✅ TAMBAHKAN
    ''');
    } else {
      return {'rit': 0, 'totalPendapatanOperan': 0, 'jumlahTiketOperan': 0};
    }

    int rit = result.isNotEmpty ? result[0]['rit']?.toInt() ?? 0 : 0;
    int totalPendapatanOperan = result.isNotEmpty ? result[0]['total_tagihan']?.toInt() ?? 0 : 0;
    int jumlahTiketOperan = result.isNotEmpty ? result[0]['jumlah_tiket']?.toInt() ?? 0 : 0;

    return {
      'rit': rit,
      'totalPendapatanOperan': totalPendapatanOperan,
      'jumlahTiketOperan': jumlahTiketOperan,
    };
  }

  // Fungsi yang sudah ada
  Future<List<PersenFeeOTA>> getAllPersenFeeOTA() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'm_persen_fee_ota',
      columns: ['nama_organisasi', 'nilai_ota', 'is_persen'],
    );

    return result.map((map) => PersenFeeOTA.fromJson(map)).toList();
  }

  /// Mengambil total pendapatan non-reguler
  Future<Map<String, dynamic>> getSumJumlahTagihanNonReguler(String? kelasBus) async {
    final db = await database;

    // Ambil data OTA
    final List<PersenFeeOTA> daftarFeeOTA = await getAllPersenFeeOTA();
    print("=== DEBUG: DATA PersenFeeOTA ===");

    // Map fee OTA valid
    final Map<String, PersenFeeOTA> feeMap = {
      for (var fee in daftarFeeOTA)
        if (fee.namaOrganisasi.trim().isNotEmpty)
          fee.namaOrganisasi.toLowerCase(): fee
    };

    feeMap.forEach((nama, fee) {
      print('Organisasi: $nama, Nilai: ${fee.nilaiOta}, isPersen: ${fee.isPersen}');
    });

    print("kelas bus : $kelasBus");

    final cekCount = await db.rawQuery('''
    SELECT COUNT(*) AS total 
    FROM penjualan_tiket 
    WHERE status = "Y" 
      AND (is_batal IS NULL OR is_batal = 0)
    ''');
    int total = int.tryParse(cekCount.first['total'].toString()) ?? 0;

    if (total == 0) {
      print("=== TABEL penjualan_tiket KOSONG ===");
      return {
        'rit': 0,
        'totalPendapatanNonReguler': 0.0,
        'totalFeeRedBus': 0.0,
        'totalFeeTraveloka': 0.0,
        'totalFeeSysconix': 0.0,
        'jumlahTiketOnLine': 0,
        'summaryPerKategoriOTA': {},
      };
    }

    // Summary per kategori OTA
    final summaryPerKategori = await db.rawQuery('''
    SELECT kategori_tiket, 
           SUM(jumlah_tagihan) AS total_tagihan,
           SUM(jumlah_tiket) AS jumlah_tiket
    FROM penjualan_tiket
    WHERE status = 'Y'
      AND kategori_tiket IN ('red_bus','traveloka')
      AND (is_batal IS NULL OR is_batal = 0)
    GROUP BY kategori_tiket
    ''');

    int parseDbInt(Object? value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    double parseDbDouble(Object? value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    // Mapping kategori → organisasi OTA
    Map<String, String> kategoriToOrganisasi = {
      'traveloka': 'traveloka',
      'red_bus': 'redbus',
    };

    Map<String, Map<String, dynamic>> summaryMap = {};
    double totalPendapatanNonReguler = 0.0;
    int jumlahTiketOnLine = 0;

    // Fee Sysconix
    final PersenFeeOTA? sysconixFee = feeMap['sysconix'];

    double totalFeeRedBus = 0.0;
    double totalFeeTraveloka = 0.0;
    double totalFeeSysconix = 0.0;

    for (var row in summaryPerKategori) {
      String kategori = row['kategori_tiket'].toString().toLowerCase();
      double totalTagihan = parseDbDouble(row['total_tagihan']);
      int jumlahTiket = parseDbInt(row['jumlah_tiket']);

      // Fee OTA
      String? namaOrganisasi = kategoriToOrganisasi[kategori];
      final PersenFeeOTA? feeOTAData =
      namaOrganisasi != null ? feeMap[namaOrganisasi] : null;

      int nilaiOta = feeOTAData?.nilaiOta ?? 0;
      int isPersen = feeOTAData?.isPersen ?? 0;

      double feeOTA = (isPersen == 1)
          ? totalTagihan * (nilaiOta / 100)
          : nilaiOta.toDouble();

      if (kategori == 'red_bus') {
        totalFeeRedBus += feeOTA;
      } else if (kategori == 'traveloka') {
        totalFeeTraveloka += feeOTA;
      }

      // Fee Sysconix
      double feeSysconix = 0.0;
      if (sysconixFee != null) {
        feeSysconix = (sysconixFee.isPersen == 1)
            ? totalTagihan * (sysconixFee.nilaiOta / 100)
            : sysconixFee.nilaiOta.toDouble();

        totalFeeSysconix += feeSysconix;
      }

      // Pendapatan PO
      double pendapatanPOOTA = totalTagihan - feeOTA - feeSysconix;

      summaryMap[kategori] = {
        'total_tagihan': totalTagihan,
        'jumlah_tiket': jumlahTiket,
        'nilai_ota': nilaiOta,
        'is_persen': isPersen,
        'fee_OTA': feeOTA,
        'fee_sysconix': feeSysconix,
        'pendapatan_PO_OTA': pendapatanPOOTA,
      };

      totalPendapatanNonReguler += pendapatanPOOTA;
      jumlahTiketOnLine += jumlahTiket;
    }

    print('Total Fee RedBus: $totalFeeRedBus');
    print('Total Fee Traveloka: $totalFeeTraveloka');
    print('Total Fee Sysconix: $totalFeeSysconix');
    print('Total Pendapatan PO OTA: $totalPendapatanNonReguler');

    return {
      'rit': 0,
      'totalPendapatanNonReguler': totalPendapatanNonReguler,
      'totalFeeRedBus': totalFeeRedBus,
      'totalFeeTraveloka': totalFeeTraveloka,
      'totalFeeSysconix': totalFeeSysconix,
      'jumlahTiketOnLine': jumlahTiketOnLine,
      'summaryPerKategoriOTA': summaryMap,
    };
  }


  // Method untuk mendapatkan nilai rit dari penjualan tiket
  Future<List<String>> getRitFromPenjualanTiket() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT DISTINCT rit 
      FROM penjualan_tiket 
      WHERE status = 'Y'
      ORDER BY rit
    ''');

      // Extract rit values and convert to String list
      final List<String> ritList = maps
          .where((map) => map['rit'] != null)
          .map((map) => map['rit'].toString())
          .toList();

      print('=== [DEBUG] RIT DARI PENJUALAN TIKET ===');
      print('Jumlah rit ditemukan: ${ritList.length}');
      print('Daftar rit: $ritList');

      return ritList;
    } catch (e) {
      print('❌ Error get rit from penjualan tiket: $e');
      return [];
    }
  }

// Method untuk mendapatkan rit terakhir
  Future<String?> getLastRitFromPenjualanTiket() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT rit 
      FROM penjualan_tiket 
      WHERE status = 'Y'
      ORDER BY id DESC 
      LIMIT 1
    ''');

      if (maps.isNotEmpty && maps.first['rit'] != null) {
        final String lastRit = maps.first['rit'].toString();
        print('=== [DEBUG] RIT TERAKHIR ===');
        print('Rit terakhir: $lastRit');
        return lastRit;
      }

      print('⚠️ Tidak ada rit ditemukan');
      return null;
    } catch (e) {
      print('❌ Error get last rit: $e');
      return null;
    }
  }

  Future<int> updateIsTurunByRute(String ruteKota, int newValue) async {
    final db = await database;

    // Pisahkan rute → "reguler - Banyuwangi - Yogyakarta"
    final parts = ruteKota.split(" - ");
    final kategori = parts[0];
    final kotaBerangkat = parts[1];
    final kotaTujuan = parts[2];

    return await db.update(
      'penjualan_tiket',
      {'is_turun': newValue},
      where: 'kategori_tiket = ? AND kota_berangkat = (SELECT id_kota_tujuan FROM list_kota WHERE nama_kota = ?) AND kota_tujuan = (SELECT id_kota_tujuan FROM list_kota WHERE nama_kota = ?)',
      whereArgs: [kategori, kotaBerangkat, kotaTujuan],
    );
  }

  Future<int> updateIsTurunByKotaTujuanLocal(
      String kotaTujuan,
      int newValue,
      ) async {
    final db = await database;

    return await db.update(
      'penjualan_tiket',
      {'is_turun': newValue},
      where: '''
      is_turun = 0
      AND kota_tujuan = (
        SELECT id_kota_tujuan
        FROM list_kota
        WHERE nama_kota = ?
      )
    ''',
      whereArgs: [kotaTujuan],
    );
  }

  double? _safeToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(',', '').trim();
      return double.tryParse(cleaned);
    }
    return null;
  }

  /// Sinkronisasi data penjualan tiket batal dari backend
  syncPenjualanTiketBatal({
    required String periodeAwal,
    required String periodeAkhir,
    required String noPol,
    required int idBus,
    required String rit,
    required String bearerToken,
  }) async {
    try {
      final db = await database;

      final url = Uri.parse(
          'https://apimila.milaberkah.com/api/tampilpenjualantiketbatal'
              '?periode_awal=$periodeAwal'
              '&periode_akhir=$periodeAkhir'
              '&no_pol=${Uri.encodeComponent(noPol)}'
              '&id_bus=$idBus'
              '&rit=$rit'
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $bearerToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }

      final List<dynamic> data = json.decode(response.body);
      print('✅ Mendapatkan ${data.length} data dari backend');

      int insertedCount = 0;
      int updatedCount = 0;

      for (var item in data) {
        final bool isBatal = item['is_batal'] == '1' || item['is_batal'] == 1;
        final String tanggalTransaksi = item['tgl_transaksi'];

        final existing = await db.query(
          'penjualan_tiket',
          where: 'tanggal_transaksi = ?',
          whereArgs: [tanggalTransaksi],
        );

        if (existing.isNotEmpty) {
          await db.update(
            'penjualan_tiket',
            {'is_batal': isBatal ? 1 : 0},
            where: 'tanggal_transaksi = ?',
            whereArgs: [tanggalTransaksi],
          );
          updatedCount++;
        } else {
          final newData = {
            'tanggal_transaksi': tanggalTransaksi,
            'kategori_tiket': item['kategori'],
            'rit': int.tryParse(item['rit']?.toString() ?? '0'),
            'no_pol': item['no_pol'],
            'id_bus': item['id_bus'],
            'kode_trayek': item['kode_trayek'],
            'kota_berangkat': item['id_kota_berangkat'],
            'kota_tujuan': item['id_kota_tujuan'],
            'jumlah_tiket': item['jml_naik'],
            'jumlah_tagihan': _safeToDouble(item['pendapatan']),
            'harga_kantor': _safeToDouble(item['harga_kantor']),
            'keterangan': item['keterangan'],
            'is_batal': isBatal ? 1 : 0,
            'id_user': item['id_personil'],
            'status': 'Y',
            'id_metode_bayar': 1,
            'is_turun': 0,
          };

          await db.insert('penjualan_tiket', newData);
          insertedCount++;
        }
      }

      return {
        'insertedCount': insertedCount,
        'updatedCount': updatedCount,
        'totalData': data.length,
      };

    } catch (e) {
      print('❌ Error sync penjualan tiket batal: $e');
      throw e;
    }
  }



  /// Mendapatkan data penjualan yang dibatalkan (is_batal = 1)
  Future<List<Map<String, dynamic>>> getPenjualanBatal() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      a.*,
      a.kategori_tiket || ' - ' ||
      (SELECT nama_kota FROM list_kota WHERE id_kota_tujuan = a.kota_berangkat LIMIT 1) || ' - ' ||
      (SELECT nama_kota FROM list_kota WHERE id_kota_tujuan = a.kota_tujuan LIMIT 1) AS rute_kota
    FROM penjualan_tiket a
    WHERE a.is_batal = 1
    ORDER BY a.id DESC
  ''');
  }

  /// Mendapatkan data penjualan yang tidak dibatalkan (is_batal = 0 atau null)
  Future<List<Map<String, dynamic>>> getPenjualanAktif() async {
    final db = await database;
    return await db.query(
      'penjualan_tiket',
      where: 'is_batal = 0 OR is_batal IS NULL',
      orderBy: 'tanggal_transaksi DESC',
    );
  }

  /// Mendapatkan data penjualan dengan informasi status batal
  Future<List<Map<String, dynamic>>> getDataPenjualanWithBatalStatus() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      a.*,
      a.kategori_tiket || ' - ' ||
      (
        SELECT nama_kota
        FROM list_kota
        WHERE id_kota_tujuan = a.kota_berangkat
        LIMIT 1
      ) || ' - ' ||
      (
        SELECT nama_kota
        FROM list_kota
        WHERE id_kota_tujuan = a.kota_tujuan
        LIMIT 1
      ) AS rute_kota,
      CASE 
        WHEN a.is_batal = 1 THEN 'DIBATALKAN'
        ELSE 'AKTIF'
      END AS status_batal_text
    FROM penjualan_tiket a
    ORDER BY a.id DESC
  ''');
  }

  /// Mendapatkan data penjualan berdasarkan status batal
  Future<List<Map<String, dynamic>>> getPenjualanByBatalStatus({
    required bool isBatal,
    String? searchQuery,
  }) async {
    final db = await database;
    String query = '''
    SELECT 
      a.*,
      a.kategori_tiket || ' - ' ||
      (
        SELECT nama_kota
        FROM list_kota
        WHERE id_kota_tujuan = a.kota_berangkat
        LIMIT 1
      ) || ' - ' ||
      (
        SELECT nama_kota
        FROM list_kota
        WHERE id_kota_tujuan = a.kota_tujuan
        LIMIT 1
      ) AS rute_kota
    FROM penjualan_tiket a
    WHERE a.is_batal = ${isBatal ? 1 : 0} OR (a.is_batal IS NULL AND ${isBatal ? 1 : 0} = 0)
    ORDER BY a.id DESC
  ''';

    return await db.rawQuery(query);
  }

  /// Sync data penjualan batal dari backend
  Future<void> syncBatalData({
    required String token,
    required String noPol,
    required int idBus,
    required String rit,
  }) async {
    try {
      final db = await database;
      final now = DateTime.now();
      final startDate = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
      final endDate = DateFormat('yyyy-MM-dd').format(now);

      final url = Uri.parse(
          'https://apimila.milaberkah.com/api/tampilpenjualantiketbatal'
              '?periode_awal=$startDate'
              '&periode_akhir=$endDate'
              '&no_pol=${Uri.encodeComponent(noPol)}'
              '&id_bus=$idBus'
              '&rit=$rit'
      );

      print('📡 [SYNC BATAL] URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 [SYNC BATAL] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception('Gagal mengambil data: ${response.statusCode}');
      }

      final List<dynamic> data = json.decode(response.body);
      print('✅ Mendapatkan ${data.length} data batal dari backend');

      if (data.isEmpty) {
        print('ℹ️ Tidak ada data batal');
        return;
      }

      // 🔥 JANGAN HAPUS DATA LAMA, UPDATE SAJA
      int updated = 0;
      int inserted = 0;

      for (var item in data) {
        // Cek apakah data sudah ada berdasarkan tanggal_transaksi
        final existing = await db.query(
          'penjualan_tiket',
          where: 'tanggal_transaksi = ?',
          whereArgs: [item['tgl_transaksi']],
        );

        final newData = {
          'tanggal_transaksi': item['tgl_transaksi'],
          'kategori_tiket': item['kategori'] ?? 'reguler',
          'rit': int.tryParse(item['rit']?.toString() ?? '0'),
          'no_pol': item['no_pol'],
          'id_bus': item['id_bus'],
          'id_user': item['id_personil'],
          'id_group': item['id_group'] ?? 0,
          'kode_trayek': item['kode_trayek'],
          'kota_berangkat': item['id_kota_berangkat'],
          'kota_tujuan': item['id_kota_tujuan'],
          'jumlah_tiket': item['jml_naik'] ?? 0,
          'jumlah_tagihan': double.tryParse(item['pendapatan']?.toString() ?? '0'),
          'harga_kantor': double.tryParse(item['harga_kantor']?.toString() ?? '0'),
          'keterangan': item['keterangan'] ?? '',
          'is_batal': 1,
          'status': 'Y',
          'id_metode_bayar': 1,
          'is_turun': 0,
        };

        if (existing.isNotEmpty) {
          // Update data yang sudah ada
          await db.update(
            'penjualan_tiket',
            newData,
            where: 'tanggal_transaksi = ?',
            whereArgs: [item['tgl_transaksi']],
          );
          updated++;
          print('🔄 Update data batal: ${item['tgl_transaksi']}');
        } else {
          // Insert data baru
          await db.insert('penjualan_tiket', newData);
          inserted++;
          print('➕ Insert data batal: ${item['tgl_transaksi']}');
        }
      }

      print('✅ Berhasil update $updated data dan insert $inserted data batal');

    } catch (e) {
      print('❌ Error sync batal: $e');
      rethrow;
    }
  }
}