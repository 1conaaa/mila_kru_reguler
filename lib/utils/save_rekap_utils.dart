import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/models/setoranKru_model.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/models/user.dart';
import 'package:mila_kru_reguler/services/setoranKru_service.dart';
import 'package:mila_kru_reguler/services/premi_harian_kru_service.dart';
import 'package:mila_kru_reguler/services/premi_posisi_kru_service.dart';
import 'package:mila_kru_reguler/models/premi_harian_kru_model.dart';
import 'package:mila_kru_reguler/models/premi_posisi_kru_model.dart';

class SaveRekapUtils {
  static SetoranKru createSetoran({
    required String tglTransaksi,
    required double kmPulang,
    required String rit,
    required String? noPol,
    required int idBus,
    required String? kodeTrayek,
    required int idPersonil,
    required int idGroup,
    required int jumlah,
    required String idTransaksi,
    required String? coa,
    required double nilai,
    required int idTagTransaksi,
    required String? keterangan,
    required String? fupload,
    required String? fileName,
  }) {
    return SetoranKru(
      tglTransaksi: tglTransaksi,
      kmPulang: kmPulang,
      rit: rit,
      noPol: noPol ?? '',
      idBus: idBus,
      kodeTrayek: kodeTrayek ?? '',
      idPersonil: idPersonil,
      idGroup: idGroup,
      jumlah: jumlah,
      idTransaksi: idTransaksi,
      coa: coa,
      nilai: nilai,
      idTagTransaksi: idTagTransaksi,
      status: 'N',
      keterangan: keterangan,
      fupload: fupload,
      fileName: fileName,
      updatedAt: tglTransaksi,
      createdAt: tglTransaksi,
    );
  }

  static List<SetoranKru> collectIncomeSetoran({
    required List<TagTransaksi> tagPendapatan,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required String formattedDate,
    required double kmPulang,
    required String ritValue,
    required String? noPol,
    required int idBus,
    required String? kodeTrayek,
    required int idUser,
    required int idGroup,
    required String idTransaksi,
    required String coaPendapatan,
  }) {
    List<SetoranKru> setoranList = [];

    for (var tag in tagPendapatan) {
      final valueText = controllers[tag.id]?.text ?? '0';
      final jumlahText = jumlahControllers[tag.id]?.text ?? '0';

      final cleanValue = valueText.replaceAll('.', '').replaceAll(',00', '');
      final nilai = double.tryParse(cleanValue) ?? 0;
      final jumlah = int.tryParse(jumlahText.replaceAll('.', '')) ?? 0;

      if (nilai > 0 || jumlah > 0) {
        print('--- Pendapatan ---');
        print('COA: $coaPendapatan');
        print('Tag ID: ${tag.id}, Nama Tag: ${tag.nama}');
        print('Nilai: $nilai, Jumlah: $jumlah');

        final setoran = createSetoran(
          tglTransaksi: formattedDate,
          kmPulang: kmPulang,
          rit: ritValue,
          noPol: noPol,
          idBus: idBus,
          kodeTrayek: kodeTrayek,
          idPersonil: idUser,
          idGroup: idGroup,
          jumlah: jumlah,
          idTransaksi: idTransaksi,
          coa: coaPendapatan,
          nilai: nilai,
          idTagTransaksi: tag.id,
          keterangan: null,
          fupload: null,
          fileName: null,
        );

        setoranList.add(setoran);
        print('✅ Ditambahkan: ${tag.nama}');
      }
    }

    return setoranList;
  }

