import 'package:intl/intl.dart';

class User {
  final int idUser;
  final int idGroup;
  final int idCompany;
  final int idGarasi;
  final int idBus;
  final int idJadwalTrip;

  final String? noPol;
  final String? namaLengkap;
  final String? namaUser;
  final String? foto;
  final String? groupName;
  final String? kodeTrayek;
  final String? namaTrayek;
  final String? rute;
  final String? jenisTrayek;
  final String? kelasBus;
  final String? premiExtra;
  final String? keydataPremiextra;
  final String? keydataPremikru;
  final String? persenPremikru;
  final String? tagTransaksiPendapatan;
  final String? tagTransaksiPengeluaran;
  final String? coaPendapatanBus;
  final String? coaPengeluaranBus;
  final String? coaUtangPremi;
  final String? noKontak;
  final String? persenSusukan;
  final String? hargaBatas;

  User({
    required this.idUser,
    required this.idGroup,
    required this.idCompany,
    required this.idGarasi,
    required this.idBus,
    required this.idJadwalTrip,
    this.noPol,
    this.namaLengkap,
    this.namaUser,
    this.foto,
    this.groupName,
    this.kodeTrayek,
    this.namaTrayek,
    this.rute,
    this.jenisTrayek,
    this.kelasBus,
    this.premiExtra,
    this.keydataPremiextra,
    this.keydataPremikru,
    this.persenPremikru,
    this.tagTransaksiPendapatan,
    this.tagTransaksiPengeluaran,
    this.coaPendapatanBus,
    this.coaPengeluaranBus,
    this.coaUtangPremi,
    this.noKontak,
    this.persenSusukan,
    this.hargaBatas,
  });

  // =======================
  // FROM API (JSON)
  // =======================
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUser: int.tryParse(json['id_user']?.toString() ?? '0') ?? 0,
      idGroup: int.tryParse(json['id_group']?.toString() ?? '0') ?? 0,
      idCompany: int.tryParse(json['id_company']?.toString() ?? '0') ?? 0,
      idGarasi: int.tryParse(json['id_garasi']?.toString() ?? '0') ?? 0,
      idBus: int.tryParse(json['id_bus']?.toString() ?? '0') ?? 0,
      idJadwalTrip: int.tryParse(json['id_jadwal_trip']?.toString() ?? '0') ?? 0,
      noPol: json['no_pol']?.toString(),
      namaLengkap: json['nama_lengkap']?.toString(),
      namaUser: json['nama_user']?.toString(),
      foto: json['foto']?.toString(),
      groupName: json['group_name']?.toString(),
      kodeTrayek: json['kode_trayek']?.toString(),
      namaTrayek: json['nama_trayek']?.toString(),
      rute: json['rute']?.toString(),
      jenisTrayek: json['jenis_trayek']?.toString(),
      kelasBus: json['kelas_bus']?.toString(),
      premiExtra: json['premi_extra']?.toString(),
      keydataPremiextra: json['keydata_premiextra']?.toString(),
      keydataPremikru: json['keydata_premikru']?.toString(),
      persenPremikru: json['persen_premikru']?.toString(),
      tagTransaksiPendapatan: json['tag_transaksi_pendapatan']?.toString(),
      tagTransaksiPengeluaran: json['tag_transaksi_pengeluaran']?.toString(),
      coaPendapatanBus: json['coa_pendapatan_bus']?.toString(),
      coaPengeluaranBus: json['coa_pengeluaran_bus']?.toString(),
      coaUtangPremi: json['coa_utang_premi']?.toString(),
      noKontak: json['no_kontak']?.toString(),
      persenSusukan: json['persen_susukan']?.toString(),
      hargaBatas: json['harga_batas']?.toString(),
    );
  }

  // =======================
  // FROM SQLITE (MAP)
  // =======================
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      idUser: map['id_user'] ?? 0,
      idGroup: map['id_group'] ?? 0,
      idCompany: map['id_company'] ?? 0,
      idGarasi: map['id_garasi'] ?? 0,
      idBus: map['id_bus'] ?? 0,
      idJadwalTrip: map['id_jadwal_trip'] ?? 0,

      noPol: map['no_pol']?.toString(),
      namaLengkap: map['nama_lengkap']?.toString(),
      namaUser: map['nama_user']?.toString(),
      foto: map['foto']?.toString(),
      groupName: map['group_name']?.toString(),
      kodeTrayek: map['kode_trayek']?.toString(),
      namaTrayek: map['nama_trayek']?.toString(),
      rute: map['rute']?.toString(),
      jenisTrayek: map['jenis_trayek']?.toString(),
      kelasBus: map['kelas_bus']?.toString(),

      premiExtra: map['premi_extra']?.toString(),
      keydataPremiextra: map['keydata_premiextra']?.toString(),
      keydataPremikru: map['keydata_premikru']?.toString(),
      persenPremikru: map['persen_premikru']?.toString(),

      tagTransaksiPendapatan: map['tag_transaksi_pendapatan']?.toString(),
      tagTransaksiPengeluaran: map['tag_transaksi_pengeluaran']?.toString(),

      coaPendapatanBus: map['coa_pendapatan_bus']?.toString(),
      coaPengeluaranBus: map['coa_pengeluaran_bus']?.toString(),
      coaUtangPremi: map['coa_utang_premi']?.toString(),

      noKontak: map['no_kontak']?.toString(),
      persenSusukan: map['persen_susukan']?.toString(),
      hargaBatas: map['harga_batas']?.toString(),
    );
  }

  // =======================
  // TO SQLITE MAP
  // =======================
  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'id_group': idGroup,
      'id_company': idCompany,
      'id_garasi': idGarasi,
      'id_bus': idBus,
      'id_jadwal_trip': idJadwalTrip,
      'no_pol': noPol,
      'nama_lengkap': namaLengkap,
      'nama_user': namaUser,
      'foto': foto,
      'group_name': groupName,
      'kode_trayek': kodeTrayek,
      'nama_trayek': namaTrayek,
      'rute': rute,
      'jenis_trayek': jenisTrayek,
      'kelas_bus': kelasBus,
      'premi_extra': premiExtra,
      'keydata_premiextra': keydataPremiextra,
      'keydata_premikru': keydataPremikru,
      'persen_premikru': persenPremikru,
      'tag_transaksi_pendapatan': tagTransaksiPendapatan,
      'tag_transaksi_pengeluaran': tagTransaksiPengeluaran,
      'coa_pendapatan_bus': coaPendapatanBus,
      'coa_pengeluaran_bus': coaPengeluaranBus,
      'coa_utang_premi': coaUtangPremi,
      'no_kontak': noKontak,
      'persen_susukan': persenSusukan,
      'harga_batas': hargaBatas,
      'tanggal_simpan': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };
  }

  factory User.empty() {
    return User(
      idUser: 0,
      idGroup: 0,
      idCompany: 0,
      idGarasi: 0,
      idBus: 0,
      idJadwalTrip: 0,
      noPol: '',
      namaLengkap: '',
      namaUser: '',
      foto: '',
      groupName: '',
      kodeTrayek: '',
      namaTrayek: '',
      rute: '',
      jenisTrayek: '',
      kelasBus: '',
      premiExtra: '0%',
      keydataPremiextra: '',
      keydataPremikru: '',
      persenPremikru: '0%',
      tagTransaksiPendapatan: '',
      tagTransaksiPengeluaran: '',
      coaPendapatanBus: '',
      coaPengeluaranBus: '',
      coaUtangPremi: '',
      noKontak: '',
      persenSusukan: '0%',
      hargaBatas: '',
    );
  }

}
