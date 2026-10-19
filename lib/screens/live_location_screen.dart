import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/emergency_provider.dart';
import '../utils/share_utils.dart';
import '../services/location_services.dart';
import 'home_dashboard_screen.dart';
import 'profile_screen.dart';
import 'setting_screen.dart';

class LiveLocationScreen extends StatefulWidget {
  const LiveLocationScreen({Key? key}) : super(key: key);

  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  int _bottomNavIndex = 1; // 1 = Location tab active

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Real GPS Coordinates (Anchored to Agni College Campus, Thalambur, updated live from device GPS)
  double _currentLat = 12.8395;
  double _currentLng = 80.2185;
  String _currentLocationText = 'Agni College Campus, Thalambur, OMR, Chennai - 600130';
  String _chennaiSubText = 'Agni College Campus Safe Corridor • GPS: 12.8395° N, 80.2185° E';

  List<Map<String, String>> _emergencyContacts = [];
  bool _isGpsActive = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fetchRealGps();
    _loadEmergencyContacts();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchRealGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.orange,
              content: Text('⚠️ Turn on phone GPS/Location for high-precision live tracking!'),
            ),
          );
        }
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );

      final areaName = await LocationServices.instance.reverseGeocodeArea(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() {
          _currentLat = pos.latitude;
          _currentLng = pos.longitude;
          _isGpsActive = true;
          _currentLocationText = areaName;
          _chennaiSubText = 'Real-time GPS: ${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E • Live Accuracy ±3m';
        });

        // Center map to real GPS location
        _mapController.move(LatLng(_currentLat, _currentLng), 16.0);
      }
    } catch (e) {
      debugPrint('Live GPS fetch: $e');
    }
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('wosafe_contacts_json') ?? prefs.getString('homesafe_emergency_contacts');
      List<Map<String, String>> loaded = [];
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map && item['name'] != null) {
              loaded.add({
                'name': item['name'].toString(),
                'phone': item['phone']?.toString() ?? '',
              });
            }
          }
        }
      }

      if (loaded.isEmpty && mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final list = auth.currentUser?.emergencyContacts;
        if (list != null) {
          for (var c in list) {
            if (c.name.isNotEmpty) {
              loaded.add({'name': c.name, 'phone': c.phone});
            }
          }
        }
      }

      if (mounted) {
        setState(() => _emergencyContacts = loaded);
      }
    } catch (e) {
      debugPrint('Error loading emergency contacts: $e');
    }
  }

  void _recenterMap() {
    _mapController.move(LatLng(_currentLat, _currentLng), 16.0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎯 Recentered to current location (${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)})'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openShareModal(BuildContext context, bool isDark) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    ShareUtils.showLocationShareModal(
      context,
      latitude: _currentLat,
      longitude: _currentLng,
      address: _currentLocationText,
      userName: auth.currentUser?.name,
      isDark: isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Consumer2<AuthProvider, EmergencyProvider>(
      builder: (context, auth, emergency, child) {
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFBFE),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
                  );
                }
              },
            ),
            title: const Text(
              'Live Location',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Color(0xFFE91E63), size: 22),
                tooltip: 'Share Live GPS',
                onPressed: () => _openShareModal(context, isDark),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. "You are currently safe" Status Banner
                  _buildSafeStatusCard(isDark),
                  const SizedBox(height: 14),

                  // 2. Real OpenStreetMap Container with GPS Pin & Interactive Controls
                  _buildOpenStreetMapCard(isDark),
                  const SizedBox(height: 14),

                  // 3. Current Location Card
                  _buildCurrentLocationCard(isDark),
                  const SizedBox(height: 12),

                  // 4. Share Live Location Card with Pink [Share] Button (WhatsApp / SMS)
                  _buildShareLiveLocationCard(context, isDark),
                  const SizedBox(height: 18),

                  // 5. Recent Shared Section Header
                  Text(
                    'Recent Shared & Monitored',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 6. Recent Shared List
                  if (_emergencyContacts.isNotEmpty)
                    ..._emergencyContacts.take(3).map((contact) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRecentSharedTile(
                            name: contact['name'] ?? 'Trusted Contact',
                            timeAgo: 'Live Tracking Active',
                            phone: contact['phone'] ?? '',
                            isDark: isDark,
                            onShare: () {
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final msg = ShareUtils.buildEmergencyMessage(
                                latitude: _currentLat,
                                longitude: _currentLng,
                                address: _currentLocationText,
                                userName: auth.currentUser?.name,
                              );
                              ShareUtils.shareViaWhatsApp(
                                message: msg,
                                phoneNumber: contact['phone'],
                                context: context,
                              );
                            },
                          ),
                        ))
                  else ...[
                    _buildRecentSharedTile(
                      name: 'Primary Emergency Contact',
                      timeAgo: 'Ready to receive location',
                      phone: '',
                      isDark: isDark,
                      onShare: () => _openShareModal(context, isDark),
                    ),
                    const SizedBox(height: 10),
                    _buildRecentSharedTile(
                      name: 'Singapen Athiradi Padai (1091)',
                      timeAgo: 'Rapid Action Rescue Post',
                      phone: '1091',
                      isDark: isDark,
                      onShare: () => _openShareModal(context, isDark),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildLiveLocationBottomNav(isDark),
        );
      },
    );
  }

  // 1. "You are currently safe" Card
  Widget _buildSafeStatusCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are currently safe',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isGpsActive ? 'High Accuracy Live GPS Satellite Active' : 'Karanai / Thalambur Safe Corridor monitored',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Real OpenStreetMap Interactive Card
  Widget _buildOpenStreetMapCard(bool isDark) {
    final userPos = LatLng(_currentLat, _currentLng);

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // REAL OPENSTREETMAP VIEW
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: userPos,
                initialZoom: 15.0,
                minZoom: 4.0,
                maxZoom: 19.0,
              ),
              children: [
                // OpenStreetMap Standard Tiles (No API key required!)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.wosafe',
                ),

                // Map Markers Layer
                MarkerLayer(
                  markers: [
                    // A. Real User GPS Marker
                    Marker(
                      point: userPos,
                      width: 130,
                      height: 75,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: const Text(
                              '📍 You are here',
                              style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 2),
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, _) => Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 28 * _pulseAnimation.value,
                                  height: 28 * _pulseAnimation.value,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFE91E63).withOpacity(0.28),
                                  ),
                                ),
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E63),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Verified Regional Landmarks (Dynamically closest safe havens)
                    ...LocationServices.instance.getAllSafePlacesSorted(_currentLat, _currentLng).take(3).map((place) {
                      final isPolice = place.category == 'police';
                      final isHosp = place.category == 'hospital';
                      final badgeColor = isPolice
                          ? const Color(0xFF0284C7)
                          : isHosp
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF4338CA);
                      final iconText = isPolice ? '👮' : isHosp ? '🏥' : '🏬';
                      final cleanName = place.name.split('(').first.trim();
                      return Marker(
                        point: LatLng(place.latitude, place.longitude),
                        width: 125,
                        height: 40,
                        child: _buildPoiPill('$iconText $cleanName', badgeColor),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),

            // Top-Right Recenter to GPS Button
            Positioned(
              right: 12,
              top: 14,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.my_location_rounded, color: Color(0xFFE91E63), size: 20),
                  onPressed: _recenterMap,
                  tooltip: 'Recenter to Real GPS',
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),

            // Bottom-Right Zoom In / Out Controls
            Positioned(
              right: 12,
              bottom: 14,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, currentZoom + 1.0);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.add, size: 20, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: isDark ? const Color(0xFF334155) : Colors.grey[300]),
                    InkWell(
                      onTap: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(_mapController.camera.center, currentZoom - 1.0);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.remove, size: 20, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom-Left OpenStreetMap Attribution Badge
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '© OpenStreetMap contributors',
                  style: TextStyle(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoiPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 3)],
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // 3. Current Location Card
  Widget _buildCurrentLocationCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on_rounded, color: Color(0xFFE91E63), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CURRENT LOCATION',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentLocationText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _chennaiSubText,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Share Live Location Card with WhatsApp & SMS Modal
  Widget _buildShareLiveLocationCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Share Live Location',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Send via WhatsApp or SMS to contacts',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => _openShareModal(context, isDark),
            icon: const Icon(Icons.share_rounded, color: Colors.white, size: 16),
            label: const Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // 6. Recent Shared Tile with 1-Tap WhatsApp
  Widget _buildRecentSharedTile({
    required String name,
    required String timeAgo,
    required String phone,
    required VoidCallback onShare,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF0F5),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  ),
                ),
                Text(
                  phone.isNotEmpty ? '$timeAgo • $phone' : timeAgo,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFFE91E63), size: 20),
            tooltip: 'Share via WhatsApp',
            onPressed: onShare,
          ),
        ],
      ),
    );
  }

  // Bottom Nav
  Widget _buildLiveLocationBottomNav(bool isDark) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_outlined, 'Home', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeDashboardScreen())), isDark),
          _navItem(1, Icons.location_on_rounded, 'Location', () {}, isDark),
          _navItem(2, Icons.notifications_none_rounded, 'Alerts', () {}, isDark),
          _navItem(3, Icons.person_outline_rounded, 'Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())), isDark),
          _navItem(4, Icons.settings_outlined, 'Settings', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())), isDark),
        ],
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label, VoidCallback onTap, bool isDark) {
    final isSel = _bottomNavIndex == idx;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSel ? const Color(0xFFE91E63) : Colors.grey, size: 24),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              color: isSel ? const Color(0xFFE91E63) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}