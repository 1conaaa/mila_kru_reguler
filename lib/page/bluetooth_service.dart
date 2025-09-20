import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';

class BluetoothPrinterService with ChangeNotifier {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;

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
    try {
      await bluetooth.disconnect();
      _isConnected = false;
      _selectedDevice = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> checkConnection() async {
    _isConnected = await bluetooth.isConnected ?? false;
    if (!_isConnected) {
      _selectedDevice = null;
    }
    notifyListeners();
    return _isConnected;
  }
}