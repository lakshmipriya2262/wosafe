import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'home_dashboard_screen.dart';
import 'live_location_screen.dart';
import 'setting_screen.dart';
import 'trusted_contents_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isEmbedded;
  const ProfileScreen({Key? key, this.isEmbedded = false}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImagePath;
  int _bottomNavIndex = 3; // 3 = Profile tab active

  @override
  void initState() {
    super.initState();
    _loadSavedProfilePhoto();
  }

  Future<void> _loadSavedProfilePhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString('wosafe_profile_photo_path');
      if (path != null && File(path).existsSync()) {
        if (mounted) setState(() => _profileImagePath = path);
      }
    } catch (e) {
      debugPrint('Error loading profile photo: $e');
    }
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (picked != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('wosafe_profile_photo_path', picked.path);
        if (mounted) {
          setState(() => _profileImagePath = picked.path);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF10B981),
              content: Text('✓ Profile picture updated successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('Camera or Gallery error: $e'),
          ),
        );
      }
    }
  }

  Future<void> _removePhoto(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('wosafe_profile_photo_path');
      if (mounted) {
        setState(() => _profileImagePath = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE91E63),
            content: Text('Profile photo removed.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (_) {}
  }

  void _showCameraPickerOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Profile Picture',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFFF0F5), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFE91E63)),
              ),
              title: Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
              subtitle: const Text('Capture live self-portrait for emergency responders', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera, context);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFFF0F5), shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFFE91E63)),
              ),
              title: Text('Choose from Photo Gallery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
              subtitle: const Text('Upload existing verified photo from device', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery, context);
              },
            ),
            if (_profileImagePath != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFFFEBEE), shape: BoxShape.circle),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                ),
                title: const Text('Remove Current Photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.red)),
                subtitle: const Text('Revert back to your name initials avatar', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                onTap: () {
                  Navigator.pop(ctx);
                  _removePhoto(context);
                },
              ),
          ],
        ),
      ),
    );
  }



  void _showVoiceCommandsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Activation SOS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            const SizedBox(height: 8),
            const Text('Hands-free voice recognition wake words:', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 14),
            _buildVoiceCommandTile('"Help Me"', 'Triggers instant SOS broadcast & GPS dispatch', isDark),
            _buildVoiceCommandTile('"Call Police"', 'Dials 100 & Tambaram Police Station', isDark),
            _buildVoiceCommandTile('"காப்பாத்துங்க"', 'Tamil distress wake-word trigger', isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCommandTile(String cmd, String desc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, color: Color(0xFFE91E63), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cmd, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE91E63))),
                Text(desc, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSafetyTipsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
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
              Text('Safety Tips & Self Defense', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
              const SizedBox(height: 12),
              _buildSafetyTipItem('Night Travel Corridors', 'Always share your live tracking route when commuting past 9 PM.', isDark),
              _buildSafetyTipItem('Smartwatch Bio-Sensors', 'Keep ESP32 watch paired; heart rate spikes above 115 BPM auto-trigger alert.', isDark),
              _buildSafetyTipItem('Medical Kit Preparedness', 'Keep asthma inhaler or emergency kit in easy-to-reach pocket.', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyTipItem(String title, String desc, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.3)),
        ],
      ),
    );
  }

  void _showNearbyHelpSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nearby Help Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
            const SizedBox(height: 12),
            const Text('• Tambaram Police Station (1.2 km) - 044-22260100', style: TextStyle(fontSize: 12.5, height: 1.4)),
            const Text('• Global Health City Hospital (OMR) - 044-44777000', style: TextStyle(fontSize: 12.5, height: 1.4)),
            const Text('• Singapen Athiradi Padai - 1091 / 044-23452359', style: TextStyle(fontSize: 12.5, height: 1.4, color: Color(0xFFE91E63), fontWeight: FontWeight.bold)),
            const Text('• Women Safe Cab Hub Thalambur (500m) - 044-28889999', style: TextStyle(fontSize: 12.5, height: 1.4)),
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
            Text('⚠️ Dimly Lit Zone: Thalambur link road lighting check advised.', style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
            SizedBox(height: 6),
            Text('💧 Hydration Reminder: Synced with smartwatch.', style: TextStyle(fontSize: 12, color: Color(0xFF15803D))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        final user = auth.currentUser;
        final displayName = (user != null && user.name.trim().isNotEmpty) ? user.name.trim() : 'Protected User';
        final displayEmail = (user != null && user.email.trim().isNotEmpty) ? user.email.trim() : 'Active Member';
        final displayPhone = (user != null && user.phone.trim().isNotEmpty) ? user.phone.trim() : 'Registered Protected Profile';

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFBFE),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0,
            leading: widget.isEmbedded
                ? null
                : IconButton(
                    icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeDashboardScreen()));
                      }
                    },
                  ),
            title: const Text(
              'Profile',
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
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. User Profile Header Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
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
                        GestureDetector(
                          onTap: () => _showCameraPickerOptions(context, isDark),
                          child: Stack(
                            children: [
                              Container(
                                width: 66,
                                height: 66,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFFFD6E0),
                                  border: Border.all(color: const Color(0xFFE91E63), width: 2),
                                ),
                                child: ClipOval(
                                  child: (_profileImagePath != null && File(_profileImagePath!).existsSync())
                                      ? Image.file(
                                          File(_profileImagePath!),
                                          width: 66,
                                          height: 66,
                                          fit: BoxFit.cover,
                                        )
                                      : Center(
                                          child: Text(
                                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFE91E63)),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE91E63),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name, Email, Phone
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                displayEmail,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayPhone,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),

                        // Edit Photo Pencil
                        GestureDetector(
                          onTap: () => _showCameraPickerOptions(context, isDark),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFFFC1D6)),
                            ),
                            child: const Center(
                              child: Icon(Icons.edit_outlined, color: Color(0xFFE91E63), size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Account Overview Header & Card
                  Text(
                    'Account Overview',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildOverviewColumn('${user?.emergencyContacts.length ?? 2}', 'Trusted Contacts', Icons.shield_outlined, isDark),
                        Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
                        _buildOverviewColumn('04', 'Rescue Units', Icons.security_rounded, isDark),
                        Container(width: 1, height: 36, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
                        _buildOverviewColumn('Active', 'GPS Status', Icons.location_on_outlined, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Quick Access Header & Items
                  Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildQuickAccessCard(
                    icon: Icons.people_outline_rounded,
                    title: 'Emergency Contacts',
                    subtitle: 'Manage your trusted contacts.',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrustedContactsScreen())),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessCard(
                    icon: Icons.mic_none_rounded,
                    title: 'Voice Activation',
                    subtitle: 'Set up voice commands',
                    onTap: () => _showVoiceCommandsSheet(context, isDark),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessCard(
                    icon: Icons.shield_outlined,
                    title: 'Safety Tips',
                    subtitle: 'Learn useful safety tips',
                    onTap: () => _showSafetyTipsSheet(context, isDark),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessCard(
                    icon: Icons.location_on_outlined,
                    title: 'Nearby Help',
                    subtitle: 'Find help services near you',
                    onTap: () => _showNearbyHelpSheet(context, isDark),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),

                  _buildQuickAccessCard(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'Theme, privacy and preferences',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildProfileBottomNav(isDark),
        );
      },
    );
  }

  Widget _buildOverviewColumn(String number, String label, IconData icon, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0F5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFFE91E63), size: 17),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          number,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF0F5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: const Color(0xFFE91E63), size: 20),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E1B4B),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          color: Color(0xFF94A3B8),
          size: 14,
        ),
      ),
    );
  }

  Widget _buildProfileBottomNav(bool isDark) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_outlined, 'Home', isDark),
          _buildNavItem(1, Icons.location_on_outlined, 'Location', isDark),
          _buildNavItem(2, Icons.notifications_none_rounded, 'Alerts', isDark),
          _buildNavItem(3, Icons.person_rounded, 'Profile', isDark),
          _buildNavItem(4, Icons.settings_outlined, 'Settings', isDark),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _bottomNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _bottomNavIndex = index);
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LiveLocationScreen()),
          );
        } else if (index == 2) {
          _showAlertsSheet(context);
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
            Icon(
              icon,
              color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF6B7280),
              size: 24,
            ),
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
}
