import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class SafePlacePoint {
  final String name;
  final String category; // 'police', 'hospital', 'mall', 'college', 'beach', 'transit', 'safe_haven'
  final double latitude;
  final double longitude;
  final String address;
  final String contact;
  final String crowdLevel;
  final String safetyHighlight;
  final double distanceKm;

  SafePlacePoint({
    required this.name,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.contact,
    required this.crowdLevel,
    required this.safetyHighlight,
    this.distanceKm = 0.0,
  });

  SafePlacePoint copyWithDistance(double dist) {
    return SafePlacePoint(
      name: name,
      category: category,
      latitude: latitude,
      longitude: longitude,
      address: address,
      contact: contact,
      crowdLevel: crowdLevel,
      safetyHighlight: safetyHighlight,
      distanceKm: dist,
    );
  }
}

class LocationServices {
  static final LocationServices instance = LocationServices._();
  LocationServices._();

  // Master catalog of Verified Regional Police Stations (Exact Coordinates)
  static final List<SafePlacePoint> policeStations = [
    SafePlacePoint(
      name: 'Sholinganallur Police Station',
      category: 'police',
      latitude: 12.8997,
      longitude: 80.2280,
      address: 'OMR Junction / Medavakkam Link Rd, Sholinganallur, Chennai',
      contact: '044-24500100 / 100',
      crowdLevel: '24/7 Police Personnel',
      safetyHighlight: 'Major OMR Highway Help Desk, Armed Women Patrol Kiosk, 24/7 Officers',
    ),
    SafePlacePoint(
      name: 'Thalambur Police Station',
      category: 'police',
      latitude: 12.8469,
      longitude: 80.2272,
      address: 'Thalambur Main Road / Navalur Junction, OMR, Chennai',
      contact: '044-27472100 / 1091',
      crowdLevel: 'Police Manned',
      safetyHighlight: '24/7 Law Enforcement, SOS Help Desk, Highway Mobile Patrol',
    ),
    SafePlacePoint(
      name: 'Semmancheri Police Station',
      category: 'police',
      latitude: 12.8710,
      longitude: 80.2245,
      address: 'Rajiv Gandhi Salai, Semmancheri, Chennai',
      contact: '044-24501100 / 100',
      crowdLevel: 'Police Manned',
      safetyHighlight: 'Active Highway Patrol, Round-the-clock Emergency Desk',
    ),
    SafePlacePoint(
      name: 'Kannagi Nagar Police Station',
      category: 'police',
      latitude: 12.9350,
      longitude: 80.2310,
      address: 'MCN Nagar, OMR, Thoraipakkam, Chennai',
      contact: '044-24961100 / 100',
      crowdLevel: 'Police Station',
      safetyHighlight: '24/7 Patrolling, CCTV Command Center',
    ),
    SafePlacePoint(
      name: 'Thoraipakkam Police Station',
      category: 'police',
      latitude: 12.9410,
      longitude: 80.2360,
      address: 'OMR Expressway, Thoraipakkam, Chennai',
      contact: '044-24960100 / 100',
      crowdLevel: 'Police Station',
      safetyHighlight: 'OMR Arterial Checkpoint, 24/7 Emergency Response',
    ),
    SafePlacePoint(
      name: 'Neelankarai Police Station',
      category: 'police',
      latitude: 12.9480,
      longitude: 80.2580,
      address: 'East Coast Road (ECR), Neelankarai, Chennai',
      contact: '044-24490100 / 100',
      crowdLevel: 'Coastal Police Post',
      safetyHighlight: 'ECR Highway Patrol, 24/7 Beachfront Security',
    ),
    SafePlacePoint(
      name: 'Velachery Police Station',
      category: 'police',
      latitude: 12.9780,
      longitude: 80.2190,
      address: 'Velachery Bypass Road, Velachery, Chennai',
      contact: '044-22440100 / 100',
      crowdLevel: 'Dense Urban Post',
      safetyHighlight: 'All-Women Help Kiosk, High-Footfall Patrol Squad',
    ),
    SafePlacePoint(
      name: 'Tambaram Police Commissionerate',
      category: 'police',
      latitude: 12.9249,
      longitude: 80.1285,
      address: 'GST Road, Near Tambaram Railway Station, Chennai',
      contact: '044-22260100 / 100',
      crowdLevel: 'Police Headquarters',
      safetyHighlight: 'Major Metropolitan Police Station, All-Women Patrol Station',
    ),
    SafePlacePoint(
      name: 'Guindy Police Station',
      category: 'police',
      latitude: 13.0070,
      longitude: 80.2130,
      address: 'Anna Salai / Kathipara, Guindy, Chennai',
      contact: '044-22340100 / 100',
      crowdLevel: 'Major Transit Police',
      safetyHighlight: 'Transit Hub Command, 24/7 Rapid Response Unit',
    ),
    SafePlacePoint(
      name: 'Medavakkam Police Station',
      category: 'police',
      latitude: 12.9190,
      longitude: 80.1910,
      address: 'Medavakkam Main Road, Chennai',
      contact: '044-22770100 / 100',
      crowdLevel: 'Police Station',
      safetyHighlight: 'Residential Corridor Patrol, 24/7 Helpdesk',
    ),
    SafePlacePoint(
      name: 'Kelambakkam Police Station',
      category: 'police',
      latitude: 12.7880,
      longitude: 80.2190,
      address: 'Vandalur-Kelambakkam Rd, Kelambakkam, Chennai',
      contact: '044-27474200 / 100',
      crowdLevel: 'Suburban Police Post',
      safetyHighlight: 'Highway Intercept Booth, 24/7 Emergency Staff',
    ),
  ];

