import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/emergency_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/phone_utils.dart';
import '../utils/share_utils.dart';
import '../services/location_services.dart';
import 'safe_route_screen.dart';

class SosScreen extends StatefulWidget {
  final bool isEmbedded;
  const SosScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Consumer2<AuthProvider, EmergencyProvider>(
      builder: (context, auth, emergency, child) {
        final user = auth.currentUser;
        final isTriggered = emergency.isSosActive;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            leading: widget.isEmbedded
                ? null
                : IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : AppTheme.textDark),
                    onPressed: () => Navigator.pop(context),
                  ),
            title: const Text(
              'SOS Emergency',
              style: TextStyle(
                color: AppTheme.primaryPink,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 22),
                tooltip: 'Call 1091',
                onPressed: () => makePhoneCall('1091', context),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),

                  // Header
                  Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Press and hold the SOS button for 3 seconds\nto share live location and open Safe Route.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : AppTheme.textMedium,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Animated Circular SOS Button with 3-Second Hold Progress
                  GestureDetector(
                    onTapDown: (_) {
                      HapticFeedback.mediumImpact();
                      if (!isTriggered) {
                        emergency.startSosHold(user, () async {
                          HapticFeedback.vibrate();

                          // 1. Instant GPS location acquisition
                          double lat = 12.8395;
                          double lng = 80.2185;
                          try {
                            final lastPos = await Geolocator.getLastKnownPosition();
                            if (lastPos != null) {
                              lat = lastPos.latitude;
                              lng = lastPos.longitude;
                            } else {
                              final curr = await Geolocator.getCurrentPosition(
                                desiredAccuracy: LocationAccuracy.high,
                                timeLimit: const Duration(seconds: 3),
                              );
                              lat = curr.latitude;
                              lng = curr.longitude;
                            }
                          } catch (e) {
                            debugPrint('SOS Screen GPS acquisition: $e');
                          }

                          // 2. Discover nearest police refuge dynamically
                          final nearestPolice = LocationServices.instance.findNearestPoliceStation(lat, lng);
                          final nearestHospital = LocationServices.instance.findNearestHospital(lat, lng);

                          // 3. Automated background emergency dispatch (SMS to contacts & police, zero popup)
                          ShareUtils.autoDispatchEmergencyDirectly(
                            latitude: lat,
                            longitude: lng,
                            address: 'EMERGENCY DISTRESS: Immediate rescue needed! Nearest Police: ${nearestPolice.name} (${nearestPolice.contact}), Nearest Hospital: ${nearestHospital.name}.',
                            userName: user?.name ?? 'WOSAFE User',
                            context: context,
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🚨 SOS DISPATCHED: Live GPS shared with Contacts & ${nearestPolice.name}!'),
                                backgroundColor: AppTheme.statusCritical,
                              ),
                            );

                            // 4. Auto launch safe route locked onto nearest police station
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SafeRouteScreen(
                                  isSosTriggered: true,
                                  destinationName: nearestPolice.name,
                                  destinationAddress: nearestPolice.address,
                                ),
                              ),
                            );
                          }
                        });
                      }
                    },
                    onTapUp: (_) => emergency.cancelSosHold(),
                    onTapCancel: () => emergency.cancelSosHold(),
                    child: ScaleTransition(
                      scale: isTriggered ? _pulseScale : const AlwaysStoppedAnimation(1.0),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Circular Progress Ring for 3-second hold
                          SizedBox(
                            width: 175,
                            height: 175,
                            child: CircularProgressIndicator(
                              value: isTriggered ? 1.0 : emergency.holdProgress,
                              strokeWidth: 8,
                              backgroundColor: isDark ? const Color(0xFF334155) : AppTheme.cardPink,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isTriggered ? AppTheme.statusCritical : AppTheme.primaryPink,
                              ),
                            ),
                          ),

                          // Outer Pulsing Glow
                          Container(
                            width: 145,
                            height: 145,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isTriggered
                                  ? const LinearGradient(
                                      colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                                    )
                                  : AppTheme.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: (isTriggered
                                          ? AppTheme.statusCritical
                                          : AppTheme.primaryPink)
                                      .withOpacity(0.4),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'SOS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isTriggered ? 'ACTIVE' : 'Hold 3 sec',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Recipients Destination Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : AppTheme.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : AppTheme.borderGrey),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : AppTheme.cardPink,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: AppTheme.primaryPink,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your alert will be sent to:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildBulletPoint('Trusted Contacts (${_getContactsPreview(user)})', isDark),
                              _buildBulletPoint('Singapen Athiradi Padai (1091)', isDark),
                              _buildBulletPoint('Nearest Police Station (24/7 Rapid Patrol)', isDark),
                              _buildBulletPoint('Nearby 24/7 Hospital (Emergency Trauma Unit)', isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Medical Kit Dispatch Advisory Card
                  if (user != null) _buildMedicalKitAdvisoryCard(user, isDark),
                  const SizedBox(height: 20),

                  // "What happens next?" Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'What happens next?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildNextStepCard(
                    icon: Icons.send_rounded,
                    title: 'Alert sent to your contacts',
                    subtitle: 'They receive your location & medical kit info',
                    isDone: isTriggered,
                    isDark: isDark,
                    onTap: null,
                  ),
                  const SizedBox(height: 10),

                  _buildNextStepCard(
                    icon: Icons.location_on_rounded,
                    title: 'Live location & Safe Route',
                    subtitle: 'Easiest safe route computed via well-lit corridor',
                    isDone: isTriggered,
                    isDark: isDark,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SafeRouteScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildNextStepCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'Alert sent to emergency services',
                    subtitle: 'Singapen Athiradi Padai & Police informed',
                    isDone: isTriggered,
                    isDark: isDark,
                    onTap: () => makePhoneCall('1091', context),
                  ),
                  const SizedBox(height: 24),

                  // Cancel SOS Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4081),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF4081).withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          emergency.abortSos();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('SOS Alert successfully cancelled.'),
                              backgroundColor: AppTheme.statusNormal,
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Cancel SOS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getContactsPreview(user) {
    if (user == null || user.emergencyContacts.isEmpty) return 'Registered Contacts';
    return user.emergencyContacts.map((c) => c.name).join(', ');
  }

  Widget _buildBulletPoint(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.primaryPink, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppTheme.textMedium),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalKitAdvisoryCard(user, bool isDark) {
    final advisories = user.getEmergencyKitAdvisories();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFFEAB308).withOpacity(0.5) : const Color(0xFFFFD54F),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_information_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                'First Responder Medical Kit Advisory',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB78103),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...advisories.map(
            (adv) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      adv,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextStepCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDone
                ? AppTheme.statusNormal
                : (isDark ? const Color(0xFF334155) : AppTheme.borderGrey),
            width: isDone ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFFE8F5E9)
                    : (isDark ? const Color(0xFF0F172A) : AppTheme.cardPink.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isDone ? AppTheme.statusNormal : AppTheme.primaryPink,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: isDone ? AppTheme.statusNormal : (isDark ? Colors.white54 : AppTheme.textLight),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
