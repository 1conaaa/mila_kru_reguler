class RuteTrayekUrutan {
  final int idJarakKota;
  final String idTrayek;
  final String kodeTrayek;
  final String idKotaBerangkat;
  final String idKotaTujuan;
  final String latitude;
  final String longitude;
  final double jarak;
  final double hargaKantor;
  final int noUrutKota;
  final String tanggal;
  final String namaKota;

  RuteTrayekUrutan({
    required this.idJarakKota,
    required this.idTrayek,
    required this.kodeTrayek,
    required this.idKotaBerangkat,
    required this.idKotaTujuan,
    required this.latitude,
    required this.longitude,
    required this.jarak,
    required this.hargaKantor,
    required this.noUrutKota,
    required this.tanggal,
    required this.namaKota,
  });

  factory RuteTrayekUrutan.fromJson(Map<String, dynamic> json) {
    return RuteTrayekUrutan(
      idJarakKota: json['id_jarak_kota'] is int
          ? json['id_jarak_kota']
          : int.tryParse(json['id_jarak_kota'].toString()) ?? 0,
      idTrayek: json['id_trayek'] ?? '',
      kodeTrayek: json['kode_trayek'] ?? '',
      idKotaBerangkat: json['id_kota_berangkat'] ?? '',
      idKotaTujuan: json['id_kota_tujuan'] ?? '',
      latitude: json['latitude'] ?? '0',
      longitude: json['longitude'] ?? '0',
      jarak: json['jarak'] != null
          ? (json['jarak'] is int
          ? json['jarak'].toDouble()
          : double.parse(json['jarak'].toString()))
          : 0.0,
      hargaKantor: json['harga_kantor'] != null
          ? (json['harga_kantor'] is int
          ? json['harga_kantor'].toDouble()
          : double.parse(json['harga_kantor'].toString()))
          : 0.0,
      noUrutKota: json['no_urut_kota'] is int
          ? json['no_urut_kota']
          : int.tryParse(json['no_urut_kota'].toString()) ?? 0,
      tanggal: json['tanggal'] ?? '',
      namaKota: json['nama_kota'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_jarak_kota': idJarakKota,
      'id_trayek': idTrayek,
      'kode_trayek': kodeTrayek,
      'id_kota_berangkat': idKotaBerangkat,
      'id_kota_tujuan': idKotaTujuan,
      'latitude': latitude,
      'longitude': longitude,
      'jarak': jarak,
      'harga_kantor': hargaKantor,
      'no_urut_kota': noUrutKota,
      'tanggal': tanggal,
      'nama_kota': namaKota,
    };
  }
}