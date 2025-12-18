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

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;

  /* ================= CONNECT ================= */

  Future<void> connect(BluetoothDevice device) async {
    try {
      await bluetooth.connect(device);
      _isConnected = await bluetooth.isConnected ?? false;
      _selectedDevice = device;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      _selectedDevice = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
    _isConnected = false;
    _selectedDevice = null;
    notifyListeners();
  }

  Future<bool> checkConnection() async {
    _isConnected = await bluetooth.isConnected ?? false;
    if (!_isConnected) _selectedDevice = null;
    notifyListeners();
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
}
