class ListKota {
  final String idTrayek;
  final String kodeTrayek;
  final String idKotaBerangkat;
  final String idKotaTujuan;
  final double jarak;
  final String namaKota;
  final int idHargaTiket;
  final double hargaKantor;
  final double biayaPerkursi;
  final double marginKantor;
  final double marginTarikan;
  final String aktif;

  ListKota({
    required this.idTrayek,
    required this.kodeTrayek,
    required this.idKotaBerangkat,
    required this.idKotaTujuan,
    required this.jarak,
    required this.namaKota,
    required this.idHargaTiket,
    required this.hargaKantor,
    required this.biayaPerkursi,
    required this.marginKantor,
    required this.marginTarikan,
    required this.aktif,
  });

  factory ListKota.fromJson(Map<String, dynamic> json) {
    return ListKota(
      idTrayek: json['id_trayek'] ?? '',
      kodeTrayek: json['kode_trayek'] ?? '',
      idKotaBerangkat: json['id_kota_berangkat'] ?? '',
      idKotaTujuan: json['id_kota_tujuan'] ?? '',
      jarak: json['jarak'] != null
          ? (json['jarak'] is int ? json['jarak'].toDouble() : double.parse(json['jarak'].toString()))
          : 0.0,
      namaKota: json['nama_kota'] ?? '',
      idHargaTiket: json['id_harga_tiket'] is int
          ? json['id_harga_tiket']
          : int.tryParse(json['id_harga_tiket'].toString()) ?? 0,
      hargaKantor: json['harga_kantor'] != null
          ? (json['harga_kantor'] is int ? json['harga_kantor'].toDouble() : double.parse(json['harga_kantor'].toString()))
          : 0.0,
      biayaPerkursi: json['biaya_perkursi'] != null
          ? (json['biaya_perkursi'] is int ? json['biaya_perkursi'].toDouble() : double.parse(json['biaya_perkursi'].toString()))
          : 0.0,
      marginKantor: json['margin_kantor'] != null
          ? (json['margin_kantor'] is int ? json['margin_kantor'].toDouble() : double.parse(json['margin_kantor'].toString()))
          : 0.0,
      marginTarikan: json['margin_tarikan'] != null
          ? (json['margin_tarikan'] is int ? json['margin_tarikan'].toDouble() : double.parse(json['margin_tarikan'].toString()))
          : 0.0,
      aktif: json['aktif'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_trayek': idTrayek,
      'kode_trayek': kodeTrayek,
      'id_kota_berangkat': idKotaBerangkat,
      'id_kota_tujuan': idKotaTujuan,
      'jarak': jarak,
      'nama_kota': namaKota,
      'id_harga_tiket': idHargaTiket,
      'harga_kantor': hargaKantor,
      'biaya_perkursi': biayaPerkursi,
      'margin_kantor': marginKantor,
      'margin_tarikan': marginTarikan,
      'aktif': aktif,
    };
  }
}