  static List<SetoranKru> collectExpenseSetoran({
    required List<TagTransaksi> tagPengeluaran,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> literSolarControllers,
    required Map<int, String> uploadedImages,
    required String formattedDate,
    required double kmPulang,
    required String ritValue,
    required String? noPol,
    required int idBus,
    required String? kodeTrayek,
    required int idUser,
    required int idGroup,
    required String idTransaksi,
    required String coaPengeluaran,
  }) {
    List<SetoranKru> setoranList = [];

    for (var tag in tagPengeluaran) {
      double nilai = 0;
      int jumlah = 1;
      String? keterangan = null;

      final fotoPath = uploadedImages[tag.id];
      final fotoName = fotoPath != null ? fotoPath.split('/').last : null;

      print('--------------------------------------------------');
      print('🔍 CEK DATA TAG: ${tag.nama} (ID: ${tag.id})');
      print('📸 Foto Path: $fotoPath');
      print('📄 Foto Name: $fotoName');
      print('--------------------------------------------------');

      if (tag.id == 16) {
        final nominalSolarText = controllers[tag.id]?.text ?? '0';
        final nominalSolar = double.tryParse(
            nominalSolarText.replaceAll('.', '').replaceAll(',00', '')) ?? 0;

        final literSolarText = literSolarControllers[tag.id]?.text ?? '0';
        final literSolar = double.tryParse(literSolarText) ?? 0;

        print('--- BIAYA SOLAR (TAG 16) ---');
        print('Nominal Text: $nominalSolarText');
        print('Nominal Solar: $nominalSolar');
        print('Liter Solar Text: $literSolarText');
        print('Liter Solar Parsed: $literSolar');

        nilai = nominalSolar;
        jumlah = literSolar.toInt();
        keterangan = literSolar > 0 ? 'Solar: $literSolar liter' : null;
      } else {
        final valueText = controllers[tag.id]?.text ?? '0';
        nilai = double.tryParse(valueText.replaceAll('.', '').replaceAll(',00', '')) ?? 0;
      }

      if (nilai > 0) {
        final setoran = createSetoran(
          tglTransaksi: formattedDate,
          kmPulang: kmPulang,
          rit: ritValue,
          noPol: noPol,
          idBus: idBus,
          kodeTrayek: kodeTrayek,
          idPersonil: idUser,
          idGroup: idGroup,
          jumlah: jumlah,
          idTransaksi: idTransaksi,
          coa: coaPengeluaran,
          nilai: nilai,
          idTagTransaksi: tag.id,
          keterangan: keterangan,
          fupload: fotoPath,
          fileName: fotoName,
        );

        setoranList.add(setoran);
        print('✅ Pengeluaran disimpan: ${tag.nama}');
      } else {
        print('⚠️ SKIP → ${tag.nama} (nilai = 0)');
      }
    }

    return setoranList;
  }

  static Future<List<PremiHarianKru>> calculateDailyPremi({
    required List<Map<String, dynamic>> kruBisList,
    required List<PremiPosisiKru> premiList,
    required String kodeTrayek,
    required String idTransaksi,
    required double pendapatanBersih,
    required double nominalPremiKru,
    required Function(String) normalizePositionName,
  }) async {
    List<PremiHarianKru> premiHarianList = [];

    for (var kru in kruBisList) {
      final int idPersonil = kru['id_personil'];
      final int idGroup = kru['id_group'];
      final String namaLengkap = kru['nama_lengkap'];
      final String groupName = kru['group_name'];

      print('🔍 Proses kru: $namaLengkap ($groupName)');

      try {
        final normalizedGroupName = normalizePositionName(groupName);
        final premiKru = premiList.firstWhere(
              (premi) {
            final premiName = (premi.namaPremi ?? '').toLowerCase().trim();
            return premiName == normalizedGroupName;
          },
        );

        print('   ✅ Premi ditemukan: ${premiKru.namaPremi} - ${premiKru.persenPremi}');

        final String persenPremiStr = (premiKru.persenPremi ?? '0').toString();
        final double persenPremi = double.tryParse(persenPremiStr.replaceAll('%', '').replaceAll(' ', '')) ?? 0.0;
        final double nominalPremiHarian = (pendapatanBersih * persenPremi) / 100;

        if (nominalPremiHarian > 0) {
          final premiHarian = PremiHarianKru(
            idTransaksi: int.tryParse(idTransaksi.replaceAll('BUS.', '')) ?? 0,
            kodeTrayek: kodeTrayek,
            idJenisPremi: 1,
            idUser: idPersonil,
            idGroup: idGroup,
            persenPremiDisetor: persenPremi,
            nominalPremiDisetor: nominalPremiHarian,
            tanggalSimpan: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
            status: 'N',
          );

          premiHarianList.add(premiHarian);
          print('   ✅ Premi harian disiapkan untuk $namaLengkap: Rp$nominalPremiHarian');
        }
      } catch (e) {
        print('   ⚠️ Premi tidak ditemukan untuk "$groupName"');
      }
    }

    return premiHarianList;
  }
}