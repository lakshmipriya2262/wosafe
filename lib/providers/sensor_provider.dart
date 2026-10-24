import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sensor_reading.dart';

class SensorProvider with ChangeNotifier {
  bool _isConnected = true; // Connected to wearable
  bool _isDistressTriggered = false;
  int _currentBpm = 97;
  int _currentSpO2 = 98;
  double _stressScore = 22.0;
  String _deviceStatus = 'Connected (ESP32-C3 Wearable)';
  Timer? _telemetryTimer;
  final Random _random = Random();

  bool get isConnected => _isConnected;
  bool get isDistressTriggered => _isDistressTriggered;
  int get currentBpm => _currentBpm;
  int get currentSpO2 => _currentSpO2;
  double get stressScore => _stressScore;
  String get deviceStatus => _deviceStatus;

  SensorReading get currentReading => SensorReading.fromBpm(_currentBpm, _currentSpO2);

  SensorProvider() {
    _startLiveVitalsMonitoring();
  }

  /// Live real-time background pulse simulation representing ESP32 telemetry stream
  void _startLiveVitalsMonitoring() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_isDistressTriggered && _isConnected) {
        // Natural resting fluctuation between 96 and 98 BPM every 4 seconds
        _currentBpm = 96 + _random.nextInt(3);
        _currentSpO2 = 97 + _random.nextInt(3);
        _stressScore = 18.0 + _random.nextDouble() * 12.0;
        _deviceStatus = 'Normal Vitals - ESP32 Active';
        notifyListeners();
      }
    });
  }

  /// Demo / Simulation trigger for College IPD presentations:
  /// Simulates a sudden physiological distress spike (> 125 BPM)
  void simulateEmergencyDistress() {
    _isDistressTriggered = true;
    _currentBpm = 138; // Abnormal spike > 120 BPM
    _currentSpO2 = 94;
    _stressScore = 94.5;
    _deviceStatus = 'CRITICAL ALERT: Abnormal Pulse Spike Detected!';
    notifyListeners();
  }

  /// Reset emergency state back to normal
  void resetEmergencyDistress() {
    _isDistressTriggered = false;
    _currentBpm = 97;
    _currentSpO2 = 98;
    _stressScore = 20.0;
    _deviceStatus = 'Normal Vitals - ESP32 Active';
    notifyListeners();
  }

  /// Update vitals from actual ESP32 BLE / WiFi packet
  void updateFromHardwarePacket(int bpm, int spO2) {
    _currentBpm = bpm;
    _currentSpO2 = spO2;
    if (bpm > 120) {
      _isDistressTriggered = true;
      _stressScore = 95.0;
      _deviceStatus = 'CRITICAL: High Heart Rate Detected from ESP32!';
    } else {
      _isDistressTriggered = false;
      _stressScore = (bpm > 100) ? 65.0 : 25.0;
      _deviceStatus = 'ESP32 Bio-Sensor Connected';
    }
    notifyListeners();
  }

  void toggleConnection(bool connected) {
    _isConnected = connected;
    _deviceStatus = connected ? 'Connected (ESP32-C3)' : 'Disconnected';
    notifyListeners();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
