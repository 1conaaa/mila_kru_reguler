class PenjualanTiket {
  final int? id;
  final String? noPol;
  final int? idBus;
  final int? idUser;
  final int? idGroup;
  final int? idGarasi;
  final int? idCompany;
  final int? jumlahTiket;
  final String? kategoriTiket;
  final int? rit;
  final String? kotaBerangkat;
  final String? kotaTujuan;
  final String? namaPembeli;
  final String? noTelepon;
  final double? hargaKantor;
  final double? jumlahTagihan;
  final double? nominalBayar;
  final double? jumlahKembalian;
  final String? tanggalTransaksi;
  final String? status;
  final int? isTurun;
  final int? isBatal; // <--- DITAMBAHKAN
  final String? kodeTrayek;
  final String? keterangan;
  final String? idInvoice;
  final int? idMetodeBayar;
  final double? nominalTagihan;
  final int? statusBayar;
  final String? trxId;
  final String? merchantId;
  final String? redirectUrl;
  final String? fupload;
  final String? fileName;

  PenjualanTiket({
    this.id,
    this.noPol,
    this.idBus,
    this.idUser,
    this.idGroup,
    this.idGarasi,
    this.idCompany,
    this.jumlahTiket,
    this.kategoriTiket,
    this.rit,
    this.kotaBerangkat,
    this.kotaTujuan,
    this.namaPembeli,
    this.noTelepon,
    this.hargaKantor,
    this.jumlahTagihan,
    this.nominalBayar,
    this.jumlahKembalian,
    this.tanggalTransaksi,
    this.status,
    this.isTurun,
    this.isBatal, // <--- DITAMBAHKAN
    this.kodeTrayek,
    this.keterangan,
    this.idInvoice,
    this.idMetodeBayar,
    this.nominalTagihan,
    this.statusBayar,
    this.trxId,
    this.merchantId,
    this.redirectUrl,
    this.fupload,
    this.fileName,
  });

  factory PenjualanTiket.fromMap(Map<String, dynamic> map) {
    return PenjualanTiket(
      id: map['id'],
      noPol: map['no_pol'],
      idBus: map['id_bus'],
      idUser: map['id_user'],
      idGroup: map['id_group'],
      idGarasi: map['id_garasi'],
      idCompany: map['id_company'],
      jumlahTiket: map['jumlah_tiket'],
      kategoriTiket: map['kategori_tiket'],
      rit: map['rit'],
      kotaBerangkat: map['kota_berangkat'],
      kotaTujuan: map['kota_tujuan'],
      namaPembeli: map['nama_pembeli'],
      noTelepon: map['no_telepon'],
      hargaKantor: map['harga_kantor']?.toDouble(),
      jumlahTagihan: map['jumlah_tagihan']?.toDouble(),
      nominalBayar: map['nominal_bayar']?.toDouble(),
      jumlahKembalian: map['jumlah_kembalian']?.toDouble(),
      tanggalTransaksi: map['tanggal_transaksi'],
      status: map['status'],
      isTurun: map['is_turun'],
      isBatal: map['is_batal'], // <--- DITAMBAHKAN
      kodeTrayek: map['kode_trayek'],
      keterangan: map['keterangan'],
      idInvoice: map['id_invoice'],
      idMetodeBayar: map['id_metode_bayar'],
      nominalTagihan: map['nominal_tagihan']?.toDouble(),
      statusBayar: map['status_bayar'],
      trxId: map['trx_id'],
      merchantId: map['merchant_id'],
      redirectUrl: map['redirect_url'],
      fupload: map['fupload'],
      fileName: map['file_name'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'no_pol': noPol,
      'id_bus': idBus,
      'id_user': idUser,
      'id_group': idGroup,
      'id_garasi': idGarasi,
      'id_company': idCompany,
      'jumlah_tiket': jumlahTiket,
      'kategori_tiket': kategoriTiket,
      'rit': rit,
      'kota_berangkat': kotaBerangkat,
      'kota_tujuan': kotaTujuan,
      'nama_pembeli': namaPembeli,
      'no_telepon': noTelepon,
      'harga_kantor': hargaKantor,
      'jumlah_tagihan': jumlahTagihan,
      'nominal_bayar': nominalBayar,
      'jumlah_kembalian': jumlahKembalian,
      'tanggal_transaksi': tanggalTransaksi,
      'status': status,
      'is_turun': isTurun,
      'is_batal': isBatal, // <--- DITAMBAHKAN
      'kode_trayek': kodeTrayek,
      'keterangan': keterangan,
      'id_invoice': idInvoice,
      'id_metode_bayar': idMetodeBayar,
      'nominal_tagihan': nominalTagihan,
      'status_bayar': statusBayar,
      'trx_id': trxId,
      'merchant_id': merchantId,
      'redirect_url': redirectUrl,
      'fupload': fupload,
      'file_name': fileName,
    };
  }

  // Method copyWith untuk memudahkan update data
  PenjualanTiket copyWith({
    int? id,
    String? noPol,
    int? idBus,
    int? idUser,
    int? idGroup,
    int? idGarasi,
    int? idCompany,
    int? jumlahTiket,
    String? kategoriTiket,
    int? rit,
    String? kotaBerangkat,
    String? kotaTujuan,
    String? namaPembeli,
    String? noTelepon,
    double? hargaKantor,
    double? jumlahTagihan,
    double? nominalBayar,
    double? jumlahKembalian,
    String? tanggalTransaksi,
    String? status,
    int? isTurun,
    int? isBatal,
    String? kodeTrayek,
    String? keterangan,
    String? idInvoice,
    int? idMetodeBayar,
    double? nominalTagihan,
    int? statusBayar,
    String? trxId,
    String? merchantId,
    String? redirectUrl,
    String? fupload,
    String? fileName,
  }) {
    return PenjualanTiket(
      id: id ?? this.id,
      noPol: noPol ?? this.noPol,
      idBus: idBus ?? this.idBus,
      idUser: idUser ?? this.idUser,
      idGroup: idGroup ?? this.idGroup,
      idGarasi: idGarasi ?? this.idGarasi,
      idCompany: idCompany ?? this.idCompany,
      jumlahTiket: jumlahTiket ?? this.jumlahTiket,
      kategoriTiket: kategoriTiket ?? this.kategoriTiket,
      rit: rit ?? this.rit,
      kotaBerangkat: kotaBerangkat ?? this.kotaBerangkat,
      kotaTujuan: kotaTujuan ?? this.kotaTujuan,
      namaPembeli: namaPembeli ?? this.namaPembeli,
      noTelepon: noTelepon ?? this.noTelepon,
      hargaKantor: hargaKantor ?? this.hargaKantor,
      jumlahTagihan: jumlahTagihan ?? this.jumlahTagihan,
      nominalBayar: nominalBayar ?? this.nominalBayar,
      jumlahKembalian: jumlahKembalian ?? this.jumlahKembalian,
      tanggalTransaksi: tanggalTransaksi ?? this.tanggalTransaksi,
      status: status ?? this.status,
      isTurun: isTurun ?? this.isTurun,
      isBatal: isBatal ?? this.isBatal,
      kodeTrayek: kodeTrayek ?? this.kodeTrayek,
      keterangan: keterangan ?? this.keterangan,
      idInvoice: idInvoice ?? this.idInvoice,
      idMetodeBayar: idMetodeBayar ?? this.idMetodeBayar,
      nominalTagihan: nominalTagihan ?? this.nominalTagihan,
      statusBayar: statusBayar ?? this.statusBayar,
      trxId: trxId ?? this.trxId,
      merchantId: merchantId ?? this.merchantId,
      redirectUrl: redirectUrl ?? this.redirectUrl,
      fupload: fupload ?? this.fupload,
      fileName: fileName ?? this.fileName,
    );
  }
}