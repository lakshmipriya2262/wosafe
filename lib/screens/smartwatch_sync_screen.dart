import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../services/smartwatch_service.dart';

class SmartwatchSyncScreen extends StatefulWidget {
  const SmartwatchSyncScreen({Key? key}) : super(key: key);

  @override
  State<SmartwatchSyncScreen> createState() => _SmartwatchSyncScreenState();
}

class _SmartwatchSyncScreenState extends State<SmartwatchSyncScreen>
    with SingleTickerProviderStateMixin {
  late final SmartwatchService _service;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _service = SmartwatchService.instance;
    _service.addListener(_onServiceUpdate);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // If disconnected, automatically connect default WOSAFE Band for seamless testing
    if (!_service.isConnected && _service.status != SmartwatchStatus.connecting) {
      final defaultDev = _service.availableDevices.firstWhere(
        (d) => d.isDefault,
        orElse: () => _service.availableDevices.first,
      );
      _service.connectDevice(defaultDev);
    }
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bluetooth Smartwatch SOS',
          style: TextStyle(
            color: Color(0xFFE91E63),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _service.isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE91E63)),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFFE91E63)),
            tooltip: 'Scan for Bluetooth Wearables',
            onPressed: _service.isScanning ? null : () => _service.startScan(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Device Status Card
              _buildConnectedCard(
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 20),

              // 2. Hardware Watch SOS Button Hero Action
              _buildHardwareWatchSosSection(isDark: isDark),
              const SizedBox(height: 24),

              // 3. Fall Detection & Vital Settings
              _buildVitalsSettingsCard(
                cardColor: cardColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // 4. Discovered Bluetooth Devices List
              Text(
                'Available Wearable Devices (BLE)',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ..._service.availableDevices.map((device) => _buildDeviceItem(
                    device: device,
                    cardColor: cardColor,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    isDark: isDark,
                  )),
              const SizedBox(height: 20),

              // 5. Educational Wearable SOS Explainer
              _buildSafetyExplainerCard(
                cardColor: cardColor,
                borderColor: borderColor,
                textSecondary: textSecondary,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedCard({
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final isConnected = _service.isConnected;
    final device = _service.connectedDevice;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConnected ? const Color(0xFF10B981).withOpacity(0.4) : borderColor,
          width: isConnected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConnected
                      ? const Color(0xFF10B981).withOpacity(0.12)
                      : const Color(0xFFE2E8F0),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.watch_rounded,
                  color: isConnected ? const Color(0xFF10B981) : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected
                          ? (device?.name ?? 'WOSAFE Smart Band')
                          : (_service.isConnecting ? 'Connecting...' : 'No Wearable Connected'),
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? 'BLE Connected • MAC: ${device?.id ?? "WS:88:21:4F"}'
                          : 'Pair a Bluetooth smartwatch to enable hardware SOS',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
              ),
              if (isConnected)
                TextButton(
                  onPressed: () => _service.disconnectDevice(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  child: const Text('Disconnect', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),

          if (isConnected) ...[
            Divider(height: 24, color: borderColor),
            // Live Telemetry Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTelemetryItem(
                  icon: Icons.battery_charging_full_rounded,
                  iconColor: const Color(0xFF10B981),
                  label: 'Battery',
                  value: '${_service.batteryPercent}%',
                  sub: 'Normal',
                  isDark: isDark,
                ),
                _buildTelemetryItem(
                  icon: Icons.favorite_rounded,
                  iconColor: _service.isPanicSpike ? const Color(0xFFDC2626) : const Color(0xFFE91E63),
                  label: 'Heart Rate',
                  value: '${_service.heartRateBpm} BPM',
                  sub: _service.isPanicSpike ? '⚠️ PANIC SPIKE' : 'Optimal',
                  isDark: isDark,
                ),
                _buildTelemetryItem(
                  icon: Icons.air_rounded,
                  iconColor: const Color(0xFF0284C7),
                  label: 'SpO2 Oxygen',
                  value: '${_service.spO2}%',
                  sub: 'Normal',
                  isDark: isDark,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTelemetryItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
        ),
        Text(
          sub,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: sub.contains('PANIC') ? const Color(0xFFDC2626) : const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildHardwareWatchSosSection({required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2E1065), const Color(0xFF4C0519)]
              : [const Color(0xFFFFF1F2), const Color(0xFFFFE4E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.touch_app_rounded, color: Color(0xFFE91E63), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Hardware Smartwatch SOS Trigger',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'SYNCED',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Click the hardware SOS button below to simulate physical crown/button press on your smartwatch. Automatically dispatches live GPS location via background SMS to contacts & 1091, calls the police station, and launches Safe Route autopilot.',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),

          // Big Glowing Hardware SOS Button
          ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.03).animate(_pulseController),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _service.triggerWatchHardwareSos(context),
                borderRadius: BorderRadius.circular(30),
                splashColor: Colors.white24,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF991B1B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withOpacity(0.45),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.radio_button_checked_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text(
                        '🔘 PRESS HARDWARE WATCH SOS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVitalsSettingsCard({
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wearable Safety Features',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFE91E63),
            title: Text(
              'Fall & Sudden Impact Detection',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              'Uses watch accelerometer to detect violent impact and prompts instant SOS confirmation',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            value: _service.fallDetectionArmed,
            onChanged: (val) => _service.toggleFallDetection(val),
          ),
          Divider(height: 16, color: borderColor),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFFE91E63),
            title: Text(
              'Panic Tachycardia Auto-Alert',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
            ),
            subtitle: Text(
              'Triggers high-priority telemetry alert if heart rate surges past 130 BPM while stationary',
              style: TextStyle(fontSize: 11, color: textSecondary),
            ),
            value: true,
            onChanged: (val) {},
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem({
    required SmartwatchDevice device,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final isCurrent = _service.connectedDevice?.id == device.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCurrent ? const Color(0xFF10B981) : borderColor,
          width: isCurrent ? 1.4 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bluetooth_audio_rounded,
            color: isCurrent ? const Color(0xFF10B981) : const Color(0xFFE91E63),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.name,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (device.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'OFFICIAL',
                          style: TextStyle(
                            color: Color(0xFFE91E63),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.model} • ${device.rssi} dBm',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isCurrent
                ? () => _service.disconnectDevice()
                : () => _service.connectDevice(device),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrent ? const Color(0xFF10B981) : const Color(0xFFE91E63),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: Text(
              isCurrent ? 'Paired ✓' : 'Pair',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyExplainerCard({
    required Color cardColor,
    required Color borderColor,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFFE91E63), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How Smartwatch Hardware SOS Operates',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFE91E63)),
                ),
                const SizedBox(height: 3),
                Text(
                  'When in imminent danger, long-pressing the watch physical button transmits a BLE signal to WOSAFE. The app immediately dispatches background SMS with your real-time GPS tracking link to your trusted contacts and local police desk (1091), initiates a direct phone call, and plots an escape safe route.',
                  style: TextStyle(fontSize: 11, color: textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
