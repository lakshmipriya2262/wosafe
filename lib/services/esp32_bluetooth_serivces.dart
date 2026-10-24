import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sensor_reading.dart';

/// Service responsible for communicating with ESP32-C3 wearable over BLE/Serial
/// and parsing real-time pulse and bio-sensor telemetry.
class Esp32BluetoothService {
  // BLE GATT UUIDs matching esp32_homesafe_firmware.ino
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String charTxUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  static const String deviceTargetName = "HomeSafe-ESP32";

  bool _isConnected = false;
  bool _isScanning = false;
  Timer? _simulationTimer;
  final Random _random = Random();

  final StreamController<SensorReading> _sensorDataController =
      StreamController<SensorReading>.broadcast();
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();

  Stream<SensorReading> get sensorDataStream => _sensorDataController.stream;
  Stream<bool> get connectionStateStream => _connectionStateController.stream;

  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;

  /// Connect to ESP32 Device
  Future<bool> connectToEsp32({String deviceName = deviceTargetName}) async {
    _isScanning = true;
    debugPrint('[ESP32 BLE] Scanning for $deviceName...');

    // Simulate scanning and connection handshake
    await Future.delayed(const Duration(milliseconds: 1200));

    _isScanning = false;
    _isConnected = true;
    _connectionStateController.add(true);
    debugPrint('[ESP32 BLE] Successfully connected to $deviceName via GATT Service');

    // Start listening to telemetry stream
    _startTelemetryStream();
    return true;
  }

  /// Disconnect from ESP32
  Future<void> disconnect() async {
    _simulationTimer?.cancel();
    _isConnected = false;
    _connectionStateController.add(false);
    debugPrint('[ESP32 BLE] Disconnected from ESP32 Wearable');
  }

  /// Parses raw packet received from ESP32:
  /// Format: "BPM:78,SPO2:98,DISTRESS:0"
  SensorReading parseRawPacket(String rawPacket) {
    try {
      int bpm = 75;
      int spO2 = 98;
      bool distress = false;

      final parts = rawPacket.split(',');
      for (var part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          final key = kv[0].trim().toUpperCase();
          final val = kv[1].trim();

          if (key == 'BPM') {
            bpm = int.tryParse(val) ?? 75;
          } else if (key == 'SPO2') {
            spO2 = int.tryParse(val) ?? 98;
          } else if (key == 'DISTRESS') {
            distress = val == '1' || val.toLowerCase() == 'true';
          }
        }
      }

      return SensorReading(
        bpm: bpm,
        spO2: spO2,
        stressScore: distress ? 95.0 : (bpm > 100 ? 68.0 : 22.0),
        isDistress: distress || bpm > 120,
        status: (distress || bpm > 120)
            ? 'CRITICAL ALERT: Abnormal Pulse Spike Detected!'
            : 'Normal & Stable',
      );
    } catch (e) {
      debugPrint('[ESP32 BLE] Packet parsing error: $e');
      return SensorReading.fromBpm(75, 98);
    }
  }

  /// Simulates continuous telemetry stream for demonstration in VS Code & Mobile
  void _startTelemetryStream() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_isConnected) {
        // Normal baseline fluctuation (96 - 98 BPM every 4 seconds)
        int bpm = 96 + _random.nextInt(3);
        int spO2 = 97 + _random.nextInt(3);
        final reading = SensorReading.fromBpm(bpm, spO2);
        _sensorDataController.add(reading);
      }
    });
  }

  /// Manually inject a distress spike packet (> 120 BPM) for testing/demo
  void injectDistressSpike() {
    final reading = SensorReading(
      bpm: 138,
      spO2: 93,
      stressScore: 96.0,
      isDistress: true,
      status: 'CRITICAL ALERT: High Pulse Spike (>120 BPM) Detected!',
    );
    _sensorDataController.add(reading);
  }

  void dispose() {
    _simulationTimer?.cancel();
    _sensorDataController.close();
    _connectionStateController.close();
  }
}