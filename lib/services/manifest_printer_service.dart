import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:mila_kru_reguler/page/bluetooth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ManifestPrinterService {
  final BluetoothPrinterService printerService;
  final NumberFormat formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');

  ManifestPrinterService(this.printerService);

  /// 🔹 Ambil kode kursi dari string seperti "A4(3A.1)" → "3A"
  String extractSeatCode(String seat) {
    final regex = RegExp(r'\((.*?)\)');
    final match = regex.firstMatch(seat);
    if (match != null) {
      final inside = match.group(1)!;
      return inside.split('.').first;
    }
    return seat;
  }

  /// 🔹 Generate bytes untuk print tiket manifest
  Future<List<int>> getTicketManifestBytes({
    required Map<String, dynamic> localData,
    required String kursi,
    required String noPol,
    required String jenisTrayek,
    required String kelasBus,
  }) async {
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

    // Format tanggal
    var formattedDate = '';
    try {
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

    List<int> bytes = [];
    CapabilityProfile profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.reset();

    // 1. LOGO
    try {
      final ByteData logoData = await rootBundle.load('assets/images/icon_mila.png');
      final Uint8List logoBytes = logoData.buffer.asUint8List();
      final img.Image? image = img.decodeImage(logoBytes);

      if (image != null) {
        final img.Image resizedImage = img.copyResize(image, width: 380);
        bytes += generator.image(resizedImage);
      }
    } catch (e) {
      print('Gagal memuat logo: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    String noWhatsapp = prefs.getString('noKontak') ?? '0822-3490-9090';

    // Header
    bytes += generator.text("PT. MILA AKAS BERKAH SEJAHTERA",
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1, bold: true));
    bytes += generator.text("Probolinggo - Jawa Timur 67214", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("IG: akasmilasejahtera_official", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("WA: $noWhatsapp", styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();


    // Informasi rute
    bytes += generator.row([
      PosColumn(text: "$namaKotaAwal -", width: 6, styles: PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: " $namaKotaAkhir", width: 6, styles: PosStyles(align: PosAlign.left, bold: true)),
    ]);
    bytes += generator.text("$jenisTrayek-$kelasBus", styles: PosStyles(align: PosAlign.center));
    bytes += generator.text("$formattedDate", styles: PosStyles(align: PosAlign.center, bold: false));

    // Informasi rit dan kategori tiket
    bytes += generator.row([
      PosColumn(text: "Rit-$rit", width: 3, styles: PosStyles(align: PosAlign.left)),
      PosColumn(text: "Tiket $kategoriTiket", width: 9, styles: PosStyles(align: PosAlign.right)),
    ]);

    // Informasi pembeli
    if (namaPembeli.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: "$namaPembeli", width: 6, styles: PosStyles(align: PosAlign.left)),
        PosColumn(text: "$noTelepon", width: 6, styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    // Tambahkan informasi kursi (tambahan khusus untuk manifest)
    bytes += generator.text("Kursi: $kursi", styles: PosStyles(align: PosAlign.left, bold: true));

    // Informasi tagihan dan pembayaran
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

    // Footer
    bytes += generator.hr();
    bytes += generator.qrcode("https://www.akasaurora.com/");
    bytes += generator.text('Barang hilang atau rusak resiko penumpang sendiri.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Tiket ini, bukti transaksi yang sah dan mohon simpan tiket ini selama perjalanan Anda.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.text('Semoga Allah SWT melindungi kita dalam perjalanan ini.', styles: PosStyles(align: PosAlign.center, bold: false));
    bytes += generator.hr();

    // 🔍 DEBUG: Tampilkan data yang digunakan untuk print
    print('==============================');
    print('🖨️ DATA UNTUK PRINT (DARI DATABASE LOKAL)');
    print('🧾 id_invoice         : ${localData['id_invoice']}');
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

  /// 🔹 Handle print tiket manifest
  Future<void> printTicketManifest({
    required Map<String, dynamic> item,
    required Future<Map<String, dynamic>?> Function(String) getLocalData,
    required String extractSeatCode,
  }) async {
    if (!printerService.isConnected || printerService.selectedDevice == null) {
      Fluttertoast.showToast(msg: "Printer belum terhubung");
      return;
    }

    try {
      print('🖨️ Memulai proses print untuk data manifest...');

      // Cek apakah data sudah tersimpan di database lokal
      final String idInvoice = item['id_order_transaksi']?.toString() ?? '';
      final localData = await getLocalData(idInvoice);

      if (localData == null) {
        Fluttertoast.showToast(
          msg: "Data belum disimpan ke database lokal. Tekan tombol SIMPAN dulu.",
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }

      // Ambil data dari SharedPreferences untuk info bus
      // (Ini bisa dipisahkan lebih lanjut jika diperlukan)

      // final kursi = extractSeatCode(item['id_cell_kategori_kursi'] ?? '');

      // Ambil data dari localData untuk kebutuhan print
      // (Asumsi data sudah lengkap di localData)

      print('✅ Data ditemukan di database lokal, memulai print...');

      // Generate bytes untuk print
      // (Perlu menambahkan parameter yang diperlukan)
      // final bytes = await getTicketManifestBytes(...);

      // Sementara return dulu karena perlu data tambahan
      // await printerService.bluetooth.writeBytes(Uint8List.fromList(bytes));
      // Fluttertoast.showToast(msg: "✅ Tiket berhasil dicetak dari data lokal");

    } catch (e) {
      print('❌ Error mencetak tiket: $e');
      Fluttertoast.showToast(
        msg: "Error mencetak: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }
}