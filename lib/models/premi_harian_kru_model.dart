class PremiHarianKru {
  int? id;
  int? idTransaksi;
  int? idUser;
  int? idGroup;
  double? persenPremiDisetor;
  double? nominalPremiDisetor;
  String? tanggalSimpan;
  String? status;

  PremiHarianKru({
    this.id,
    this.idTransaksi,
    this.idUser,
    this.idGroup,
    this.persenPremiDisetor,
    this.nominalPremiDisetor,
    this.tanggalSimpan,
    this.status,
  });

  // Convert Map to PremiHarianKru
  factory PremiHarianKru.fromMap(Map<String, dynamic> map) {
    return PremiHarianKru(
      id: map['id'] as int?,
      idTransaksi: map['id_transaksi'] as int?,
      idUser: map['id_user'] as int?,
      idGroup: map['id_group'] as int?,
      persenPremiDisetor: map['persen_premi_disetor'] as double?,
      nominalPremiDisetor: map['nominal_premi_disetor'] as double?,
      tanggalSimpan: map['tanggal_simpan'] as String?,
      status: map['status'] as String?,
    );
  }

  // Convert PremiHarianKru to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_transaksi': idTransaksi,
      'id_user': idUser,
      'id_group': idGroup,
      'persen_premi_disetor': persenPremiDisetor,
      'nominal_premi_disetor': nominalPremiDisetor,
      'tanggal_simpan': tanggalSimpan,
      'status': status,
    };
  }

  @override
  String toString() {
    return 'PremiHarianKru{id: $id, idTransaksi: $idTransaksi, idUser: $idUser, idGroup: $idGroup, persenPremiDisetor: $persenPremiDisetor, nominalPremiDisetor: $nominalPremiDisetor, tanggalSimpan: $tanggalSimpan, status: $status}';
  }
}