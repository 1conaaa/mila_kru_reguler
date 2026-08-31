import 'package:sqflite/sqflite.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // Tambahkan import ini

class ManifestLocalService {
  final DatabaseHelper databaseHelper = DatabaseHelper.instance;

  /// 🔹 Cek apakah tabel sudah ada
  Future<bool> _isTableExists(Database db, String tableName) async {
    try {
      List<Map> result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]
      );
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Error saat mengecek tabel: $e');
      return false;
    }
  }

  /// 🔹 Buat tabel penjualan_tiket jika belum ada
  Future<void> _createPenjualanTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS penjualan_tiket (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        no_pol TEXT,
        id_bus INTEGER,
        id_user INTEGER,
        id_group INTEGER,
        id_garasi INTEGER,
        id_company INTEGER,
        jumlah_tiket INTEGER,
        kategori_tiket TEXT,
        rit TEXT,
        kota_berangkat TEXT,
        kota_tujuan TEXT,
        nama_pembeli TEXT,
        no_telepon TEXT,
        harga_kantor REAL,
        jumlah_tagihan REAL,
        nominal_bayar REAL,
        jumlah_kembalian REAL,
        tanggal_transaksi TEXT,
        status TEXT,
        kode_trayek TEXT,
        keterangan TEXT,
        id_invoice TEXT,
        status_bayar INTEGER
      )
    ''');
  }

  /// 🔹 Ambil data penjualan dari database lokal dengan JOIN
  Future<Map<String, dynamic>?> getPenjualanDataFromLocal(String idInvoice) async {
    final db = await databaseHelper.database;

    try {
      final result = await db.rawQuery('''
      SELECT 
        a.*,
        b.nama_kota AS nama_kota_berangkat,
        c.nama_kota AS nama_kota_tujuan,
        d.*
      FROM 
        penjualan_tiket AS a
        LEFT JOIN list_kota AS b ON a.kota_berangkat = b.id_kota_tujuan
        LEFT JOIN list_kota AS c ON a.kota_tujuan = c.id_kota_tujuan
        LEFT JOIN m_metode_pembayaran d ON a.id_metode_bayar = d.payment_channel
      WHERE 
        a.id_invoice = ?
      LIMIT 1
    ''', [idInvoice]);

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print('❌ Error mengambil data dari database lokal: $e');
      return null;
    }
  }

  /// 🔹 Ambil RIT terakhir dari database t_rit_user
  Future<int> getCurrentRit(Database db, int idUser) async {
    try {
      final result = await db.rawQuery(
          'SELECT rit FROM t_rit_user WHERE id_user = ? ORDER BY id DESC LIMIT 1',
          [idUser]
      );

      if (result.isNotEmpty) {
        final int rit = result.first['rit'] as int? ?? 1;
        print('📊 RIT terakhir untuk user $idUser: $rit');
        return rit;
      }
      print('⚠️ Tidak ada data RIT untuk user $idUser, default ke 1');
      return 1;
    } catch (e) {
      print('❌ Error mengambil RIT: $e');
      return 1;
    }
  }

  // /// 🔹 Simpan manifest ke database lokal
  // Future<List<String>> simpanManifestKeDatabase({
  //   required List<dynamic> manifestList,
  //   required BuildContext context,
  // }) async {
  //   if (manifestList.isEmpty) {
  //     // Tampilkan snackbar langsung tanpa ScaffoldMessenger
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       final scaffold = ScaffoldMessenger.of(context);
  //       scaffold.showSnackBar(
  //         const SnackBar(content: Text('Tidak ada data manifest untuk disimpan')),
  //       );
  //     });
  //     return [];
  //   }
  //
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final int idUser = prefs.getInt('idUser') ?? 0;
  //   final int idGroup = prefs.getInt('idGroup') ?? 0;
  //   final int idCompany = prefs.getInt('idCompany') ?? 0;
  //   final int idGarasi = prefs.getInt('idGarasi') ?? 0;
  //   final int idBus = prefs.getInt('idBus') ?? 0;
  //   final String? noPol = prefs.getString('noPol');
  //   final String? kodeTrayek = prefs.getString('kode_trayek');
  //
  //   final DateTime now = DateTime.now();
  //   final String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
  //
  //   final Database database = await databaseHelper.database;
  //
  //   // Pastikan tabel sudah ada
  //   final bool tableExists = await _isTableExists(database, 'penjualan_tiket');
  //   if (!tableExists) {
  //     await _createPenjualanTable(database);
  //   }
  //
  //   int jumlahSukses = 0;
  //   int detikOffset = 0;
  //   List<String> insertedInvoices = [];
  //
  //   print('==============================');
  //   print('💾 MULAI PROSES SIMPAN DATA MANIFEST KE DATABASE LOKAL');
  //   print('🕒 Waktu: $formattedDate');
  //   print('👤 idUser: $idUser | idGroup: $idGroup | idCompany: $idCompany');
  //   print('🚌 idBus: $idBus | noPol: $noPol | kodeTrayek: $kodeTrayek');
  //   print('==============================');
  //
  //   String getKategoriTiket(dynamic idAgen) {
  //     final int agenId = int.tryParse(idAgen.toString()) ?? 0;
  //
  //     const Map<int, String> kategoriMap = {
  //       29: 'traveloka',
  //       30: 'red_bus',
  //       31: 'sysconix',
  //     };
  //
  //     return kategoriMap[agenId] ?? 'offline';
  //   }
  //
  //   for (var item in manifestList) {
  //     try {
  //       final String idInvoice = item['id_order_transaksi']?.toString() ?? '';
  //       final DateTime waktuTransaksi =
  //       DateTime.now().add(Duration(seconds: detikOffset));
  //
  //       final String formattedDate =
  //       DateFormat('yyyy-MM-dd HH:mm:ss').format(waktuTransaksi);
  //
  //       detikOffset++; // ⏱️ tambah 1 detik untuk item berikutnya
  //
  //       if (idInvoice.isEmpty) {
  //         print('⚠️ ID Invoice kosong, dilewati');
  //         continue;
  //       }
  //
  //       final String kategoriTiket =
  //       getKategoriTiket(item['id_agen']);
  //
  //       // 🔹 Cek apakah id_invoice sudah ada di DB
  //       final existing = await database.query(
  //         'penjualan_tiket',
  //         where: 'id_invoice = ?',
  //         whereArgs: [idInvoice],
  //       );
  //
  //       if (existing.isNotEmpty) {
  //         final String existingStatus = existing.first['status']?.toString() ?? 'N';
  //
  //         if (existingStatus == 'Y') {
  //           print('⚠️ Data dengan id_invoice $idInvoice sudah ada dan sudah terkirim (status=Y), dilewati');
  //           continue; // skip data yang sudah dikirim
  //         } else {
  //           print('🔁 Data dengan id_invoice $idInvoice sudah ada tapi belum terkirim (status=N), tetap diproses untuk pengiriman ulang');
  //           insertedInvoices.add(idInvoice); // tambahkan agar tetap bisa dikirim ulang
  //           continue; // tidak perlu insert ulang, tapi tetap kirim
  //         }
  //       }
  //
  //       // 🔍 DEBUG sebelum insert
  //       print('------------------------------');
  //       print('🧾 Menyimpan data manifest baru:');
  //       print('📦 id_invoice       : $idInvoice');
  //       print('👤 id_user          : $idUser');
  //       print('👥 id_group         : $idGroup');
  //       print('🏢 id_company       : $idCompany');
  //       print('🚐 id_bus           : $idBus');
  //       print('🔢 id_garasi        : $idGarasi');
  //       print('🚌 no_pol           : $noPol');
  //       print('🧭 kode_trayek      : $kodeTrayek');
  //       print('🏙️ id_agen          : ${item['id_agen']}');
  //       print('🏙️ kota_berangkat   : ${item['id_kota_berangkat']}');
  //       print('🏙️ kota_tujuan      : ${item['id_kota_tujuan']}');
  //       print('👤 nama_pembeli     : ${item['nama_penumpang']}');
  //       print('📞 no_telepon       : ${item['no_tlp']}');
  //       print('💵 harga_kantor     : ${item['harga_kantor']}');
  //       print('💰 harga_tercatat   : ${item['harga_tercatat']}');
  //       print('📅 tanggal_transaksi: $formattedDate');
  //       print('------------------------------');
  //
  //       // Parse harga
  //       final hargaKantor = double.tryParse(item['harga_kantor']?.toString() ?? '0') ?? 0.0;
  //       final hargaTercatat = double.tryParse(item['harga_tercatat']?.toString() ?? '0') ?? 0.0;
  //
  //       await database.insert('penjualan_tiket', {
  //         'no_pol': noPol,
  //         'id_bus': idBus,
  //         'id_user': idUser,
  //         'id_group': idGroup,
  //         'id_garasi': idGarasi,
  //         'id_company': idCompany,
  //         'jumlah_tiket': 1,
  //         'kategori_tiket': kategoriTiket,
  //         'rit': 1,
  //         'kota_berangkat': item['id_kota_berangkat']?.toString() ?? '',
  //         'kota_tujuan': item['id_kota_tujuan']?.toString() ?? '',
  //         'nama_pembeli': item['nama_penumpang']?.toString() ?? '',
  //         'no_telepon': item['no_tlp']?.toString() ?? '',
  //         'harga_kantor': hargaKantor,
  //         'jumlah_tagihan': hargaTercatat,
  //         'nominal_bayar': hargaTercatat,
  //         'jumlah_kembalian': 0.0,
  //         'tanggal_transaksi': formattedDate,
  //         'status': 'N',
  //         'kode_trayek': kodeTrayek,
  //         'keterangan': 'Penumpang MILA BUS',
  //         'id_invoice': idInvoice,
  //         'is_turun': 0,
  //         'status_bayar': 1,
  //       });
  //
  //       jumlahSukses++;
  //       insertedInvoices.add(idInvoice);
  //       print('✅ Data berhasil disimpan untuk id_invoice: $idInvoice');
  //     } catch (e) {
  //       print('⚠️ Gagal simpan data manifest: $e');
  //     }
  //   }
  //
  //   print('==============================');
  //   print('📊 RINGKASAN PENYIMPANAN');
  //   print('✅ Jumlah sukses: $jumlahSukses');
  //   print('🧾 Total ID Invoice baru: ${insertedInvoices.length}');
  //   print('🧩 Daftar ID Invoice: ${insertedInvoices.join(', ')}');
  //   print('==============================');
  //
  //   // Tampilkan snackbar dengan hasil
  //   WidgetsBinding.instance.addPostFrameCallback((_) {
  //     final scaffold = ScaffoldMessenger.of(context);
  //     scaffold.showSnackBar(
  //       SnackBar(content: Text('$jumlahSukses data berhasil disimpan ke database lokal')),
  //     );
  //   });
  //
  //   return insertedInvoices;
  // }

  Future<List<String>> simpanManifestKeDatabase({
    required List<dynamic> manifestList,
    required BuildContext context,
  }) async {
    if (manifestList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(
          const SnackBar(content: Text('Tidak ada data manifest untuk disimpan')),
        );
      });
      return [];
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int idUser = prefs.getInt('idUser') ?? 0;
    final int idGroup = prefs.getInt('idGroup') ?? 0;
    final int idCompany = prefs.getInt('idCompany') ?? 0;
    final int idGarasi = prefs.getInt('idGarasi') ?? 0;
    final int idBus = prefs.getInt('idBus') ?? 0;
    final String? noPol = prefs.getString('noPol');
    final String? kodeTrayek = prefs.getString('kode_trayek');

    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final Database database = await databaseHelper.database;

    // ✅ AMBIL RIT TERAKHIR DARI DATABASE
    final int rit = await getCurrentRit(database, idUser);
    print('📌 RIT yang akan digunakan: $rit');

    // Pastikan tabel sudah ada
    final bool tableExists = await _isTableExists(database, 'penjualan_tiket');
    if (!tableExists) {
      await _createPenjualanTable(database);
    }

    int jumlahSukses = 0;
    int detikOffset = 0;
    List<String> insertedInvoices = [];

    print('==============================');
    print('💾 MULAI PROSES SIMPAN DATA MANIFEST KE DATABASE LOKAL');
    print('🕒 Waktu: $formattedDate');
    print('👤 idUser: $idUser | idGroup: $idGroup | idCompany: $idCompany');
    print('🚌 idBus: $idBus | noPol: $noPol | kodeTrayek: $kodeTrayek');
    print('🔄 RIT: $rit');  // ✅ Tampilkan RIT di log
    print('==============================');

    String getKategoriTiket(dynamic idAgen) {
      final int agenId = int.tryParse(idAgen.toString()) ?? 0;

      const Map<int, String> kategoriMap = {
        29: 'traveloka',
        30: 'red_bus',
        31: 'sysconix',
      };

      return kategoriMap[agenId] ?? 'offline';
    }

    for (var item in manifestList) {
      try {
        final String idInvoice = item['id_order_transaksi']?.toString() ?? '';
        final DateTime waktuTransaksi = DateTime.now().add(Duration(seconds: detikOffset));
        final String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(waktuTransaksi);

        detikOffset++;

        if (idInvoice.isEmpty) {
          print('⚠️ ID Invoice kosong, dilewati');
          continue;
        }

        final String kategoriTiket = getKategoriTiket(item['id_agen']);

        // Cek apakah id_invoice sudah ada di DB
        final existing = await database.query(
          'penjualan_tiket',
          where: 'id_invoice = ?',
          whereArgs: [idInvoice],
        );

        if (existing.isNotEmpty) {
          final String existingStatus = existing.first['status']?.toString() ?? 'N';

          if (existingStatus == 'Y') {
            print('⚠️ Data dengan id_invoice $idInvoice sudah ada dan sudah terkirim (status=Y), dilewati');
            continue;
          } else {
            print('🔁 Data dengan id_invoice $idInvoice sudah ada tapi belum terkirim (status=N), tetap diproses untuk pengiriman ulang');
            insertedInvoices.add(idInvoice);
            continue;
          }
        }

        // DEBUG sebelum insert
        print('------------------------------');
        print('🧾 Menyimpan data manifest baru:');
        print('📦 id_invoice       : $idInvoice');
        print('🔄 RIT              : $rit');  // ✅ Tampilkan RIT
        print('🏙️ kota_berangkat   : ${item['id_kota_berangkat']}');
        print('🏙️ kota_tujuan      : ${item['id_kota_tujuan']}');
        print('👤 nama_pembeli     : ${item['nama_penumpang']}');
        print('💰 harga_tercatat   : ${item['harga_tercatat']}');
        print('📅 tanggal_transaksi: $formattedDate');
        print('------------------------------');

        // Parse harga
        final hargaKantor = double.tryParse(item['harga_kantor']?.toString() ?? '0') ?? 0.0;
        final hargaTercatat = double.tryParse(item['harga_tercatat']?.toString() ?? '0') ?? 0.0;

        // ✅ INSERT DENGAN RIT YANG BENAR
        await database.insert('penjualan_tiket', {
          'no_pol': noPol,
          'id_bus': idBus,
          'id_user': idUser,
          'id_group': idGroup,
          'id_garasi': idGarasi,
          'id_company': idCompany,
          'jumlah_tiket': 1,
          'kategori_tiket': kategoriTiket,
          'rit': rit,  // ✅ Gunakan variabel rit, bukan hardcode 1
          'kota_berangkat': item['id_kota_berangkat']?.toString() ?? '',
          'kota_tujuan': item['id_kota_tujuan']?.toString() ?? '',
          'nama_pembeli': item['nama_penumpang']?.toString() ?? '',
          'no_telepon': item['no_tlp']?.toString() ?? '',
          'harga_kantor': hargaKantor,
          'jumlah_tagihan': hargaTercatat,
          'nominal_bayar': hargaTercatat,
          'jumlah_kembalian': 0.0,
          'tanggal_transaksi': formattedDate,
          'status': 'N',
          'kode_trayek': kodeTrayek,
          'keterangan': 'Penumpang MILA BUS',
          'id_invoice': idInvoice,
          'is_turun': 0,
          'status_bayar': 1,
        });

        jumlahSukses++;
        insertedInvoices.add(idInvoice);
        print('✅ Data berhasil disimpan untuk id_invoice: $idInvoice dengan RIT: $rit');
      } catch (e) {
        print('⚠️ Gagal simpan data manifest: $e');
      }
    }

    print('==============================');
    print('📊 RINGKASAN PENYIMPANAN');
    print('✅ Jumlah sukses: $jumlahSukses');
    print('🔄 RIT yang digunakan: $rit');  // ✅ Tampilkan RIT di ringkasan
    print('🧾 Total ID Invoice baru: ${insertedInvoices.length}');
    print('🧩 Daftar ID Invoice: ${insertedInvoices.join(', ')}');
    print('==============================');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(
        SnackBar(content: Text('$jumlahSukses data berhasil disimpan ke database lokal (RIT: $rit)')),
      );
    });

    return insertedInvoices;
  }

  /// 🔹 Ambil data penjualan yang belum dikirim (status = 'N')
  Future<List<Map<String, dynamic>>> getPenjualanBelumDikirim(List<String> idInvoices) async {
    final Database db = await databaseHelper.database;

    if (idInvoices.isEmpty) {
      return [];
    }

    final placeholders = List.filled(idInvoices.length, '?').join(',');
    final penjualanData = await db.query(
      'penjualan_tiket',
      where: 'status = ? AND id_invoice IN ($placeholders)',
      whereArgs: ['N', ...idInvoices],
    );

    return penjualanData;
  }

  /// 🔹 Ambil semua data penjualan untuk dikirim
  Future<List<Map<String, dynamic>>> getAllPenjualanBelumDikirim() async {
    final Database db = await databaseHelper.database;

    final penjualanData = await db.query(
      'penjualan_tiket',
      where: 'status = ?',
      whereArgs: ['N'],
    );

    return penjualanData;
  }

  /// 🔹 Update status penjualan di database lokal
  Future<void> updateStatusPenjualan(String idInvoice, String status) async {
    final Database db = await databaseHelper.database;

    await db.update(
      'penjualan_tiket',
      {'status': status},
      where: 'id_invoice = ?',
      whereArgs: [idInvoice],
    );

    print('✅ Status id_invoice $idInvoice diperbarui menjadi: $status');
  }

  /// 🔹 Hapus data penjualan berdasarkan id_invoice
  Future<void> deletePenjualan(String idInvoice) async {
    final Database db = await databaseHelper.database;

    await db.delete(
      'penjualan_tiket',
      where: 'id_invoice = ?',
      whereArgs: [idInvoice],
    );

    print('🗑️ Data id_invoice $idInvoice dihapus dari database lokal');
  }

  /// 🔹 Ambil jumlah data penjualan berdasarkan status
  Future<int> getJumlahPenjualanByStatus(String status) async {
    final Database db = await databaseHelper.database;

    final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM penjualan_tiket WHERE status = ?',
        [status]
    );

    return result.first['count'] as int? ?? 0;
  }

  /// 🔹 Ambil semua id_invoice yang ada di database lokal
  Future<List<String>> getAllIdInvoices() async {
    final Database db = await databaseHelper.database;

    final result = await db.rawQuery(
        'SELECT id_invoice FROM penjualan_tiket'
    );

    return result.map((e) => e['id_invoice']?.toString() ?? '').where((id) => id.isNotEmpty).toList();
  }

  /// 🔹 Cek apakah id_invoice sudah ada di database lokal
  Future<bool> isIdInvoiceExists(String idInvoice) async {
    final Database db = await databaseHelper.database;

    final result = await db.query(
      'penjualan_tiket',
      where: 'id_invoice = ?',
      whereArgs: [idInvoice],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// 🔹 Ambil data penjualan untuk print berdasarkan id_invoice
  Future<Map<String, dynamic>?> getDataUntukPrint(String idInvoice) async {
    final Database db = await databaseHelper.database;

    try {
      final result = await db.rawQuery('''
      SELECT 
        pt.*,
        lk_berangkat.nama_kota AS nama_kota_berangkat,
        lk_tujuan.nama_kota AS nama_kota_tujuan
      FROM 
        penjualan_tiket AS pt
        LEFT JOIN list_kota AS lk_berangkat ON pt.kota_berangkat = lk_berangkat.id_kota_tujuan
        LEFT JOIN list_kota AS lk_tujuan ON pt.kota_tujuan = lk_tujuan.id_kota_tujuan
      WHERE 
        pt.id_invoice = ?
      LIMIT 1
    ''', [idInvoice]);

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print('❌ Error mengambil data untuk print: $e');
      return null;
    }
  }
}