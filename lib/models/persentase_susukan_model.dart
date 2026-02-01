class PersentaseSusukan {
  final int id;
  final double nominalDari;
  final double nominalSampai;
  final double persentase;

  PersentaseSusukan({
    required this.id,
    required this.nominalDari,
    required this.nominalSampai,
    required this.persentase,
  });

  factory PersentaseSusukan.fromJson(Map<String, dynamic> json) {
    return PersentaseSusukan(
      id: json['id'],
      nominalDari: (json['nominal_dari'] as num).toDouble(),
      nominalSampai: (json['nominal_sampai'] as num).toDouble(),
      persentase: (json['persentase'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nominal_dari': nominalDari,
      'nominal_sampai': nominalSampai,
      'persentase': persentase,
    };
  }
}
