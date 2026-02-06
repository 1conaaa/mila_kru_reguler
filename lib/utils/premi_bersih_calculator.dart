import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/models/persentase_susukan_model.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/models/user.dart';
import 'package:mila_kru_reguler/services/persentase_susukan_service.dart';

class PremiBersihCalculator {
  /// Method utama untuk kalkulasi premi bersih dengan user data
  static Future<Map<String, dynamic>> calculatePremiBersih({
    required List<TagTransaksi> tagPendapatan,
    required List<TagTransaksi> tagPengeluaran,
    required List<TagTransaksi> tagPremi,
    required List<TagTransaksi> tagBersihSetoran,
    required List<TagTransaksi> tagSusukan,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
    required User userData,
  }) async { // ✅ INI YANG WAJIB

    final List<PersentaseSusukan> persentaseSusukanList = await PersentaseSusukanService.getAllLocal();

    final allData = collectAllTagData(
      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      tagSusukan: tagSusukan,
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
      persentaseSusukanList: persentaseSusukanList,
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
  static Future<Map<String, dynamic>> calculatePremiBersihWithoutUser({
    required List<TagTransaksi> tagPendapatan,
    required List<TagTransaksi> tagPengeluaran,
    required List<TagTransaksi> tagPremi,
    required List<TagTransaksi> tagBersihSetoran,
    required List<TagTransaksi> tagSusukan,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
  }) async {
    return await calculatePremiBersih(
      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      tagSusukan: tagSusukan,
      controllers: controllers,
      jumlahControllers: jumlahControllers,
      literSolarControllers: literSolarControllers,
      userData: User.empty(),
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
      'nominalTiketOperan': getValue(71),         // ID 3: Pendapatan Bagasi

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

      // Persen Susukan
      'persenSusukan': getValue(70),               // ID 70: Persen Susukan
    };
  }

  /// Kalkulasi kompleks berdasarkan aturan bisnis
  static Map<String, dynamic> _calculateComplexPremi({
      required Map<String, double> extractedValues,
      required User userData,
      required Map<String, List<TagData>> allData,
      required List<PersentaseSusukan> persentaseSusukanList, // 👈 BARU
    }) {
    print('=== [DEBUG] START CALCULATION ===');
    print('Kelas Bus: ${userData.kelasBus}');
    print('Jenis Trayek: ${userData.jenisTrayek}');
    print('Kode Trayek: ${userData.kodeTrayek}');
    print('Nama Trayek: ${userData.namaTrayek}');
    print('Premi Extra: ${userData.premiExtra}%');
    print('Persen Premi Kru: ${userData.persenPremikru}%');

    // Ekstrak nilai
    final double nominalTiketReguler = extractedValues['nominalTiketReguler'] ?? 0.0;

    final double nominalTiketOperan = extractedValues['nominalTiketOperan'] ?? 0.0;

    final double nominalTiketOnline = extractedValues['nominalTiketOnline'] ?? 0.0;

    final double pendapatanBagasi = extractedValues['pendapatanBagasi']!;
    double pengeluaranTol = extractedValues['pengeluaranTol']!;
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
    print('Nominal Tiket Operan: $nominalTiketOperan');
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
    final double persenPremiExtra = (double.tryParse(userData.premiExtra?.replaceAll('%', '') ?? '0') ?? 0) / 100;

    final double persenPremiKru = (double.tryParse(userData.persenPremikru?.replaceAll('%', '') ?? '0') ?? 0) / 100;
    final double pendKeseluruhan = nominalTiketReguler + nominalTiketOnline + pendapatanBagasi;
    final double pendapatanKotor = (nominalTiketReguler) - operan;

    print('=== [DEBUG] PARSED PERCENTAGES ===');
    print('Persen Premi Extra: $persenPremiExtra');
    print('Persen Premi Kru: $persenPremiKru');

    // Variabel umum
    double nominalPremiExtra = 0.0;
    double nominalPremiKru = 0.0;
    double pendBersih = 0.0;
    double pendDisetor = 0.0;
    double nominalSusukan = 0.0;
    double totalPengeluaran = 0.0;
    double sisaPendapatan = 0.0;
    double tolAdjustment = 0;

    PersentaseSusukan? matchedPersen;

    // Logika berdasarkan kelas bus, jenis trayek, dan nama trayek
    switch (userData.kelasBus) {
      case 'Ekonomi':
        print('=== [DEBUG] PROCESSING: EKONOMI ===');
        switch (userData.jenisTrayek) {
          case 'AKAP':
            print('=== [DEBUG] PROCESSING: AKAP ===');
            switch (userData.kodeTrayek) {
              //BWI-YOG BWI-STB-YOG
              case '3471351001':
              case '3471351002':
                PersentaseSusukan? matchedPersen;
                for (final item in persentaseSusukanList) {
                  if (nominalTiketReguler >= item.nominalDari && nominalTiketReguler <= item.nominalSampai) {
                    matchedPersen = item;
                    break;
                  }
                }

                final double persenSusukanRaw = matchedPersen?.persentase ?? 0.0;
                final double persenSusukan = persenSusukanRaw > 1 ? persenSusukanRaw / 100 : persenSusukanRaw;
                nominalSusukan = nominalTiketReguler * persenSusukan;

                double pendapatanKotor = nominalTiketReguler;

                print('=== [DEBUG SUSUKAN] ===');
                print('Tiket Reguler          : $nominalTiketReguler');
                print('Persen Susukan (raw)   : $persenSusukanRaw');
                print('Persen Susukan (%)     : ${persenSusukan * 100}');
                print('Nominal Susukan        : $nominalSusukan');
                print('Operan Nominal         : $nominalTiketOperan');
                print('Operan                : $operan');

                print('=== [DEBUG] BASE CALCULATIONS ===');
                print('Pendapatan Kotor (Tiket Reguler): $pendapatanKotor');
                print('=== [DEBUG] PROCESSING: YOGYAKARTA - BANYUWANGI ===');
                // Pengeluaran untuk AKAP Ekonomi Yogyakarta-Banyuwangi
                totalPengeluaran = nominalsolar + pengeluaranMakelar + pengeluaranCuci + pengeluaranParkir + pengeluaranPerbaikan + pengeluaranLainLain + nominalSusukan;

                print('=== [DEBUG] PENGELUARAN DETAIL ===');
                print('Solar: $nominalsolar');
                print('Makelar: $pengeluaranMakelar');
                print('Cuci: $pengeluaranCuci');
                print('Parkir: $pengeluaranParkir');
                print('Perbaikan: $pengeluaranPerbaikan');
                print('Lain-lain: $pengeluaranLainLain');
                print('Total Pengeluaran: $totalPengeluaran');

                if (operan > 0) {
                  pendBersih = (pendapatanKotor - totalPengeluaran) - operan;
                  print('1. Pendapatan Bersih (Kotor - Pengeluaran) - operan: $pendBersih');
                }else{
                  pendBersih = (pendapatanKotor - totalPengeluaran) + nominalTiketOperan;
                  print('2. Pendapatan Bersih (Kotor - Pengeluaran) + nominalTiketOperan: $pendBersih');
                }

                // Premi berdasarkan pendapatan bersih
                nominalPremiExtra = pendBersih * persenPremiExtra;
                nominalPremiKru   = pendBersih * (persenPremiKru - persenPremiExtra);

                print('Premi Extra ($persenPremiExtra): $nominalPremiExtra');
                print('Premi Kru ($persenPremiKru): $nominalPremiKru');

                sisaPendapatan = pendBersih - nominalPremiExtra;
                print('Sisa Pendapatan (Bersih - Premi Extra): $sisaPendapatan');

                if (sisaPendapatan >= 2500000) {
                  tolAdjustment = 270000;
                } else {
                  tolAdjustment = 140000;
                }

                print('Tol: $tolAdjustment');

                pendDisetor = (sisaPendapatan + pendapatanBagasi) - (nominalTiketOnline + tolAdjustment);
                print('($sisaPendapatan + $pendapatanBagasi) - ($nominalTiketOnline + $tolAdjustment)');
                print('=== [DEBUG] FINAL CALCULATION ===');
                print('Pendapatan Bersih: $pendBersih');
                print('Sisa Pendapatan: $sisaPendapatan');
                print('Tol Adjustment: $tolAdjustment');
                print('Pendapatan Bagasi: $pendapatanBagasi');
                print('Tiket Online: $nominalTiketOnline');
                print('Pendapatan Disetor: $pendDisetor');
                print('Nominal Susukan: $nominalSusukan');
                break;

              case '3471352901':
                print('=== [DEBUG] PROCESSING: YOG-SMP ===');
                PersentaseSusukan? matchedPersen;

                for (final item in persentaseSusukanList) {
                  if (nominalTiketReguler >= item.nominalDari && nominalTiketReguler <= item.nominalSampai) {
                    matchedPersen = item;
                    break;
                  }
                }
                final double persenSusukanRaw = matchedPersen?.persentase ?? 0.0;
                final double persenSusukan = persenSusukanRaw > 1 ? persenSusukanRaw / 100 : persenSusukanRaw;

                nominalSusukan = nominalTiketReguler * persenSusukan;
                double pendapatanKotor = nominalTiketReguler;

                // ===============================
                // DEBUG LOG
                // ===============================
                print('=== [DEBUG SUSUKAN] ===');
                print('Pendapatan Keseluruhan : $pendKeseluruhan');
                print('Tiket Reguler          : $nominalTiketReguler');
                print('Persen Susukan (raw)   : $persenSusukanRaw');
                print('Persen Susukan (%)     : ${persenSusukan * 100}');
                print('Nominal Susukan        : $nominalSusukan');
                print('Operan Nominal         : $nominalTiketOperan');
                print('Operan                : $operan');

                print('=== [DEBUG] BASE CALCULATIONS ===');
                print('Pendapatan Kotor (Tiket Reguler): $pendapatanKotor');

                // Pengeluaran untuk AKAP Ekonomi YOG-SMP
                totalPengeluaran = nominalsolar + pengeluaranMakelar + pengeluaranCuci + pengeluaranParkir + pengeluaranPerbaikan + pengeluaranLainLain + pengeluaranSuramadu + nominalSusukan;

                if (operan > 0) {
                  pendBersih = (pendapatanKotor - totalPengeluaran) - operan;
                  print('1. Pendapatan Bersih (Kotor - Pengeluaran) - operan: $pendBersih');
                }else{
                  pendBersih = (pendapatanKotor - totalPengeluaran) + nominalTiketOperan;
                  print('2. Pendapatan Bersih (Kotor - Pengeluaran) + nominalTiketOperan: $pendBersih');
                }

                // Premi berdasarkan pendapatan bersih
                nominalPremiExtra = pendBersih * persenPremiExtra;
                // nominalPremiKru = pendBersih * persenPremiKru;
                nominalPremiKru   = pendBersih * (persenPremiKru - persenPremiExtra);

                print('Premi Extra ($persenPremiExtra): $nominalPremiExtra');
                print('Premi Kru ($persenPremiKru): $nominalPremiKru');

                sisaPendapatan = pendBersih - nominalPremiExtra;
                print('Sisa Pendapatan (Bersih - Premi Extra): $sisaPendapatan');

                if (sisaPendapatan >= 2500000) {
                  tolAdjustment = 270000;
                } else {
                  tolAdjustment = 140000;
                }

                print('Tol: $tolAdjustment');

                print('=== [DEBUG] PENGELUARAN DETAIL ===');
                print('Solar: $nominalsolar');
                print('Makelar: $pengeluaranMakelar');
                print('Cuci: $pengeluaranCuci');
                print('Parkir: $pengeluaranParkir');
                print('Perbaikan: $pengeluaranPerbaikan');
                print('Lain-lain: $pengeluaranLainLain');
                print('Suramadu: $pengeluaranSuramadu');
                print('Total Pengeluaran: $totalPengeluaran');
                print('Tol: $tolAdjustment');

                pendDisetor = (sisaPendapatan + pendapatanBagasi) - (nominalTiketOnline + tolAdjustment);

                print('=== [DEBUG] FINAL CALCULATION ===');
                print('Pendapatan Bersih: $pendBersih');
                print('Sisa Pendapatan: $sisaPendapatan');
                print('Tol Adjustment: $tolAdjustment');
                print('Pendapatan Bagasi: $pendapatanBagasi');
                print('Tiket Online: $nominalTiketOnline');
                print('Pendapatan Disetor: $pendDisetor');
                print('Nominal Susukan: $nominalSusukan');
                break;

              default:
                final double pendKeseluruhan = nominalTiketReguler + nominalTiketOnline + pendapatanBagasi;
                final double pendapatanKotor = (nominalTiketReguler) - operan;

                print('=== [DEBUG] BASE CALCULATIONS ===');
                print('Pendapatan Keseluruhan: $pendKeseluruhan');
                print('Pendapatan Kotor (Reguler - Operan): $pendapatanKotor');

                print('=== [DEBUG] PROCESSING: AKAP EKONOMI DEFAULT ===');
                // Default calculation for AKAP Ekonomi lainnya
                totalPengeluaran = nominalsolar + pengeluaranMakelar + pengeluaranCuci + pengeluaranParkir + pengeluaranPerbaikan + pengeluaranLainLain;

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
            final double pendKeseluruhan = nominalTiketReguler + nominalTiketOnline + pendapatanBagasi;
            final double pendapatanKotor = (nominalTiketReguler) - operan;
            switch (userData.namaTrayek) {
              case 'JEMBER - KALIANGET':
              case 'KALIANGET - JEMBER':
              case 'AMBULU - PONOROGO':
              case 'PONOROGO - AMBULU':
                break;
              default:
                break;
            }
            break;
        }
        break;

      case 'Non Ekonomi':
        print('=== [DEBUG] PROCESSING: NON EKONOMI ===');
        final double pendKeseluruhan = nominalTiketReguler + nominalTiketOnline + pendapatanBagasi;
        final double pendapatanKotor = (nominalTiketReguler) - operan;
        switch (userData.jenisTrayek) {
          case 'AKDP':
            print('=== [DEBUG] PROCESSING: AKDP ===');
            switch (userData.namaTrayek) {
              case 'JEMBER - SURABAYA':
              case 'SURABAYA - JEMBER':
                break;
              case 'JEMBER - YOGYAKARTA':
              case 'YOGYAKARTA - JEMBER':
                break;
              default:
            }
            break;

          case 'AKAP':
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
    print('Nominal Susukan x: $nominalSusukan');
    print('Total Pengeluaran: $totalPengeluaran');
    print('=== [DEBUG] END CALCULATION ===');

    return {
      'nominalPremiExtra': nominalPremiExtra,
      'nominalPremiKru': nominalPremiKru,
      'pendapatanBersih': pendBersih,
      'pendapatanDisetor': pendDisetor,
      'nominalSusukan': nominalSusukan,
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
    required User userData,
  }) {
    // Helper untuk ambil double dari map, aman null dan int
    double getDouble(String key) {
      final value = calculationResult[key];
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final double nominalPremiExtra = getDouble('nominalPremiExtra');
    final double nominalPremiKru   = getDouble('nominalPremiKru');
    final double pendapatanBersih  = getDouble('pendapatanBersih');
    final double pendapatanDisetor = getDouble('pendapatanDisetor');
    final double nominalSusukan    = getDouble('nominalSusukan');

    void setController(int id, double value) {
      final controller = controllers[id];
      if (controller != null) {
        controller.text = value.toStringAsFixed(0);
      }
    }

    setController(27, nominalPremiExtra);  // Premi Atas
    setController(32, nominalPremiKru);    // Premi Bawah
    setController(60, pendapatanBersih);   // Pendapatan Bersih
    setController(61, pendapatanDisetor);  // Pendapatan Disetor
    setController(70, nominalSusukan);     // Nominal Susukan

    print('=== [DEBUG] Auto-calculated fields updated ===');
    print('Premi Atas (ID 27): $nominalPremiExtra');
    print('Premi Bawah (ID 32): $nominalPremiKru');
    print('Pendapatan Bersih (ID 60): $pendapatanBersih');
    print('Pendapatan Disetor (ID 61): $pendapatanDisetor');
    print('Nominal Susukan (ID 70): $nominalSusukan');
  }



  /// Update controllers tanpa user data
  static void updateAutoCalculatedFieldsWithoutUser({
    required Map<String, dynamic> calculationResult,
    required Map<int, TextEditingController> controllers,
  }) {
    updateAutoCalculatedFields(
      calculationResult: calculationResult,
      controllers: controllers,
      userData: User.empty(),
    );
  }

  // ========== METHOD BANTUAN ==========

  static Map<String, List<TagData>> collectAllTagData({
    required List<TagTransaksi> tagPendapatan,
    required List<TagTransaksi> tagPengeluaran,
    required List<TagTransaksi> tagPremi,
    required List<TagTransaksi> tagBersihSetoran,
    required List<TagTransaksi> tagSusukan,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
  }) {
    final pendapatanData = _collectTagData(tagPendapatan, controllers, jumlahControllers, literSolarControllers);
    final pengeluaranData = _collectTagData(tagPengeluaran, controllers, jumlahControllers, literSolarControllers);
    final premiData = _collectTagData(tagPremi, controllers, jumlahControllers, literSolarControllers);
    final bersihSetoranData = _collectTagData(tagBersihSetoran, controllers, jumlahControllers, literSolarControllers);
    final susukanData = _collectTagData(tagBersihSetoran, controllers, jumlahControllers, literSolarControllers);

    return {
      'pendapatan': pendapatanData,
      'pengeluaran': pengeluaranData,
      'premi': premiData,
      'bersihSetoran': bersihSetoranData,
      'susukan': susukanData,
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
      User userData,
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