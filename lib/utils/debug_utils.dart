import 'package:flutter/cupertino.dart';

class DebugUtils {
  static void printControllerValues(Map<int, TextEditingController> controllers) {
    print('=== FINAL CHECK SEBELUM BUILD WIDGET ===');
    controllers.forEach((key, controller) {
      if (key <= 3) { // Hanya print untuk tag penting
        print('_controllers[$key]: "${controller.text}"');
      }
    });
  }

  static void printCalculationResults({
    required double nominalPremiKru,
    required double nominalPremiExtra,
    required double pendapatanBersih,
    required double pendapatanDisetor,
    required double totalPendapatan,
    required double totalPengeluaran,
    required double sisaPendapatan,
    required double tolAdjustment,
  }) {
    print('=== HASIL KALKULASI YANG DIEKSTRAK ===');
    print('📊 Nominal Premi Kru: $nominalPremiKru');
    print('📊 Nominal Premi Extra: $nominalPremiExtra');
    print('💰 Pendapatan Bersih: $pendapatanBersih');
    print('💰 Pendapatan Disetor: $pendapatanDisetor');
    print('💰 Total Pendapatan: $totalPendapatan');
    print('💰 Total Pengeluaran: $totalPengeluaran');
    print('💰 Sisa Pendapatan: $sisaPendapatan');
    print('💰 Tol Adjustment: $tolAdjustment');
    print('====================================');
  }

  static void printSaveProgress(String step, String message) {
    print('$step: $message');
  }
}