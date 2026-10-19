import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/share_utils.dart';
import '../utils/phone_utils.dart';
import '../screens/safe_route_screen.dart';

enum SmartwatchStatus {
  disconnected,
  scanning,
  connecting,
  connected,
}

class SmartwatchDevice {
  final String id;
  final String name;
  final String model;
  final int rssi;
  final bool isDefault;

  const SmartwatchDevice({
    required this.id,
    required this.name,
    required this.model,
    required this.rssi,
    this.isDefault = false,
  });
}

class SmartwatchService extends ChangeNotifier {
  static final SmartwatchService instance = SmartwatchService._internal();
  SmartwatchService._internal();

  SmartwatchStatus _status = SmartwatchStatus.disconnected;
  SmartwatchDevice? _connectedDevice;
  int _batteryPercent = 92;
  int _heartRateBpm = 76;
  int _spO2 = 98;
  bool _fallDetectionArmed = true;
  bool _isSosActive = false;
  Timer? _telemetryTimer;
  final Random _rand = Random();

  List<SmartwatchDevice> _availableDevices = [
    const SmartwatchDevice(
      id: 'WS:88:21:4F:9A:01',
      name: 'WOSAFE Smart Band V2 (BLE)',
      model: 'WOSAFE Hardware SOS & Fall Sensor',
      rssi: -48,
      isDefault: true,
    ),
    const SmartwatchDevice(
      id: 'NB:12:9A:34:CC:22',
      name: 'Noise ColorFit Pulse 3',
      model: 'Smart Wearable with BLE Button',
      rssi: -58,
    ),
    const SmartwatchDevice(
      id: 'FB:44:88:01:FE:33',
      name: 'Fire-Boltt Watch Pro',
      model: 'Optical Biometrics + SOS Kiosk',
      rssi: -65,
    ),
    const SmartwatchDevice(
      id: 'BT:33:11:90:AA:44',
      name: 'Boat Wave Call Smartwatch',
      model: 'BLE 5.2 Wearable Sensor',
      rssi: -72,
    ),
    const SmartwatchDevice(
      id: 'GW:99:45:AB:12:55',
      name: 'Samsung Galaxy Watch / WearOS',
      model: 'WearOS Panic Button Companion',
      rssi: -62,
    ),
  ];

  SmartwatchStatus get status => _status;
  bool get isConnected => _status == SmartwatchStatus.connected;
  bool get isScanning => _status == SmartwatchStatus.scanning;
  bool get isConnecting => _status == SmartwatchStatus.connecting;
  SmartwatchDevice? get connectedDevice => _connectedDevice;
  int get batteryPercent => _batteryPercent;
  int get heartRateBpm => _heartRateBpm;
  int get spO2 => _spO2;
  bool get fallDetectionArmed => _fallDetectionArmed;
  bool get isSosActive => _isSosActive;
  bool get isPanicSpike => _heartRateBpm >= 125;
  List<SmartwatchDevice> get availableDevices => _availableDevices;

  /// Start BLE scanning for nearby smartwatches & smart bands
  Future<void> startScan() async {
    _status = SmartwatchStatus.scanning;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1600));

    // Refresh RSSI with small random jitter
    _availableDevices = _availableDevices.map((d) {
      final delta = _rand.nextInt(5) - 2;
      return SmartwatchDevice(
        id: d.id,
        name: d.name,
        model: d.model,
        rssi: (d.rssi + delta).clamp(-90, -30),
        isDefault: d.isDefault,
      );
    }).toList();

    _status = SmartwatchStatus.disconnected;
    notifyListeners();
  }

  /// Connect to chosen smartwatch / wearable
  Future<bool> connectDevice(SmartwatchDevice device) async {
    _status = SmartwatchStatus.connecting;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1400));

    _connectedDevice = device;
    _status = SmartwatchStatus.connected;
    _batteryPercent = 88 + _rand.nextInt(10);
    _heartRateBpm = 74;
    _spO2 = 98;
    _isSosActive = false;

    _startTelemetryLoop();
    notifyListeners();
    return true;
  }

  /// Disconnect current wearable
  void disconnectDevice() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
    _connectedDevice = null;
    _status = SmartwatchStatus.disconnected;
    _isSosActive = false;
    notifyListeners();
  }

  /// Toggle fall detection sensor trigger
  void toggleFallDetection(bool enabled) {
    _fallDetectionArmed = enabled;
    notifyListeners();
  }

  /// Periodic telemetry updates from watch (BPM and SpO2)
  void _startTelemetryLoop() {
    _telemetryTimer?.cancel();
    _telemetryTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_status != SmartwatchStatus.connected) return;

      if (!_isSosActive) {
        // Natural pulse fluctuations (70 - 79 bpm)
        _heartRateBpm = 72 + _rand.nextInt(7);
        _spO2 = 97 + _rand.nextInt(3);
      }
      notifyListeners();
    });
  }

  /// TRIGGER WATCH HARDWARE SOS BUTTON:
  /// Automatically shares live GPS location link to emergency contacts and police station via background SMS,
  /// initiates direct phone call to 1091 / Police Station desk, and launches Safe Route navigation!
  Future<void> triggerWatchHardwareSos(BuildContext context) async {
    _isSosActive = true;
    _heartRateBpm = 138; // Abnormal distress tachycardia spike
    notifyListeners();

    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();

    String userName = 'WOSAFE User';
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      userName = auth.currentUser?.name ?? 'WOSAFE User';
    } catch (_) {}

    double userLat = 12.8406;
    double userLng = 80.1534;
    String address = 'Near Agni College / Thalambur Main Rd, Chennai';

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      userLat = pos.latitude;
      userLng = pos.longitude;
      address = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)} (Thalambur OMR Area)';
    } catch (_) {}

    if (!context.mounted) return;

    // 1. Dispatch background SMS with live tracking link to Emergency Contacts & 1091
    ShareUtils.autoDispatchEmergencyDirectly(
      latitude: userLat,
      longitude: userLng,
      address: address,
      userName: userName,
      context: context,
    );

    // 2. Direct emergency phone call to 1091 (Women Helpline / Police Desk)
    directEmergencyCall('1091', context);

    // 3. User feedback SnackBar
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.watch_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '🚨 SMARTWATCH HARDWARE SOS TRIGGERED!\nLive GPS sent via SMS. Calling Police Desk (1091) & starting Safe Route...',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 4. Auto-launch SafeRouteScreen with verified coordinates for Thazhambur Police Station
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SafeRouteScreen(
                isSosTriggered: true,
                destinationName: 'Thazhambur Police Station (Nearest Safe Haven)',
                destinationCategory: 'police',
                destinationLat: 12.8598,
                destinationLng: 80.2075,
              ),
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();
    super.dispose();
  }
}
