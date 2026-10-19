import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All Alerts', 'Safety Alerts', 'Incidents', 'Update'];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFBFBFE),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alerts',
          style: TextStyle(
            color: Color(0xFFE91E63),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 1. Filter Tabs
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                itemBuilder: (ctx, index) {
                  final isSelected = _selectedTabIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(_tabs[index]),
                      selected: isSelected,
                      selectedColor: const Color(0xFFE91E63),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF1E1B4B)),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFFE91E63)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      onSelected: (val) => setState(() => _selectedTabIndex = index),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),

            // 2. Alerts Feed
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                children: [
                  // Stay Informed Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF0F3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFFFD1DC)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shield_outlined, color: Color(0xFFE91E63), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Stay informed , Stay safe.',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFE91E63),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "We'll notify you about important alerts and incidents.",
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.info_outline, color: Color(0xFFE91E63), size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Today Section
                  Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildAlertCard(
                    title: '🚨 Suspicious Follower Alert',
                    subtitle: 'Person walking behind you detected near Tambaram station corridor for 200m. Keep moving to well-lit main road.',
                    time: '10:45 AM',
                    isDanger: true,
                    isDark: isDark,
                  ),

                  _buildAlertCard(
                    title: 'High alert in your area',
                    subtitle: 'Avoid Karve nagar / East Tambaram unlit bypass due to reported incidents.',
                    time: '10:30 AM',
                    isDanger: true,
                    isDark: isDark,
                  ),

                  _buildAlertCard(
                    title: 'Road Damage & Dim Lighting Alert',
                    subtitle: 'Potholes, road work, and inactive streetlights on Bajman Rd. Safe detour active.',
                    time: '09:45 AM',
                    isWarning: true,
                    isDark: isDark,
                  ),

                  _buildAlertCard(
                    title: 'Safe route suggestion',
                    subtitle: 'New safe corridor available with active CCTV & police mobile patrol.',
                    time: '09:15 AM',
                    isDark: isDark,
                  ),

                  _buildAlertCard(
                    title: 'Emergency drill notice',
                    subtitle: 'Safety drill and siren test will be conducted in your area tomorrow.',
                    time: '08:00 AM',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 14),

                  // Yesterday Section
                  Text(
                    'Yesterday',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildAlertCard(
                    title: 'Incident Reported',
                    subtitle: 'Minor disturbance reported near Phoenix mall bus stop.',
                    time: '06:45 PM',
                    isDark: isDark,
                  ),

                  _buildAlertCard(
                    title: 'System Update',
                    subtitle: 'Wosafe Infinity security patches and ESP32 firmware synced successfully.',
                    time: '02:30 PM',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 18),
                  const Center(
                    child: Text(
                      'No more alerts',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String subtitle,
    required String time,
    bool isDanger = false,
    bool isWarning = false,
    required bool isDark,
  }) {
    Color iconColor = isDanger ? Colors.redAccent : (isWarning ? Colors.orange : const Color(0xFFE91E63));
    Color bgColor = isDanger
        ? (isDark ? const Color(0xFF3B1824) : const Color(0xFFFFF5F5))
        : (isDark ? const Color(0xFF1E293B) : Colors.white);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDanger
              ? (isDark ? Colors.red.withOpacity(0.4) : const Color(0xFFFFCDD2))
              : (isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDanger
                  ? (isDark ? const Color(0xFF4C1D24) : const Color(0xFFFFEBEE))
                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF0F5)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDanger ? Icons.warning_rounded : (isWarning ? Icons.construction_rounded : Icons.info_outline_rounded),
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDanger
                              ? (isDark ? const Color(0xFFF87171) : Colors.red[800])
                              : (isDark ? Colors.white : const Color(0xFF1E1B4B)),
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF6B7280), height: 1.25),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : const Color(0xFFB0B0C0), size: 18),
        ],
      ),
    );
  }
}
