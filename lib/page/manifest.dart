import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mila_kru_reguler/database/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../main.dart'; // 🔹 untuk akses buildDrawer(context, idUser)
import 'package:intl/intl.dart';

// Tambahkan di bagian atas file
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mila_kru_reguler/page/bluetooth_service.dart';

class ManifestPage extends StatefulWidget {
  final String idJadwalTrip;
  final String token;

  const ManifestPage({
    Key? key,
    required this.idJadwalTrip,
    required this.token,
  }) : super(key: key);

  @override
  _ManifestPageState createState() => _ManifestPageState();
}

class _ManifestPageState extends State<ManifestPage> {
  List<dynamic> manifestList = [];
  int idUser = 0;
  int idBus = 0;
  String? noPol;

  // Tambahkan di dalam class _ManifestPageState
  final printerService = BluetoothPrinterService();
  final NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _checkPrinterConnection();
  }

  Future<void> _checkPrinterConnection() async {
    await printerService.checkConnection();
  }

  /// 🔹 Format angka ke Rupiah dengan pemisah ribuan
  String formatRupiah(dynamic number) {
    try {
      final value = int.tryParse(number.toString()) ?? 0;
      final formatter = NumberFormat('#,###', 'id_ID');
      return formatter.format(value);
    } catch (e) {
      return number.toString();
    }
  }

  /// 🔹 Ambil data user & bus dari SharedPreferences
  Future<void> _loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    idUser = prefs.getInt('idUser') ?? 0;
    idBus = prefs.getInt('idBus') ?? 0;
    noPol = prefs.getString('noPol');

    // Jalankan update notifikasi dulu
    await _updateNotifikasi();

    // Lalu ambil data manifest
    await _fetchManifest();

    setState(() {}); // update tampilan drawer
  }

  /// 🔹 Update status notifikasi menjadi 1
  /// 🔹 Fungsi untuk update notifikasi ke server
  Future<void> _updateNotifikasi() async {
    print('🚀 [UPDATE NOTIFIKASI] Fungsi dipanggil...');
    print('📦 Token: ${widget.token}');
    print('🚌 ID Jadwal Trip: ${widget.idJadwalTrip}');
    print('🆔 ID Bus: $idBus');
    print('🚐 No. Polisi: ${noPol ?? '(kosong)'}');

    if (widget.token.isEmpty) {
      print('⚠️ [UPDATE NOTIFIKASI] Token kosong, proses dibatalkan.');
      return;
    }

    try {
      final uri = Uri.parse(
        'https://apimila.sysconix.id/api/updatenotifikasireguler',
      ).replace(queryParameters: {
        'id_jadwal_trip': widget.idJadwalTrip.toString(),
        'id_bus': idBus.toString() ?? '',
        'no_pol': noPol ?? '',
      });

      print('🌐 [UPDATE NOTIFIKASI] Endpoint URI: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Accept': 'application/json',
        },
      );

      print('🔄 [UPDATE NOTIFIKASI] HTTP Status: ${response.statusCode}');
      print('📥 [UPDATE NOTIFIKASI] Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [UPDATE NOTIFIKASI] Update notifikasi berhasil.');
      } else {
        print('❌ [UPDATE NOTIFIKASI] Gagal update. Status: ${response.statusCode}');
      }
    } catch (e, stacktrace) {
      print('🔥 [UPDATE NOTIFIKASI] ERROR: $e');
      print('📚 Stacktrace: $stacktrace');
    }
  }

  /// 🔹 Fungsi untuk mengambil data manifest
  Future<void> _fetchManifest() async {
    print('🚀 [FETCH MANIFEST] Fungsi dipanggil...');
    print('📦 Token: ${widget.token}');
    print('🚌 ID Jadwal Trip: ${widget.idJadwalTrip}');

    if (widget.token.isEmpty) {
      print('⚠️ [FETCH MANIFEST] Token kosong, proses dibatalkan.');
      return;
    }

    try {
      final url =
          'https://apimila.sysconix.id/api/listmanifestreguler/${widget.idJadwalTrip}';
      print('🌐 [FETCH MANIFEST] Endpoint URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      print('🔄 [FETCH MANIFEST] HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('📥 [FETCH MANIFEST] Response body mentah: ${response.body}');
        try {
          final data = jsonDecode(response.body);

          if (data is List) {
            print('✅ [FETCH MANIFEST] Data valid. Jumlah item: ${data.length}');
            setState(() {
              manifestList = data;
            });
          } else {
            print('⚠️ [FETCH MANIFEST] Format tidak sesuai (bukan List).');
            print('Tipe data: ${data.runtimeType}');
          }
        } catch (e) {
          print('❌ [FETCH MANIFEST] Gagal parsing JSON: $e');
        }
      } else {
        print('❌ [FETCH MANIFEST] Gagal ambil data. Status code: ${response.statusCode}');
        print('📦 Body: ${response.body}');
      }
    } catch (e, stacktrace) {
      print('🔥 [FETCH MANIFEST] ERROR: $e');
      print('📚 Stacktrace: $stacktrace');
    }
  }

  /// 🔹 Ambil kode kursi dari string seperti "A4(3A.1)" → "3A"
  String _extractSeatCode(String seat) {
    final regex = RegExp(r'\((.*?)\)');
    final match = regex.firstMatch(seat);
    if (match != null) {
      final inside = match.group(1)!;
      return inside.split('.').first;
    }
    return seat;
  }

  Future<void> _getBluetoothDevices() async {
    try {
      final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();

      if (devices.isEmpty) {
        Fluttertoast.showToast(msg: "Tidak ada printer yang ditemukan");
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Pilih Printer"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name ?? 'Printer ${index + 1}'),
                  subtitle: Text(device.address ?? 'Alamat tidak tersedia'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _connectToDevice(device);
                  },
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    try {
      await printerService.connect(device);
      Fluttertoast.showToast(msg: "Terhubung ke printer ${device.name}");
    } catch (e) {
      Fluttertoast.showToast(msg: "Gagal terhubung ke printer: ${e.toString()}");
    }
  }

  // Fungsi untuk mengambil data penjualan dari database lokal dengan JOIN
  Future<Map<String, dynamic>?> _getPenjualanDataFromLocal(String idInvoice) async {
    final databaseHelper = DatabaseHelper();
    final db = await databaseHelper.database;

    try {
      final result = await db.rawQuery('''
      SELECT 
        a.*,
        b.nama_kota AS nama_kota_berangkat,
        c.nama_kota AS nama_kota_tujuan,
        d.*
      FROM 
        penjualan_tiket AS a
        LEFT JOIN list_kota AS b ON a.kota_berangkat = b.id_kota_tujuan
        LEFT JOIN list_kota AS c ON a.kota_tujuan = c.id_kota_tujuan
        LEFT JOIN m_metode_pembayaran d ON a.id_metode_bayar = d.payment_channel
      WHERE 
        a.id_invoice = ?
      LIMIT 1
    ''', [idInvoice]);

      if (result.isNotEmpty) {
        return result.first;
      }
      return null;
    } catch (e) {
      print('❌ Error mengambil data dari database lokal: $e');
      return null;
    }
  }

  // Ganti fungsi getTicketManifest dengan versi yang mengambil data dari database lokal dengan JOIN
  Future<List<int>> getTicketManifest(Map<String, dynamic> item) async {
    // Ambil id_invoice dari data manifest
    final idInvoice = item['id_order_transaksi']?.toString() ?? '';

    if (idInvoice.isEmpty) {
      throw Exception('ID Invoice tidak ditemukan');
    }

    // 🔍 Ambil data dari database lokal dengan JOIN
    final localData = await _getPenjualanDataFromLocal(idInvoice);

    if (localData == null) {
      throw Exception('Data penjualan tidak ditemukan di database lokal untuk invoice: $idInvoice');
    }

    // Ekstrak data dari database lokal
    final rit = localData['rit'] ?? 0;
    final kotaBerangkat = localData['kota_berangkat']?.toString() ?? '';
    final kotaTujuan = localData['kota_tujuan']?.toString() ?? '';
    final namaKotaBerangkat = localData['nama_kota_berangkat']?.toString() ?? kotaBerangkat;
    final namaKotaTujuan = localData['nama_kota_tujuan']?.toString() ?? kotaTujuan;
    final namaPembeli = localData['nama_pembeli']?.toString() ?? '';
    final noTelepon = localData['no_telepon']?.toString() ?? '';
    final jumlahTiket = localData['jumlah_tiket'] ?? 1;
    final jumlahTagihan = localData['jumlah_tagihan']?.toDouble() ?? 0.0;
    final nominalBayar = localData['nominal_bayar']?.toDouble() ?? 0.0;
    final jumlahKembalian = localData['jumlah_kembalian']?.toDouble() ?? 0.0;
    final tanggalTransaksi = localData['tanggal_transaksi']?.toString() ?? '';
    final kodeTrayek = localData['kode_trayek']?.toString() ?? '';
    final kategoriTiket = localData['kategori_tiket']?.toString() ?? 'REGULER';

    // Ambil data tambahan dari SharedPreferences untuk info bus
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final noPol = prefs.getString('noPol') ?? '';
    final jenisTrayek = prefs.getString('jenisTrayek') ?? 'REGULER';
    final kelasBus = prefs.getString('kelasBus') ?? 'EKONOMI';

    // Format tanggal
    var formattedDate = '';
    try {
      // Handle format tanggal "2024-01-01 10:30:00" -> "01-01-2024"
      var dateTimeParts = tanggalTransaksi.split(' ');
      var dateParts = dateTimeParts[0].split('-');
      if (dateParts.length >= 3) {
        formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';
      } else {
        formattedDate = tanggalTransaksi;
      }
    } catch (e) {
      formattedDate = tanggalTransaksi;
    }

    // Format mata uang
    String jumlahTagihanCetak = formatter.format(jumlahTagihan);
    String jumlahBayarCetak = formatter.format(nominalBayar);
    String jumlahKembalianCetak = formatter.format(jumlahKembalian);

    // Konversi nama kota ke uppercase
    String namaKotaAwal = namaKotaBerangkat.toUpperCase();
    String namaKotaAkhir = namaKotaTujuan.toUpperCase();

    // Ambil info kursi dari data manifest asli
    final kursi = _extractSeatCode(item['id_cell_kategori_kursi'] ?? '');

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.reset();

    // 1. LOGO - Gunakan logo yang sama seperti di getTicket()
    try {
      final ByteData logoData = await rootBundle.load('assets/images/sysconix.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final img.Image? image = img.decodeImage(logoBytes);

      if (image != null) {
        final img.Image resizedImage = img.copyResize(image, width: 380);
        bytes += generator.image(resizedImage);
      }
    } catch (e) {
      print('Gagal memuat logo: $e');
    }

    // Header - SAMA PERSIS dengan getTicket()
    bytes += generator.text("PT. ANDRY FEBIOLA TRANSPORTASI",
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1, bold: true));
    bytes += generator.text("Probolinggo - Jatim 67251", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("IG: akas.aaa.official", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("WA: 0853-9991-2500", styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Informasi rute - SAMA PERSIS dengan getTicket()
    bytes += generator.row([
      PosColumn(text: "$namaKotaAwal -", width: 6, styles: PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: " $namaKotaAkhir", width: 6, styles: PosStyles(align: PosAlign.left, bold: true)),
    ]);
    bytes += generator.text("$jenisTrayek-$kelasBus", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("$formattedDate", styles: PosStyles(align: PosAlign.center, bold: false));

    // Informasi rit dan kategori tiket - SAMA PERSIS dengan getTicket()
    bytes += generator.row([
      PosColumn(text: "Rit-$rit", width: 3, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "Tiket $kategoriTiket", width: 9, styles: PosStyles(align: PosAlign.right)),
    ]);

    // Informasi pembeli - SAMA PERSIS dengan getTicket()
    if (namaPembeli.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: "$namaPembeli", width: 6, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: "$noTelepon", width: 6, styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    // Tambahkan informasi kursi (tambahan khusus untuk manifest)
    bytes += generator.text("Kursi: $kursi", styles: PosStyles(align: PosAlign.left, bold: true));

    // Informasi tagihan dan pembayaran - SAMA PERSIS dengan getTicket()
    bytes += generator.row([
      PosColumn(text: "$jumlahTiket Tiket", width: 3, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "Tagihan: $jumlahTagihanCetak", width: 9, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Bayar", width: 6, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "$jumlahBayarCetak", width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: "Kembalian", width: 6, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "$jumlahKembalianCetak", width: 6, styles: PosStyles(align: PosAlign.right)),
    ]);

    // Footer - SAMA PERSIS dengan getTicket()
    bytes += generator.hr();
    bytes += generator.qrcode("https://www.akasaurora.com/");
    bytes += generator.text('Barang hilang atau rusak resiko penumpang sendiri.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Tiket ini, bukti transaksi yang sah dan mohon simpan tiket ini selama perjalanan Anda.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Semoga Allah SWT melindungi kita dalam perjalanan ini.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.hr();

    // 🔍 DEBUG: Tampilkan data yang digunakan untuk print
    print('==============================');
    print('🖨️ DATA UNTUK PRINT (DARI DATABASE LOKAL)');
    print('🧾 id_invoice         : $idInvoice');
    print('🔁 rit                : $rit');
    print('🏙️ nama_kota_berangkat: $namaKotaBerangkat');
    print('🏙️ nama_kota_tujuan   : $namaKotaTujuan');
    print('👤 nama_pembeli       : $namaPembeli');
    print('📞 no_telepon         : $noTelepon');
    print('💺 kursi              : $kursi');
    print('🎫 jumlah_tiket       : $jumlahTiket');
    print('💰 jumlah_tagihan     : $jumlahTagihan');
    print('💵 nominal_bayar      : $nominalBayar');
    print('🔄 jumlah_kembalian   : $jumlahKembalian');
    print('📅 tanggal_transaksi  : $tanggalTransaksi');
    print('🧭 kode_trayek        : $kodeTrayek');
    print('🎟️ kategori_tiket     : $kategoriTiket');
    print('🚌 no_pol             : $noPol');
    print('==============================');

    return bytes;
  }

  // Fungsi untuk handle print dengan data dari database lokal
  Future<void> _printTicketManifest(Map<String, dynamic> item) async {
    if (!printerService.isConnected || printerService.selectedDevice == null) {
      Fluttertoast.showToast(msg: "Printer belum terhubung");
      return;
    }

    try {
      print('🖨️ Memulai proses print untuk data manifest...');

      // Cek apakah data sudah tersimpan di database lokal
      final idInvoice = item['id_order_transaksi']?.toString() ?? '';
      final localData = await _getPenjualanDataFromLocal(idInvoice);

      if (localData == null) {
        Fluttertoast.showToast(
            msg: "Data belum disimpan ke database lokal. Tekan tombol SIMPAN dulu.",
            toastLength: Toast.LENGTH_LONG
        );
        return;
      }

      print('✅ Data ditemukan di database lokal, memulai print...');
      final bytes = await getTicketManifest(item);
      await printerService.bluetooth.writeBytes(Uint8List.fromList(bytes));
      Fluttertoast.showToast(msg: "✅ Tiket berhasil dicetak dari data lokal");
    } catch (e) {
      print('❌ Error mencetak tiket: $e');
      Fluttertoast.showToast(
          msg: "Error mencetak: ${e.toString()}",
          toastLength: Toast.LENGTH_LONG
      );
    }
  }

  Future<bool> _isTableExists(Database db, String tableName) async {
    try {
      List<Map> result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [tableName]
      );
      return result.isNotEmpty;
    } catch (e) {
      print('❌ Error saat mengecek tabel: $e');
      return false;
    }
  }

  Future<List<String>> _simpanKeDatabase() async {
    if (manifestList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data manifest untuk disimpan')),
      );
      return [];
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int idUser = prefs.getInt('idUser') ?? 0;
    int idGroup = prefs.getInt('idGroup') ?? 0;
    int idCompany = prefs.getInt('idCompany') ?? 0;
    int idGarasi = prefs.getInt('idGarasi') ?? 0;
    int idBus = prefs.getInt('idBus') ?? 0;
    String? noPol = prefs.getString('noPol');
    String? kodeTrayek = prefs.getString('kode_trayek');

    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    final databaseHelper = DatabaseHelper();
    final database = await databaseHelper.database;

    bool tableExists = await _isTableExists(database, 'penjualan_tiket');
    if (!tableExists) {
      await database.execute('''
      CREATE TABLE IF NOT EXISTS penjualan_tiket (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        no_pol TEXT,
        id_bus INTEGER,
        id_user INTEGER,
        id_group INTEGER,
        id_garasi INTEGER,
        id_company INTEGER,
        jumlah_tiket INTEGER,
        kategori_tiket TEXT,
        rit TEXT,
        kota_berangkat TEXT,
        kota_tujuan TEXT,
        nama_pembeli TEXT,
        no_telepon TEXT,
        harga_kantor REAL,
        jumlah_tagihan REAL,
        nominal_bayar REAL,
        jumlah_kembalian REAL,
        tanggal_transaksi TEXT,
        status TEXT,
        kode_trayek TEXT,
        keterangan TEXT,
        id_invoice TEXT,
        status_bayar INTEGER
      )
    ''');
    }

    int jumlahSukses = 0;
    List<String> insertedInvoices = [];

    print('==============================');
    print('💾 MULAI PROSES SIMPAN DATA MANIFEST KE DATABASE LOKAL');
    print('🕒 Waktu: $formattedDate');
    print('👤 idUser: $idUser | idGroup: $idGroup | idCompany: $idCompany');
    print('🚌 idBus: $idBus | noPol: $noPol | kodeTrayek: $kodeTrayek');
    print('==============================');

    for (var item in manifestList) {
      try {
        final idInvoice = item['id_order_transaksi']?.toString() ?? '';

        // 🔹 Cek apakah id_invoice sudah ada di DB
        final existing = await database.query(
          'penjualan_tiket',
          where: 'id_invoice = ?',
          whereArgs: [idInvoice],
        );

        if (existing.isNotEmpty) {
          final existingStatus = existing.first['status']?.toString() ?? 'N';

          if (existingStatus == 'Y') {
            print('⚠️ Data dengan id_invoice $idInvoice sudah ada dan sudah terkirim (status=Y), dilewati');
            continue; // skip data yang sudah dikirim
          } else {
            print('🔁 Data dengan id_invoice $idInvoice sudah ada tapi belum terkirim (status=N), tetap diproses untuk pengiriman ulang');
            insertedInvoices.add(idInvoice); // tambahkan agar tetap bisa dikirim ulang
            continue; // tidak perlu insert ulang, tapi tetap kirim
          }
        }

        // 🔍 DEBUG sebelum insert
        print('------------------------------');
        print('🧾 Menyimpan data manifest baru:');
        print('📦 id_invoice       : $idInvoice');
        print('👤 id_user          : $idUser');
        print('👥 id_group         : $idGroup');
        print('🏢 id_company       : $idCompany');
        print('🚐 id_bus           : $idBus');
        print('🔢 id_garasi        : $idGarasi');
        print('🚌 no_pol           : $noPol');
        print('🧭 kode_trayek      : $kodeTrayek');
        print('🏙️ kota_berangkat   : ${item['id_kota_berangkat']}');
        print('🏙️ kota_tujuan      : ${item['id_kota_tujuan']}');
        print('👤 nama_pembeli     : ${item['nama_penumpang']}');
        print('📞 no_telepon       : ${item['no_tlp']}');
        print('💵 harga_kantor     : ${item['harga_kantor']}');
        print('💰 harga_tercatat   : ${item['harga_tercatat']}');
        print('📅 tanggal_transaksi: $formattedDate');
        print('------------------------------');

        await database.insert('penjualan_tiket', {
          'no_pol': noPol,
          'id_bus': idBus,
          'id_user': idUser,
          'id_group': idGroup,
          'id_garasi': idGarasi,
          'id_company': idCompany,
          'jumlah_tiket': 1,
          'kategori_tiket': 'online',
          'rit': 1,
          'kota_berangkat': item['id_kota_berangkat'] ?? '',
          'kota_tujuan': item['id_kota_tujuan'] ?? '',
          'nama_pembeli': item['nama_penumpang'] ?? '',
          'no_telepon': item['no_tlp'] ?? '',
          'harga_kantor': double.tryParse(item['harga_kantor'] ?? '0') ?? 0,
          'jumlah_tagihan': double.tryParse(item['harga_tercatat'] ?? '0') ?? 0,
          'nominal_bayar': double.tryParse(item['harga_tercatat'] ?? '0') ?? 0,
          'jumlah_kembalian': 0,
          'tanggal_transaksi': formattedDate,
          'status': 'N',
          'kode_trayek': kodeTrayek,
          'keterangan': 'Penumpang Akas Aurora APPS',
          'id_invoice': idInvoice,
          'status_bayar': 1,
        });

        jumlahSukses++;
        insertedInvoices.add(idInvoice);
        print('✅ Data berhasil disimpan untuk id_invoice: $idInvoice');
      } catch (e) {
        print('⚠️ Gagal simpan data manifest: $e');
      }
    }

    print('==============================');
    print('📊 RINGKASAN PENYIMPANAN');
    print('✅ Jumlah sukses: $jumlahSukses');
    print('🧾 Total ID Invoice baru: ${insertedInvoices.length}');
    print('🧩 Daftar ID Invoice: ${insertedInvoices.join(', ')}');
    print('==============================');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$jumlahSukses data berhasil disimpan ke database lokal')),
    );

    return insertedInvoices;
  }

  Future<void> _kirimPenjualanKeServer(List<String> idInvoices) async {
    if (idInvoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data baru untuk dikirim')),
      );
      return;
    }

    final databaseHelper = DatabaseHelper();
    final db = await databaseHelper.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    // 🔹 Ambil data status N sesuai id_invoice
    final placeholders = List.filled(idInvoices.length, '?').join(',');
    final penjualanData = await db.query(
      'penjualan_tiket',
      where: 'status = ? AND id_invoice IN ($placeholders)',
      whereArgs: ['N', ...idInvoices],
    );

    if (penjualanData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data penjualan baru untuk dikirim')),
      );
      return;
    }

    int suksesKirim = 0;
    int gagalKirim = 0;

    for (var penjualan in penjualanData) {
      final idInvoice = penjualan['id_invoice'].toString();
      final tanggalTransaksi = penjualan['tanggal_transaksi'];
      final kategoriTiket = penjualan['kategori_tiket'];
      final rit = penjualan['rit'].toString();
      final noPol = penjualan['no_pol'];
      final idBus = penjualan['id_bus'];
      final kodeTrayek = penjualan['kode_trayek'];
      final idUser = penjualan['id_user'];
      final idGroup = penjualan['id_group'];
      final idKotaBerangkat = penjualan['kota_berangkat'];
      final idKotaTujuan = penjualan['kota_tujuan'];
      final jumlahTiket = penjualan['jumlah_tiket'];
      final jumlahTagihan = penjualan['jumlah_tagihan'];
      final hargaKantor = penjualan['harga_kantor'];
      final status = penjualan['status'];
      final namaPembeli = penjualan['nama_pembeli'];
      final noTelepon = penjualan['no_telepon'];
      final keterangan = penjualan['keterangan'];

      final apiUrl = 'https://apimila.sysconix.id/api/penjualantiketonline';
      final queryParams =
          '?tgl_transaksi=${Uri.encodeFull(tanggalTransaksi.toString())}'
          '&kategori=${Uri.encodeFull(kategoriTiket.toString())}'
          '&rit=${Uri.encodeFull(rit.toString())}'
          '&no_pol=${Uri.encodeFull(noPol?.toString() ?? '')}'
          '&id_bus=${idBus.toString()}'
          '&kode_trayek=${Uri.encodeFull(kodeTrayek?.toString() ?? '')}'
          '&id_personil=${idUser.toString()}'
          '&id_group=${idGroup.toString()}'
          '&id_kota_berangkat=${Uri.encodeFull(idKotaBerangkat?.toString() ?? '')}'
          '&id_kota_tujuan=${Uri.encodeFull(idKotaTujuan?.toString() ?? '')}'
          '&jml_naik=${jumlahTiket.toString()}'
          '&pendapatan=${jumlahTagihan.toString()}'
          '&harga_kantor=${hargaKantor.toString()}'
          '&nama_pelanggan=${Uri.encodeFull(namaPembeli?.toString() ?? '')}'
          '&no_telepon=${Uri.encodeFull(noTelepon?.toString() ?? '')}'
          '&status=${Uri.encodeFull(status.toString())}'
          '&keterangan=${Uri.encodeFull(keterangan?.toString() ?? '')}'
          '&id_invoice=${Uri.encodeFull(idInvoice.toString())}';

      // 🟡 DEBUG PRINT — tampilkan semua nilai yang dikirim
      print('==============================');
      print('🚀 Mengirim data penjualan ke server');
      print('🧾 id_invoice       : $idInvoice');
      print('📅 tanggal_transaksi: $tanggalTransaksi');
      print('🎟️ kategori_tiket   : $kategoriTiket');
      print('🔁 rit              : $rit');
      print('🚌 no_pol           : $noPol');
      print('🆔 id_bus           : $idBus');
      print('🧭 kode_trayek      : $kodeTrayek');
      print('👤 id_user          : $idUser');
      print('👥 id_group         : $idGroup');
      print('🏙️ kota_berangkat   : $idKotaBerangkat');
      print('🏙️ kota_tujuan      : $idKotaTujuan');
      print('🎫 jumlah_tiket     : $jumlahTiket');
      print('💰 jumlah_tagihan   : $jumlahTagihan');
      print('💵 harga_kantor     : $hargaKantor');
      print('📞 no_telepon       : $noTelepon');
      print('👤 nama_pembeli     : $namaPembeli');
      print('🗒️ keterangan       : $keterangan');
      print('📦 status           : $status');
      print('🔗 API URL          : $apiUrl$queryParams');
      print('==============================');

      try {
        final response = await http.post(
          Uri.parse(apiUrl + queryParams),
          headers: {'Authorization': 'Bearer $token'},
        );

        print('🛰️ [POST] ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          suksesKirim++;
          await db.update(
            'penjualan_tiket',
            {'status': 'Y'},
            where: 'id_invoice = ?',
            whereArgs: [idInvoice],
          );
          print('✅ Data id_invoice $idInvoice berhasil dikirim dan diperbarui ke status Y');
        } else {
          gagalKirim++;
          print('❌ Gagal kirim id_invoice $idInvoice: ${response.body}');
        }
      } catch (e) {
        gagalKirim++;
        print('⚠️ Error kirim data penjualan (id_invoice: $idInvoice): $e');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Kirim selesai: $suksesKirim berhasil, $gagalKirim gagal')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manifest Penumpang'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Tombol set printer
          IconButton(
            icon: const Icon(Icons.print, color: Colors.deepOrange),
            tooltip: 'Set Printer',
            onPressed: () async {
              await _getBluetoothDevices();
            },
          ),
          // Tombol simpan ke penjualan
          IconButton(
            icon: const Icon(Icons.save, color: Colors.deepOrange),
            tooltip: 'Simpan ke Penjualan',
            onPressed: () async {
              final idInvoices = await _simpanKeDatabase();
              await _kirimPenjualanKeServer(idInvoices);
            },
          ),
        ],
      ),
      drawer: buildDrawer(context, idUser),
      body: Container(
        color: Colors.white,
        child: manifestList.isEmpty
            ? const Center(
          child: CircularProgressIndicator(color: Colors.deepOrange),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: manifestList.length,
          itemBuilder: (context, index) {
            final item = manifestList[index];
            final kursi = _extractSeatCode(item['id_cell_kategori_kursi'] ?? '');
            final nama = item['nama_penumpang'] ?? '-';
            final tlp = item['no_tlp'] ?? '-';
            final naik = item['nama_lokasi'] ?? '-';
            final turun = item['nama_daerah'] ?? '-';
            final harga = item['harga_tercatat'] ?? '0';

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 16),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.deepOrange.shade100,
                  child: Text(
                    kursi,
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                title: Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📞 $tlp', style: const TextStyle(fontSize: 13)),
                      Text('🟢 Naik: $naik', style: const TextStyle(fontSize: 13)),
                      Text('🔻 Turun: $turun', style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        '💰 Rp${formatRupiah(harga)}',
                        style: const TextStyle(
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // TAMBAHKAN TOMBOL PRINT DI TRAILING
                trailing: IconButton(
                  icon: const Icon(Icons.print, color: Colors.blue),
                  onPressed: () => _printTicketManifest(item),
                  tooltip: 'Cetak Tiket',
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
