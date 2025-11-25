import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/models/user_data.dart';

class PremiBersihCalculator {
  /// Method utama untuk kalkulasi premi bersih dengan user data
  static Map<String, dynamic> calculatePremiBersih({
    required List<TagTransaksi> tagPendapatan,
    required List<TagTransaksi> tagPengeluaran,
    required List<TagTransaksi> tagPremi,
    required List<TagTransaksi> tagBersihSetoran,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
    required UserData userData,
  }) {
    final allData = collectAllTagData(
      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      controllers: controllers,
      jumlahControllers: jumlahControllers,
      literSolarControllers: literSolarControllers,
    );

    // Ekstrak nilai dari controllers berdasarkan ID tag
    final Map<String, double> extractedValues = _extractValuesFromControllers(
      controllers: controllers,
      jumlahControllers: jumlahControllers,
      literSolarControllers: literSolarControllers,
    );

    // Kalkulasi berdasarkan formula kompleks sesuai aturan bisnis
    final Map<String, dynamic> complexCalculations = _calculateComplexPremi(
      extractedValues: extractedValues,
      userData: userData,
      allData: allData,
    );

    // Debug output
    _printDebugInfo(
      complexCalculations,
      userData,
    );

    return {
      ...complexCalculations,
      'allData': allData,
      'userData': userData,
    };
  }

  /// Method untuk kalkulasi tanpa user data (menggunakan default)
  static Map<String, dynamic> calculatePremiBersihWithoutUser({
    required List<TagTransaksi> tagPendapatan,
    required List<TagTransaksi> tagPengeluaran,
    required List<TagTransaksi> tagPremi,
    required List<TagTransaksi> tagBersihSetoran,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
  }) {
    return calculatePremiBersih(
      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      controllers: controllers,
      jumlahControllers: jumlahControllers,
      literSolarControllers: literSolarControllers,
      userData: UserData.empty(),
    );
  }

  /// Ekstrak nilai dari controllers berdasarkan ID tag
  static Map<String, double> _extractValuesFromControllers({
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
  }) {
    double getValue(int id) {
      final text = controllers[id]?.text ?? '0';
      return double.tryParse(text.replaceAll('.', '').replaceAll(',00', '')) ?? 0.0;
    }

    double getLiterSolar(int id) {
      final text = literSolarControllers[id]?.text ?? '0';
      return double.tryParse(text) ?? 0.0;
    }

    return {
      // Pendapatan
      'nominalTiketReguler': getValue(1),      // ID 1: Pendapatan Tiket Reguler
      'nominalTiketOnline': getValue(2),       // ID 2: Pendapatan Tiket Ota
      'pendapatanBagasi': getValue(3),         // ID 3: Pendapatan Bagasi

      // Pengeluaran Operasional
      'pengeluaranTol': getValue(15),          // ID 15: Biaya Tol
      'litersolar': getLiterSolar(16),         // ID 16: Biaya Solar (liter)
      'nominalsolar': getValue(16),            // ID 16: Biaya Solar (nominal)
      'pengeluaranCuci': getValue(17),         // ID 17: Biaya Cuci
      'pengeluaranLainLain': getValue(18),     // ID 18: Biaya Lain-Lain
      'pengeluaranPerbaikan': getValue(22),    // ID 22: Biaya Perbaikan
      'pengeluaranMakelar': getValue(28),      // ID 28: Biaya Makelar
      'pengeluaranParkir': getValue(29),       // ID 29: Biaya Parkir Terminal
      'operan': getValue(33),                  // ID 33: Operan
      'pengeluaranSuramadu': getValue(59),     // ID 59: Biaya Suramadu
      'uangMakan': getValue(13),               // ID 13: Uang Makan Kru
      'uangSakuSupir': getValue(34),           // ID 34: Uang Saku Supir
      'uangSakuKondektur': getValue(35),       // ID 35: Uang Saku Kondektur
      'pengeluaranTpr': getValue(30),          // ID 30: Biaya Tpr
      'pengeluaranOperasionalSby': getValue(31), // ID 31: Biaya Operasional Surabaya

      // Premi
      'premiAtas': getValue(27),               // ID 27: Premi Atas
      'premiBawah': getValue(32),              // ID 32: Premi Bawah
    };
  }

