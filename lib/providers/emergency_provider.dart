import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class EmergencyProvider with ChangeNotifier {
  bool _isSosActive = false;
  double _holdProgress = 0.0; // 0.0 to 1.0 for 3-second hold
  Timer? _holdTimer;
  DateTime? _sosTriggeredTime;
  List<String> _dispatchedRecipients = [];
  List<String> _activeMedicalKits = [];
  String _currentAddress = 'Thalambur OMR, Chennai, Tamil Nadu 600130';
  String _safeRouteStatus = 'Optimal Safe Route Active (98% Well-Lit)';

  bool get isSosActive => _isSosActive;
  double get holdProgress => _holdProgress;
  DateTime? get sosTriggeredTime => _sosTriggeredTime;
  List<String> get dispatchedRecipients => _dispatchedRecipients;
  List<String> get activeMedicalKits => _activeMedicalKits;
  String get currentAddress => _currentAddress;
  String get safeRouteStatus => _safeRouteStatus;

  /// Starts 3-second continuous hold countdown for SOS button
  void startSosHold(UserModel? user, Function() onTriggered) {
    _holdProgress = 0.0;
    _holdTimer?.cancel();

    const intervalMs = 50;
    const totalMs = 3000; // 3 seconds
    const step = intervalMs / totalMs;

    _holdTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      _holdProgress += step;
      if (_holdProgress >= 1.0) {
        _holdProgress = 1.0;
        timer.cancel();
        triggerSos(user);
        onTriggered();
      }
      notifyListeners();
    });
  }

  /// Cancels hold countdown if user releases button before 3 seconds
  void cancelSosHold() {
    _holdTimer?.cancel();
    _holdProgress = 0.0;
    notifyListeners();
  }

  /// Activates the emergency alert and compiles medical kit advisories
  void triggerSos(UserModel? user) {
    _isSosActive = true;
    _sosTriggeredTime = DateTime.now();

    // Prepare dispatch list
    _dispatchedRecipients = [
      if (user != null && user.emergencyContacts.isNotEmpty)
        ...user.emergencyContacts.map((c) => '${c.name} (${c.relation} - ${c.phone})'),
      if (user == null || user.emergencyContacts.isEmpty) ...[
        'Emergency Contact 1 (Registered Guardian)',
        'Emergency Contact 2 (Registered Family)',
      ],
      'Nearest Police Station (Central Patrol Hub - 0.8 km)',
      'Nearby 24/7 Hospital (Emergency Trauma Unit - 1.2 km)',
    ];

    // Compile customized medical kit requirements
    if (user != null) {
      _activeMedicalKits = user.getEmergencyKitAdvisories();
    } else {
      _activeMedicalKits = [
        'Standard Trauma & Emergency First-Aid Kit',
        'Oxygen Cylinder & Nebulizer Support',
      ];
    }

    notifyListeners();
  }

  /// Aborts active SOS
  void abortSos() {
    _isSosActive = false;
    _holdProgress = 0.0;
    _dispatchedRecipients.clear();
    _activeMedicalKits.clear();
    notifyListeners();
  }

  void updateLocation(String newAddress) {
    _currentAddress = newAddress;
    notifyListeners();
  }
}