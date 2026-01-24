import 'package:flutter/cupertino.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';
import 'package:mila_kru_reguler/models/user.dart';
import 'package:mila_kru_reguler/utils/premi_bersih_calculator.dart';
import 'package:mila_kru_reguler/models/calculation_result.dart';

class RekapTransaksiService {
  CalculationResult calculatePremiBersih({
    required List<TagTransaksi> tagPendapatan,
    required List<TagTransaksi> tagPengeluaran,
    required List<TagTransaksi> tagPremi,
    required List<TagTransaksi> tagBersihSetoran,
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required Map<int, TextEditingController> literSolarControllers,
    required User userData,
  }) {
    final result = PremiBersihCalculator.calculatePremiBersih(
      tagPendapatan: tagPendapatan,
      tagPengeluaran: tagPengeluaran,
      tagPremi: tagPremi,
      tagBersihSetoran: tagBersihSetoran,
      controllers: controllers,
      jumlahControllers: jumlahControllers,
      literSolarControllers: literSolarControllers,
      userData: userData,
    );

    return CalculationResult.fromMap(result);
  }

  void updateAutoCalculatedFields({
    required CalculationResult calculationResult,
    required Map<int, TextEditingController> controllers,
    required User userData,
  }) {
    PremiBersihCalculator.updateAutoCalculatedFields(
      calculationResult: calculationResult.toMap(),
      controllers: controllers,
      userData: userData,
    );
  }

  String generateTransactionId(int idUser) {
    final now = DateTime.now();
    final monthYear = '${now.month.toString().padLeft(2, '0')}${now.year}';
    final milliseconds = now.millisecondsSinceEpoch;
    return 'BUS.$monthYear.$milliseconds.$idUser';
  }

  String getKelasLayanan(String? keydataPremiextra) {
    if (keydataPremiextra == null || keydataPremiextra.isEmpty) {
      return '';
    }

    List<String> parts = keydataPremiextra.split('_');
    if (parts.length >= 2) {
      return '${parts[0]}${parts[1]}'.toLowerCase();
    }
    return '';
  }

  String normalizePositionName(String positionName) {
    final normalized = positionName.toLowerCase().trim();

    final mapping = {
      'supir': 'supir',
      'driver': 'supir',
      'sopir': 'supir',
      'kernet': 'kernet',
      'kenek': 'kernet',
      'asisten': 'kernet',
      'kondektur': 'kondektur',
      'kondek': 'kondektur',
      'pramugara': 'kondektur',
    };

    return mapping[normalized] ?? normalized;
  }
}