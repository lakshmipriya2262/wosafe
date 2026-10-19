import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emergency_provider.dart';
import '../screens/safe_route_screen.dart';

class LiveMapWidget extends StatefulWidget {
  final double height;
  final bool showControls;
  final bool showPoiMarkers;
  final VoidCallback? onMapTap;

  const LiveMapWidget({
    Key? key,
    this.height = 240.0,
    this.showControls = true,
    this.showPoiMarkers = true,
    this.onMapTap,
  }) : super(key: key);

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget>
    with TickerProviderStateMixin {
  late AnimationController _driveController;
  late AnimationController _pulseController;

  bool _showTraffic = true;
  bool _isSafeCorridorActive = true;
  bool _isPlaying = true;
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();

    // 1. Continuous smooth driving animation along road waypoints (Ola/Uber style)
    _driveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    // 2. Radar pulse animation around active cab/user GPS
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _driveController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _driveController.repeat();
      } else {
        _driveController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmergencyProvider>(
      builder: (context, emergency, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header: Ola/Uber Telemetry & Layer Toggles
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F9D58).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Color(0xFF0F9D58),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Live GPS Tracking (Ola/Uber Mode)',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'Active Route • Moving in Real-time',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Quick Toggle Chips (Traffic & Safe Mode)
                    Row(
                      children: [
                        // Traffic Toggle Chip
                        InkWell(
                          onTap: () => setState(() => _showTraffic = !_showTraffic),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: _showTraffic ? const Color(0xFFFFF3E0) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _showTraffic ? const Color(0xFFFF9800) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.traffic_rounded,
                                  size: 12,
                                  color: _showTraffic ? const Color(0xFFE65100) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Traffic',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: _showTraffic ? const Color(0xFFE65100) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Safe Corridor Toggle Chip
                        InkWell(
                          onTap: () => setState(() => _isSafeCorridorActive = !_isSafeCorridorActive),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isSafeCorridorActive ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _isSafeCorridorActive ? const Color(0xFF0F9D58) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_rounded,
                                  size: 12,
                                  color: _isSafeCorridorActive ? const Color(0xFF0F9D58) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Safe',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: _isSafeCorridorActive ? const Color(0xFF0F9D58) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. Interactive Map Viewport with Animated Moving Vehicle
              GestureDetector(
                onTap: widget.onMapTap ??
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SafeRouteScreen()),
                      );
                    },
                child: Container(
                  height: widget.height,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F3F0), // Google Maps base color
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // Animated Road Network, Traffic lines & Waypoints
                        AnimatedBuilder(
                          animation: Listenable.merge([_driveController, _pulseController]),
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size(double.infinity, widget.height),
                              painter: _AdvancedOlaTrackingPainter(
                                driveProgress: _driveController.value,
                                pulseProgress: _pulseController.value,
                                showTraffic: _showTraffic,
                                isSafeCorridor: _isSafeCorridorActive,
                                zoom: _zoomLevel,
                              ),
                            );
                          },
                        ),

                        // Top-Left: Ola/Uber Ride Telemetry HUD Pill
                        Positioned(
                          left: 10,
                          top: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.96),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isPlaying ? const Color(0xFF00C853) : Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  '32 km/h • ETA: 6 min (2.4 km)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '98% SAFE',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F9D58),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Top-Right: Map Floating Action Buttons (Play/Pause, Zoom, Fullscreen)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Column(
                            children: [
                              _buildMiniMapBtn(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                _togglePlayPause,
                              ),
                              const SizedBox(height: 6),
                              _buildMiniMapBtn(
                                Icons.fullscreen_rounded,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SafeRouteScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                        // Bottom-Right: Traffic Flow Indicator
                        if (_showTraffic)
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTrafficDot(const Color(0xFF00C853), 'Fast'),
                                  const SizedBox(width: 6),
                                  _buildTrafficDot(const Color(0xFFFFA000), 'Moderate'),
                                  const SizedBox(width: 6),
                                  _buildTrafficDot(const Color(0xFFE53935), 'Slow'),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Bottom Address Info & Action Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFE91E63),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emergency.currentAddress,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Thalambur OMR ➔ Kelambakkam Safe Corridor',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D58),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SafeRouteScreen()),
                        );
                      },
                      icon: const Icon(Icons.alt_route_rounded, size: 16),
                      label: const Text(
                        'Change Route',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrafficDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
      ],
    );
  }

  Widget _buildMiniMapBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 4,
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1E293B), size: 18),
      ),
    );
  }
}

/// Advanced Ola / Uber Style Live Vector Tracking Painter
class _AdvancedOlaTrackingPainter extends CustomPainter {
  final double driveProgress;
  final double pulseProgress;
  final bool showTraffic;
  final bool isSafeCorridor;
  final double zoom;

