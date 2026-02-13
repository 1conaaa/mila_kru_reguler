import 'package:flutter/cupertino.dart';
import 'package:mila_kru_reguler/models/tag_transaksi.dart';

class ControllerUtils {
  static void fillOutcomeControllers({
    required Map<int, TextEditingController> controllers,
    required double totalFeeRedBusValue,
    required double totalFeeTravelokaValue,
    required double totalFeeSysconixValue,
  }){
    print('=== MENGISI CONTROLLER Pengeluaran FEE ===');
    if (controllers.containsKey(6)) {
      controllers[6]!.text = totalFeeRedBusValue.toInt().toString();
      print('✓ _controllers[1] diisi: ${totalFeeRedBusValue.toInt()}');
    }
    if (controllers.containsKey(7)) {
      controllers[7]!.text = totalFeeTravelokaValue.toInt().toString();
      print('✓ _controllers[1] diisi: ${totalFeeTravelokaValue.toInt()}');
    }
    if (controllers.containsKey(81)) {
      controllers[81]!.text = totalFeeSysconixValue.toInt().toString();
      print('✓ _controllers[1] diisi: ${totalFeeSysconixValue.toInt()}');
    }
    print('=== SELESAI MENGISI CONTROLLER ===');
  }

  static void fillIncomeControllers({
    required Map<int, TextEditingController> controllers,
    required Map<int, TextEditingController> jumlahControllers,
    required double totalPendapatanRegulerValue,
    required int jumlahTiketRegulerValue,
    required double totalPendapatanNonRegulerValue,
    required int jumlahTiketOnlineValue,
    required double totalPendapatanBagasiValue,
    required int jumlahBarangBagasiValue,
    required double totalPendapatanOperanValue,
    required int jumlahTiketOperanValue,
  }) {
    print('=== MENGISI CONTROLLER PENDAPATAN ===');

    if (controllers.containsKey(1)) {
      controllers[1]!.text = totalPendapatanRegulerValue.toInt().toString();
      print('✓ _controllers[1] diisi: ${totalPendapatanRegulerValue.toInt()}');
    }
    if (jumlahControllers.containsKey(1)) {
      jumlahControllers[1]!.text = jumlahTiketRegulerValue.toString();
      print('✓ _jumlahControllers[1] diisi: $jumlahTiketRegulerValue');
    }

    if (controllers.containsKey(71)) {
      controllers[71]!.text = totalPendapatanOperanValue.toInt().toString();
      print('✓ _controllers[1] diisi: ${totalPendapatanOperanValue.toInt()}');
    }
    if (jumlahControllers.containsKey(71)) {
      jumlahControllers[71]!.text = jumlahTiketOperanValue.toString();
      print('✓ _jumlahControllers[1] diisi: $jumlahTiketOperanValue');
    }

    if (controllers.containsKey(2)) {
      controllers[2]!.text = totalPendapatanNonRegulerValue.toInt().toString();
      print('✓ _controllers[2] diisi: ${totalPendapatanNonRegulerValue.toInt()}');
    }
    if (jumlahControllers.containsKey(2)) {
      jumlahControllers[2]!.text = jumlahTiketOnlineValue.toString();
      print('✓ _jumlahControllers[2] diisi: $jumlahTiketOnlineValue');
    }

    if (controllers.containsKey(3)) {
      controllers[3]!.text = totalPendapatanBagasiValue.toInt().toString();
      print('✓ _controllers[3] diisi: ${totalPendapatanBagasiValue.toInt()}');
    }
    if (jumlahControllers.containsKey(3)) {
      jumlahControllers[3]!.text = jumlahBarangBagasiValue.toString();
      print('✓ _jumlahControllers[3] diisi: $jumlahBarangBagasiValue');
    }

    print('=== SELESAI MENGISI CONTROLLER ===');
  }

  static bool requiresQuantity(TagTransaksi tag, List<TagTransaksi> tagPendapatan) {
    if (tagPendapatan.any((pendapatan) => pendapatan.id == tag.id)) {
      return true;
    }

    List<String> tagsWithJumlah = ['Biaya Solar'];
    return tagsWithJumlah.contains(tag.nama);
  }

  static bool requiresLiterSolar(TagTransaksi tag) {
    List<String> tagsWithLiterSolar = ['Biaya Solar'];
    return tagsWithLiterSolar.contains(tag.nama);
  }

  static bool requiresImage(TagTransaksi tag) {
    List<String> tagsWithImage = [
      'Biaya Solar',
      'Biaya Perbaikan',
      'Biaya Tol',
      'Biaya Operasional Surabaya'
    ];
    return tagsWithImage.contains(tag.nama);
  }

  static bool isExpense(TagTransaksi tag, List<TagTransaksi> tagPengeluaran) {
    return tagPengeluaran.any((pengeluaran) => pengeluaran.id == tag.id);
  }
}