  /// Kalkulasi kompleks berdasarkan aturan bisnis
  /// Kalkulasi kompleks berdasarkan aturan bisnis
  static Map<String, dynamic> _calculateComplexPremi({
    required Map<String, double> extractedValues,
    required UserData userData,
    required Map<String, List<TagData>> allData,
  }) {
    print('=== [DEBUG] START CALCULATION ===');
    print('Kelas Bus: ${userData.kelasBus}');
    print('Jenis Trayek: ${userData.jenisTrayek}');
    print('Nama Trayek: ${userData.namaTrayek}');
    print('Premi Extra: ${userData.premiExtra}%');
    print('Persen Premi Kru: ${userData.persenPremikru}%');

    // Ekstrak nilai
    final double nominalTiketReguler = extractedValues['nominalTiketReguler']!;
    final double nominalTiketOnline = extractedValues['nominalTiketOnline']!;
    final double pendapatanBagasi = extractedValues['pendapatanBagasi']!;
    final double pengeluaranTol = extractedValues['pengeluaranTol']!;
    final double nominalsolar = extractedValues['nominalsolar']!;
    final double pengeluaranCuci = extractedValues['pengeluaranCuci']!;
    final double pengeluaranLainLain = extractedValues['pengeluaranLainLain']!;
    final double pengeluaranPerbaikan = extractedValues['pengeluaranPerbaikan']!;
    final double pengeluaranMakelar = extractedValues['pengeluaranMakelar']!;
    final double pengeluaranParkir = extractedValues['pengeluaranParkir']!;
    final double operan = extractedValues['operan']!;
    final double pengeluaranSuramadu = extractedValues['pengeluaranSuramadu']!;
    final double uangMakan = extractedValues['uangMakan']!;
    final double uangSakuSupir = extractedValues['uangSakuSupir']!;
    final double uangSakuKondektur = extractedValues['uangSakuKondektur']!;
    final double pengeluaranTpr = extractedValues['pengeluaranTpr']!;
    final double pengeluaranOperasionalSby = extractedValues['pengeluaranOperasionalSby']!;

    // Debug nilai yang diekstrak
    print('=== [DEBUG] EXTRACTED VALUES ===');
    print('Nominal Tiket Reguler: $nominalTiketReguler');
    print('Nominal Tiket Online: $nominalTiketOnline');
    print('Pendapatan Bagasi: $pendapatanBagasi');
    print('Operan: $operan');
    print('Pengeluaran Tol: $pengeluaranTol');
    print('Nominal Solar: $nominalsolar');
    print('Pengeluaran Cuci: $pengeluaranCuci');
    print('Pengeluaran Lain-Lain: $pengeluaranLainLain');
    print('Pengeluaran Perbaikan: $pengeluaranPerbaikan');
    print('Pengeluaran Makelar: $pengeluaranMakelar');
    print('Pengeluaran Parkir: $pengeluaranParkir');
    print('Pengeluaran Suramadu: $pengeluaranSuramadu');
    print('Uang Makan: $uangMakan');
    print('Uang Saku Supir: $uangSakuSupir');
    print('Uang Saku Kondektur: $uangSakuKondektur');
    print('Pengeluaran TPR: $pengeluaranTpr');
    print('Pengeluaran Operasional Sby: $pengeluaranOperasionalSby');

    // Parse persentase premi dari userData
    final double persenPremiExtra = (double.tryParse(userData.premiExtra.replaceAll('%', '')) ?? 0.0) / 100;
    final double persenPremiKru = ((double.tryParse(userData.persenPremikru.replaceAll('%', '')) ?? 0.0) -
        (double.tryParse(userData.premiExtra.replaceAll('%', '')) ?? 0.0)) / 100;

    print('=== [DEBUG] PARSED PERCENTAGES ===');
    print('Persen Premi Extra: $persenPremiExtra');
    print('Persen Premi Kru: $persenPremiKru');

    // Variabel umum
    final double pendKeseluruhan = nominalTiketReguler + nominalTiketOnline + pendapatanBagasi;
    // final double pendapatanKotor = (pendKeseluruhan-pendapatanBagasi) - operan;
    final double pendapatanKotor = pendKeseluruhan - operan;

    print('=== [DEBUG] BASE CALCULATIONS ===');
    print('Pendapatan Keseluruhan: $pendKeseluruhan');
    print('Pendapatan Kotor (Reguler - Operan): $pendapatanKotor');

    double nominalPremiExtra = 0.0;
    double nominalPremiKru = 0.0;
    double pendBersih = 0.0;
    double pendDisetor = 0.0;
    double totalPengeluaran = 0.0;
    double sisaPendapatan = 0.0;
    double tolAdjustment = pengeluaranTol;

    // Logika berdasarkan kelas bus, jenis trayek, dan nama trayek
    switch (userData.kelasBus) {
      case 'Ekonomi':
        print('=== [DEBUG] PROCESSING: EKONOMI ===');
        switch (userData.jenisTrayek) {
          case 'AKAP':
            print('=== [DEBUG] PROCESSING: AKAP ===');
            switch (userData.namaTrayek) {
              case 'YOGYAKARTA - BANYUWANGI':
              case 'BANYUWANGI - YOGYAKARTA':
                print('=== [DEBUG] PROCESSING: YOGYAKARTA - BANYUWANGI ===');
                // Pengeluaran untuk AKAP Ekonomi Yogyakarta-Banyuwangi
                totalPengeluaran = nominalsolar + pengeluaranMakelar + pengeluaranCuci +
                    pengeluaranParkir + pengeluaranPerbaikan + pengeluaranLainLain;

                print('=== [DEBUG] PENGELUARAN DETAIL ===');
                print('Solar: $nominalsolar');
                print('Makelar: $pengeluaranMakelar');
                print('Cuci: $pengeluaranCuci');
                print('Parkir: $pengeluaranParkir');
                print('Perbaikan: $pengeluaranPerbaikan');
                print('Lain-lain: $pengeluaranLainLain');
                print('Total Pengeluaran: $totalPengeluaran');

                pendBersih = pendapatanKotor - totalPengeluaran;
                print('Pendapatan Bersih (Kotor - Pengeluaran): $pendBersih');

                // Premi berdasarkan pendapatan bersih
                nominalPremiExtra = pendBersih * persenPremiExtra;
                nominalPremiKru = pendBersih * persenPremiKru;

                print('Premi Extra ($persenPremiExtra): $nominalPremiExtra');
                print('Premi Kru ($persenPremiKru): $nominalPremiKru');

                sisaPendapatan = pendBersih - nominalPremiExtra;
                print('Sisa Pendapatan (Bersih - Premi Extra): $sisaPendapatan');

                // Adjust tol berdasarkan sisa pendapatan
                if (sisaPendapatan > 0) {
                  if (sisaPendapatan < 2500000) {
                    tolAdjustment = 140000;
                    print('Tol Adjustment: 140.000 (sisa < 2.5jt)');
                  } else if (sisaPendapatan > 2500000) {
                    tolAdjustment = 270000;
                    print('Tol Adjustment: 270.000 (sisa > 2.5jt)');
                  }
                } else {
                  print('Tol Adjustment: Tidak ada penyesuaian (sisa <= 0)');
                }

                pendDisetor = sisaPendapatan - tolAdjustment + pendapatanBagasi - nominalTiketOnline;
                print('=== [DEBUG] FINAL CALCULATION ===');
                print('Pendapatan Bersih: $pendBersih');
                print('Sisa Pendapatan: $sisaPendapatan');
                print('Tol Adjustment: $tolAdjustment');
                print('Pendapatan Bagasi: $pendapatanBagasi');
                print('Tiket Online: $nominalTiketOnline');
                print('Pendapatan Disetor: $pendDisetor');
                break;

              case 'MADURA - YOGYAKARTA':
              case 'YOGYAKARTA - MADURA':
                print('=== [DEBUG] PROCESSING: MADURA - YOGYAKARTA ===');
                // Pengeluaran untuk AKAP Ekonomi Madura-Yogyakarta (termasuk Suramadu)
                totalPengeluaran = nominalsolar + pengeluaranMakelar + pengeluaranCuci +
                    pengeluaranParkir + pengeluaranPerbaikan + pengeluaranLainLain + pengeluaranSuramadu;

                print('=== [DEBUG] PENGELUARAN DETAIL ===');
                print('Solar: $nominalsolar');
                print('Makelar: $pengeluaranMakelar');
                print('Cuci: $pengeluaranCuci');
                print('Parkir: $pengeluaranParkir');
                print('Perbaikan: $pengeluaranPerbaikan');
                print('Lain-lain: $pengeluaranLainLain');
                print('Suramadu: $pengeluaranSuramadu');
                print('Total Pengeluaran: $totalPengeluaran');

                pendBersih = pendapatanKotor - totalPengeluaran;
                print('Pendapatan Bersih (Kotor - Pengeluaran): $pendBersih');

                nominalPremiExtra = pendBersih * persenPremiExtra;
                nominalPremiKru = pendBersih * persenPremiKru;

                print('Premi Extra ($persenPremiExtra): $nominalPremiExtra');
                print('Premi Kru ($persenPremiKru): $nominalPremiKru');

                sisaPendapatan = pendBersih - nominalPremiExtra;
                print('Sisa Pendapatan (Bersih - Premi Extra): $sisaPendapatan');

                // Adjust tol berdasarkan sisa pendapatan
                if (sisaPendapatan > 0) {
                  if (sisaPendapatan < 2500000) {
                    tolAdjustment = 140000;
                    print('Tol Adjustment: 140.000 (sisa < 2.5jt)');
                  } else if (sisaPendapatan > 2500000) {
                    tolAdjustment = 270000;
                    print('Tol Adjustment: 270.000 (sisa > 2.5jt)');
                  }
                } else {
                  print('Tol Adjustment: Tidak ada penyesuaian (sisa <= 0)');
                }

                pendDisetor = sisaPendapatan - tolAdjustment + pendapatanBagasi - nominalTiketOnline;
                print('=== [DEBUG] FINAL CALCULATION ===');
                print('Sisa Pendapatan: $sisaPendapatan');
                print('Tol Adjustment: $tolAdjustment');
                print('Pendapatan Bagasi: $pendapatanBagasi');
                print('Tiket Online: $nominalTiketOnline');
                print('Pendapatan Disetor: $pendDisetor');
                break;

              default:
                print('=== [DEBUG] PROCESSING: AKAP EKONOMI DEFAULT ===');
                // Default calculation for AKAP Ekonomi lainnya
                totalPengeluaran = nominalsolar + pengeluaranMakelar + pengeluaranCuci +
                    pengeluaranParkir + pengeluaranPerbaikan + pengeluaranLainLain;

                print('Total Pengeluaran: $totalPengeluaran');

                pendBersih = pendapatanKotor - totalPengeluaran;
                nominalPremiExtra = pendBersih * persenPremiExtra;
                nominalPremiKru = pendBersih * persenPremiKru;
                pendDisetor = pendBersih - nominalPremiExtra + pendapatanBagasi - nominalTiketOnline;

                print('Pendapatan Bersih: $pendBersih');
                print('Premi Extra: $nominalPremiExtra');
                print('Premi Kru: $nominalPremiKru');
                print('Pendapatan Disetor: $pendDisetor');
            }
            break;

          case 'AKDP':
            print('=== [DEBUG] PROCESSING: AKDP ===');
            switch (userData.namaTrayek) {
              case 'JEMBER - KALIANGET':
              case 'KALIANGET - JEMBER':
              case 'AMBULU - PONOROGO':
              case 'PONOROGO - AMBULU':
                print('=== [DEBUG] PROCESSING: ${userData.namaTrayek} ===');
                // Pengeluaran untuk AKDP Ekonomi
                totalPengeluaran = nominalsolar + pengeluaranTol + pengeluaranCuci +
                    pengeluaranParkir + pengeluaranPerbaikan + pengeluaranLainLain;

                print('=== [DEBUG] PENGELUARAN DETAIL ===');
                print('Solar: $nominalsolar');
                print('Tol: $pengeluaranTol');
                print('Cuci: $pengeluaranCuci');
                print('Parkir: $pengeluaranParkir');
                print('Perbaikan: $pengeluaranPerbaikan');
                print('Lain-lain: $pengeluaranLainLain');
                print('Total Pengeluaran: $totalPengeluaran');

                pendBersih = pendapatanKotor - totalPengeluaran;
                nominalPremiExtra = pendBersih * persenPremiExtra;
                nominalPremiKru = pendBersih * persenPremiKru;
                pendDisetor = pendBersih - nominalPremiExtra + pendapatanBagasi - nominalTiketOnline;

                print('=== [DEBUG] FINAL CALCULATION ===');
                print('Pendapatan Bersih: $pendBersih');
                print('Premi Extra: $nominalPremiExtra');
                print('Premi Kru: $nominalPremiKru');
                print('Pendapatan Disetor: $pendDisetor');
                break;

              default:
                print('=== [DEBUG] PROCESSING: AKDP EKONOMI DEFAULT ===');
                // Default calculation for AKDP Ekonomi
                totalPengeluaran = nominalsolar + pengeluaranTol + pengeluaranCuci +
                    pengeluaranParkir + pengeluaranPerbaikan + pengeluaranLainLain;

                print('Total Pengeluaran: $totalPengeluaran');

                pendBersih = pendapatanKotor - totalPengeluaran;
                nominalPremiExtra = pendBersih * persenPremiExtra;
                nominalPremiKru = pendBersih * persenPremiKru;
                pendDisetor = pendBersih - nominalPremiExtra + pendapatanBagasi - nominalTiketOnline;

                print('Pendapatan Bersih: $pendBersih');
                print('Premi Extra: $nominalPremiExtra');
                print('Premi Kru: $nominalPremiKru');
                print('Pendapatan Disetor: $pendDisetor');
            }
            break;
        }
        break;

      case 'Non Ekonomi':
        print('=== [DEBUG] PROCESSING: NON EKONOMI ===');
        switch (userData.jenisTrayek) {
          case 'AKDP':
            print('=== [DEBUG] PROCESSING: AKDP ===');
            switch (userData.namaTrayek) {
              case 'JEMBER - SURABAYA':
              case 'SURABAYA - JEMBER':
                print('=== [DEBUG] PROCESSING: ${userData.namaTrayek} ===');
                // Pengeluaran untuk Non Ekonomi AKDP Jember-Surabaya
                totalPengeluaran = nominalsolar + pengeluaranTpr + pengeluaranParkir +
                    pengeluaranCuci + pengeluaranOperasionalSby +
                    pengeluaranPerbaikan + pengeluaranTol + uangMakan;

                print('=== [DEBUG] PENGELUARAN DETAIL ===');
                print('Solar: $nominalsolar');
                print('TPR: $pengeluaranTpr');
                print('Parkir: $pengeluaranParkir');
                print('Cuci: $pengeluaranCuci');
                print('Operasional Sby: $pengeluaranOperasionalSby');
                print('Perbaikan: $pengeluaranPerbaikan');
                print('Tol: $pengeluaranTol');
                print('Uang Makan: $uangMakan');
                print('Total Pengeluaran: $totalPengeluaran');

                pendBersih = pendapatanKotor - totalPengeluaran;
                nominalPremiExtra = pendBersih * persenPremiExtra;
                nominalPremiKru = pendBersih * persenPremiKru;
                sisaPendapatan = pendBersih - nominalPremiExtra;
                pendDisetor = sisaPendapatan + pendapatanBagasi - nominalTiketOnline;

                print('=== [DEBUG] FINAL CALCULATION ===');
                print('Pendapatan Bersih: $pendBersih');
                print('Premi Extra: $nominalPremiExtra');
                print('Premi Kru: $nominalPremiKru');
                print('Sisa Pendapatan: $sisaPendapatan');
                print('Pendapatan Disetor: $pendDisetor');
                break;

              case 'JEMBER - YOGYAKARTA':
              case 'YOGYAKARTA - JEMBER':
                print('=== [DEBUG] PROCESSING: ${userData.namaTrayek} ===');
                // Khusus Jember-Yogyakarta menggunakan uang saku tetap
                totalPengeluaran = uangSakuSupir + uangSakuKondektur + pengeluaranTol + nominalsolar;

                print('=== [DEBUG] PENGELUARAN DETAIL ===');
                print('Uang Saku Supir: $uangSakuSupir');
                print('Uang Saku Kondektur: $uangSakuKondektur');
                print('Tol: $pengeluaranTol');
                print('Solar: $nominalsolar');
                print('Total Pengeluaran: $totalPengeluaran');

                pendBersih = pendapatanKotor - totalPengeluaran;
                nominalPremiExtra = 0; // Tidak ada premi untuk rute ini
                nominalPremiKru = 0;
                pendDisetor = pendBersih + pendapatanBagasi - nominalTiketOnline;

                print('=== [DEBUG] FINAL CALCULATION ===');
                print('Pendapatan Bersih: $pendBersih');
                print('Premi Extra: $nominalPremiExtra (TIDAK ADA PREMI)');
                print('Premi Kru: $nominalPremiKru (TIDAK ADA PREMI)');
                print('Pendapatan Disetor: $pendDisetor');
                break;

              default:
                print('=== [DEBUG] PROCESSING: AKDP NON EKONOMI DEFAULT ===');
                // Default calculation for Non Ekonomi AKDP
                totalPengeluaran = nominalsolar + pengeluaranTpr + pengeluaranParkir +
                    pengeluaranCuci + pengeluaranOperasionalSby +
                    pengeluaranPerbaikan + pengeluaranTol + uangMakan;

                print('Total Pengeluaran: $totalPengeluaran');

                pendBersih = pendapatanKotor - totalPengeluaran;
                nominalPremiExtra = pendBersih * persenPremiExtra;
                nominalPremiKru = pendBersih * persenPremiKru;
                pendDisetor = pendBersih - nominalPremiExtra + pendapatanBagasi - nominalTiketOnline;

                print('Pendapatan Bersih: $pendBersih');
                print('Premi Extra: $nominalPremiExtra');
                print('Premi Kru: $nominalPremiKru');
                print('Pendapatan Disetor: $pendDisetor');
            }
            break;

          case 'AKAP':
            print('=== [DEBUG] PROCESSING: AKAP NON EKONOMI (PREMI PATAS) ===');
            // Premi Patas untuk Non Ekonomi AKAP
            totalPengeluaran = uangSakuSupir + uangSakuKondektur + pengeluaranParkir +
                pengeluaranOperasionalSby + uangMakan + pengeluaranCuci +
                pengeluaranMakelar + pengeluaranPerbaikan;

            print('=== [DEBUG] PENGELUARAN DETAIL ===');
            print('Uang Saku Supir: $uangSakuSupir');
            print('Uang Saku Kondektur: $uangSakuKondektur');
            print('Parkir: $pengeluaranParkir');
            print('Operasional Sby: $pengeluaranOperasionalSby');
            print('Uang Makan: $uangMakan');
            print('Cuci: $pengeluaranCuci');
            print('Makelar: $pengeluaranMakelar');
            print('Perbaikan: $pengeluaranPerbaikan');
            print('Total Pengeluaran: $totalPengeluaran');

            pendBersih = pendapatanKotor - totalPengeluaran;
            print('Pendapatan Bersih: $pendBersih');

            // Ketentuan khusus premi patas
            if (pendBersih > 2000000) {
              // Mendapat premi patas
              nominalPremiExtra = pendBersih * persenPremiExtra;
              nominalPremiKru = pendBersih * persenPremiKru;
              print('STATUS: MENDAPAT PREMI PATAS (pendapatan > 2jt)');
            } else {
              // Hanya mendapat uang saku
              nominalPremiExtra = 0;
              nominalPremiKru = 0;
              print('STATUS: HANYA UANG SAKU (pendapatan ≤ 2jt)');
            }

            sisaPendapatan = pendBersih - nominalPremiExtra;
            pendDisetor = sisaPendapatan + pendapatanBagasi - nominalTiketOnline;

            print('=== [DEBUG] FINAL CALCULATION ===');
            print('Premi Extra: $nominalPremiExtra');
            print('Premi Kru: $nominalPremiKru');
            print('Sisa Pendapatan: $sisaPendapatan');
            print('Pendapatan Disetor: $pendDisetor');
            break;
        }
        break;
    }

    // Validasi nilai negatif
    print('=== [DEBUG] VALIDATION ===');
    if (nominalPremiExtra <= 0) {
      nominalPremiExtra = 0;
      print('Premi Extra diset ke 0 (nilai negatif)');
    }
    if (nominalPremiKru <= 0) {
      nominalPremiKru = 0;
      print('Premi Kru diset ke 0 (nilai negatif)');
    }
    if (pendBersih <= 0) {
      pendBersih = 0;
      pendDisetor = 0;
      print('Pendapatan Bersih & Disetor diset ke 0 (nilai negatif)');
    }

    print('=== [DEBUG] FINAL RESULTS ===');
    print('Nominal Premi Extra: $nominalPremiExtra');
    print('Nominal Premi Kru: $nominalPremiKru');
    print('Pendapatan Bersih: $pendBersih');
    print('Pendapatan Disetor: $pendDisetor');
    print('Total Pengeluaran: $totalPengeluaran');
    print('=== [DEBUG] END CALCULATION ===');

    return {
      'nominalPremiExtra': nominalPremiExtra,
      'nominalPremiKru': nominalPremiKru,
      'pendapatanBersih': pendBersih,
      'pendapatanDisetor': pendDisetor,
      'totalPendapatan': pendKeseluruhan,
      'totalPengeluaran': totalPengeluaran,
      'sisaPendapatan': sisaPendapatan,
      'tolAdjustment': tolAdjustment,
      'persenPremiExtra': persenPremiExtra,
      'persenPremiKru': persenPremiKru,
      'namaTrayek': userData.namaTrayek,
      'jenisTrayek': userData.jenisTrayek,
      'kelasBus': userData.kelasBus,
    };
  }

