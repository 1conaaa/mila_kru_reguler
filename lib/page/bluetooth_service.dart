import 'dart:async';
import 'dart:typed_data';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BluetoothPrinterService with ChangeNotifier {
  static final BluetoothPrinterService _instance =
  BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  // ✅ TAMBAHKAN STREAM UNTUK STATUS KONEKSI
  final StreamController<bool> _connectionStatusController =
  StreamController<bool>.broadcast();

  // Timer untuk pengecekan periodik
  Timer? _connectionCheckTimer;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;

  // ✅ GETTER STREAM
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;

  /* ================= CONNECT ================= */

  Future<void> connect(BluetoothDevice device) async {
    try {
      await bluetooth.connect(device);
      _isConnected = await bluetooth.isConnected ?? false;
      _selectedDevice = device;

      // ✅ MULAI PENGECEKAN PERIODIK
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

    // ✅ HENTIKAN PENGECEKAN
    _stopConnectionCheck();

    notifyListeners();
    _connectionStatusController.add(false);
  }

  Future<bool> checkConnection() async {
    _isConnected = await bluetooth.isConnected ?? false;
    if (!_isConnected) _selectedDevice = null;
    notifyListeners();
    _connectionStatusController.add(_isConnected);
    return _isConnected;
  }

  /* ================= PRINT ================= */

  Future<void> printBytes(List<int> bytes) async {
    if (!_isConnected || _selectedDevice == null) {
      Fluttertoast.showToast(msg: "Printer belum terhubung");
      return;
    }
    await bluetooth.writeBytes(Uint8List.fromList(bytes));
  }

  /* ================= ✅ TAMBAHKAN INI ================= */

  // Fungsi untuk mengecek koneksi secara periodik
  void _startConnectionCheck() {
    _stopConnectionCheck();
    _connectionCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (_selectedDevice != null) {
        bool currentStatus = await bluetooth.isConnected ?? false;

        // Jika status berubah
        if (currentStatus != _isConnected) {
          _isConnected = currentStatus;
          if (!_isConnected) {
            _selectedDevice = null;
            print('⚠️ Printer terdeteksi mati');
          } else {
            print('✅ Printer terhubung kembali');
          }
          notifyListeners();
          _connectionStatusController.add(_isConnected);
        }
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