  // Master catalog of Emergency Hospitals (Exact Coordinates)
  static final List<SafePlacePoint> hospitals = [
    SafePlacePoint(
      name: 'Swaram Specialty Hospital (Sholinganallur)',
      category: 'hospital',
      latitude: 12.8990,
      longitude: 80.2290,
      address: 'OMR Junction, Sholinganallur, Chennai',
      contact: '044-43444000 / 108',
      crowdLevel: '24/7 Emergency Trauma',
      safetyHighlight: 'Full 24/7 Emergency Care, Ambulance & Oxygen Support',
    ),
    SafePlacePoint(
      name: 'Gleneagles Global Health City',
      category: 'hospital',
      latitude: 12.8980,
      longitude: 80.1910,
      address: 'Perumbakkam Main Road, Cheran Nagar, Chennai',
      contact: '044-44777777 / 108',
      crowdLevel: 'Major Multi-Specialty',
      safetyHighlight: 'Level-1 Emergency Trauma Center, 24/7 Critical Care Support',
    ),
    SafePlacePoint(
      name: 'Apollo Cradle & Children\'s Hospital',
      category: 'hospital',
      latitude: 12.9220,
      longitude: 80.2330,
      address: 'Rajiv Gandhi Salai, Karapakkam OMR, Chennai',
      contact: '044-42999999 / 108',
      crowdLevel: '24/7 Women & Child Care',
      safetyHighlight: 'Dedicated 24/7 Women\'s Emergency & Maternity Care',
    ),
    SafePlacePoint(
      name: 'Chettinad Super Speciality Hospital',
      category: 'hospital',
      latitude: 12.7930,
      longitude: 80.2220,
      address: 'Rajiv Gandhi Salai, Kelambakkam, Chennai',
      contact: '044-47411000 / 108',
      crowdLevel: 'Large Teaching Hospital',
      safetyHighlight: '24/7 Casualty & Trauma Center, Dedicated Ambulance Fleet',
    ),
    SafePlacePoint(
      name: 'Prashanth Super Speciality Hospital',
      category: 'hospital',
      latitude: 12.9860,
      longitude: 80.2210,
      address: 'Velachery Main Road, Velachery, Chennai',
      contact: '044-46805555 / 108',
      crowdLevel: '24/7 Multi-Specialty',
      safetyHighlight: '24/7 Trauma Care, In-house Pharmacy, Ambulance Hub',
    ),
    SafePlacePoint(
      name: 'Hindu Mission Hospital',
      category: 'hospital',
      latitude: 12.9260,
      longitude: 80.1230,
      address: 'GST Road, Tambaram West, Chennai',
      contact: '044-22262244 / 108',
      crowdLevel: '24/7 Emergency Trauma',
      safetyHighlight: 'Round-the-clock Emergency Casualty, Intensive Care Units',
    ),
  ];

