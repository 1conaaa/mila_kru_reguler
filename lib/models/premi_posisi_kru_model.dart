class PremiPosisiKru {
  final int? id; // nullable karena AUTOINCREMENT
  final String namaPremi;
  final String persenPremi;
  final String tanggalSimpan;

  PremiPosisiKru({
    this.id,
    required this.namaPremi,
    required this.persenPremi,
    required this.tanggalSimpan,
  });

  /// Convert Map → Object
  factory PremiPosisiKru.fromMap(Map<String, dynamic> map) {
    return PremiPosisiKru(
      id: map['id'], // biarkan null jika belum ada
      namaPremi: map['nama_premi'] ?? '',
      persenPremi: map['persen_premi'] ?? '',
      tanggalSimpan: map['tanggal_simpan'] ?? '',
    );
  }

  /// Convert Object → Map (untuk UPDATE)
  /// ID diikutkan karena dipakai UPDATE
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_premi': namaPremi,
      'persen_premi': persenPremi,
      'tanggal_simpan': tanggalSimpan,
    };
  }

  /// Convert Object → Map (untuk INSERT)
  /// ID *tidak dikirim* agar AUTOINCREMENT berjalan
  Map<String, dynamic> toMapForInsert() {
    return {
      'nama_premi': namaPremi,
      'persen_premi': persenPremi,
      'tanggal_simpan': tanggalSimpan,
    };
  }

  /// Copy object
  PremiPosisiKru copyWith({
    int? id,
    String? namaPremi,
    String? persenPremi,
    String? tanggalSimpan,
  }) {
    return PremiPosisiKru(
      id: id ?? this.id,
      namaPremi: namaPremi ?? this.namaPremi,
      persenPremi: persenPremi ?? this.persenPremi,
      tanggalSimpan: tanggalSimpan ?? this.tanggalSimpan,
    );
  }

  @override
  String toString() {
    return 'PremiPosisiKru{id: $id, namaPremi: $namaPremi, persenPremi: $persenPremi, tanggalSimpan: $tanggalSimpan}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PremiPosisiKru &&
              runtimeType == other.runtimeType &&
              namaPremi == other.namaPremi;

  @override
  int get hashCode => namaPremi.hashCode;
}
