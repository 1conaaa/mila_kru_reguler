import 'package:intl/intl.dart';

class ApiResponseUser {
  final int success;
  final String token;
  final User user;

  ApiResponseUser({
    required this.success,
    required this.token,
    required this.user,
  });

  factory ApiResponseUser.fromJson(Map<String, dynamic> json) {
    return ApiResponseUser(
      success: json['success'] is int ? json['success'] : int.tryParse(json['success']) ?? 0,
      token: json['token'] ?? '',
      user: User.fromJson(json['user']),
    );
  }
}

class User {
  final int idUser;
  final int idGroup;
  final int idCompany;
  final int idGarasi;
  final int idBus;
  final String noPol;
  final String namaLengkap;
  final String namaUser;
  final String password;
  final String foto;
  final String groupName;
  final String kodeTrayek;
  final String namaTrayek;
  final String jenisTrayek;
  final String kelasBus;
  final String rute;
  final String premiExtra;
  final String keydataPremiextra;
  final String keydataPremikru;
  final String persenPremikru;
  final String idJadwalTrip;
  final String tagTransaksiPendapatan;
  final String tagTransaksiPengeluaran;
  final String coaPendapatanBus;
  final String coaPengeluaranBus;
  final String coaUtangPremi;

  User({
    required this.idUser,
    required this.idGroup,
    required this.idCompany,
    required this.idGarasi,
    required this.idBus,
    required this.noPol,
    required this.namaLengkap,
    required this.namaUser,
    required this.password,
    required this.foto,
    required this.groupName,
    required this.kodeTrayek,
    required this.namaTrayek,
    required this.jenisTrayek,
    required this.kelasBus,
    required this.rute,
    required this.premiExtra,
    required this.keydataPremiextra,
    required this.keydataPremikru,
    required this.persenPremikru,
    required this.idJadwalTrip,
    required this.tagTransaksiPendapatan,
    required this.tagTransaksiPengeluaran,
    required this.coaPendapatanBus,
    required this.coaPengeluaranBus,
    required this.coaUtangPremi,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUser: json['id_user'] is int ? json['id_user'] : int.tryParse(json['id_user']) ?? 0,
      idGroup: json['id_group'] is int ? json['id_group'] : int.tryParse(json['id_group']) ?? 0,
      idCompany: json['id_company'] is int ? json['id_company'] : int.tryParse(json['id_company']) ?? 0,
      idGarasi: json['id_garasi'] is int ? json['id_garasi'] : int.tryParse(json['id_garasi']) ?? 0,
      idBus: json['id_bus'] is int ? json['id_bus'] : int.tryParse(json['id_bus']) ?? 0,
      noPol: json['no_pol'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      namaUser: json['nama_user'] ?? '',
      password: json['password'] ?? '',
      foto: json['foto'] ?? '',
      groupName: json['group_name'] ?? '',
      kodeTrayek: json['kode_trayek'] ?? '',
      namaTrayek: json['nama_trayek'] ?? '',
      rute: json['rute'] ?? '',
      jenisTrayek: json['jenis_trayek'] ?? '',
      kelasBus: json['kelas_bus'] ?? '',
      premiExtra: json['premi_extra'] ?? '',
      keydataPremiextra: json['keydata_premiextra'] ?? '',
      keydataPremikru: json['keydata_premikru'] ?? '',
      persenPremikru: json['persen_premikru'] ?? '',
      idJadwalTrip: json['id_jadwal_trip'] ?? '',
      tagTransaksiPendapatan: json['tag_transaksi_pendapatan'] ?? '',
      tagTransaksiPengeluaran: json['tag_transaksi_pengeluaran'] ?? '',
      coaPendapatanBus: json['coa_pendapatan_bus'] ?? '',
      coaPengeluaranBus: json['coa_pengeluaran_bus'] ?? '',
      coaUtangPremi: json['coa_utang_premi'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'id_group': idGroup,
      'id_company': idCompany,
      'id_garasi': idGarasi,
      'id_bus': idBus,
      'no_pol': noPol,
      'nama_lengkap': namaLengkap,
      'nama_user': namaUser,
      'password': password,
      'foto': foto,
      'group_name': groupName,
      'kode_trayek': kodeTrayek,
      'nama_trayek': namaTrayek,
      'rute': rute,
      'jenis_trayek': jenisTrayek,
      'kelas_bus': kelasBus,
      'keydataPremiextra': keydataPremiextra,
      'premiExtra': premiExtra,
      'keydataPremikru': keydataPremikru,
      'persenPremikru': persenPremikru,
      'idJadwalTrip': idJadwalTrip,
      'tagTransaksiPendapatan': tagTransaksiPendapatan,
      'tagTransaksiPengeluaran': tagTransaksiPengeluaran,
      'coaPendapatanBus': coaPendapatanBus,
      'coaPengeluaranBus': coaPengeluaranBus,
      'coaUtangPremi': coaUtangPremi,
      'tanggal_simpan': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    };
  }
}
