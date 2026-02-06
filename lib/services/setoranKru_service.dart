import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:mila_kru_reguler/models/setoranKru_model.dart';
import 'package:mila_kru_reguler/services/premi_posisi_kru_service.dart';
import 'package:mila_kru_reguler/models/premi_posisi_kru_model.dart';

class SetoranKruService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final PremiPosisiKruService _premiService = PremiPosisiKruService();

  // Insert
  Future<int> insertSetoran(SetoranKru setoran) async {
    final db = await _dbHelper.database;

    /// TAG HASIL KALKULASI
    final isCalculatedTag = [27, 32, 60, 61, 70].contains(setoran.idTagTransaksi);

    /// Untuk tag non-kalkulasi → nilai 0 dilewati
    if (!isCalculatedTag && setoran.nilai == 0) {
      print('⏭️ SKIP INSERT | nilai=0 | tag=${setoran.idTagTransaksi}');
      return 0;
    }

    final map = setoran.toMap();

    /// ================= LOG AWAL =================
    print('''
📝 PROSES SETORAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Tag ID      : ${setoran.idTagTransaksi}
Nilai       : ${setoran.nilai}
Rit         : ${setoran.rit}
No Pol      : ${setoran.noPol}
ID Bus      : ${setoran.idBus}
Kode Trayek : ${setoran.kodeTrayek}
Personil    : ${setoran.idPersonil}
Group       : ${setoran.idGroup}
Tanggal     : ${setoran.tglTransaksi}
Calculated  : $isCalculatedTag
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');

    try {
      /// ================= CEK SESUAI UNIQUE INDEX =================
      final existing = await db.query(
        't_setoran_kru',
        where: '''
        rit = ?
        AND no_pol = ?
        AND id_bus = ?
        AND kode_trayek = ?
        AND id_personil = ?
        AND id_group = ?
        AND id_tag_transaksi = ?
      ''',
        whereArgs: [
          setoran.rit,
          setoran.noPol,
          setoran.idBus,
          setoran.kodeTrayek,
          setoran.idPersonil,
          setoran.idGroup,
          setoran.idTagTransaksi,
        ],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final int rowId = existing.first['id'] as int;

        /// ================= UPDATE =================
        await db.update(
          't_setoran_kru',
          {
            'nilai': setoran.nilai,
            'jumlah': setoran.jumlah,
            'status': setoran.status,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [rowId],
        );

        print(
          '🔄 UPDATE BERHASIL | rowId=$rowId | tag=${setoran.idTagTransaksi} | nilai=${setoran.nilai}',
        );

        return rowId;
      }

      /// ================= INSERT =================
      final result = await db.insert(
        't_setoran_kru',
        map,
      );

      print(
        '✅ INSERT BERHASIL | rowId=$result | tag=${setoran.idTagTransaksi}',
      );

      return result;
    } catch (e, stackTrace) {
      print('''
❌ GAGAL PROSES SETORAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Error : $e
Data  : $map
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''');

      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }


  Future<bool> existsSetoranKru(SetoranKru setoran) async {
    final db = await _dbHelper.database;

    final result = await db.rawQuery(
      '''
    SELECT 1 FROM t_setoran_kru
    WHERE rit = ?
      AND no_pol = ?
      AND id_bus = ?
      AND kode_trayek = ?
      AND id_personil = ?
      AND id_group = ?
      AND id_tag_transaksi = ?
    LIMIT 1
    ''',
      [
        setoran.rit,
        setoran.noPol,
        setoran.idBus,
        setoran.kodeTrayek,
        setoran.idPersonil,
        setoran.idGroup,
        setoran.idTagTransaksi,
      ],
    );

    return result.isNotEmpty;
  }

  Future<bool> cekPremiHarianKruSudahAda({
    required int idTransaksi,
    required int idUser,
    required int idGroup,
    required String tanggalSimpan,
  }) async {
    final db = await _dbHelper.database;

    final result = await db.query(
      'premi_harian_kru',
      where: '''
      id_transaksi = ?
      AND id_user = ?
      AND id_group = ?
      AND tanggal_simpan = ?
    ''',
      whereArgs: [
        idTransaksi,
        idUser,
        idGroup,
        tanggalSimpan,
      ],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<void> updatePremiHarianKru({
    required int idTransaksi,
    required int idUser,
    required int idGroup,
    required String tanggalSimpan,
    required double persenPremi,
    required double nominalPremi,
    required String status,
  }) async {
    final db = await _dbHelper.database;

    await db.update(
      'premi_harian_kru',
      {
        'persen_premi_disetor': persenPremi,
        'nominal_premi_disetor': nominalPremi,
        'status': status,
      },
      where: '''
      id_transaksi = ?
      AND id_user = ?
      AND id_group = ?
      AND tanggal_simpan = ?
    ''',
      whereArgs: [
        idTransaksi,
        idUser,
        idGroup,
        tanggalSimpan,
      ],
    );
  }



  // Method untuk menghitung dan menyimpan premi bawah setiap kru
  Future<void> hitungDanSimpanPremiBawahKru({
      required double nominalPremiKru,
      required String tanggalTransaksi,
      required String rit,
      required String noPol,
      required int idBus,
      required String kodeTrayek,
    }) async {
      print('=== [DEBUG] MULAI HITUNG PREMI BAWAH KRU ===');
      print('Nominal Premi Kru: $nominalPremiKru');
      print('Tanggal Transaksi: $tanggalTransaksi');
      print('Rit: $rit, No Pol: $noPol, ID Bus: $idBus, Kode Trayek: $kodeTrayek');

      try {
        // 1. Ambil data premi posisi kru
        print('--- [DEBUG] AMBIL DATA PREMI POSISI KRU ---');
        final List<PremiPosisiKru> premiList = await _premiService.getAllPremiPosisiKru(); // PERBAIKAN: gunakan instance

        print('Jumlah data premi posisi kru: ${premiList.length}');
        for (var premi in premiList) {
          print('Premi: ${premi.namaPremi} - ${premi.persenPremi}%');
        }

        if (premiList.isEmpty) {
          print('⚠️ Tidak ada data premi posisi kru ditemukan');
          return;
        }

        // 2. Ambil data kru bis untuk mendapatkan id_personil dan id_group
        print('--- [DEBUG] AMBIL DATA KRU BIS ---');
        final List<Map<String, dynamic>> kruBisList = await _dbHelper.getKruBis();

        print('Jumlah data kru bis: ${kruBisList.length}');
        for (var kru in kruBisList) {
          print('Kru: ${kru['nama_lengkap']} - ${kru['group_name']} - ID: ${kru['id_personil']}');
        }

        if (kruBisList.isEmpty) {
          print('⚠️ Tidak ada data kru bis ditemukan');
          return;
        }

        // 3. Hitung premi bawah untuk setiap kru
        print('--- [DEBUG] HITUNG PREMI BAWAH SETIAP KRU ---');
        for (var kru in kruBisList) {
          final int idPersonil = kru['id_personil'];
          final int idGroup = kru['id_group'];
          final String namaLengkap = kru['nama_lengkap'];
          final String groupName = kru['group_name'];

          print('Proses kru: $namaLengkap ($groupName)');

          // Cari premi dengan matching yang flexible
          PremiPosisiKru? premiKru;
          try {
            premiKru = premiList.firstWhere(
                  (premi) {
                final premiName = (premi.namaPremi ?? '').toLowerCase().trim();
                final groupNameNormalized = groupName.toLowerCase().trim();

                // Debug matching
                print('   - Mencocokkan: "$premiName" dengan "$groupNameNormalized"');

                return premiName == groupNameNormalized;
              },
            );
          } catch (e) {
            print('⚠️ Premi tidak ditemukan untuk "$groupName"');

            // Tampilkan daftar premi yang tersedia untuk debugging
            print('   Daftar premi tersedia:');
            for (var p in premiList) {
              print('     - "${p.namaPremi}"');
            }
            continue;
          }

          print('✅ Premi ditemukan: ${premiKru.namaPremi} - ${premiKru.persenPremi}%');

          final String persenPremiStr = (premiKru.persenPremi ?? '0').toString();
          final double persenPremi = double.tryParse(persenPremiStr.replaceAll('%', '').replaceAll(' ', '')) ?? 0.0;

          // Hitung nominal premi bawah
          final double nominalPremiBawah = (nominalPremiKru * persenPremi) / 100;

          print('📊 Perhitungan premi bawah:');
          print('   - Persen premi: $persenPremi%');
          print('   - Nominal premi kru: $nominalPremiKru');
          print('   - Hasil: $nominalPremiBawah');

        }

        print('=== [DEBUG] SELESAI HITUNG PREMI BAWAH KRU ===');

      } catch (e, stackTrace) {
        print('❌ ERROR dalam hitungDanSimpanPremiBawahKru: $e');
        print(stackTrace);
        rethrow;
      }
  }

  // Method untuk proses simpan setoran lengkap dengan premi
  Future<void> simpanSetoranLengkap({
    required List<SetoranKru> setoranList,
    required double nominalPremiKru,
    required String tanggalTransaksi,
    required String rit,
    required String noPol,
    required int idBus,
    required String kodeTrayek,
  }) async {
    print('=== [DEBUG] MULAI SIMPAN SETORAN LENGKAP ===');
    print('Jumlah setoran: ${setoranList.length}');
    print('Nominal Premi Kru: $nominalPremiKru');

    try {
      // 1. Simpan semua setoran dasar
      print('--- [DEBUG] SIMPAN SETORAN DASAR xxx ---');
      for (var setoran in setoranList) {
        await insertSetoran(setoran);
      }

      // 2. Hitung dan simpan premi bawah untuk setiap kru
      if (nominalPremiKru > 0) {
        await hitungDanSimpanPremiBawahKru(
          nominalPremiKru: nominalPremiKru,
          tanggalTransaksi: tanggalTransaksi,
          rit: rit,
          noPol: noPol,
          idBus: idBus,
          kodeTrayek: kodeTrayek,
        );
      } else {
        print('⚠️ Nominal premi kru 0, skip perhitungan premi bawah');
      }

      print('✅ Semua setoran berhasil disimpan');
      print('=== [DEBUG] SELESAI SIMPAN SETORAN LENGKAP ===');

    } catch (e, stackTrace) {
      print('❌ ERROR dalam simpanSetoranLengkap: $e');
      print(stackTrace);
      rethrow;
    }
  }

  // Get all
  Future<List<SetoranKru>> getAllSetoran() async {
    try {
      final db = await _dbHelper.database;

      print("===============================================");
      print("📥 MENGAMBIL SEMUA DATA SETORAN KRU DARI TABEL");
      print("===============================================");

      final maps = await db.query('t_setoran_kru');

      print("🔢 Total data ditemukan: ${maps.length}");

      if (maps.isEmpty) {
        print("⚠️ Tabel t_setoran_kru masih kosong.");
        return [];
      }

      print("-----------------------------------------------");
      print("📄 DATA TABEL t_setoran_kru:");
      print("-----------------------------------------------");

      int index = 0;
      for (var row in maps) {
        print("Row #$index:");
        print(const JsonEncoder.withIndent('  ').convert(row));
        print("-----------------------------------------------");
        index++;
      }

      // Convert to model
      return maps.map((e) => SetoranKru.fromMap(e)).toList();

    } catch (e) {
      print("🔥 ERROR saat mengambil data dari t_setoran_kru: $e");
      return [];
    }
  }


  // Get by id
  Future<SetoranKru?> getSetoranById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      't_setoran_kru',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return SetoranKru.fromMap(maps.first);
    }
    return null;
  }

  // Get setoran by tanggal dan rit
  Future<List<SetoranKru>> getSetoranByTanggalRit(String tanggal, String rit) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      't_setoran_kru',
      where: 'tgl_transaksi = ? AND rit = ?',
      whereArgs: [tanggal, rit],
    );
    return maps.map((e) => SetoranKru.fromMap(e)).toList();
  }

  // Get setoran premi bawah
  Future<List<SetoranKru>> getSetoranPremiBawah() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      't_setoran_kru',
      where: 'id_tag_transaksi = ?',
      whereArgs: [32], // ID untuk Premi Bawah
    );
    return maps.map((e) => SetoranKru.fromMap(e)).toList();
  }

  // Update
  Future<int> updateSetoran(SetoranKru setoran) async {
    final db = await _dbHelper.database;
    return await db.update(
      't_setoran_kru',
      setoran.toMap(),
      where: 'id = ?',
      whereArgs: [setoran.id],
    );
  }

  // Delete
  Future<int> deleteSetoran(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      't_setoran_kru',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete setoran by tanggal dan rit
  Future<int> deleteSetoranByTanggalRit(String tanggal, String rit) async {
    final db = await _dbHelper.database;
    return await db.delete(
      't_setoran_kru',
      where: 'tgl_transaksi = ? AND rit = ?',
      whereArgs: [tanggal, rit],
    );
  }

  // Optional: delete all
  Future<int> clearSetoran() async {
    final db = await _dbHelper.database;
    return await db.delete('t_setoran_kru');
  }

  Future<void> updateFilePath(int idTagTransaksi, String filePath) async {
    final db = await DatabaseHelper.instance.database;

    await db.update(
      't_setoran_kru',
      {
        'fupload': filePath,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id_tag_transaksi = ? AND status = ?',
      whereArgs: [idTagTransaksi, 'N'], // update hanya yang belum dikirim
    );

    print("🔧 File path updated untuk idTagTransaksi: $idTagTransaksi → $filePath");
  }

}