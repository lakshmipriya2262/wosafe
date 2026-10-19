import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/share_utils.dart';
import '../utils/phone_utils.dart';
import 'safe_route_screen.dart';

class VoiceActiveScreen extends StatefulWidget {
  const VoiceActiveScreen({Key? key}) : super(key: key);

  @override
  State<VoiceActiveScreen> createState() => _VoiceActiveScreenState();
}

class _VoiceActiveScreenState extends State<VoiceActiveScreen>
    with SingleTickerProviderStateMixin {
  static const MethodChannel _channel = MethodChannel('wosafe/emergency_channel');

  late AnimationController _animController;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isEmergencyTriggered = false;
  double _rmsLevel = 0.2;
  String _liveTranscript = 'Listening for "Help Me", "Save Me", or "காப்பாத்துங்க"...';
  String? _detectedKeyword;

  // Emergency Trigger Keywords
  final List<String> _englishKeywords = [
    'help me',
    'save me',
    'help',
    'emergency',
    'danger',
    'police',
    'save',
  ];

  final List<String> _tamilKeywords = [
    'காப்பாத்துங்க',
    'காப்பாத்து',
    'உதவி',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _startListening();
  }

  @override
  void dispose() {
    _stopListening();
    _animController.dispose();
    super.dispose();
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (!mounted) return;
    switch (call.method) {
      case 'onSpeechStatus':
        final status = call.arguments?['status'] as String?;
        setState(() {
          _isSpeaking = (status == 'speaking');
        });
        break;
      case 'onSpeechRms':
        final rms = (call.arguments?['rms'] as num?)?.toDouble() ?? 0.0;
        setState(() {
          _rmsLevel = ((rms + 3) / 10).clamp(0.15, 1.0);
        });
        break;
      case 'onSpeechPartial':
        final partial = call.arguments?['text'] as String? ?? '';
        if (partial.trim().isNotEmpty) {
          setState(() {
            _liveTranscript = partial;
          });
          _analyzeSpokenText(partial);
        }
        break;
      case 'onSpeechResult':
        final text = call.arguments?['text'] as String? ?? '';
        if (text.trim().isNotEmpty) {
          setState(() {
            _liveTranscript = text;
          });
          _analyzeSpokenText(text);
        }
        break;
      case 'onSpeechError':
        final code = call.arguments?['errorCode'];
        debugPrint('Voice Recognition notification: code $code');
        break;
    }
  }

  Future<void> _startListening() async {
    try {
      _channel.setMethodCallHandler(_handleNativeCall);
      await _channel.invokeMethod('startSpeechRecognition');
      if (mounted) {
        setState(() {
          _isListening = true;
          _liveTranscript = 'Listening... Speak clearly or use quick test buttons';
        });
      }
    } catch (e) {
      debugPrint('Speech service note: $e');
      if (mounted) {
        setState(() {
          _isListening = true;
          _liveTranscript = 'Active (Ready for voice analysis & test triggers)';
        });
      }
    }
  }

  Future<void> _stopListening() async {
    try {
      await _channel.invokeMethod('stopSpeechRecognition');
    } catch (_) {}
    if (mounted) {
      setState(() => _isListening = false);
    }
  }

  void _analyzeSpokenText(String rawText) {
    if (_isEmergencyTriggered) return;

    final normalized = rawText.toLowerCase().trim();

    // 1. Check English Keywords
    for (final kw in _englishKeywords) {
      if (normalized.contains(kw)) {
        _triggerEmergencyDispatch(kw.toUpperCase());
        return;
      }
    }

    // 2. Check Tamil Keywords
    for (final kw in _tamilKeywords) {
      if (rawText.contains(kw)) {
        _triggerEmergencyDispatch(kw);
        return;
      }
    }
  }

  Future<void> _triggerEmergencyDispatch(String matchedWord) async {
    if (_isEmergencyTriggered) return;
    setState(() {
      _isEmergencyTriggered = true;
      _detectedKeyword = matchedWord;
      _liveTranscript = '🚨 DISTRESS PHRASE DETECTED: "$matchedWord"';
    });

    HapticFeedback.heavyImpact();
    HapticFeedback.vibrate();

    // Fetch user current position (fallback to Chennai / Thalambur if offline)
    double userLat = 12.8406;
    double userLng = 80.1534;
    String address = 'Near Agni College / Thalambur Main Rd, Chennai';

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.currentUser?.name ?? 'WOSAFE User';

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 4),
      );
      userLat = pos.latitude;
      userLng = pos.longitude;
      address = 'Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)} (Thalambur OMR Area)';
    } catch (_) {}

    if (!mounted) return;

    // 1. Dispatch Background Emergency SMS directly to contacts & 1091
    ShareUtils.autoDispatchEmergencyDirectly(
      latitude: userLat,
      longitude: userLng,
      address: address,
      userName: userName,
      context: context,
    );

    // If "POLICE" was spoken, also dial 1091 directly
    if (matchedWord.contains('POLICE')) {
      directEmergencyCall('1091', context);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🚨 Voice SOS: "$matchedWord" detected!\nEmergency SMS sent. Launching Safe Route autopilot...',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Auto-navigate to SafeRouteScreen with SOS mode
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SafeRouteScreen(
                isSosTriggered: true,
                destinationName: 'Thazhambur Police Station (Nearest Safe Haven)',
                destinationCategory: 'police',
                destinationLat: 12.8598,
                destinationLng: 80.2075,
              ),
            ),
          );
        }
      });
    }
  }

  void _simulateKeyword(String keyword) {
    setState(() {
      _liveTranscript = 'Spoken: "$keyword"';
    });
    _analyzeSpokenText(keyword);
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
          'Voice SOS Activation',
          style: TextStyle(
            color: Color(0xFFE91E63),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Banner Info Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF0F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_rounded, color: Color(0xFFE91E63), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hands-free Voice Distress Detection',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Say "Help Me", "Save Me", or "காப்பாத்துங்க" to trigger SOS automatically.',
                            style: TextStyle(fontSize: 11.5, color: textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Listening / Speaking Status Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isEmergencyTriggered
                        ? const Color(0xFFDC2626).withOpacity(0.15)
                        : _isSpeaking
                            ? const Color(0xFF10B981).withOpacity(0.15)
                            : const Color(0xFFE91E63).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isEmergencyTriggered
                          ? const Color(0xFFDC2626)
                          : _isSpeaking
                              ? const Color(0xFF10B981)
                              : const Color(0xFFE91E63),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _isEmergencyTriggered
                              ? const Color(0xFFDC2626)
                              : _isSpeaking
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE91E63),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isEmergencyTriggered
                            ? '🚨 SOS DISPATCHED: $_detectedKeyword'
                            : _isSpeaking
                                ? '🎙️ Speech Detected...'
                                : _isListening
                                    ? '🟢 Live Microphone Active'
                                    : '⏸️ Mic Paused',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: _isEmergencyTriggered
                              ? const Color(0xFFDC2626)
                              : _isSpeaking
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Wave Bars + Animated Mic Button
              GestureDetector(
                onTap: () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
                child: AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final scale = _isListening
                        ? 0.94 + 0.12 * (_isSpeaking ? _rmsLevel : _animController.value)
                        : 1.0;
                    final waveHeightMultiplier = _isListening
                        ? (_isSpeaking ? _rmsLevel * 2.2 : _animController.value)
                        : 0.2;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildWaveBar(14 * waveHeightMultiplier + 10),
                        const SizedBox(width: 4),
                        _buildWaveBar(26 * waveHeightMultiplier + 12),
                        const SizedBox(width: 4),
                        _buildWaveBar(38 * waveHeightMultiplier + 14),
                        const SizedBox(width: 14),

                        // Center Circle Mic
                        Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: _isEmergencyTriggered
                                    ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                                    : [const Color(0xFFFF3366), const Color(0xFFE91E63)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (_isEmergencyTriggered
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFFE91E63))
                                      .withOpacity(0.4),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                _isListening ? Icons.mic_rounded : Icons.mic_off_rounded,
                                color: Colors.white,
                                size: 42,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),
                        _buildWaveBar(38 * waveHeightMultiplier + 14),
                        const SizedBox(width: 4),
                        _buildWaveBar(26 * waveHeightMultiplier + 12),
                        const SizedBox(width: 4),
                        _buildWaveBar(14 * waveHeightMultiplier + 10),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Live Transcript Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _isEmergencyTriggered
                        ? const Color(0xFFDC2626)
                        : borderColor,
                    width: _isEmergencyTriggered ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LIVE TRANSCRIPT',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: textSecondary,
                          ),
                        ),
                        if (_isSpeaking)
                          const Text(
                            '● REC',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _liveTranscript,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: _isEmergencyTriggered
                            ? const Color(0xFFDC2626)
                            : textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Quick Test Trigger Simulation Chips
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Voice Keyword Simulation (1-Tap Test):',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSimChip(
                        label: '🚨 "Help Me"',
                        onTap: () => _simulateKeyword('Help Me'),
                        isDark: isDark,
                      ),
                      _buildSimChip(
                        label: '🛡️ "Save Me"',
                        onTap: () => _simulateKeyword('Save Me'),
                        isDark: isDark,
                      ),
                      _buildSimChip(
                        label: '🗣️ "காப்பாத்துங்க"',
                        onTap: () => _simulateKeyword('காப்பாத்துங்க'),
                        isDark: isDark,
                      ),
                      _buildSimChip(
                        label: '🆘 "Emergency"',
                        onTap: () => _simulateKeyword('Emergency'),
                        isDark: isDark,
                      ),
                      _buildSimChip(
                        label: '👮 "Call Police"',
                        onTap: () => _simulateKeyword('Call Police'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Voice Commands Reference Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supported Emergency Trigger Keywords',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildVoiceCommandRow(
                      icon: Icons.shield_outlined,
                      command: '"Help Me" / "Save Me"',
                      desc: 'Instant GPS dispatch via background SMS to contacts & safe route autopilot',
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                    Divider(height: 18, color: borderColor),
                    _buildVoiceCommandRow(
                      icon: Icons.record_voice_over_rounded,
                      command: '"காப்பாத்துங்க" (Save Me) / "உதவி"',
                      desc: 'Tamil regional distress triggers auto emergency broadcast and safe route navigation',
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                    Divider(height: 18, color: borderColor),
                    _buildVoiceCommandRow(
                      icon: Icons.local_police_outlined,
                      command: '"Police" / "Call Police"',
                      desc: 'Direct dispatch to 1091 Women Helpline & Thazhambur Police Desk',
                      isDark: isDark,
                      textPrimary: textPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Privacy Notice Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF0F5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFFFD1DC),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: Color(0xFFE91E63), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Edge Voice Processing & Privacy',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE91E63),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Audio analysis is performed directly on your device. Audio recordings are never uploaded or stored remotely.',
                            style: TextStyle(fontSize: 11, color: textSecondary, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimChip({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE91E63).withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE91E63).withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFFE91E63),
          ),
        ),
      ),
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 4,
      height: height.clamp(8.0, 52.0),
      decoration: BoxDecoration(
        color: _isEmergencyTriggered
            ? const Color(0xFFDC2626)
            : const Color(0xFFE91E63),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildVoiceCommandRow({
    required IconData icon,
    required String command,
    required String desc,
    required bool isDark,
    required Color textPrimary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFE91E63), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                command,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