  /// Update controllers untuk field yang dihitung otomatis
  static void updateAutoCalculatedFields({
    required Map<String, dynamic> calculationResult,
    required Map<int, TextEditingController> controllers,
    required UserData userData,
  }) {
    final double nominalPremiExtra = calculationResult['nominalPremiExtra'] as double;
    final double nominalPremiKru = calculationResult['nominalPremiKru'] as double;
    final double pendapatanBersih = calculationResult['pendapatanBersih'] as double;
    final double pendapatanDisetor = calculationResult['pendapatanDisetor'] as double;

    // Update field-field berdasarkan ID tag yang sesuai
    // Premi Atas (ID 27)
    final premiAtasController = controllers[27];
    if (premiAtasController != null) {
      premiAtasController.text = nominalPremiExtra.toStringAsFixed(0);
    }

    // Premi Bawah (ID 32)
    final premiBawahController = controllers[32];
    if (premiBawahController != null) {
      premiBawahController.text = nominalPremiKru.toStringAsFixed(0);
    }

    // Pendapatan Bersih (ID 60)
    final pendapatanBersihController = controllers[60];
    if (pendapatanBersihController != null) {
      pendapatanBersihController.text = pendapatanBersih.toStringAsFixed(0);
    }

    // Pendapatan Disetor (ID 61)
    final pendapatanDisetorController = controllers[61];
    if (pendapatanDisetorController != null) {
      pendapatanDisetorController.text = pendapatanDisetor.toStringAsFixed(0);
    }

    print('=== [DEBUG] Auto-calculated fields updated ===');
    print('Premi Atas (ID 27): $nominalPremiExtra');
    print('Premi Bawah (ID 32): $nominalPremiKru');
    print('Pendapatan Bersih (ID 60): $pendapatanBersih');
    print('Pendapatan Disetor (ID 61): $pendapatanDisetor');
  }

