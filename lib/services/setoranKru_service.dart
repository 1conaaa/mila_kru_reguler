import 'package:sqflite/sqflite.dart';
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

    // Debug: tampilkan data yang akan dimasukkan
    print('--- INSERT SETORAN ---');
    print('Data setoran: ${setoran.toMap()}');

    try {
      final result = await db.insert(
        't_setoran_kru',
        setoran.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Debug: tampilkan hasil insert
      print('Insert berhasil, row ID: $result');

      // Debug: tampilkan semua isi tabel setelah insert
      final allSetoran = await getAllSetoran();
      print('--- ISI TABLE t_setoran_kru ---');
      for (var s in allSetoran) {
        print(s.toMap());
      }

      return result;
    } catch (e, stackTrace) {
      // Debug: tampilkan error jika gagal insert
      print('Gagal insert setoran: $e');
      print(stackTrace);

      // Debug: tampilkan semua isi tabel setelah gagal insert
      try {
        final allSetoran = await getAllSetoran();
        print('--- ISI TABLE t_setoran_kru (SETELAH GAGAL INSERT) ---');
        for (var s in allSetoran) {
          print(s.toMap());
        }
      } catch (e2) {
        print('Gagal menampilkan isi tabel: $e2');
      }

      rethrow;
    }
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

        // 4. Simpan premi bawah ke tabel setoran kru
        // if (nominalPremiBawah > 0) {
        //   final setoranPremiBawah = SetoranKru(
        //     tglTransaksi: tanggalTransaksi,
        //     kmPulang: 0,
        //     rit: rit,
        //     noPol: noPol,
        //     idBus: idBus,
        //     kodeTrayek: kodeTrayek,
        //     idPersonil: idPersonil,
        //     idGroup: idGroup,
        //     jumlah: 1,
        //     idTransaksi: 'PREMI_BAWAH_${DateTime.now().millisecondsSinceEpoch}_$idPersonil',
        //     coa: null,
        //     nilai: nominalPremiBawah,
        //     idTagTransaksi: 32,
        //     status: 'N',
        //     keterangan: 'Premi Bawah untuk $namaLengkap ($groupName)',
        //     fupload: null,
        //     fileName: null,
        //     updatedAt: DateTime.now().toString(),
        //     createdAt: DateTime.now().toString(),
        //   );
        //
        //   try {
        //     final result = await insertSetoran(setoranPremiBawah);
        //     print('✅ Premi bawah berhasil disimpan untuk $namaLengkap: ID $result');
        //   } catch (e) {
        //     print('❌ Gagal menyimpan premi bawah untuk $namaLengkap: $e');
        //   }
        // } else {
        //   print('⚠️ Premi bawah 0 untuk $namaLengkap, tidak disimpan');
        // }
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
      print('--- [DEBUG] SIMPAN SETORAN DASAR ---');
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
    final db = await _dbHelper.database;
    final maps = await db.query('t_setoran_kru');
    return maps.map((e) => SetoranKru.fromMap(e)).toList();
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
}