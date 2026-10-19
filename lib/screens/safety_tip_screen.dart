import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SafetyTipsScreen extends StatefulWidget {
  const SafetyTipsScreen({Key? key}) : super(key: key);

  @override
  State<SafetyTipsScreen> createState() => _SafetyTipsScreenState();
}

class _SafetyTipsScreenState extends State<SafetyTipsScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['All Tips', 'Travel Safety', 'Self defense', 'General'];

  final List<Map<String, dynamic>> _tips = [
    {
      'title': 'Travel Safety Tips',
      'desc': 'Tips to keep you safe while travelling alone or in groups.',
      'icon': Icons.directions_walk_rounded,
      'category': 'Travel Safety',
      'details': 'Always keep your phone charged. Use live-monitored safe corridors and inform a trusted contact before boarding unfamiliar cabs or autos.',
    },
    {
      'title': 'Self Defense Basics',
      'desc': 'Learn simple self-defense techniques that can help you.',
      'icon': Icons.shield_outlined,
      'category': 'Self defense',
      'details': 'Target vulnerable pressure points: eyes, nose, throat, groin. Keep keys or personal safety spray readily accessible in your jacket or hand.',
    },
    {
      'title': 'Stay Alert , Stay safe',
      'desc': 'Be aware of your surroundings and avoid risky situations.',
      'icon': Icons.warning_amber_rounded,
      'category': 'General',
      'details': 'Avoid looking down at headphones/screens when walking through dimly lit or quiet streets. Trust your instincts—if a situation feels wrong, enter a crowded shop.',
    },
    {
      'title': 'Safe Commute Tips',
      'desc': 'Follow these tips for a safe commute every day.',
      'icon': Icons.directions_car_rounded,
      'category': 'Travel Safety',
      'details': 'Verify vehicle number and driver photo before boarding. Share your trip status with one tap via Wosafe.',
    },
    {
      'title': 'Social Safety Tips',
      'desc': 'Safe behavior on social media and while meeting people.',
      'icon': Icons.people_outline_rounded,
      'category': 'General',
      'details': 'Never check in publicly in real time when you are alone. Meet new contacts only in daylight in high-footfall public venues.',
    },
    {
      'title': 'Emergency Preparedness',
      'desc': 'What to do and how to be prepared in emergencies.',
      'icon': Icons.phone_in_talk_outlined,
      'category': 'General',
      'details': 'Memorize emergency numbers (100 Police, 1091 Women Helpline). Use the Wosafe 1-Tap SOS to send GPS coordinates and alert your contacts.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    final filteredTips = _selectedTabIndex == 0
        ? _tips
        : _tips.where((t) => t['category'] == _tabs[_selectedTabIndex]).toList();

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
          'Safety Tips',
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
            // 1. Top Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
              child: Container(
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
                            'Stay aware , Stay safe.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE91E63),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Helpful tips to protect yourself in everyday situation.',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.info_outline, color: Color(0xFFE91E63), size: 18),
                  ],
                ),
              ),
            ),

            // 2. Filter Pills
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

            // 3. Tips List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                itemCount: filteredTips.length,
                itemBuilder: (ctx, i) {
                  final tip = filteredTips[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1E9F5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _showTipDetailsModal(context, tip, isDark),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF0F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(tip['icon'] as IconData, color: const Color(0xFFE91E63), size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tip['title'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tip['desc'] as String,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : const Color(0xFFB0B0C0), size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTipDetailsModal(BuildContext context, Map<String, dynamic> tip, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(tip['icon'] as IconData, color: const Color(0xFFE91E63)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tip['title'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          tip['details'],
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