  /// Update controllers tanpa user data
  static void updateAutoCalculatedFieldsWithoutUser({
    required Map<String, dynamic> calculationResult,
    required Map<int, TextEditingController> controllers,
  }) {
    updateAutoCalculatedFields(
      calculationResult: calculationResult,
      controllers: controllers,
      userData: UserData.empty(),
    );
  }

  // ========== METHOD BANTUAN ==========

  static Map<String, List<TagData>> collectAllTagData({
    required List<TagTransaksi> tagPendapatan,
    required List<TagTransaksi> tagPengeluaran,
    required List<TagTransaksi> tagPremi,
    required List<TagTransaksi> tagBersihSetoran,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
  }) {
    final pendapatanData = _collectTagData(tagPendapatan, controllers, jumlahControllers, literSolarControllers);
    final pengeluaranData = _collectTagData(tagPengeluaran, controllers, jumlahControllers, literSolarControllers);
    final premiData = _collectTagData(tagPremi, controllers, jumlahControllers, literSolarControllers);
    final bersihSetoranData = _collectTagData(tagBersihSetoran, controllers, jumlahControllers, literSolarControllers);

    return {
      'pendapatan': pendapatanData,
      'pengeluaran': pengeluaranData,
      'premi': premiData,
      'bersihSetoran': bersihSetoranData,
    };
  }

