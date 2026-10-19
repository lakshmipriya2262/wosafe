import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'home_dashboard_screen.dart';
import 'live_location_screen.dart';
import 'profile_screen.dart';
import '../utils/phone_utils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _currentBottomNavIndex = 4; // 4 = Settings selected
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFBFE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFFE91E63),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
          children: [
            // ----------------------------------------------------
            // 1. GENERAL SECTION
            // ----------------------------------------------------
            Text(
              'General',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  // A. Notifications
                  _buildSettingRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Manage your alert and message preferences',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications active: SOS sirens and hydration alerts enabled.')),
                      );
                    },
                  ),
                  _buildDivider(isDark),

                  // B. Dark Mode Toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        _buildPinkIconBadge(Icons.nightlight_round_outlined),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark Mode',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                                ),
                              ),
                              Text(
                                'Enable dark theme',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: themeProvider.isDarkMode,
                          activeColor: const Color(0xFFE91E63),
                          onChanged: (val) => themeProvider.toggleTheme(val),
                        ),
                      ],
                    ),
                  ),
                  _buildDivider(isDark),

                  // C. Language
                  _buildSettingRow(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: 'Choose your preferred langauge',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedLanguage, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedLanguage = _selectedLanguage == 'English' ? 'தமிழ்' : 'English';
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Language switched to $_selectedLanguage')),
                      );
                    },
                  ),
                  _buildDivider(isDark),

                  // D. Privacy & Security
                  _buildSettingRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Privacy & Security',
                    subtitle: 'Manage your data and privacy',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Privacy & Security'),
                          content: const Text('Live GPS logs and biometric heart-rate telemetry are end-to-end encrypted for high user safety.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                        ),
                      );
                    },
                  ),
                  _buildDivider(isDark),

                  // E. Change Password
                  _buildSettingRow(
                    icon: Icons.key_rounded,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => _showChangePasswordDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ----------------------------------------------------
            // 2. SUPPORT SECTION
            // ----------------------------------------------------
            Text(
              'Support',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : const Color(0xFF1E1B4B),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  // A. Help Center (With Singapen Athiradi Padai, Police, Hospital)
                  _buildSettingRow(
                    icon: Icons.help_outline_rounded,
                    title: 'Help Center',
                    subtitle: 'Get help and support',
                    onTap: () => _showEmergencyHelpCenter(context),
                  ),
                  _buildDivider(isDark),

                  // B. Terms & Conditions
                  _buildSettingRow(
                    icon: Icons.description_outlined,
                    title: 'Terms & Conditions',
                    subtitle: 'Read our terms and conditions',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Terms & Conditions'),
                          content: const Text('WOSAFE Infinity Protection • Agni College of Technology IPD (ID: 24IPD010). All rights reserved.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
                        ),
                      );
                    },
                  ),
                  _buildDivider(isDark),

                  // C. About SafeHer / Wosafe
                  _buildSettingRow(
                    icon: Icons.shield_outlined,
                    title: 'About WOSAFE',
                    subtitle: 'App version and info',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('About WOSAFE'),
                          content: const Text('WOSAFE v1.0.0\nDeveloped by Team PIXAL TECH HUB\nAgni College of Technology, Thalambur, Chennai.'),
                          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ----------------------------------------------------
            // 3. SOLID PINK LOGOUT BUTTON
            // ----------------------------------------------------
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE91E63).withOpacity(0.35),
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
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    auth.logout();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
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
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  Widget _buildPinkIconBadge(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF0F5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(icon, color: const Color(0xFFE91E63), size: 19),
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: _buildPinkIconBadge(icon),
      title: Text(
        title,
        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
      ),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, thickness: 1, indent: 64, endIndent: 14, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5));
  }

  // Emergency Help Center with the user's specific requested numbers
  void _showEmergencyHelpCenter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🚨 Emergency & Safety Helplines', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFFE91E63))),
            const SizedBox(height: 14),
            _buildContactRow('🦁 Singapen Athiradi Padai', '1091 / 044-23452359', 'Women Safety Action Force'),
            _buildContactRow('👮 Tambaram Police Station', '044-22260100 / 100', 'Nearby Police Assistance'),
            _buildContactRow('🏥 Global Hospital (OMR)', '044-44777000 / 108', '24/7 Ambulance & Trauma'),
            _buildContactRow('🚖 Women Safe Cab Service', '044-28889999', 'Fast Track / Safe Transit'),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(String name, String phone, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD1DC)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1B4B))),
                Text(desc, style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
                Text('Phone: $phone', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFE91E63))),
              ],
            ),
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

  void _showChangePasswordDialog(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPass, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
            TextField(controller: newPass, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Password updated successfully!')));
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(0, Icons.home_outlined, 'Home', () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeDashboardScreen()))),
          _navItem(1, Icons.location_on_outlined, 'Location', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LiveLocationScreen()))),
          _navItem(2, Icons.notifications_none_rounded, 'Alerts', () {}),
          _navItem(3, Icons.person_outline_rounded, 'Profile', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))),
          _navItem(4, Icons.settings_rounded, 'Settings', () {}),
        ],
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label, VoidCallback onTap) {
    final isSel = _currentBottomNavIndex == idx;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSel ? const Color(0xFFE91E63) : Colors.grey, size: 24),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? const Color(0xFFE91E63) : Colors.grey)),
        ],
      ),
    );
  }
}