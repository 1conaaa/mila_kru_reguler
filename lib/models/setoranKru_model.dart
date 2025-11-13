class SetoranKru {
  int? id;
  String tglTransaksi;
  double? kmPulang;
  String rit;
  String noPol;
  int idBus;
  String kodeTrayek;
  int idPersonil;
  int idGroup;
  int? jumlah;
  String? idTransaksi;
  String? coa;
  double nilai;
  int idTagTransaksi;
  String status;
  String? keterangan;
  String? fupload;
  String? fileName;
  String updatedAt;
  String createdAt;

  SetoranKru({
    this.id,
    required this.tglTransaksi,
    this.kmPulang,
    required this.rit,
    required this.noPol,
    required this.idBus,
    required this.kodeTrayek,
    required this.idPersonil,
    required this.idGroup,
    this.jumlah,
    this.idTransaksi,
    this.coa,
    required this.nilai,
    required this.idTagTransaksi,
    this.status = 'N',
    this.keterangan,
    this.fupload,
    this.fileName,
    required this.updatedAt,
    required this.createdAt,
  });

  factory SetoranKru.fromMap(Map<String, dynamic> json) => SetoranKru(
    id: json['id'],
    tglTransaksi: json['tgl_transaksi'],
    kmPulang: json['km_pulang'] != null ? (json['km_pulang'] as num).toDouble() : null,
    rit: json['rit'],
    noPol: json['no_pol'],
    idBus: json['id_bus'],
    kodeTrayek: json['kode_trayek'],
    idPersonil: json['id_personil'],
    idGroup: json['id_group'],
    jumlah: json['jumlah'],
    idTransaksi: json['id_transaksi'],
    coa: json['coa'],
    nilai: (json['nilai'] as num).toDouble(),
    idTagTransaksi: json['id_tag_transaksi'],
    status: json['status'],
    keterangan: json['keterangan'],
    fupload: json['fupload'],
    fileName: json['file_name'],
    updatedAt: json['updated_at'],
    createdAt: json['created_at'],
  );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tgl_transaksi': tglTransaksi,
      'km_pulang': kmPulang,
      'rit': rit,
      'no_pol': noPol,
      'id_bus': idBus,
      'kode_trayek': kodeTrayek,
      'id_personil': idPersonil,
      'id_group': idGroup,
      'jumlah': jumlah,
      'id_transaksi': idTransaksi,
      'coa': coa,
      'nilai': nilai,
      'id_tag_transaksi': idTagTransaksi,
      'status': status,
      'keterangan': keterangan,
      'fupload': fupload,
      'file_name': fileName,
      'updated_at': updatedAt,
      'created_at': createdAt,
    };
  }
}
