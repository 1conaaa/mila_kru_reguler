// lib/models/penjualan_tiket_model.dart
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
  final String? kodeTrayek;
  final String? keterangan;
  final String? idInvoice;
  final int? idMetodeBayar;
  final double? nominalTagihan;
  final int? statusBayar;
  final String? trxId;
  final String? merchantId;
  final String? redirectUrl;

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
    this.kodeTrayek,
    this.keterangan,
    this.idInvoice,
    this.idMetodeBayar,
    this.nominalTagihan,
    this.statusBayar,
    this.trxId,
    this.merchantId,
    this.redirectUrl,
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
      kodeTrayek: map['kode_trayek'],
      keterangan: map['keterangan'],
      idInvoice: map['id_invoice'],
      idMetodeBayar: map['id_metode_bayar'],
      nominalTagihan: map['nominal_tagihan']?.toDouble(),
      statusBayar: map['status_bayar'],
      trxId: map['trx_id'],
      merchantId: map['merchant_id'],
      redirectUrl: map['redirect_url'],
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
      'kode_trayek': kodeTrayek,
      'keterangan': keterangan,
      'id_invoice': idInvoice,
      'id_metode_bayar': idMetodeBayar,
      'nominal_tagihan': nominalTagihan,
      'status_bayar': statusBayar,
      'trx_id': trxId,
      'merchant_id': merchantId,
      'redirect_url': redirectUrl,
    };
  }
}