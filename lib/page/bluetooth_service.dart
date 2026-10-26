import 'dart:async';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ============================================================================
// BluetoothPrinterService — deteksi printer thermal mati (APP-BLE-01)
// ============================================================================
// TEMUAN QA 26 Okt 2026 (round 2 — dari log real-device RPP02N):
//
// Write-test sederhana (1 byte NUL) TIDAK bisa dipercaya di Android karena
// pada plugin blue_thermal_printer 1.2.3:
//   1) isConnected  ->  result.success(THREAD != null) → CACHED state.
//      Printer dimatikan → THREAD tetap ada → masih "true".
//   2) writeBytes   ->  ConnectedThread.write() MELAN IOException
//      (Broken pipe) ke logcat TANPA melempar ulang → Dart selalu terima
//      `true` walau printer mati. Write kecil juga hanya masuk buffer
//      RFCOMM (bluetooth stack) sehingga tidak membuktikan apa pun.
//
// SOLUSI: "deep liveness probe" satu-satunya operasi plugin yang benar2
// menguji printer HIDUP adalah `connect()` (socket.connect() ke printer).
// Alur deteksi:
//   [1] cek state THREAD (cepat, cached)
//   [2] disconnect() + connect(device) ulang (reconnect probe)
//       - printer hidup  → reconnect sukses → sehat
//       - printer mati   → socket.connect() gagal (connect_error) → mati
// Verifikasi pasca-cetak juga memakai probe ini setelah estimasi data
// struk selesai dikirim (drain time) agar tidak memotong transmisi.
class BluetoothPrinterService with ChangeNotifier {
  static final BluetoothPrinterService _instance =
  BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  // ======================================================================
  // KONFIGURASI DETEKSI
  // ======================================================================
  /// Interval pengecekan periodik (deep probe tiap 5 detik).
  static const Duration _periodicCheckInterval = Duration(seconds: 5);

  /// Batas waktu reconnect saat probe (printer mati biasanya
  /// menghasilkan connect_error dalam 1–3 detik).
  static const Duration _probeConnectTimeout = Duration(seconds: 6);

  /// Batas waktu kirim payload struk.
  static const Duration _printWriteTimeout = Duration(seconds: 20);

  /// Estimasi drain pasca-cetak memakai baud minimal 9600 bps
  /// (≈1200 byte/detik) — konservatif agar struk tak terpotong saat verifikasi.

  /// Delay drain minimum/max pasca-cetak.
  static const Duration _postPrintVerifyMin = Duration(milliseconds: 800);
  static const Duration _postPrintVerifyMax = Duration(seconds: 15);

  // ======================================================================
  // STATE INTERNAL
  // ======================================================================
  /// Hasil health check terakhir.
  bool _printerHealthy = false;

  /// Waktu health check terakhir.
  DateTime? _lastHealthCheckAt;

  /// Proteksi agar probe tidak beruntun/tumpang tindih.
  /// SEMUA probe (UI, timer, pasca-cetak) lewat serialisasi ini —
  /// dua `connect()` paralel ke device yang sama menghasilkan
  /// "read failed, socket might closed or timeout" (FALSE POSITIVE mati).
  bool _probeBusy = false;

  /// Shield ketika sesi cetak sedang berjalan (timer probe harus skip).
  bool _printInProgress = false;

  /// ✅ STREAM untuk status koneksi.
  final StreamController<bool> _connectionStatusController =
  StreamController<bool>.broadcast();

  /// Timer pengecekan periodik.
  Timer? _connectionCheckTimer;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;
  DateTime? get lastHealthCheckAt => _lastHealthCheckAt;

  /// ✅ Getter stream.
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /* ================= CONNECT ================= */