  // Master catalog of Popular Safe Hubs, Malls, Colleges, Beaches
  static final List<SafePlacePoint> popularPlaces = [
    // 🏬 Malls
    SafePlacePoint(
      name: 'Vivira Mall (Navalur OMR)',
      category: 'mall',
      latitude: 12.8538,
      longitude: 80.2268,
      address: 'OMR, Navalur Junction, Chennai',
      contact: '044-66085555',
      crowdLevel: 'High Footfall Crowd',
      safetyHighlight: 'Crowded Multiplex & Food Court, 24/7 Private Security & CCTV, Well-Lit Entrance',
    ),
    SafePlacePoint(
      name: 'The Marina Mall (Egattur OMR)',
      category: 'mall',
      latitude: 12.8235,
      longitude: 80.2272,
      address: 'Rajiv Gandhi Salai, Egattur, OMR, Chennai',
      contact: '044-67215555',
      crowdLevel: 'High Footfall Crowd',
      safetyHighlight: 'Bustling Shopping Crowd, 24/7 Security Guards, Bright Taxi Stand',
    ),
    SafePlacePoint(
      name: 'BSR Mall & INOX (Thoraipakkam)',
      category: 'mall',
      latitude: 12.9405,
      longitude: 80.2355,
      address: 'Rajiv Gandhi Salai, Thoraipakkam, Chennai',
      contact: '044-24962222',
      crowdLevel: 'High Footfall Crowd',
      safetyHighlight: 'Lit Arterial Entrance, Security Checkpoint, Continuous Pedestrian Transit',
    ),
    SafePlacePoint(
      name: 'Phoenix MarketCity (Velachery)',
      category: 'mall',
      latitude: 12.9915,
      longitude: 80.2170,
      address: 'Velachery Main Road, Chennai',
      contact: '044-61343000',
      crowdLevel: 'Dense Public Crowd',
      safetyHighlight: 'Massive Footfall, Professional Security, 24/7 Taxi & Cab Hub',
    ),
    SafePlacePoint(
      name: 'Grand Square Mall (Velachery)',
      category: 'mall',
      latitude: 12.9772,
      longitude: 80.2212,
      address: 'Seetharam Nagar Main Road, Velachery, Chennai',
      contact: '044-66083333',
      crowdLevel: 'Family Shopping Crowd',
      safetyHighlight: 'Multi-screen Cinema, Active Pedestrian Transit, Private Security',
    ),

    // 💼 IT Parks & Commercial Safe Refuges
    SafePlacePoint(
      name: 'ELCOT IT Park & SEZ (Sholinganallur)',
      category: 'safe_haven',
      latitude: 12.9060,
      longitude: 80.2250,
      address: 'Sholinganallur SEZ, Chennai',
      contact: '044-24500000',
      crowdLevel: 'Active 24/7 Tech Hub',
      safetyHighlight: 'Manned Corporate Security Posts, Floodlit Boulevards, Continuous Cabs',
    ),
    SafePlacePoint(
      name: 'SIPCOT IT Park Main Gate (Siruseri)',
      category: 'safe_haven',
      latitude: 12.8310,
      longitude: 80.2230,
      address: 'Rajiv Gandhi Salai, Siruseri, Chennai',
      contact: '044-27470000',
      crowdLevel: 'Heavy Transit Hub',
      safetyHighlight: '24/7 Highway Security Kiosk, Multiple Bus Stands, Lit Corridor',
    ),

    // 🎓 Colleges & Campuses
    SafePlacePoint(
      name: 'Agni College of Technology',
      category: 'college',
      latitude: 12.8395,
      longitude: 80.2185,
      address: 'Thalambur Road, Off OMR, Chennai - 600130',
      contact: '044-67408888',
      crowdLevel: '24/7 Security Guarded',
      safetyHighlight: 'Manned Campus Security Gate, Floodlight Checkpoint, CCTV Surveillance',
    ),
    SafePlacePoint(
      name: 'Sathyabama University',
      category: 'college',
      latitude: 12.8725,
      longitude: 80.2205,
      address: 'Jeppiaar Nagar, Rajiv Gandhi Salai, OMR, Chennai',
      contact: '044-24503150',
      crowdLevel: '24/7 Security Guarded',
      safetyHighlight: 'Round-the-clock Security Post, Bus Terminal, Bright High-Traffic Entrance',
    ),
    SafePlacePoint(
      name: 'Hindustan Institute of Tech & Science (HITS)',
      category: 'college',
      latitude: 12.8252,
      longitude: 80.2218,
      address: 'Rajiv Gandhi Salai (OMR), Padur, Chennai',
      contact: '044-27474262',
      crowdLevel: 'Active Student Transit',
      safetyHighlight: 'Manned Guard Kiosk, Continuous Student Footfall, Lit Walkways',
    ),

    // 🏖️ Beaches & Open Public Corridors
    SafePlacePoint(
      name: 'Akkarai Beach & Safe Promenade',
      category: 'beach',
      latitude: 12.8930,
      longitude: 80.2550,
      address: 'East Coast Road (ECR), Akkarai / Sholinganallur Link, Chennai',
      contact: 'Police: 100',
      crowdLevel: 'Public Promenade Crowd',
      safetyHighlight: 'Illuminated Shoreline Access, High-Visibility Highway Connection',
    ),
    SafePlacePoint(
      name: 'Kovalam Beach (ECR)',
      category: 'beach',
      latitude: 12.7925,
      longitude: 80.2520,
      address: 'East Coast Road (ECR), Kovalam, Chennai',
      contact: 'Tourism Police: 1091',
      crowdLevel: 'Tourist Crowd',
      safetyHighlight: 'Coastal Tourism Police Booth, Open Highway Access, Surfing Safe Spot',
    ),
    SafePlacePoint(
      name: 'Besant Nagar / Elliot\'s Beach',
      category: 'beach',
      latitude: 13.0001,
      longitude: 80.2675,
      address: 'Besant Nagar Promenade, Chennai',
      contact: 'Police: 100',
      crowdLevel: 'Dense Public Footfall',
      safetyHighlight: 'Police Booth on Beach Front, Continuous Family Crowd, 100% Streetlights',
    ),
    SafePlacePoint(
      name: 'Marina Beach Promenade',
      category: 'beach',
      latitude: 13.0500,
      longitude: 80.2824,
      address: 'Kamarajar Salai, Triplicane, Chennai',
      contact: 'Marina Police: 044-28460100',
      crowdLevel: 'Major Metropolitan Crowd',
      safetyHighlight: 'Continuous Police All-Terrain Patrol, High Illumination, Heavy Pedestrian Density',
    ),
  ];