  static List<TagData> _collectTagData(
      List<TagTransaksi> tags,
      Map<int, TextEditingController> controllers,
      Map<int, TextEditingController> jumlahControllers,
      Map<int, TextEditingController> literSolarControllers,
      ) {
    return tags.map((tag) {
      final nominalController = controllers[tag.id];
      final jumlahController = jumlahControllers[tag.id];
      final literSolarController = literSolarControllers[tag.id];

      return TagData(
        id: tag.id,
        nama: tag.nama ?? 'Unknown',
        nominal: nominalController?.text.isNotEmpty == true
            ? int.tryParse(nominalController!.text) ?? 0
            : 0,
        jumlah: jumlahController?.text.isNotEmpty == true
            ? int.tryParse(jumlahController!.text) ?? 0
            : 0,
        literSolar: literSolarController?.text.isNotEmpty == true
            ? int.tryParse(literSolarController!.text) ?? 0
            : 0,
        tagTransaksi: tag,
      );
    }).toList();
  }

  static int _calculateTotal(List<TagData> dataList) {
    return dataList.fold<int>(0, (sum, data) => sum + data.nominal);
  }

  static TagData _findTagById(List<TagData> dataList, int id) {
    return dataList.firstWhere(
          (data) => data.id == id,
      orElse: () => _createEmptyTagData(),
    );
  }

