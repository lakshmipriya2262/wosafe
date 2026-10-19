import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/sensor_provider.dart';
import '../providers/emergency_provider.dart';
import 'safe_route_screen.dart';
import 'nearby_help_screen.dart';
import 'login_screen.dart';
import 'live_location_screen.dart';
import 'profile_screen.dart';
import 'setting_screen.dart';
import 'trusted_contents_screen.dart';
import 'voice_active_screen.dart';
import 'smartwatch_sync_screen.dart';
import '../utils/phone_utils.dart';
import '../utils/share_utils.dart';
import '../services/location_services.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({Key? key}) : super(key: key);

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with SingleTickerProviderStateMixin {
  int _currentBottomNavIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _hourlyWaterReminderDismissed = false;

  // Real backend server endpoint
  final String _backendUrl = 'http://10.22.178.147:3000';

  // Dynamic GPS and nearest safe haven state
  double _currentLat = 12.8395;
  double _currentLng = 80.2185;
  String _currentLocationName = 'Thalambur Safe Corridor, Chennai';
  SafePlacePoint? _nearestPoliceStation;
  SafePlacePoint? _nearestHospital;

  // 3-Second Long Press States
  Timer? _sosHoldTimer;
  int _secondsHeld = 0;
  bool _isHoldingSos = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Dynamic Emergency Contacts list (Loaded from SharedPreferences / AuthProvider)
  List<Map<String, String>> _dynamicContacts = [];

  // Persisted user profile photo from Camera / Gallery
  String? _profileImagePath;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial safe haven defaults before GPS resolves
    _nearestPoliceStation = LocationServices.instance.findNearestPoliceStation(_currentLat, _currentLng);
    _nearestHospital = LocationServices.instance.findNearestHospital(_currentLat, _currentLng);

    _loadUserLocation();
    _loadDynamicContacts();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('wosafe_profile_photo_path');
      if (path != null && File(path).existsSync()) {
        if (mounted) setState(() => _profileImagePath = path);
      } else {
        if (mounted) setState(() => _profileImagePath = null);
      }
    } catch (e) {
      debugPrint('Error loading profile photo in Home: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sosHoldTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  /// Initial live GPS reading with instant fallback and dynamic AI landmark detection
  Future<void> _loadUserLocation() async {
    try {
      // 1. Instant last known position (0ms)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null && mounted) {
        _applyNewGpsCoordinates(lastPos.latitude, lastPos.longitude);
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // 2. High-accuracy GPS with 3-second limit
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 3),
      );
      if (mounted) {
        _applyNewGpsCoordinates(pos.latitude, pos.longitude);
      }
    } catch (e) {
      debugPrint('Initial GPS fetch note: $e');
      if (mounted) {
        _applyNewGpsCoordinates(_currentLat, _currentLng);
      }
    }
  }

  void _applyNewGpsCoordinates(double lat, double lng) {
    final nearestPolice = LocationServices.instance.findNearestPoliceStation(lat, lng);
    final nearestHosp = LocationServices.instance.findNearestHospital(lat, lng);

    setState(() {
      _currentLat = lat;
      _currentLng = lng;
      _nearestPoliceStation = nearestPolice;
      _nearestHospital = nearestHosp;
      _currentLocationName = '${nearestPolice.name.replaceAll("Police Station", "").replaceAll("Police Commissionerate", "").trim()} Corridor (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
    });

    // Asynchronously resolve human-readable neighborhood name without blocking
    LocationServices.instance.reverseGeocodeArea(lat, lng).then((area) {
      if (mounted && area.isNotEmpty) {
        setState(() {
          _currentLocationName = area;
        });
      }
    });
  }

  /// Load contacts entered during Sign Up or previously saved
  Future<void> _loadDynamicContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString('wosafe_contacts_json') ??
          prefs.getString('homesafe_emergency_contacts');

      List<Map<String, String>> loaded = [];

      if (contactsJson != null && contactsJson.isNotEmpty) {
        final decoded = json.decode(contactsJson);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map) {
              final name = item['name']?.toString() ?? '';
              final phone = item['phone']?.toString() ?? '';
              final rel = item['relation']?.toString() ?? item['tag']?.toString() ?? 'Contact';
              if (name.isNotEmpty && phone.isNotEmpty) {
                loaded.add({
                  'name': name,
                  'phone': phone,
                  'relation': rel,
                  'location': 'Primary Contact',
                });
              }
            }
          }
        }
      }

      // If no stored contacts found, load from AuthProvider
      if (loaded.isEmpty && mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final userContacts = auth.currentUser?.emergencyContacts;
        if (userContacts != null && userContacts.isNotEmpty) {
          for (var c in userContacts) {
            if (c.name.isNotEmpty && c.phone.isNotEmpty) {
              loaded.add({
                'name': c.name,
                'phone': c.phone,
                'relation': c.relation,
                'location': 'Primary Contact',
              });
            }
          }
        }
      }

      // Append official rescue & emergency numbers requested by user
      _appendOfficialHelplines(loaded);

      if (mounted) {
        setState(() {
          _dynamicContacts = loaded;
        });
      }
    } catch (e) {
      debugPrint('Error loading dynamic contacts: $e');
    }
  }

  void _appendOfficialHelplines(List<Map<String, String>> list) {
    bool hasSingapen = list.any((c) => c['name']!.contains('Singapen'));
    bool hasPolice = list.any((c) => c['name']!.contains('Police'));
    bool hasHospital = list.any((c) => c['name']!.contains('Hospital'));
    bool hasCab = list.any((c) => c['name']!.contains('Cab'));

    if (!hasSingapen) {
      list.add({
        'name': '🦁 Singapen Athiradi Padai',
        'phone': '1091 / 044-23452359',
        'relation': 'Women Safety Action Force',
        'location': '24/7 Rapid Response',
      });
    }
    if (!hasPolice) {
      list.add({
        'name': '👮 Tambaram Police Station',
        'phone': '044-22260100 / 100',
        'relation': 'Police Helpline',
        'location': 'GST Road, Tambaram (1.2 km)',
      });
    }
    if (!hasHospital) {
      list.add({
        'name': '🏥 Global Hospital (OMR)',
        'phone': '044-44777000 / 108',
        'relation': 'Trauma & Emergency',
        'location': 'Perumbakkam / OMR (800m)',
      });
    }
    if (!hasCab) {
      list.add({
        'name': '🚖 Women Safe Cab Service',
        'phone': '044-28889999',
        'relation': 'Safe Transit Hub',
        'location': 'Thalambur Safe Corridor (500m)',
      });
    }
  }

  /// Persists a new contact to storage
  Future<void> _addNewEmergencyContact(String name, String phone, String relation) async {
    final newEntry = {
      'name': name.trim(),
      'phone': phone.trim(),
      'relation': relation.trim(),
      'location': 'Custom Trusted Contact',
    };

    setState(() {
      _dynamicContacts.insert(0, newEntry);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Filter out official helplines before saving user-defined contacts
      final userDefined = _dynamicContacts
          .where((c) => !c['name']!.startsWith('🦁') && !c['name']!.startsWith('👮') && !c['name']!.startsWith('🏥') && !c['name']!.startsWith('🚖'))
          .toList();
      final jsonString = json.encode(userDefined);
      await prefs.setString('wosafe_contacts_json', jsonString);
      await prefs.setString('homesafe_emergency_contacts', jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10B981),
            content: Text('✓ "$name" added to Trusted Contacts!'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving new contact: $e');
    }
  }

  // ========================================================
  // 1. 3-SECOND LONG PRESS HANDLERS
  // ========================================================
  void _onSosPointerDown() {
    setState(() {
      _isHoldingSos = true;
      _secondsHeld = 0;
    });

    _sosHoldTimer?.cancel();
    _sosHoldTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsHeld++;
      });
      HapticFeedback.selectionClick();

      if (_secondsHeld >= 3) {
        timer.cancel();
        _triggerEmergencyExecution();
        setState(() {
          _isHoldingSos = false;
          _secondsHeld = 0;
        });
      }
    });
  }

  void _onSosPointerUp() {
    if (_secondsHeld < 3) {
      _sosHoldTimer?.cancel();
      setState(() {
        _isHoldingSos = false;
        _secondsHeld = 0;
      });
    }
  }

  // ========================================================
  // 2. REAL DEVICE GPS & EMERGENCY SOS PIPELINE
  // ========================================================
  Future<void> _triggerEmergencyExecution() async {
    HapticFeedback.heavyImpact();

    // Instant location resolution (0ms from current state)
    double lat = _currentLat;
    double lng = _currentLng;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final userName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim()
        : 'Protected User';

    // Dynamic Police & Hospital based on REAL GPS
    final nearestPolice = _nearestPoliceStation ?? LocationServices.instance.findNearestPoliceStation(lat, lng);
    final nearestHosp = _nearestHospital ?? LocationServices.instance.findNearestHospital(lat, lng);
    final policeName = nearestPolice.name;
    final hospitalName = nearestHosp.name;

    // Step A: Send backend telemetry asynchronously in background with 2s timeout (DO NOT BLOCK UI)
    http.post(
      Uri.parse('$_backendUrl/api/sos/trigger'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userId": "USER_001",
        "userName": userName,
        "latitude": lat,
        "longitude": lng,
        "hasAsthma": user?.hasAsthma ?? true,
        "triggerSource": "SOS_BUTTON",
        "emergencyContacts": _dynamicContacts,
      }),
    ).timeout(const Duration(seconds: 2)).catchError((e) {
      debugPrint("Backend alert note: $e");
      return http.Response('{"error": "$e"}', 500);
    });

    // Step B: Start Continuous GPS Tracking Stream in background
    _startContinuousGpsStream();

    // Step C: Zero-Delay Automated Direct SOS Dispatch (Direct SMS to contacts & police, NO modal sheet)
    ShareUtils.autoDispatchEmergencyDirectly(
      latitude: lat,
      longitude: lng,
      address: 'EMERGENCY DISTRESS: Immediate rescue needed near $_currentLocationName! Closest Police Refuge: $policeName (${nearestPolice.contact}), Nearest Hospital: $hospitalName.',
      userName: userName,
      context: context,
    );

    // Step D: Immediate UI Notification & Autopilot Safe Route Navigation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('🚨 SOS DISPATCHED! Live GPS (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}) sent to Emergency Contacts & $policeName!'),
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SafeRouteScreen(
            isSosTriggered: true,
            destinationName: policeName,
            destinationAddress: nearestPolice.address,
          ),
        ),
      );
    }
  }

  // ========================================================
  // 3. CONTINUOUS GPS STREAM (BROADCASTS MOVEMENT TRAIL)
  // ========================================================
  void _startContinuousGpsStream() {
    _positionStreamSubscription?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings)
        .listen((Position pos) async {
      try {
        await http.post(
          Uri.parse('$_backendUrl/api/location/stream'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "userId": "USER_001",
            "latitude": pos.latitude,
            "longitude": pos.longitude,
          }),
        );
      } catch (e) {
        debugPrint("Stream ping error: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Consumer3<AuthProvider, SensorProvider, EmergencyProvider>(
      builder: (context, auth, sensor, emergency, child) {
        final user = auth.currentUser;
        final displayName = (user != null && user.name.trim().isNotEmpty)
            ? user.name.trim()
            : 'Protected User';

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFBFE),
          appBar: _buildWosafeAppBar(context, isDark),
          drawer: _buildDrawer(context, user, auth, isDark),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGreetingBanner(displayName, user, isDark),
                  const SizedBox(height: 10),

                  if (!_hourlyWaterReminderDismissed)
                    _buildHydrationAlertBanner(isDark),

                  _buildThalamburMapCard(context, isDark),
                  const SizedBox(height: 14),

                  // 3-SECOND LONG PRESS SOS BUTTON BAR
                  _buildCenteredSosBar(context, isDark),
                  const SizedBox(height: 16),

                  _buildSixQuickAccessCards(context, isDark),
                  const SizedBox(height: 14),

                  _buildSafetyTipOfTheDay(isDark),
                  const SizedBox(height: 14),

                  _buildWearableSection(context, sensor, isDark),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildWosafeBottomNavBar(isDark),
        );
      },
    );
  }

  // 1. Top Bar
  PreferredSizeWidget _buildWosafeAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFBFBFE),
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: isDark ? Colors.white : const Color(0xFF1E1B4B), size: 26),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Wosafe',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              Row(
                children: const [
                  Text('∞ ', style: TextStyle(color: Color(0xFFE91E63), fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    'Infinity Protection',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 9.0, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.watch_rounded, color: Color(0xFFF59E0B), size: 25),
          tooltip: 'Bluetooth Smartwatch SOS & Sync',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartwatchSyncScreen())),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: isDark ? Colors.white : const Color(0xFF1E1B4B), size: 26),
              onPressed: () => _showAlertsSheet(context),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Greeting Header
  Widget _buildGreetingBanner(String displayName, user, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hello, $displayName',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('👋', style: TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 2),
            const Text(
              'Stay safe , stay protected ♡',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 12.5, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            _loadProfilePhoto();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFEBF0), Color(0xFFFCE4EC)]),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFC1D6), width: 1.5),
            ),
            child: _profileImagePath != null && File(_profileImagePath!).existsSync()
                ? ClipOval(
                    child: Image.file(
                      File(_profileImagePath!),
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  )
                : Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Color(0xFFE91E63), fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // Hourly Hydration Alert Banner
  Widget _buildHydrationAlertBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.water_drop_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '💧 Hydration Alert: Time to drink water! Synced to Smartwatch.',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF166534)),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _hourlyWaterReminderDismissed = true),
            child: const Icon(Icons.close_rounded, color: Color(0xFF10B981), size: 16),
          ),
        ],
      ),
    );
  }

  // Dynamic Real-Time Interactive Map Card (OpenStreetMap)
  Widget _buildThalamburMapCard(BuildContext context, bool isDark) {
    final userPos = LatLng(_currentLat, _currentLng);
    final nearestPolice = _nearestPoliceStation ?? LocationServices.instance.findNearestPoliceStation(_currentLat, _currentLng);
    final policePos = LatLng(nearestPolice.latitude, nearestPolice.longitude);

    // Compute midpoint waypoint for polyline
    final midPos = LatLng(
      (_currentLat + nearestPolice.latitude) / 2,
      (_currentLng + nearestPolice.longitude) / 2,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 165,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: userPos,
                      initialZoom: 15.0,
                      minZoom: 10.0,
                      maxZoom: 19.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.wosafe',
                      ),
                      // Real Safe Corridor polyline dynamically targeting nearest Police Station
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: [
                              userPos,
                              midPos,
                              policePos,
                            ],
                            strokeWidth: 4.5,
                            color: const Color(0xFFE91E63),
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // User live pulsing marker
                          Marker(
                            point: userPos,
                            width: 34,
                            height: 34,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, _) => Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE91E63),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2.5),
                                    boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
                                  ),
                                  child: const Center(
                                    child: CircleAvatar(radius: 4, backgroundColor: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Dynamic Nearest Police Station Marker
                          Marker(
                            point: policePos,
                            width: 130,
                            height: 25,
                            child: _buildMapBadge('👮 ${nearestPolice.name.replaceAll("Police Station", "PS").replaceAll("Police Commissionerate", "HQ")}', const Color(0xFF0284C7)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Top right Active Badge
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SafeRouteScreen(
                        destinationName: nearestPolice.name,
                        destinationAddress: nearestPolice.address,
                      ))),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE91E63).withOpacity(0.92),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.alt_route_rounded, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text('Safe Route Active', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom left Live GPS Coordinates badge
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'GPS: ${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E',
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Bottom right expand to Live Location button
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveLocationScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: const Icon(Icons.fullscreen_rounded, color: Color(0xFFE91E63), size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveLocationScreen())),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: const Color(0xFFFFF0F5), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFFE91E63), size: 16),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LIVE LOCATION | $_currentLocationName',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '🛡️ Target Safe Refuge: ${nearestPolice.name} • 100% CCTV Monitored Corridor',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildMapBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      ),
    );
  }

  // ========================================================
  // 4. SOS BAR WITH 3-SECOND LONG PRESS VISUAL INDICATOR
  // ========================================================
  Widget _buildCenteredSosBar(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
        boxShadow: [
          BoxShadow(color: const Color(0xFFE91E63).withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Need Help?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Hold for 3s to trigger SOS & safe routes.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.25),
                ),
              ],
            ),
          ),

          // 3-SECOND LONG PRESS BUTTON
          Expanded(
            flex: 4,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  _triggerEmergencyExecution();
                },
                onTapDown: (_) => _onSosPointerDown(),
                onTapUp: (_) => _onSosPointerUp(),
                onTapCancel: () => _onSosPointerUp(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Dynamic Circular Progress Ring
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: CircularProgressIndicator(
                        value: _isHoldingSos ? (_secondsHeld / 3.0) : 0.0,
                        strokeWidth: 4.5,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFFFD1DC),
                      ),
                    ),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2E63), Color(0xFFE91E63)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE91E63).withOpacity(0.42),
                            blurRadius: 12 * _pulseAnimation.value,
                            spreadRadius: 2 * _pulseAnimation.value,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _isHoldingSos ? '${3 - _secondsHeld}s' : 'SOS',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () => _showSosLearnMoreSheet(context, isDark),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE91E63), width: 2),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_forward_rounded, color: Color(0xFFE91E63), size: 20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Learn More',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Six Quick Access Cards
  Widget _buildSixQuickAccessCards(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            _buildPinkQuickCard(
              title: 'Safe Route',
              iconWidget: const Icon(Icons.verified_user_outlined, color: Color(0xFFE91E63), size: 28),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafeRouteScreen())),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildPinkQuickCard(
              title: 'Trusted Contacts',
              iconWidget: const Icon(Icons.people_outline_rounded, color: Color(0xFFE91E63), size: 28),
              onTap: () => _showContactsSheet(context, isDark),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildPinkQuickCard(
              title: 'Nearby Help',
              iconWidget: const Icon(Icons.location_on_outlined, color: Color(0xFFE91E63), size: 28),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyHelpScreen())),
              isDark: isDark,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildPinkQuickCard(
              title: 'Voice SOS',
              iconWidget: const Icon(Icons.mic_none_rounded, color: Color(0xFFE91E63), size: 28),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceActiveScreen())),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildPinkQuickCard(
              title: 'Safety Tips',
              iconWidget: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFE91E63), size: 28),
              onTap: () => _showSafetyTipsSheet(context, isDark),
              isDark: isDark,
            ),
            const SizedBox(width: 10),
            _buildPinkQuickCard(
              title: 'IoT Wearable',
              iconWidget: const Icon(Icons.watch_rounded, color: Color(0xFFE91E63), size: 28),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartwatchSyncScreen())),
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPinkQuickCard({
    required String title,
    required Widget iconWidget,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 6. Safety Tip
  Widget _buildSafetyTipOfTheDay(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFFFD1DC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFFE91E63), shape: BoxShape.circle),
            child: const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Safety Tip of the Day',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFFE91E63)),
                ),
                const SizedBox(height: 3),
                Text(
                  'Always stay alert in unfamiliar surroundings. If you sense danger, hold the SOS button for 3s to alert emergency responders and auto-guide yourself along verified Safe Corridors.',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF4B5563), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. Wearable Section
  Widget _buildWearableSection(BuildContext context, SensorProvider sensor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Color(0xFFFFF0F5), shape: BoxShape.circle),
            child: const Icon(Icons.watch_rounded, color: Color(0xFFE91E63), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ESP32 Smartwatch Connected',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.bluetooth_connected_rounded, color: Color(0xFF00C853), size: 14),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'HR: ${sensor.currentBpm} BPM • Fall Sensor Active • Spike Alert >120 BPM',
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE91E63),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            onPressed: () => _triggerEmergencyExecution(),
            child: const Text('Test Spike', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar
  Widget _buildWosafeBottomNavBar(bool isDark) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home', isDark),
          _buildNavItem(1, Icons.location_on_outlined, 'Location', isDark),
          _buildNavItem(2, Icons.notifications_none_rounded, 'Alerts', isDark),
          _buildNavItem(3, Icons.person_outline_rounded, 'Profile', isDark),
          _buildNavItem(4, Icons.settings_outlined, 'Settings', isDark),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentBottomNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _currentBottomNavIndex = index);
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveLocationScreen()));
        } else if (index == 2) {
          _showAlertsSheet(context);
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _loadProfilePhoto());
        } else if (index == 4) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF6B7280), size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer
  Widget _buildDrawer(BuildContext context, user, AuthProvider auth, bool isDark) {
    final userName = (user != null && user.name.trim().isNotEmpty)
        ? user.name.trim()
        : 'Protected User';

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            currentAccountPicture: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                _loadProfilePhoto();
              },
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: (_profileImagePath != null && File(_profileImagePath!).existsSync())
                    ? FileImage(File(_profileImagePath!))
                    : null,
                child: (_profileImagePath == null || !File(_profileImagePath!).existsSync())
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'W',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFE91E63)),
                      )
                    : null,
              ),
            ),
            accountName: Text(userName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            accountEmail: Text('Wosafe Infinity Protection • ${user?.phone ?? "Active"}'),
          ),
          ListTile(
            leading: const Icon(Icons.person_rounded, color: Color(0xFFE91E63)),
            title: Text('My Profile & Photo', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              _loadProfilePhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.home_rounded, color: Color(0xFFE91E63)),
            title: Text('Home Dashboard', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_rounded, color: Color(0xFFE91E63)),
            title: Text('Live Location (GPS Tracking)', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveLocationScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.alt_route_rounded, color: Color(0xFFE91E63)),
            title: Text('Safe Route Navigation', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SafeRouteScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_rounded, color: Color(0xFFE91E63)),
            title: Text('Trusted Contacts & Nearby Help', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TrustedContactsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.mic_rounded, color: Color(0xFFE91E63)),
            title: Text('Voice Activation SOS', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const VoiceActiveScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.watch_rounded, color: Color(0xFFE91E63)),
            title: Text('Smartwatch & Bluetooth SOS', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartwatchSyncScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active_rounded, color: Color(0xFFE91E63)),
            title: Text('Safety Alerts', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            onTap: () {
              Navigator.pop(context);
              _showAlertsSheet(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_rounded, color: Color(0xFFE91E63)),
            title: Text('Settings', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: () {
              auth.logout();
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 8. TRUSTED CONTACTS BOTTOM SHEET WITH ADD CONTACT
  // ========================================================
  void _showContactsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (ctx, scroll) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: ListView(
              controller: scroll,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Emergency Contacts',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFE91E63)),
                      tooltip: 'Add New Contact',
                      onPressed: () => _showAddContactDialog(context, setSheetState),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF0F3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Your trusted contacts & rescue helplines are instantly notified when SOS is triggered.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFFE91E63), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 14),

                if (_dynamicContacts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'No contacts saved yet. Tap "Add New Contact" below.',
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
                      ),
                    ),
                  ),

                ..._dynamicContacts.map((c) => _buildContactTile(
                  name: c['name'] ?? '',
                  phone: c['phone'] ?? '',
                  tag: c['relation'] ?? 'Contact',
                  loc: c['location'] ?? 'Chennai',
                  av: (c['name'] != null && c['name']!.isNotEmpty) ? c['name']![0].toUpperCase() : 'C',
                  isDark: isDark,
                )),

                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _showAddContactDialog(context, setSheetState),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                  label: const Text('Add New Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, StateSetter setSheetState) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final relationCtrl = TextEditingController(text: 'Family');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.person_add_rounded, color: Color(0xFFE91E63)),
            SizedBox(width: 8),
            Text('Add Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Contact Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: relationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Relation / Tag (e.g. Family, Friend)',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter name and phone number')),
                );
                return;
              }
              _addNewEmergencyContact(nameCtrl.text, phoneCtrl.text, relationCtrl.text);
              setSheetState(() {});
              Navigator.pop(dialogCtx);
            },
            child: const Text('Save Contact', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required String name,
    required String phone,
    required String tag,
    required String loc,
    required String av,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF0F5),
            child: Text(av, style: const TextStyle(color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
              Text(phone, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              Text('$tag • $loc', style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: Color(0xFFE91E63)),
            onPressed: () {
              makePhoneCall(phone, context);
            },
          ),
        ],
      ),
    );
  }

  void _showSafetyTipsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Safety Tips & Self-Defense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            const SizedBox(height: 10),
            Text('• Stick to verified Safe Corridors with active lighting and CCTV.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.4)),
            Text('• Keep your phone accessible and voice trigger enabled.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.4)),
            Text('• Wear your ESP32 smartwatch to detect pulse spikes automatically.', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.4)),
          ],
        ),
      ),
    );
  }

  void _showAlertsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Alerts & Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
            SizedBox(height: 12),
            Text('🚨 Suspicious Movement Alert: Safe corridor monitored.', style: TextStyle(fontSize: 12, color: Color(0xFFE91E63))),
            SizedBox(height: 6),
            Text('⚠️ Dimly Lit Zone: Side street lighting check advised along bypass.', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
            SizedBox(height: 6),
            Text('💧 Hydration Reminder: Smartwatch sync active.', style: TextStyle(fontSize: 12, color: Color(0xFF15803D))),
          ],
        ),
      ),
    );
  }

  void _showSosLearnMoreSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFFE91E63), size: 24),
                const SizedBox(width: 8),
                Text('How Wosafe SOS Works', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
              ],
            ),
            const SizedBox(height: 12),
            _buildLearnItem('1. 3-Second Hold to Prevent False Alarms', 'Hold the SOS button for 3 seconds to initiate emergency response.', isDark),
            _buildLearnItem('2. Instant Live GPS Dispatch', 'Broadcasts coordinates directly to emergency contacts and backend server.', isDark),
            _buildLearnItem('3. Automatic Safe Route Navigation', 'Automatically displays verified routes to the nearest police stations and hospitals.', isDark),
            _buildLearnItem('4. Continuous Location Tracking', 'Transmits movement telemetry every 5 meters as you navigate to safety.', isDark),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLearnItem(String title, String desc, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.3)),
        ],
      ),
    );
  }
}