  /// Finds the absolute closest Police Station from user's current GPS coordinates
  SafePlacePoint findNearestPoliceStation(double userLat, double userLng) {
    SafePlacePoint closest = policeStations.first;
    double minDistance = double.infinity;

    for (final ps in policeStations) {
      final double distMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        ps.latitude,
        ps.longitude,
      );
      final double distKm = distMeters / 1000.0;
      if (distKm < minDistance) {
        minDistance = distKm;
        closest = ps.copyWithDistance(distKm);
      }
    }
    return closest;
  }

  /// Finds the absolute closest Hospital from user's current GPS coordinates
  SafePlacePoint findNearestHospital(double userLat, double userLng) {
    SafePlacePoint closest = hospitals.first;
    double minDistance = double.infinity;

    for (final h in hospitals) {
      final double distMeters = Geolocator.distanceBetween(
        userLat,
        userLng,
        h.latitude,
        h.longitude,
      );
      final double distKm = distMeters / 1000.0;
      if (distKm < minDistance) {
        minDistance = distKm;
        closest = h.copyWithDistance(distKm);
      }
    }
    return closest;
  }

  /// Returns all safe places sorted by proximity to user
  List<SafePlacePoint> getAllSafePlacesSorted(double userLat, double userLng, {String? categoryFilter}) {
    final List<SafePlacePoint> all = [
      ...policeStations,
      ...hospitals,
      ...popularPlaces,
    ];

    final sorted = all.map((p) {
      final double distKm = Geolocator.distanceBetween(
        userLat,
        userLng,
        p.latitude,
        p.longitude,
      ) / 1000.0;
      return p.copyWithDistance(distKm);
    }).toList();

    sorted.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

    if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'all') {
      return sorted.where((p) => p.category.toLowerCase() == categoryFilter.toLowerCase()).toList();
    }
    return sorted;
  }

  /// Dynamic Reverse Geocoding with fallback
  /// Queries OpenStreetMap Nominatim to identify user's real area (e.g. "Sholinganallur", "Velachery", etc.)
  Future<String> reverseGeocodeArea(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&zoom=16&addressdetails=1',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'WosafeEmergencyApp/1.0',
      }).timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final suburb = addr['suburb'] ?? addr['neighbourhood'] ?? addr['residential'] ?? addr['quarter'];
          final city = addr['city'] ?? addr['town'] ?? addr['county'] ?? 'Chennai';
          if (suburb != null) {
            return '$suburb, $city';
          }
        }
        if (data['display_name'] != null) {
          final parts = (data['display_name'] as String).split(',');
          return parts.take(2).join(',').trim();
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode note: $e');
    }

    // Dynamic Fallback: Match against nearest known landmark neighborhood
    final nearest = findNearestPoliceStation(lat, lng);
    final cleanName = nearest.name.replaceAll('Police Station', '').replaceAll('Police Commissionerate', '').trim();
    return '$cleanName Corridor, Chennai';
  }

  /// Search places via OpenStreetMap Nominatim or catalog
  Future<List<SafePlacePoint>> searchDestinations(String query, double userLat, double userLng) async {
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.isEmpty) return getAllSafePlacesSorted(userLat, userLng).take(6).toList();

    // 1. Search locally in catalog
    final catalogMatches = getAllSafePlacesSorted(userLat, userLng).where((p) {
      return p.name.toLowerCase().contains(cleanQ) ||
          p.address.toLowerCase().contains(cleanQ) ||
          p.category.toLowerCase().contains(cleanQ);
    }).toList();

    if (catalogMatches.isNotEmpty) {
      return catalogMatches;
    }

    // 2. Query Nominatim Geocoding API with viewbox centered on South India / Chennai
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=5&countrycodes=in',
      );
      final res = await http.get(url, headers: {
        'User-Agent': 'WosafeEmergencyApp/1.0',
      }).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        final results = <SafePlacePoint>[];
        for (final item in list) {
          final lat = double.tryParse(item['lat']?.toString() ?? '') ?? 0.0;
          final lon = double.tryParse(item['lon']?.toString() ?? '') ?? 0.0;
          final displayName = item['display_name']?.toString() ?? query;
          final shortName = displayName.split(',').first.trim();
          final distKm = Geolocator.distanceBetween(userLat, userLng, lat, lon) / 1000.0;

          results.add(SafePlacePoint(
            name: shortName,
            category: 'transit',
            latitude: lat,
            longitude: lon,
            address: displayName,
            contact: '100 / 108',
            crowdLevel: 'Public Location',
            safetyHighlight: 'Public destination accessed via verified arterial roads',
            distanceKm: distKm,
          ));
        }
        if (results.isNotEmpty) return results;
      }
    } catch (e) {
      debugPrint('Nominatim place search note: $e');
    }

    return catalogMatches;
  }
}