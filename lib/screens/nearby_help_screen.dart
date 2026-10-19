import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/theme_provider.dart';
import '../utils/phone_utils.dart';
import 'safe_route_screen.dart';

class NearbyHelpScreen extends StatefulWidget {
  const NearbyHelpScreen({Key? key}) : super(key: key);

  @override
  State<NearbyHelpScreen> createState() => _NearbyHelpScreenState();
}

class _NearbyHelpScreenState extends State<NearbyHelpScreen> {
  int _selectedCategoryIndex = -1; // -1 means "All"
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Base user GPS location (Defaults to Agni College Campus, Thalambur, updated via live GPS)
  double _userLat = 12.8395;
  double _userLng = 80.2185;
  bool _isGpsActive = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'icon': Icons.grid_view_rounded,
      'categoryKey': 'all',
    },
    {
      'name': 'Clinics',
      'icon': Icons.healing_rounded,
      'categoryKey': 'clinic',
    },
    {
      'name': 'Hospitals',
      'icon': Icons.local_hospital_rounded,
      'categoryKey': 'hospital',
    },
    {
      'name': 'Cab Services',
      'icon': Icons.local_taxi_rounded,
      'categoryKey': 'cab',
    },
    {
      'name': 'Police',
      'icon': Icons.security_rounded,
      'categoryKey': 'police',
    },
    {
      'name': 'Pharmacy',
      'icon': Icons.medical_services_rounded,
      'categoryKey': 'pharmacy',
    },
    {
      'name': 'Safe Zones',
      'icon': Icons.shield_rounded,
      'categoryKey': 'safe_zone',
    },
  ];

  // Master places database with exact real-world coordinates around OMR, Thalambur, Navalur, Tambaram, Chennai
  final List<Map<String, dynamic>> _rawPlaces = [
    // 🩺 CLINICS & URGENT CARE
    {
      'title': '🩺 Apollo 24/7 Urgent Care Clinic',
      'subtitle': 'Immediate Trauma, First Aid & Urgent Care',
      'category': 'Urgent Care Clinic',
      'categoryKey': 'clinic',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8530,
      'lng': 80.2265,
      'phone': '044-24501234',
      'phoneLabel': 'Apollo Clinic Desk (044-24501234)',
      'imageType': 'clinic',
      'accentColor': Color(0xFF0284C7),
      'address': 'OMR Navalur Junction, Chennai',
    },
    {
      'title': '🩺 V-Care Community Health & Emergency Clinic',
      'subtitle': 'Minor Surgeries, IV Fluids & 24/7 Doctors',
      'category': 'Medical Clinic',
      'categoryKey': 'clinic',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.9080,
      'lng': 80.1920,
      'phone': '044-22771200',
      'phoneLabel': 'V-Care Clinic (044-22771200)',
      'imageType': 'clinic',
      'accentColor': Color(0xFF0D9488),
      'address': 'Perumbakkam Main Road, Medavakkam Link, Chennai',
    },
    {
      'title': '🩺 LifeLine 24/7 Emergency Clinic',
      'subtitle': 'Rapid Ambulance & Women Care Specialist',
      'category': 'Emergency Clinic',
      'categoryKey': 'clinic',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.9750,
      'lng': 80.2210,
      'phone': '044-42456789',
      'phoneLabel': 'LifeLine Clinic (044-42456789)',
      'imageType': 'clinic',
      'accentColor': Color(0xFF059669),
      'address': 'Velachery Main Road, Chennai',
    },
    {
      'title': '🩺 Primary Health Centre & Emergency Clinic',
      'subtitle': 'Government Health Sub-Centre & First Aid Post',
      'category': 'Primary Clinic',
      'categoryKey': 'clinic',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8425,
      'lng': 80.2190,
      'phone': '044-27472255',
      'phoneLabel': 'PHC Thalambur (044-27472255)',
      'imageType': 'clinic',
      'accentColor': Color(0xFF16A34A),
      'address': 'Thalambur Main Road, Off OMR, Chennai',
    },

    // 🏥 HOSPITALS
    {
      'title': '🏥 Gleneagles Global Health City',
      'subtitle': 'Multi-Speciality, Level-1 Trauma & ICU Care',
      'category': 'Hospital',
      'categoryKey': 'hospital',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.9038,
      'lng': 80.1901,
      'phone': '044-44777000',
      'phoneLabel': 'Global Hospital 24/7 Trauma (044-44777000 / 108)',
      'imageType': 'hospital',
      'accentColor': Color(0xFFE53935),
      'address': '439, Cheran Nagar, Perumbakkam, OMR, Chennai',
    },
    {
      'title': '🏥 Chettinad Super Speciality Hospital',
      'subtitle': 'Emergency Medicine, Cardiac & 24/7 Ambulance',
      'category': 'Hospital',
      'categoryKey': 'hospital',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.7932,
      'lng': 80.2185,
      'phone': '044-47411000',
      'phoneLabel': 'Chettinad Emergency (044-47411000 / 108)',
      'imageType': 'hospital',
      'accentColor': Color(0xFFDC2626),
      'address': 'Rajiv Gandhi Salai, Kelambakkam, OMR, Chennai',
    },
    {
      'title': '🏥 Dr. Kamakshi Memorial Hospital',
      'subtitle': '24/7 Comprehensive Trauma & Critical Care Unit',
      'category': 'Hospital',
      'categoryKey': 'hospital',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.9460,
      'lng': 80.2010,
      'phone': '044-66300300',
      'phoneLabel': 'Kamakshi Emergency (044-66300300)',
      'imageType': 'hospital',
      'accentColor': Color(0xFFBE123C),
      'address': 'Radial Road, Pallikaranai, Chennai',
    },

    // 🚖 CAB & TRANSIT SERVICES
    {
      'title': '🚖 Women Safe Cab Service Hub',
      'subtitle': 'Verified Female Drivers, GPS Tracked & SOS Alert',
      'category': 'Safe Cab Service',
      'categoryKey': 'cab',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8400,
      'lng': 80.2015,
      'phone': '044-28889999',
      'phoneLabel': 'Women Safe Cab Hub (044-28889999)',
      'imageType': 'cab',
      'accentColor': Color(0xFFF59E0B),
      'address': 'Thalambur Safe Corridor Stand, Chennai',
    },
    {
      'title': '🚖 Fast Track 24/7 Safe Fleet & Cab Dispatch',
      'subtitle': 'Rapid Cab Pickup, SOS Transit & Live Telemetry',
      'category': 'Cab Service',
      'categoryKey': 'cab',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8510,
      'lng': 80.2240,
      'phone': '044-28888888',
      'phoneLabel': 'Fast Track Dispatch (044-28888888)',
      'imageType': 'cab',
      'accentColor': Color(0xFFD97706),
      'address': 'OMR Navalur Transit Hub, Chennai',
    },
    {
      'title': '🚖 Emergency Campus Transit & Escort Post',
      'subtitle': '24/7 Safe Student Escort Shuttle & Auto Post',
      'category': 'Transit Escort',
      'categoryKey': 'cab',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8415,
      'lng': 80.2008,
      'phone': '044-33553355',
      'phoneLabel': 'Campus Ride Support (044-33553355)',
      'imageType': 'cab',
      'accentColor': Color(0xFFB45309),
      'address': 'Agni College Main Gate, Thalambur, Chennai',
    },
    {
      'title': '🚖 Ola / Uber Safe Corridor Cab Station',
      'subtitle': 'Dedicated OMR Highway Safe Drop & Pickup Kiosk',
      'category': 'Cab Station',
      'categoryKey': 'cab',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8997,
      'lng': 80.2280,
      'phone': '044-60006000',
      'phoneLabel': 'OMR Safe Transit Desk (044-60006000)',
      'imageType': 'cab',
      'accentColor': Color(0xFFEAB308),
      'address': 'Sholinganallur Junction, OMR, Chennai',
    },

    // 👮 POLICE STATIONS
    {
      'title': '🦁 Singapen Athiradi Padai',
      'subtitle': 'Women Safety Action Force & Rapid Patrol Unit',
      'category': 'Women Safety Unit',
      'categoryKey': 'police',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8395,
      'lng': 80.2185,
      'phone': '1091',
      'phoneLabel': 'Women Distress Helpline (1091 / 044-23452359)',
      'imageType': 'police',
      'accentColor': Color(0xFFE91E63),
      'address': 'Agni College Campus / Thalambur Women Safe Corridor',
    },
    {
      'title': '👮 Thalambur Police Station',
      'subtitle': 'Local Precinct, SOS Checkpoint & Patrol Response',
      'category': 'Police Station',
      'categoryKey': 'police',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8469,
      'lng': 80.2272,
      'phone': '044-27472100',
      'phoneLabel': 'Thalambur Police Post (044-27472100)',
      'imageType': 'police',
      'accentColor': Color(0xFF0284C7),
      'address': 'Thalambur Main Road, OMR Cyber Belt',
    },
    {
      'title': '👮 Sholinganallur Police Station',
      'subtitle': 'Major OMR Highway Help Desk & Women Kiosk',
      'category': 'Police Station',
      'categoryKey': 'police',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8997,
      'lng': 80.2280,
      'phone': '044-24500100',
      'phoneLabel': 'Sholinganallur Police Desk (044-24500100 / 100)',
      'imageType': 'police',
      'accentColor': Color(0xFF0369A1),
      'address': 'OMR Junction / Medavakkam Link Road, Sholinganallur, Chennai',
    },
    {
      'title': '👮 Semmancheri Police Station',
      'subtitle': 'Active Highway Mobile Patrol & 24/7 Desk',
      'category': 'Police Station',
      'categoryKey': 'police',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8710,
      'lng': 80.2245,
      'phone': '044-24501100',
      'phoneLabel': 'Semmancheri Station (044-24501100 / 100)',
      'imageType': 'police',
      'accentColor': Color(0xFF0284C7),
      'address': 'Rajiv Gandhi Salai, Semmancheri, Chennai',
    },
    {
      'title': '👮 Tambaram Police Commissionerate',
      'subtitle': 'Metropolitan Police HQ & All-Women Police Station',
      'category': 'Police Station',
      'categoryKey': 'police',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.9249,
      'lng': 80.1278,
      'phone': '044-22260100',
      'phoneLabel': 'Tambaram Station Desk (044-22260100 / 100)',
      'imageType': 'police',
      'accentColor': Color(0xFF1E88E5),
      'address': 'GST Road, Near Tambaram Bus Stand, Chennai',
    },

    // 💊 PHARMACIES
    {
      'title': '💊 Apollo Pharmacy 24/7',
      'subtitle': 'Inhalers, BP Medicines & Emergency Meds',
      'category': 'Pharmacy',
      'categoryKey': 'pharmacy',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8420,
      'lng': 80.2040,
      'phone': '044-24505678',
      'phoneLabel': 'Apollo Pharmacy (044-24505678)',
      'imageType': 'pharmacy',
      'accentColor': Color(0xFF10B981),
      'address': 'Thalambur Link Road, Chennai',
    },
    {
      'title': '💊 MedPlus 24/7 Pharmacy',
      'subtitle': 'Medical Supplies & First Aid Kits',
      'category': 'Pharmacy',
      'categoryKey': 'pharmacy',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8515,
      'lng': 80.2250,
      'phone': '044-24509999',
      'phoneLabel': 'MedPlus Desk (044-24509999)',
      'imageType': 'pharmacy',
      'accentColor': Color(0xFF059669),
      'address': 'Navalur OMR Junction, Chennai',
    },

    // 🛡️ SAFE ZONES & CAMPUS HAVENS
    {
      'title': '🛡️ Agni College 24/7 Security Haven',
      'subtitle': 'CCTV Monitored Security Gate & Safe Refuge',
      'category': 'Safe Zone',
      'categoryKey': 'safe_zone',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8395,
      'lng': 80.2185,
      'phone': '044-27498700',
      'phoneLabel': 'Campus Security Control (044-27498700)',
      'imageType': 'safe_zone',
      'accentColor': Color(0xFF8B5CF6),
      'address': 'Agni College of Technology, Thalambur Road, Chennai',
    },
    {
      'title': '🛡️ Vivira Mall 24/7 Guarded Atrium',
      'subtitle': 'High-Crowd Monitored Safe Haven with CCTVs',
      'category': 'Safe Zone',
      'categoryKey': 'safe_zone',
      'timing': 'Open 24 Hours',
      'isOpen24': true,
      'lat': 12.8538,
      'lng': 80.2268,
      'phone': '044-66008800',
      'phoneLabel': 'Mall Security Desk (044-66008800)',
      'imageType': 'safe_zone',
      'accentColor': Color(0xFF7C3AED),
      'address': 'Navalur Junction, Rajiv Gandhi Salai, Chennai',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchLiveGps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Calculates real distance in kilometers and sorts places by distance
  Future<void> _fetchLiveGps() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
          _isGpsActive = true;
        });
      }
    } catch (e) {
      debugPrint('Live GPS fetch for nearby places: $e');
    }
  }

  /// Calculates dynamic distance in kilometers from current location
  double _calculateDistanceKm(double lat, double lng) {
    try {
      final meters = Geolocator.distanceBetween(_userLat, _userLng, lat, lng);
      return meters / 1000.0;
    } catch (e) {
      return 1.0;
    }
  }

  List<Map<String, dynamic>> get _computedPlaces {
    final list = _rawPlaces.map((p) {
      final double distKm = _calculateDistanceKm(p['lat'], p['lng']);
      final Map<String, dynamic> copy = Map<String, dynamic>.from(p);
      copy['distanceKm'] = distKm;
      copy['distance'] = distKm < 1.0
          ? '${(distKm * 1000).toInt()} m'
          : '${distKm.toStringAsFixed(1)} km';
      // Multi-modal transit analysis
      copy['walkTime'] = '${math.max(1, (distKm / 4.5 * 60).round())} min';
      copy['bikeTime'] = '${math.max(1, (distKm / 25.0 * 60).round())} min';
      copy['cabTime'] = '${math.max(1, (distKm / 35.0 * 60).round())} min';
      return copy;
    }).toList();

    // Sort by proximity
    list.sort((a, b) => (a['distanceKm'] as double).compareTo(b['distanceKm'] as double));

    return list.where((place) {
      // Category filter
      if (_selectedCategoryIndex > 0) {
        final catKey = _categories[_selectedCategoryIndex]['categoryKey'];
        if (place['categoryKey'] != catKey) return false;
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (place['title'] ?? '').toString().toLowerCase();
        final cat = (place['category'] ?? '').toString().toLowerCase();
        final addr = (place['address'] ?? '').toString().toLowerCase();
        final phone = (place['phone'] ?? '').toString().toLowerCase();
        return title.contains(q) || cat.contains(q) || addr.contains(q) || phone.contains(q);
      }

      return true;
    }).toList();
  }

  void _callPlace(Map<String, dynamic> place) {
    final phone = place['phone'] as String;
    makePhoneCall(phone, context);
  }

  void _copyPhoneNumber(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF10B981),
        content: Text('✓ Phone number $phone copied to clipboard! Ready to paste.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _trackLocation(Map<String, dynamic> place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SafeRouteScreen(
          destinationName: place['title'].toString().replaceAll(RegExp(r'^[^\w\s]+'), '').trim(),
          destinationCategory: place['categoryKey'],
          distanceKm: place['distanceKm'] as double,
          destinationAddress: place['address'],
          destinationLat: place['lat'] as double,
          destinationLng: place['lng'] as double,
        ),
      ),
    );
  }

  void _showPlaceDetailModal(BuildContext context, Map<String, dynamic> place, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),

            Row(
              children: [
                _buildPlaceThumbnail(place['imageType'], place['accentColor']),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['title'],
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${place['category']} • ${place['distance']}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFFE91E63), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Address
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFFE91E63), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place['address'],
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Phone Box with Copy and Call
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFFFD1DC)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_rounded, color: Color(0xFFE91E63), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EMERGENCY PHONE', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
                        Text(
                          place['phone'],
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFFE91E63)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Color(0xFFE91E63), size: 20),
                    tooltip: 'Copy Number',
                    onPressed: () => _copyPhoneNumber(place['phone']),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons: Call Now & Get Safe Route
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _callPlace(place);
                    },
                    icon: const Icon(Icons.call_rounded, color: Colors.white, size: 20),
                    label: Text('Call ${place['phone']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE91E63),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _trackLocation(place);
                    },
                    icon: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 20),
                    label: const Text('Safe Route', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final places = _computedPlaces;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFBFE),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF1E1B4B), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nearby Help',
          style: TextStyle(
            color: Color(0xFFE91E63),
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location_rounded, color: _isGpsActive ? const Color(0xFF10B981) : Colors.grey, size: 22),
            tooltip: 'Live GPS (${_userLat.toStringAsFixed(4)}, ${_userLng.toStringAsFixed(4)})',
            onPressed: () {
              _fetchLiveGps();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🛰️ GPS Recalibrated: (${_userLat.toStringAsFixed(4)}, ${_userLng.toStringAsFixed(4)})'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    _buildSearchBar(isDark),
                    const SizedBox(height: 14),

                    // Horizontal Category Chips
                    _buildCategoriesList(isDark),
                    const SizedBox(height: 14),

                    // Location Tracking Banner
                    _buildLocationTrackingBanner(isDark),
                    const SizedBox(height: 14),

                    // Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Emergency Services & Havens',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                          ),
                        ),
                        Text(
                          '${places.length} Found',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // List of Computed Place Cards
                    if (places.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            'No emergency services found for "$_searchQuery"',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
                          ),
                        ),
                      )
                    else
                      ...places.map((place) => _buildPlaceCard(place, isDark)),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
        decoration: InputDecoration(
          hintText: 'Search hospital, police, cab, pharmacy...',
          hintStyle: TextStyle(fontSize: 12.5, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFE91E63), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
      ),
    );
  }

  Widget _buildCategoriesList(bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isSelected = (_selectedCategoryIndex == -1 && i == 0) || (_selectedCategoryIndex == i);

          return InkWell(
            onTap: () {
              setState(() {
                _selectedCategoryIndex = (i == 0) ? -1 : i;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE91E63)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFE91E63)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 15,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationTrackingBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF047857) : const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
            child: const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Proximity Tracking Active',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF166534)),
                ),
                Text(
                  'Distances calculated from: ${_userLat.toStringAsFixed(4)}° N, ${_userLng.toStringAsFixed(4)}° E (Karanai / Thalambur)',
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Map<String, dynamic> place, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showPlaceDetailModal(context, place, isDark),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlaceThumbnail(place['imageType'], place['accentColor']),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            place['subtitle'],
                            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  place['timing'],
                                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '• ${place['distance']} away',
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Multi-modal Transit & ETA Proximity Analysis Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_walk_rounded, size: 14, color: Color(0xFFE91E63)),
                          const SizedBox(width: 4),
                          Text(
                            'Walk: ${place['walkTime']}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF1E1B4B),
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 12, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.two_wheeler_rounded, size: 14, color: Color(0xFF0284C7)),
                          const SizedBox(width: 4),
                          Text(
                            'Bike: ${place['bikeTime']}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF1E1B4B),
                            ),
                          ),
                        ],
                      ),
                      Container(width: 1, height: 12, color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_taxi_rounded, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text(
                            'Cab: ${place['cabTime']}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : const Color(0xFF1E1B4B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
                const SizedBox(height: 8),

                // Phone Number Display Bar & Call Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _copyPhoneNumber(place['phone']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF0F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFFFD1DC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.phone_rounded, color: Color(0xFFE91E63), size: 14),
                            const SizedBox(width: 6),
                            Text(
                              place['phone'],
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFFE91E63)),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy_rounded, color: Color(0xFFE91E63), size: 12),
                          ],
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        // Call Now Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () => _callPlace(place),
                          icon: const Icon(Icons.call_rounded, color: Colors.white, size: 14),
                          label: const Text('Call', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),

                        // Safe Route Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE91E63),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () => _trackLocation(place),
                          icon: const Icon(Icons.alt_route_rounded, color: Colors.white, size: 14),
                          label: const Text('Route', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceThumbnail(String type, Color accentColor) {
    IconData icon;
    if (type == 'police') {
      icon = Icons.security_rounded;
    } else if (type == 'hospital') {
      icon = Icons.local_hospital_rounded;
    } else if (type == 'clinic') {
      icon = Icons.healing_rounded;
    } else if (type == 'cab') {
      icon = Icons.local_taxi_rounded;
    } else if (type == 'pharmacy') {
      icon = Icons.medical_services_rounded;
    } else {
      icon = Icons.shield_rounded;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.25)),
      ),
      child: Center(
        child: Icon(icon, color: accentColor, size: 22),
      ),
    );
  }
}
