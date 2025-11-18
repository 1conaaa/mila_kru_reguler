import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static Database? _database;
  static final DatabaseHelper instance = DatabaseHelper._();
  // Define a constructor
  DatabaseHelper();
  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  get databaseHelper => null;

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = '${documentsDirectory.path}/bisapp_18112025-v1.db';

    return await openDatabase(
      path,
      version: 1, // Update the version number
      onCreate: (db, version) async {
        await _createTables(db, version); // Call the updated _createTables function
      },
      onUpgrade: (db, oldVersion, newVersion) {
        // Handle database migration if needed
      },
    );

  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS m_premi_posisi_kru (
        id INTEGER PRIMARY KEY,
        nama_premi TEXT,
        persen_premi TEXT,
        tanggal_simpan TEXT, UNIQUE (nama_premi, persen_premi)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS premi_harian_kru (
        id INTEGER PRIMARY KEY,
        id_transaksi INTEGER,
        id_user INTEGER,
        id_group INTEGER,
        persen_premi_disetor REAL,
        nominal_premi_disetor REAL,
        tanggal_simpan TEXT,
        status TEXT, UNIQUE (id_transaksi, id_user, id_group, tanggal_simpan)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS resume_transaksi (
        id INTEGER PRIMARY KEY,
        no_pol TEXT,
        id_bus INTEGER,
        id_user INTEGER,
        id_group INTEGER,
        id_garasi INTEGER,
        id_company INTEGER,
        jumlah_tiket INTEGER,
        km_masuk_garasi REAL,
        kode_trayek TEXT,
        pendapatan_reguler REAL,
        pendapatan_online REAL,
        pendapatan_bagasi_perusahaan REAL,
        pendapatan_bagasi_kru REAL,
        biaya_perbaikan REAL,
        keterangan_perbaikan TEXT,
        biaya_tol REAL,
        biaya_tpr REAL,
        biaya_solar REAL,
        liter_solar REAL,
        biaya_perpal REAL,
        biaya_premi_extra REAL,
        biaya_premi_disetor REAL,
        pendapatan_bersih REAL,
        pendapatan_disetor REAL,
        tanggal_transaksi TEXT,
        status TEXT, UNIQUE (no_pol, id_bus, id_user, id_group, id_garasi, id_company, tanggal_transaksi)
      )
    ''');

      // Tabel t_setoran_kru
      await db.execute('''
      CREATE TABLE t_setoran_kru (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tgl_transaksi TEXT,
        km_pulang REAL,
        rit TEXT,
        no_pol TEXT,
        id_bus INTEGER,
        kode_trayek TEXT,
        id_personil INTEGER,
        id_group INTEGER,
        jumlah INTEGER,
        id_transaksi TEXT,
        coa TEXT,
        nilai REAL,
        id_tag_transaksi INTEGER,
        status TEXT,
        keterangan TEXT,
        fupload TEXT,
        file_name TEXT,
        updated_at TEXT,
        created_at TEXT,
        UNIQUE(rit, no_pol, id_bus, kode_trayek, id_personil, id_group, id_tag_transaksi)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS penjualan_tiket (
        id INTEGER PRIMARY KEY,
        no_pol TEXT,
        id_bus INTEGER,
        id_user INTEGER,
        id_group INTEGER,
        id_garasi INTEGER,
        id_company INTEGER,
        jumlah_tiket INTEGER,
        kategori_tiket TEXT,
        rit INTEGER,
        kota_berangkat TEXT,
        kota_tujuan TEXT,
        nama_pembeli TEXT,
        no_telepon TEXT,
        harga_kantor REAL,
        jumlah_tagihan REAL,
        nominal_bayar REAL,
        jumlah_kembalian REAL,
        tanggal_transaksi DATETIME,
        status TEXT,
        kode_trayek TEXT,
        keterangan TEXT,
        id_invoice TEXT,
        id_metode_bayar INTEGER DEFAULT 1,
        nominal_tagihan REAL,
        status_bayar INTEGER,
        trx_id TEXT,
        merchant_id TEXT,
        redirect_url TEXT,
        fupload TEXT,
        file_name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS list_kota (
        id INTEGER PRIMARY KEY,
        kode_trayek TEXT,
        id_kota_berangkat INTEGER,
        id_kota_tujuan INTEGER,
        jarak INTEGER,
        nama_kota TEXT,
        id_harga_tiket INTEGER,
        harga_kantor REAL,
        biaya_perkursi REAL,
        margin_kantor REAL,
        margin_tarikan REAL,
        aktif TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS kru_bis (
        id INTEGER PRIMARY KEY,
        id_personil INTEGER,
        id_group INTEGER,
        nama_lengkap TEXT,
        group_name TEXT, UNIQUE (id_personil, id_group)
      )
    ''');

    await db.execute('''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY,
      id_user INTEGER,
      id_group INTEGER,
      id_company INTEGER,
      id_garasi INTEGER,
      id_bus INTEGER,
      no_pol TEXT,
      nama_lengkap TEXT,
      nama_user TEXT,
      password TEXT,
      foto TEXT,
      group_name TEXT,
      kode_trayek TEXT,
      nama_trayek TEXT,
      trip TEXT,
      jenis_trayek TEXT,
      kelas_bus TEXT,
      tanggal_simpan TEXT,
      rute TEXT,
      keydataPremiextra TEXT,
      premiExtra TEXT,
      keydataPremikru TEXT,
      persenPremikru TEXT,
      idJadwalTrip TEXT,
      tagTransaksiPendapatan TEXT,
      tagTransaksiPengeluaran TEXT,
      coaPendapatanBus TEXT,
      coaPengeluaranBus TEXT,
      coaUtangPremi TEXT,
      noKontak TEXT,
      UNIQUE (id_user, id_group, id_company, id_garasi, id_bus, no_pol, tanggal_simpan)
    )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS m_inspection_items (
        id INTEGER PRIMARY KEY,
        item_name INTEGER,
        description TEXT, UNIQUE (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS t_inspection_results (
        id INTEGER,
        id_form TEXT,
        inspections_item_id INTEGER,
        id_bus INTEGER,
        no_pol TEXT,
        status TEXT,
        remarks TEXT,
        id_kru INTEGER,
        tgl_periksa TEXT,
        status_qc TEXT, UNIQUE (id),
        PRIMARY KEY (id, id_form, inspections_item_id, id_bus, no_pol, id_kru, tgl_periksa)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS m_jenis_paket (
        id INTEGER PRIMARY KEY,
        jenis_paket TEXT,
        deskripsi TEXT, 
        persen REAL,
        UNIQUE (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS t_order_bagasi (
        id INTEGER PRIMARY KEY,
        tgl_order DATETIME,
        id_jenis_paket int,
        id_order TEXT,
        rit int, 
        no_pol TEXT,
        id_bus int,
        kode_trayek TEXT,
        id_personil int,
        id_group int,
        id_kota_berangkat TEXT,
        id_kota_tujuan TEXT,
        qty_barang int,
        harga_km REAL,
        jml_harga REAL,
        nama_pengirim TEXT,
        no_tlp_pengirim TEXT,
        nama_penerima TEXT,
        no_tlp_penerima TEXT,
        keterangan TEXT,
        status TEXT,
        file_name TEXT,
        fupload TEXT,
        UNIQUE (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS t_order_bagasi_status (
        id INTEGER PRIMARY KEY,
        id_order INTEGER,
        status TEXT, 
        id_personil int,
        nama_penerima TEXT,
        no_tlp_penerima TEXT,
        tanggal TEXT,
        UNIQUE (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS m_metode_pembayaran (
          id INT(15) PRIMARY KEY,
          nama VARCHAR(60) NULL,
          payment_channel INT(5) NULL,
          nama_bank VARCHAR(100) NULL,
          pemilik_rekening VARCHAR(100) NULL,
          no_rekening VARCHAR(50) NULL,
          biaya_admin DOUBLE NULL,
          deskripsi VARCHAR(100) NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS m_tag_transaksi (
          id INTEGER PRIMARY KEY,
          kategori_transaksi INTEGER,
          nama TEXT
      )
    ''');
  }

  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }



  Future<Map<String, int>> getSumJumlahPendapatanBagasi(String? kelasBus) async {
    final db = await database;
    List<Map<String, dynamic>> result;

    if (kelasBus == 'Ekonomi') {
      result = await db.rawQuery('''
      SELECT SUM(jml_harga)*0.6 AS total_tagihan_bagasi, SUM(qty_barang) AS jumlah_barang, rit
      FROM t_order_bagasi
      WHERE status = 'Y'
    ''');
    } else if (kelasBus == 'Non Ekonomi') {
      result = await db.rawQuery('''
      SELECT SUM(jml_harga)*0.6 AS total_tagihan_bagasi, SUM(qty_barang) AS jumlah_barang, rit
      FROM t_order_bagasi
      WHERE status = 'Y'
    ''');
    } else {
      // Jika kelasBus tidak sesuai, kembalikan nilai default
      return {
        'rit': 0,
        'totalPendapatanBagasi': 0,
        'jumlahTiketBagasi': 0,
      };
    }

    int rit = result.isNotEmpty ? result[0]['rit']?.toInt() ?? 0 : 0;
    int totalPendapatanBagasi = result.isNotEmpty ? result[0]['total_tagihan_bagasi']?.toInt() ?? 0 : 0;
    int jumlahBarangBagasi = result.isNotEmpty ? result[0]['jumlah_barang']?.toInt() ?? 0 : 0;
    print('Total Pendapatan Bagasi: $totalPendapatanBagasi'); // Cetak hasil
    return {
      'rit': rit,
      'totalPendapatanBagasi': totalPendapatanBagasi,
      'jumlahBarangBagasi': jumlahBarangBagasi,
    };
  }

  Future<List<Map<String, dynamic>>> getMasterPremiKru() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
      a.id_group, a.id_personil, a.nama_lengkap, a.group_name, b.persen_premi
    FROM 
      kru_bis AS a
      JOIN m_premi_posisi_kru AS b ON LOWER(a.group_name) = LOWER(b.nama_premi)
    ORDER BY a.id DESC
  ''');
  }

  Future<void> clearJenisPaket() async {
    final db = await database;
    await db.delete('m_jenis_paket');
  }


  Future<void> clearResumeTransaksi() async {
    final db = await database;
    await db.delete('resume_transaksi');
  }

  Future<List<Map<String, dynamic>>> queryResumeTransaksi() async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query('resume_transaksi');

    // Cetak hasil query
    print('Hasil query resume_transaksi:');
    results.forEach((row) {
      print(row);
    });

    return results;
  }

  Future<List<Map<String, dynamic>>> getResumeTransaksiByStatus(String status) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT a.*
    FROM resume_transaksi AS a
    WHERE a.status = ?
  ''', [status]);
  }

  Future<void> updateResumeTransaksiStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'resume_transaksi',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearPremiHarianKru() async {
    final db = await database;
    await db.delete('premi_harian_kru');
  }

  Future<List<Map<String, dynamic>>> getPremiHarianKru() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT a.*, b.nama_lengkap AS nama_kru, (a.persen_premi_disetor*100) AS persen_premi 
    FROM premi_harian_kru AS a
    JOIN kru_bis AS b ON a.id_user = b.id_personil
  ''');
  }

  Future<List<Map<String, dynamic>>> getPremiHarianKruByStatus(String status) async {
    final db = await database;
    return await db.rawQuery('''
    SELECT a.*, b.nama_lengkap AS nama_kru, (a.persen_premi_disetor*100) AS persen_premi 
    FROM premi_harian_kru AS a
    JOIN kru_bis AS b ON a.id_user = b.id_personil
    WHERE a.status = ?
  ''', [status]);
  }

  Future<void> updatePremiHarianKruStatus(int id, String status) async {
    final db = await database;
    await db.update(
      'premi_harian_kru',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearPremiPosisiKru() async {
    final db = await database;
    await db.delete('m_premi_posisi_kru');
  }

  Future<void> updateInspectionStatusQc(int id) async {
    final db = await database;
    await db.update(
      't_inspection_results',
      {'status_qc': 'Y'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateTransaksiBagasiStatusQc(int id) async {
    final db = await database;
    await db.update(
      't_order_bagasi',
      {'status': 'Y'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransaksiBagasi() async {
    final db = await database;

    // Menggunakan rawQuery untuk menjalankan query JOIN
    return await db.rawQuery('''
      SELECT 
        a.id,a.tgl_order,a.id_jenis_paket,a.id_order,a.rit,a.no_pol,a.id_bus,
        a.kode_trayek,a.id_personil,a.id_group,a.id_kota_berangkat,a.id_kota_tujuan,
        a.qty_barang,a.harga_km,a.jml_harga,a.nama_pengirim,a.no_tlp_pengirim,
        a.nama_penerima,a.no_tlp_penerima,a.keterangan,b.jenis_paket,b.deskripsi,b.persen,
        c.nama_kota AS kota_berangkat,d.nama_kota AS kota_tujuan,a.keterangan,a.fupload,a.file_name,a.status
      FROM
        t_order_bagasi AS a
        INNER JOIN m_jenis_paket AS b ON a.id_jenis_paket=b.id
        LEFT JOIN list_kota AS c ON a.id_kota_berangkat = c.id_kota_tujuan
        LEFT JOIN list_kota AS d ON a.id_kota_tujuan = d.id_kota_tujuan
    ''');
  }

  Future<List<Map<String, dynamic>>> getDataTransaksiBagasiTerakhir() async {
    final db = await database;
    return await db.rawQuery('''
    SELECT 
        a.id,a.tgl_order,a.id_jenis_paket,a.id_order,a.rit,a.no_pol,a.id_bus,
        a.kode_trayek,a.id_personil,a.id_group,a.id_kota_berangkat,a.id_kota_tujuan,
        a.qty_barang,a.harga_km,a.jml_harga,a.nama_pengirim,a.no_tlp_pengirim,
        a.nama_penerima,a.no_tlp_penerima,a.keterangan,b.jenis_paket,b.deskripsi,b.persen,
        c.nama_kota AS kota_berangkat,d.nama_kota AS kota_tujuan,a.keterangan,a.fupload,a.file_name,a.status,a.tgl_order
      FROM
        t_order_bagasi AS a
        INNER JOIN m_jenis_paket AS b ON a.id_jenis_paket=b.id
        LEFT JOIN list_kota AS c ON a.id_kota_berangkat = c.id_kota_tujuan
        LEFT JOIN list_kota AS d ON a.id_kota_tujuan = d.id_kota_tujuan
    ORDER BY a.id DESC LIMIT 1
  ''');
  }

  Future<void> insertTransaksiBagasi(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('t_order_bagasi', data);
  }

  Future<void> clearOrderBagasi() async {
    final db = await database;
    await db.delete('t_order_bagasi');
  }

  Future<List<Map<String, dynamic>>> getAllJenisPaket() async {
    final db = await database;

    // Menggunakan rawQuery untuk menjalankan query JOIN
    return await db.rawQuery('''
      SELECT 
        a.id,a.jenis_paket,a.deskripsi,a.persen
      FROM
        m_jenis_paket a 
    ''');
  }

  Future<void> insertJenisPaket(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('m_jenis_paket', data);
  }

  Future<void> clearOrderBagasiStatus() async {
    final db = await database;
    await db.delete('t_order_bagasi_status');
  }

  Future<void> insertOrderBagasiStatus(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('t_order_bagasi_status', data);
  }

  Future<List<Map<String, dynamic>>> getAllInspectionResults() async {
    final db = await database;

    // Menggunakan rawQuery untuk menjalankan query JOIN
    return await db.rawQuery('''
    SELECT 
      a.id, a.id_form, a.inspections_item_id, a.id_bus, a.no_pol,
      a.status, a.remarks, a.id_kru, a.tgl_periksa, a.status_qc,
      b.item_name
    FROM
      t_inspection_results a 
      INNER JOIN m_inspection_items b ON a.inspections_item_id = b.id
  ''');
  }

  Future<List<Map<String, dynamic>>> getAllInspectionItems() async {
    final db = await database;
    return await db.query('m_inspection_items');
  }

  Future<void> clearInspectionItems() async {
    final db = await database;
    await db.delete('m_inspection_items');
  }

  Future<void> insertPremiPosisiKru(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('m_premi_posisi_kru', data);
  }

  Future<List<Map<String, dynamic>>> getPremiPosisiKru() async {
    final db = await database;
    return await db.query('m_premi_posisi_kru');
  }

  Future<void> updatePremiPosisiKru(int id, String deskripsi) async {
    final db = await database;
    await db.update(
      'm_premi_posisi_kru',
      {'id': id},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deletePremiPosisiKru(int id) async {
    final db = await database;
    await db.delete(
      'm_premi_posisi_kru',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user);
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<void> updateUser(int id, String name) async {
    final db = await database;
    await db.update('users', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> initDatabase() async {
    _database = await database;
  }

  Future<List<Map<String, dynamic>>> queryUsers() async {
    final db = await database;
    return await db.query('users');
  }

  Future<void> clearUsersTable() async {
    final db = await database;
    await db.delete('users');
  }

  Future<void> insertKruBis(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('kru_bis', data);
  }

  Future<List<Map<String, dynamic>>> getKruBis() async {
    final db = await database;
    return await db.query('kru_bis');
  }

  Future<void> updateKruBis(int id, String deskripsi) async {
    final db = await database;
    await db.update(
      'kru_bis',
      {'id': id},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteKruBis(int id) async {
    final db = await database;
    await db.delete(
      'kru_bis',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> queryKruBis() async {
    final db = await database;
    return await db.query('kru_bis');
  }

  Future<void> clearKruBis() async {
    final db = await database;
    await db.delete('kru_bis');
  }

  Future<void> insertListKota(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('list_kota', data);
  }

  Future<List<Map<String, dynamic>>> getCariHargaKantor(int idkotaAwal, int idkotaAkhir) async {
    final db = await database;
    // Jalankan query untuk mendapatkan harga kantor
    List<Map<String, dynamic>> results = await db.rawQuery('''
    SELECT id_kota_berangkat, id_kota_tujuan, harga_kantor, margin_tarikan
    FROM list_kota 
    WHERE id_kota_berangkat = ? AND id_kota_tujuan = ?
    UNION ALL
    SELECT id_kota_berangkat, id_kota_tujuan, harga_kantor, margin_tarikan
    FROM list_kota 
    WHERE id_kota_berangkat = ? AND id_kota_tujuan = ?
  ''', [idkotaAwal, idkotaAkhir, idkotaAkhir, idkotaAwal]);

    // Cetak hasil pencarian harga kantor untuk debugging
    print('cari harga: $results');

    // Kembalikan hasil pencarian
    return results;
  }


  Future<List<Map<String, dynamic>>> getListKota() async {
    final db = await database;
    return await db.query('list_kota');
  }

  Future<Map<String, dynamic>> getLastKotaTerakhir() async {
    final db = await database;
    List<Map<String, dynamic>> results = [];

    try {
      results = await db.rawQuery('SELECT * FROM list_kota ORDER BY jarak DESC LIMIT 1');
      // print(results); // Cetak hasil query
    } catch (e) {
      print('Error executing query: $e');
    }

    if (results.isNotEmpty) {
      return results[0];
    } else {
      return {};
    }
  }

  Future<String> getNamaKota(int idKota) async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query(
      'list_kota',
      where: 'id_kota_tujuan = ?',
      whereArgs: [idKota],
      limit: 1,
    );

    if (result.isNotEmpty) {
      String namaKota = result.first['nama_kota'];
      return namaKota;
    } else {
      // Jika data tidak ditemukan, Anda bisa mengembalikan nilai default atau menangani kasus ini sesuai kebutuhan aplikasi Anda.
      return '';
    }
  }

  Future<void> updateListKota(int id, String deskripsi) async {
    final db = await database;
    await db.update(
      'list_kota',
      {'id': id},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteListKota(int id) async {
    final db = await database;
    await db.delete(
      'list_kota',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> queryListKota() async {
    final db = await database;
    return await db.query('list_kota');
  }

  Future<void> clearListKota() async {
    final db = await database;
    await db.delete('list_kota');
  }

  Future<void> insertInspectionItem(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('m_inspection_items', data);
  }

  Future<void> insertMetodePembayaran(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('m_metode_pembayaran', data);
  }

  Future<void> clearMetodePembayaran() async {
    final db = await database;
    await db.delete('m_metode_pembayaran');
  }

  Future<List<Map<String, dynamic>>> getAllMetodePembayaran() async {
    final db = await database;

    // Menggunakan rawQuery untuk menjalankan query JOIN
    return await db.rawQuery('''
      SELECT 
        a.id,a.nama,a.payment_channel,a.nama_bank,
        a.pemilik_rekening,a.no_rekening,a.biaya_admin,a.deskripsi
      FROM
        m_metode_pembayaran a 
    ''');
  }

  Future<void> insertTagTransaksi(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('m_tag_transaksi', data);
  }

  Future<void> clearTagTransaksi() async {
    final db = await database;
    await db.delete('m_tag_transaksi');
  }

  Future<List<Map<String, dynamic>>> getAllTagTransaksi() async {
    final db = await database;

    // Menggunakan rawQuery untuk menjalankan query JOIN
    return await db.rawQuery('''
      SELECT 
        a.id,a.kategori_transaksi,a.nama
      FROM
        m_tag_transaksi a 
    ''');
  }


}