  _AdvancedOlaTrackingPainter({
    required this.driveProgress,
    required this.pulseProgress,
    required this.showTraffic,
    required this.isSafeCorridor,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Waterways (Buckingham Canal) on right
    final waterPaint = Paint()..color = const Color(0xFFA5D7E8);
    final waterPath = Path()
      ..moveTo(size.width * 0.90, 0)
      ..cubicTo(
        size.width * 0.86, size.height * 0.40,
        size.width * 0.93, size.height * 0.70,
        size.width * 0.88, size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // 2. Parks & Campus Reserves (Green zones)
    final parkPaint = Paint()..color = const Color(0xFFCEE7D0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.04, size.height * 0.06, size.width * 0.20, size.height * 0.32),
        const Radius.circular(8),
      ),
      parkPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.65, size.height * 0.62, size.width * 0.20, size.height * 0.32),
        const Radius.circular(8),
      ),
      parkPaint,
    );

    // 3. Realistic City Street Network (Intersections, Roundabouts, Cross Streets)
    final streetBorder = Paint()
      ..color = const Color(0xFFDADCE0)
      ..strokeWidth = 7.0 * zoom
      ..style = PaintingStyle.stroke;
    final streetSurface = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.0 * zoom
      ..style = PaintingStyle.stroke;

    // Cross Street 1 (Horizontal - Thalambur Main Rd)
    final h1 = Path()..moveTo(0, size.height * 0.40)..lineTo(size.width * 0.88, size.height * 0.40);
    canvas.drawPath(h1, streetBorder);
    canvas.drawPath(h1, streetSurface);

    // Cross Street 2 (Horizontal - Medavakkam Link)
    final h2 = Path()..moveTo(0, size.height * 0.74)..lineTo(size.width * 0.88, size.height * 0.74);
    canvas.drawPath(h2, streetBorder);
    canvas.drawPath(h2, streetSurface);

    // Vertical Arterial 1
    final v1 = Path()..moveTo(size.width * 0.28, 0)..lineTo(size.width * 0.28, size.height);
    canvas.drawPath(v1, streetBorder);
    canvas.drawPath(v1, streetSurface);

    // Vertical Arterial 2
    final v2 = Path()..moveTo(size.width * 0.68, 0)..lineTo(size.width * 0.68, size.height);
    canvas.drawPath(v2, streetBorder);
    canvas.drawPath(v2, streetSurface);

    // Roundabout Junction
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.40), 16 * zoom, streetBorder);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.40), 16 * zoom, streetSurface);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 0.40), 6 * zoom, parkPaint);

    // 4. Primary Highway: Rajiv Gandhi Salai (OMR IT Expressway)
    final highwayBorder = Paint()
      ..color = const Color(0xFFE8BE54)
      ..strokeWidth = 13.0 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final highwaySurface = Paint()
      ..color = const Color(0xFFFBD880)
      ..strokeWidth = 10.0 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highwayPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.88)
      ..lineTo(size.width * 0.28, size.height * 0.74)
      ..lineTo(size.width * 0.50, size.height * 0.40)
      ..cubicTo(
        size.width * 0.60, size.height * 0.28,
        size.width * 0.72, size.height * 0.24,
        size.width * 0.84, size.height * 0.16,
      );

    canvas.drawPath(highwayPath, highwayBorder);
    canvas.drawPath(highwayPath, highwaySurface);

    // Street Names
    _drawStreetLabel(canvas, 'Rajiv Gandhi Salai (OMR)', size.width * 0.58, size.height * 0.32, -0.40);
    _drawStreetLabel(canvas, 'Thalambur Main Rd', size.width * 0.04, size.height * 0.37, 0.0);
    _drawStreetLabel(canvas, 'Medavakkam Link', size.width * 0.04, size.height * 0.71, 0.0);

    // 5. Waypoints along the road network:
    final List<Offset> waypoints = [
      Offset(size.width * 0.08, size.height * 0.88),
      Offset(size.width * 0.28, size.height * 0.74),
      Offset(size.width * 0.50, size.height * 0.40),
      Offset(size.width * 0.68, size.height * 0.26),
      Offset(size.width * 0.84, size.height * 0.16),
    ];

    // Draw Route segments with Real-time Traffic Colors:
    _drawTrafficSegment(canvas, waypoints[0], waypoints[1], showTraffic ? const Color(0xFF00C853) : const Color(0xFF4285F4));
    _drawTrafficSegment(canvas, waypoints[1], waypoints[2], showTraffic ? const Color(0xFFFFA000) : const Color(0xFF4285F4));
    _drawTrafficSegment(canvas, waypoints[2], waypoints[3], showTraffic ? const Color(0xFF00C853) : const Color(0xFF4285F4));
    _drawTrafficSegment(canvas, waypoints[3], waypoints[4], showTraffic ? const Color(0xFF00C853) : const Color(0xFF4285F4));

    // Alternate Shortcut with Traffic Congestion (Red Segment)
    if (showTraffic) {
      final redPath = Path()
        ..moveTo(waypoints[1].dx, waypoints[1].dy)
        ..lineTo(size.width * 0.52, size.height * 0.74)
        ..lineTo(waypoints[4].dx, waypoints[4].dy);

      final redPaint = Paint()
        ..color = const Color(0xFFE53935).withOpacity(0.85)
        ..strokeWidth = 3.5 * zoom
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(redPath, redPaint);
    }

    // 6. Landmark POIs
    _drawPoiPin(canvas, waypoints[0], const Color(0xFF0F9D58), 'Start');
    _drawPoiBadge(canvas, waypoints[2], 'Safe Hub 🛡️', const Color(0xFF0F9D58));
    _drawPoiPin(canvas, waypoints[4], const Color(0xFFE53935), 'End');

    // 7. REAL-TIME MOVING VEHICLE / CAB (Ola / Uber Style!)
    final vehiclePos = _calculatePosition(waypoints, driveProgress);
    final vehicleHeading = _calculateHeading(waypoints, driveProgress);

    // A. Headlight Directional Beam Cone
    canvas.save();
    canvas.translate(vehiclePos.dx, vehiclePos.dy);
    canvas.rotate(vehicleHeading);

    final beamPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF4285F4).withOpacity(0.6),
          const Color(0xFF4285F4).withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 46))
      ..style = PaintingStyle.fill;

    final beamPath = Path()
      ..moveTo(0, 0)
      ..lineTo(42, -18)
      ..arcToPoint(const Offset(42, 18), radius: const Radius.circular(25))
      ..close();
    canvas.drawPath(beamPath, beamPaint);
    canvas.restore();

    // B. Pulsing Concentric GPS Waves
    final waveRadius = 14 + (pulseProgress * 26);
    final wavePaint = Paint()
      ..color = const Color(0xFF1A73E8).withOpacity((1.0 - pulseProgress) * 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(vehiclePos, waveRadius, wavePaint);

    // C. Realistic Cab / Car Vector Marker
    canvas.save();
    canvas.translate(vehiclePos.dx, vehiclePos.dy);
    canvas.rotate(vehicleHeading);

    final carShadow = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -7, 20, 14), const Radius.circular(5)),
      carShadow,
    );

    final carBody = Paint()..color = const Color(0xFF1A73E8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -6, 18, 12), const Radius.circular(4)),
      carBody,
    );

    final carGlass = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -4, 9, 8), const Radius.circular(2)),
      carGlass,
    );

    final headlight = Paint()..color = const Color(0xFFFFEB3B);
    canvas.drawCircle(const Offset(9, -4), 1.5, headlight);
    canvas.drawCircle(const Offset(9, 4), 1.5, headlight);

    canvas.restore();
  }

  void _drawTrafficSegment(Canvas canvas, Offset p1, Offset p2, Color trafficColor) {
    final glow = Paint()
      ..color = trafficColor.withOpacity(0.35)
      ..strokeWidth = 10.0 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, glow);

    final border = Paint()
      ..color = trafficColor.withOpacity(0.9)
      ..strokeWidth = 6.5 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, border);

    final core = Paint()
      ..color = trafficColor
      ..strokeWidth = 4.2 * zoom
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(p1, p2, core);
  }

  Offset _calculatePosition(List<Offset> pts, double t) {
    if (pts.length < 2) return const Offset(100, 100);

    final double totalSegments = (pts.length - 1).toDouble();
    final double segmentFloat = t * totalSegments;
    final int idx = segmentFloat.floor().clamp(0, pts.length - 2);
    final double localT = segmentFloat - idx;

    final p1 = pts[idx];
    final p2 = pts[idx + 1];

    return Offset(
      p1.dx + (p2.dx - p1.dx) * localT,
      p1.dy + (p2.dy - p1.dy) * localT,
    );
  }

  double _calculateHeading(List<Offset> pts, double t) {
    if (pts.length < 2) return 0.0;

    final double totalSegments = (pts.length - 1).toDouble();
    final double segmentFloat = t * totalSegments;
    final int idx = segmentFloat.floor().clamp(0, pts.length - 2);

    final p1 = pts[idx];
    final p2 = pts[idx + 1];

    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;

    return math.atan2(dy, dx);
  }

  void _drawPoiPin(Canvas canvas, Offset pos, Color color, String label) {
    canvas.drawCircle(pos, 8 * zoom, Paint()..color = color);
    canvas.drawCircle(pos, 3.5 * zoom, Paint()..color = Colors.white);
  }

  void _drawPoiBadge(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 8.5 * zoom,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy - 12), width: tp.width + 10, height: tp.height + 6),
      const Radius.circular(6),
    );
    canvas.drawRRect(bgRect, Paint()..color = Colors.white);
    canvas.drawRRect(bgRect, Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.stroke);
    tp.paint(canvas, Offset(pos.dx - tp.width / 2, pos.dy - 12 - tp.height / 2));
  }

  void _drawStreetLabel(Canvas canvas, String text, double x, double y, double rotation) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(rotation);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF64748B),
          fontSize: 8.5 * zoom,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AdvancedOlaTrackingPainter oldDelegate) => true;
}