  Future<void> connect(BluetoothDevice device) async {
    // Tunggu probe lain selesai agar koneksi manual tidak berbenturan
    // dengan disconnect+connect probe (penyebab connect gagal acak).
    while (_probeBusy) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    try {
      await bluetooth.connect(device);
      _isConnected = true;
      _printerHealthy = true;
      _selectedDevice = device;

      // ✅ Mulai pengecekan periodik
      _startConnectionCheck();

      notifyListeners();
      _connectionStatusController.add(_isConnected);
    } catch (e) {
      _isConnected = false;
      _selectedDevice = null;
      notifyListeners();
      _connectionStatusController.add(false);
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
    _isConnected = false;
    _selectedDevice = null;

    // ✅ Hentikan pengecekan
    _stopConnectionCheck();

    notifyListeners();
    _connectionStatusController.add(false);
  }

  /// Cek cepat (cached `THREAD != null`) — TIDAK mendeteksi printer mati.
  /// Khusus kompatibilitas pemakaian lama (main.dart, manifest, dll).
  Future<bool> checkConnection() async {
    _isConnected = await bluetooth.isConnected ?? false;
    notifyListeners();
    _connectionStatusController.add(_isConnected);
    return _isConnected;
  }

  /* ================= HEALTH CHECK (DEEP PROBE) ================= */

  /// ✅ Verifikasi printer benar-benar aktif:
  ///   [1] state socket & device terpilih harus ada
  ///   [2] DEEP PROBE: disconnect + connect ulang ke printer.
  /// Ketika printer mati → connect melempar `connect_error` → ditandai mati.
  ///
  /// Kembalikan `true` bila printer siap mencetak. Saat mati: status internal
  /// disconnected + notifyListeners + stream false (semua UI ikut update).
  /// NOTE: `_selectedDevice` TIDAK dihapus saat mati agar timer periodik
  /// dapat AUTO-RECONNECT ketika printer kembali menyala.
  Future<bool> performHealthCheck() async {
    bool healthy = false;
    bool changed = false;

    final device = _selectedDevice;
    if (device == null) {
      healthy = false;
    } else {
      // [1] Cek cepat state plugin
      final bool? stateOk = await bluetooth.isConnected;
      if (stateOk != true) {
        healthy = false;
      } else {
        // [2] DEEP PROBE — disconnect + connect ulang
        healthy = await _serialLivenessProbe(device);
      }
    }

    _lastHealthCheckAt = DateTime.now();

    final bool previous = _isConnected;
    _isConnected = healthy;
    _printerHealthy = healthy;
    if (previous != healthy) changed = true;
    if (changed) {
      if (!healthy) print('⚠️ Printer terdeteksi mati / terputus (probe)');
      notifyListeners();
      _connectionStatusController.add(healthy);
    }

    return healthy;
  }

  /// Serialisasi DEEP PROBE + retry.
  ///
  /// SAAT INI (QA Round 2, 26 Okt 2026): probe pasca-cetak `printBytes`
  /// bisa bersinggungan dengan probe timer 5 detik → dua `connect()`
  /// paralel → salah satu gagal "read failed, socket might closed or
  /// timeout" → printer yang HIDUP salah tandai mati.
  /// Solusi: semua probe mengantri di `_probeBusy`, dan hasil gagal
  /// di-retry 1x (race biasanya pulih; printer benar-benar mati gagal 2x).
  Future<bool> _serialLivenessProbe(
    BluetoothDevice device, {
    int attempts = 2,
  }) async {
    // Tunggu probe lain selesai (serial)
    while (_probeBusy) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    _probeBusy = true;
    try {
      for (int attempt = 1; attempt <= attempts; attempt++) {
        final bool ok = await _reconnectProbe(device);
        if (ok) return true;
        if (attempt < attempts) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }
      return false;
    } finally {
      _probeBusy = false;
    }
  }

  /// Deep probe: putuskan koneksi lama, lalu coba koneksi ulang ke device.
  /// `true` = printer hidup & koneksi baru siap, `false` = mati/gagal.
  Future<bool> _reconnectProbe(BluetoothDevice device) async {
    // Putuskan koneksi lama (harus agar plugin mengizinkan connect baru)
    try {
      await bluetooth.disconnect();
    } catch (_) {
      // abaikan (sudah putus)
    }

    try {
      await bluetooth
          .connect(device)
          .timeout(_probeConnectTimeout, onTimeout: () => throw TimeoutException('probe connect'));
      // Koneksi baru siap; sedikit jeda agar siklus siap
      final ok = await bluetooth.isConnected ?? false;
      return ok;
    } catch (e) {
      print('❌ Probe reconnect gagal (printer mati?): ${e.toString()}');
      // Bersihkan sisa socket (cadangan bila connect setengah jalan)
      try {
        await bluetooth.disconnect();
      } catch (_) {}
      return false;
    }
  }

  /* ================= PRINT ================= */

  /// Kirim payload struk. Return `true` HANYA bila data terkirim DAN
  /// printer terverifikasi hidup pasca-cetak (deep probe).
  ///
  /// Android: ConnectedThread.write() menelan IOException sehingga
  /// `writeBytes` selalu true — maka verifikasi PASCA-cetak wajib:
  /// tunggu estimasi drain data, lalu probe reconnect.
  /// Bila probe gagal → status disconnected & return `false` (pemanggil
  /// tiket/bagasi akan rollback transaksi).
  Future<bool> printBytes(List<int> bytes) async {
    if (!_isConnected || !_printerHealthy || _selectedDevice == null) {
      Fluttertoast.showToast(msg: "Printer belum terhubung");
      return false;
    }
    _printInProgress = true;
    try {
      final res = await bluetooth
          .writeBytes(Uint8List.fromList(bytes))
          .timeout(_printWriteTimeout, onTimeout: () => false);
      if (res != true) {
        _markDisconnected("Gagal kirim data ke printer");
        return false;
      }

      // ---- VERIFIKASI PASCA-CETAK (Android: writeBytes tak bisa dipercaya)
      // Tunggu drain estimasi: bytes.len / (9600/8) = 1.2 byte/ms
      final int drainMs = ((bytes.length * 1000) ~/ 1200)
          .clamp(_postPrintVerifyMin.inMilliseconds, _postPrintVerifyMax.inMilliseconds);
      print("⏳ Menunggu drain struk... ${drainMs}ms (${bytes.length} bytes)");
      await Future.delayed(Duration(milliseconds: drainMs));

      print("🔎 Verifikasi printer pasca-cetak (probe koneksi ulang)...");
      final device = _selectedDevice;
      if (device == null) {
        _markDisconnected("Device hilang saat verifikasi");
        return false;
      }
      final bool alive = await _serialLivenessProbe(device);
      if (!alive) {
        _markDisconnected("Printer mati / offline saat verifikasi pasca-cetak");
        Fluttertoast.showToast(
          msg: "⚠️ Struk TIDAK tercetak (printer mati/tidak merespons)",
          gravity: ToastGravity.BOTTOM,
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        return false;
      }
      return true;
    } catch (e) {
      _markDisconnected("Terputus saat mencetak: ${e.toString()}");
      return false;
    } finally {
      _printInProgress = false;
    }
  }

  /// Tandai printer disconnected dan broadcast ke seluruh UI.
  /// Device DIPERTAHANKAN agar timer periodik bisa auto-reconnect
  /// ketika printer kembali menyala.
  void _markDisconnected(String reason) {
    print('⚠️ Printer terdeteksi mati / terputus: $reason');
    _isConnected = false;
    _printerHealthy = false;
    notifyListeners();
    _connectionStatusController.add(false);
  }

  /* ================= PENGECEKAN PERIODIK ================= */

  // Timer pengecekan periodik (deep probe).
  void _startConnectionCheck() {
    _stopConnectionCheck();
    _connectionCheckTimer = Timer.periodic(_periodicCheckInterval, (timer) async {
      // Jangan tumpangkan probe periodik di atas probe lain (UI/pasca-cetak)
      if (_selectedDevice != null && !_printInProgress && !_probeBusy) {
        await performHealthCheck();
      }
    });
  }

  void _stopConnectionCheck() {
    _connectionCheckTimer?.cancel();
    _connectionCheckTimer = null;
  }

  // Tambahkan dispose
  void dispose() {
    _stopConnectionCheck();
    _connectionStatusController.close();
    super.dispose();
  }
}
