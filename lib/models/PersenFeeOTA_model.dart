class PersenFeeOTA {
  final String namaOrganisasi;
  final int nilaiOta;
  final int isPersen;

  PersenFeeOTA({
    required this.namaOrganisasi,
    required this.nilaiOta,
    required this.isPersen,
  });

  factory PersenFeeOTA.fromJson(Map<String, dynamic> json) {
    return PersenFeeOTA(
      namaOrganisasi: json['nama_organisasi'] ?? '',
      nilaiOta: json['nilai_ota'] is int ? json['nilai_ota'] : int.tryParse(json['nilai_ota'].toString()) ?? 0,
      isPersen: json['is_persen'] is int ? json['is_persen'] : int.tryParse(json['is_persen'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_organisasi': namaOrganisasi,
      'nilai_ota': nilaiOta,
      'is_persen': isPersen,
    };
  }
}
