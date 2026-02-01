class CalculationResult {
  final double nominalPremiKru;
  final double nominalPremiExtra;
  final double pendapatanBersih;
  final double pendapatanDisetor;
  final double totalPendapatan;
  final double totalPengeluaran;
  final double sisaPendapatan;
  final double tolAdjustment;
  final double nominalSusukan;

  CalculationResult({
    required this.nominalPremiKru,
    required this.nominalPremiExtra,
    required this.pendapatanBersih,
    required this.pendapatanDisetor,
    required this.totalPendapatan,
    required this.totalPengeluaran,
    required this.sisaPendapatan,
    required this.tolAdjustment,
    required this.nominalSusukan,
  });

  Map<String, dynamic> toMap() {
    return {
      'nominalPremiKru': nominalPremiKru,
      'nominalPremiExtra': nominalPremiExtra,
      'pendapatanBersih': pendapatanBersih,
      'pendapatanDisetor': pendapatanDisetor,
      'totalPendapatan': totalPendapatan,
      'totalPengeluaran': totalPengeluaran,
      'sisaPendapatan': sisaPendapatan,
      'tolAdjustment': tolAdjustment,
      'nominalSusukan': nominalSusukan,
    };
  }

  static CalculationResult fromMap(Map<String, dynamic> map) {
    return CalculationResult(
      nominalPremiKru: (map['nominalPremiKru'] as num).toDouble(),
      nominalPremiExtra: (map['nominalPremiExtra'] as num).toDouble(),
      pendapatanBersih: (map['pendapatanBersih'] as num).toDouble(),
      pendapatanDisetor: (map['pendapatanDisetor'] as num).toDouble(),
      totalPendapatan: (map['totalPendapatan'] as num).toDouble(),
      totalPengeluaran: (map['totalPengeluaran'] as num).toDouble(),
      sisaPendapatan: (map['sisaPendapatan'] as num).toDouble(),
      tolAdjustment: (map['tolAdjustment'] as num).toDouble(),// 🔥 AMBIL DARI MAP
      nominalSusukan: (map['nominalSusukan'] ?? 0).toDouble(),
    );
  }
}