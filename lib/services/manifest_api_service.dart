import 'dart:convert';
import 'package:http/http.dart' as http;

class ManifestApiService {
  /// 🔹 Update status notifikasi ke server
  static Future<void> updateNotifikasi({
    required String token,
    required String idJadwalTrip,
    required int idBus,
    required String? noPol,
  }) async {
    print('🚀 [UPDATE NOTIFIKASI] Fungsi dipanggil...');
    print('📦 Token: $token');
    print('🚌 ID Jadwal Trip: $idJadwalTrip');
    print('🆔 ID Bus: $idBus');
    print('🚐 No. Polisi: ${noPol ?? '(kosong)'}');

    if (token.isEmpty) {
      print('⚠️ [UPDATE NOTIFIKASI] Token kosong, proses dibatalkan.');
      return;
    }

    try {
      final uri = Uri.parse(
        'https://apimila.milaberkah.com/api/updatenotifikasireguler',
      ).replace(queryParameters: {
        'id_jadwal_trip': idJadwalTrip.toString(),
        'id_bus': idBus.toString(),
        'no_pol': noPol ?? '',
      });

      print('🌐 [UPDATE NOTIFIKASI] Endpoint URI: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
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

  /// 🔹 Ambil data manifest dari server
  static Future<List<dynamic>> fetchManifest({
    required String token,
    required String idJadwalTrip,
  }) async {
    print('🚀 [FETCH MANIFEST] Fungsi dipanggil...');
    print('📦 Token: $token');
    print('🚌 ID Jadwal Trip: $idJadwalTrip');

    if (token.isEmpty) {
      print('⚠️ [FETCH MANIFEST] Token kosong, proses dibatalkan.');
      return [];
    }

    try {
      final url = 'https://apimila.milaberkah.com/api/listmanifestreguler/$idJadwalTrip';
      print('🌐 [FETCH MANIFEST] Endpoint URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('🔄 [FETCH MANIFEST] HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('📥 [FETCH MANIFEST] Response body mentah: ${response.body}');
        try {
          final data = jsonDecode(response.body);

          if (data is List) {
            print('✅ [FETCH MANIFEST] Data valid. Jumlah item: ${data.length}');
            return data;
          } else {
            print('⚠️ [FETCH MANIFEST] Format tidak sesuai (bukan List).');
            print('Tipe data: ${data.runtimeType}');
            return [];
          }
        } catch (e) {
          print('❌ [FETCH MANIFEST] Gagal parsing JSON: $e');
          return [];
        }
      } else {
        print('❌ [FETCH MANIFEST] Gagal ambil data. Status code: ${response.statusCode}');
        print('📦 Body: ${response.body}');
        return [];
      }
    } catch (e, stacktrace) {
      print('🔥 [FETCH MANIFEST] ERROR: $e');
      print('📚 Stacktrace: $stacktrace');
      return [];
    }
  }

  /// 🔹 Kirim data penjualan ke server
  static Future<void> kirimPenjualanKeServer({
    required Map<String, dynamic> penjualan,
    required String token,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    final idInvoice = penjualan['id_invoice'].toString();
    final apiUrl = 'https://apimila.milaberkah.com/api/penjualantiketonline';

    final queryParams =
        '?tgl_transaksi=${Uri.encodeFull(penjualan['tanggal_transaksi'].toString())}'
        '&kategori=${Uri.encodeFull(penjualan['kategori_tiket'].toString())}'
        '&rit=${Uri.encodeFull(penjualan['rit'].toString())}'
        '&no_pol=${Uri.encodeFull(penjualan['no_pol']?.toString() ?? '')}'
        '&id_bus=${penjualan['id_bus'].toString()}'
        '&kode_trayek=${Uri.encodeFull(penjualan['kode_trayek']?.toString() ?? '')}'
        '&id_personil=${penjualan['id_user'].toString()}'
        '&id_group=${penjualan['id_group'].toString()}'
        '&id_kota_berangkat=${Uri.encodeFull(penjualan['kota_berangkat']?.toString() ?? '')}'
        '&id_kota_tujuan=${Uri.encodeFull(penjualan['kota_tujuan']?.toString() ?? '')}'
        '&jml_naik=${penjualan['jumlah_tiket'].toString()}'
        '&pendapatan=${penjualan['jumlah_tagihan'].toString()}'
        '&harga_kantor=${penjualan['harga_kantor'].toString()}'
        '&nama_pelanggan=${Uri.encodeFull(penjualan['nama_pembeli']?.toString() ?? '')}'
        '&no_telepon=${Uri.encodeFull(penjualan['no_telepon']?.toString() ?? '')}'
        '&status=${Uri.encodeFull(penjualan['status'].toString())}'
        '&keterangan=${Uri.encodeFull(penjualan['keterangan']?.toString() ?? '')}'
        '&id_invoice=${Uri.encodeFull(idInvoice)}'
        '&is_turun=0';

    // 🟡 DEBUG PRINT
    print('==============================');
    print('🚀 Mengirim data penjualan ke server');
    print('🧾 id_invoice       : $idInvoice');
    print('🔗 API URL          : $apiUrl$queryParams');
    print('==============================');

    try {
      final response = await http.post(
        Uri.parse(apiUrl + queryParams),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('🛰️ [POST] ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        onSuccess(idInvoice);
      } else {
        onError('Gagal kirim id_invoice $idInvoice: ${response.body}');
      }
    } catch (e) {
      onError('Error kirim data penjualan (id_invoice: $idInvoice): $e');
    }
  }
}