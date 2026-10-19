import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/sensor_reading.dart';

class SosDispatcher {
  bool _isDispatching = false;
  DateTime? _lastDispatchTime;

  bool get isDispatching => _isDispatching;
  DateTime? get lastDispatchTime => _lastDispatchTime;

  /// Builds emergency SMS payload for registered Trusted Contacts
  String buildContactsDispatchMessage({
    required UserModel user,
    required SensorReading vitals,
    required String currentAddress,
    required String mapsLink,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🚨 [EMERGENCY SOS ALERT] 🚨');
    buffer.writeln('${user.name} needs immediate assistance!');
    buffer.writeln('');
    buffer.writeln('📍 Live Location: $currentAddress');
    buffer.writeln('🗺️ Google Maps Tracking: $mapsLink');
    buffer.writeln('');
    buffer.writeln('💓 ESP32 Heart Rate: ${vitals.bpm} BPM (SpO2: ${vitals.spO2}%)');
    if (vitals.isDistress) {
      buffer.writeln('⚠️ Vitals Alert: Abnormal pulse distress detected!');
    }
    buffer.writeln('');
    buffer.writeln('🏥 Vital Medical Info:');
    buffer.writeln('• Blood Group: ${user.bloodGroup}');
    if (user.hasAsthma) {
      buffer.writeln('• ⚠️ ASTHMA ALERT: User has respiratory condition. Carry Inhaler/Oxygen!');
    }
    if (user.bloodPressure.toLowerCase().contains('high')) {
      buffer.writeln('• ⚠️ HYPERTENSION ALERT: Patient has high blood pressure.');
    }
    buffer.writeln('');
    buffer.writeln('Sent via HomeSafe (WOSAFE) Women Safety System');

    return buffer.toString();
  }

  /// Builds high-priority medical kit dispatch advisory for responding Hospital
  String buildHospitalDispatchMessage({
    required UserModel user,
    required SensorReading vitals,
    required String currentAddress,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🚑 [TRAUMA FIRST RESPONDER DISPATCH]');
    buffer.writeln('Patient: ${user.name} (${user.phone})');
    buffer.writeln('Incident Location: $currentAddress');
    buffer.writeln('Current Telemetry: ${vitals.bpm} BPM | SpO2: ${vitals.spO2}%');
    buffer.writeln('');
    buffer.writeln('📦 REQUIRED EMERGENCY MEDICAL KITS:');
    for (var advisory in user.getEmergencyKitAdvisories()) {
      buffer.writeln('• [KIT NEEDED] $advisory');
    }
    buffer.writeln('Physical Profile: Height ${user.height} cm | Weight ${user.weight} kg');

    return buffer.toString();
  }

  /// Dispatches alerts across all channels
  Future<Map<String, dynamic>> dispatchAllEmergencyChannels({
    required UserModel user,
    required SensorReading vitals,
    required String currentAddress,
    required String mapsLink,
  }) async {
    _isDispatching = true;
    _lastDispatchTime = DateTime.now();

    final contactsMessage = buildContactsDispatchMessage(
      user: user,
      vitals: vitals,
      currentAddress: currentAddress,
      mapsLink: mapsLink,
    );

    final hospitalMessage = buildHospitalDispatchMessage(
      user: user,
      vitals: vitals,
      currentAddress: currentAddress,
    );

    debugPrint('[SOS Dispatcher] --- DISPATCHING TO CONTACTS ---');
    debugPrint(contactsMessage);
    debugPrint('[SOS Dispatcher] --- DISPATCHING TO HOSPITAL TRAUMA UNIT ---');
    debugPrint(hospitalMessage);

    // Simulate SMS and emergency gateway latency
    await Future.delayed(const Duration(milliseconds: 1500));

    _isDispatching = false;

    return {
      'success': true,
      'timestamp': _lastDispatchTime,
      'contactsNotified': user.emergencyContacts.length,
      'policeNotified': true,
      'hospitalNotified': true,
      'medicalAdvisoriesCount': user.getEmergencyKitAdvisories().length,
    };
  }

  /// Builds cancellation notice if user aborts false alarm
  String buildCancellationMessage(UserModel user) {
    return '✅ [SOS CANCELLED] ${user.name} has marked the emergency alert as SAFE / FALSE ALARM. No further action needed.';
  }
}