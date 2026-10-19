import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sensor_provider.dart';
import '../theme/app_theme.dart';

class PulseGaugeWidget extends StatefulWidget {
  const PulseGaugeWidget({Key? key}) : super(key: key);

  @override
  State<PulseGaugeWidget> createState() => _PulseGaugeWidgetState();
}

class _PulseGaugeWidgetState extends State<PulseGaugeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.12).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, sensor, child) {
        final isSpike = sensor.isDistressTriggered || sensor.currentBpm > 120;
        final statusColor = isSpike
            ? AppTheme.statusCritical
            : (sensor.currentBpm > 100
                ? AppTheme.statusWarning
                : AppTheme.statusNormal);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSpike ? const Color(0xFFFFEBEE) : AppTheme.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSpike ? AppTheme.statusCritical : AppTheme.cardPink,
              width: isSpike ? 2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSpike ? AppTheme.statusCritical : AppTheme.primaryPink)
                    .withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Hardware Status & Microcontroller Tag
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ESP32-C3 Bio-Sensor',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textDark.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isSpike ? 'CRITICAL SPIKE' : 'STABLE',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Metrics Row: BPM & SpO2
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Pulse / BPM
                  Row(
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Icon(
                          Icons.favorite_rounded,
                          color: statusColor,
                          size: 34,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sensor.currentBpm} BPM',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isSpike ? AppTheme.statusCritical : AppTheme.textDark,
                            ),
                          ),
                          const Text(
                            'Heart Rate',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Divider
                  Container(
                    height: 38,
                    width: 1,
                    color: AppTheme.borderGrey,
                  ),

                  // SpO2
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop_rounded,
                        color: Color(0xFF0288D1),
                        size: 30,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${sensor.currentSpO2}%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const Text(
                            'Pulse SpO2',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interactive simulation button for college presentations
              InkWell(
                onTap: () {
                  if (sensor.isDistressTriggered) {
                    sensor.resetEmergencyDistress();
                  } else {
                    sensor.simulateEmergencyDistress();
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSpike ? AppTheme.white : AppTheme.cardPink.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSpike ? Icons.refresh_rounded : Icons.bolt_rounded,
                        size: 16,
                        color: AppTheme.primaryPink,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSpike
                            ? 'Reset Simulation to Normal'
                            : 'Test IPD Demo: Simulate Pulse Spike (>120 BPM)',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryPink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}