  static TagData _createEmptyTagData() {
    return TagData(
      id: 0,
      nama: 'Unknown',
      nominal: 0,
      jumlah: 0,
      literSolar: 0,
      tagTransaksi: TagTransaksi(
        id: 0,
        kategoriTransaksi: '',
        nama: '',
      ),
    );
  }

  static void _printDebugInfo(
      Map<String, dynamic> calculations,
      UserData userData,
      ) {
    print('=== HASIL KALKULASI PREMI BERSIH ===');
    print('  User Data:');
    print('    Nama Trayek: ${userData.namaTrayek}');
    print('    Jenis Trayek: ${userData.jenisTrayek}');
    print('    Kelas Bus: ${userData.kelasBus}');
    print('    Premi Extra: ${userData.premiExtra}');
    print('    Persen Premi Kru: ${userData.persenPremikru}%');
    print('  Hasil Kalkulasi:');
    print('    Premi Extra: Rp${calculations['nominalPremiExtra']?.toStringAsFixed(0)}');
    print('    Premi Kru: Rp${calculations['nominalPremiKru']?.toStringAsFixed(0)}');
    print('    Pendapatan Bersih: Rp${calculations['pendapatanBersih']?.toStringAsFixed(0)}');
    print('    Pendapatan Disetor: Rp${calculations['pendapatanDisetor']?.toStringAsFixed(0)}');
    print('    Total Pendapatan: Rp${calculations['totalPendapatan']?.toStringAsFixed(0)}');
    print('    Total Pengeluaran: Rp${calculations['totalPengeluaran']?.toStringAsFixed(0)}');
    print('    Sisa Pendapatan: Rp${calculations['sisaPendapatan']?.toStringAsFixed(0)}');
    print('    Tol Adjustment: Rp${calculations['tolAdjustment']?.toStringAsFixed(0)}');
    print('====================================');
  }
}

// TagData class harus tetap ada di file yang sama
class TagData {
  final int id;
  final String nama;
  final int nominal;
  final int jumlah;
  final int literSolar;
  final TagTransaksi tagTransaksi;

  TagData({
    required this.id,
    required this.nama,
    required this.nominal,
    required this.jumlah,
    required this.literSolar,
    required this.tagTransaksi,
  });

  @override
  String toString() {
    return 'TagData{id: $id, nama: $nama, nominal: $nominal, jumlah: $jumlah, literSolar: $literSolar}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'nominal': nominal,
      'jumlah': jumlah,
      'literSolar': literSolar,
    };
  }
}