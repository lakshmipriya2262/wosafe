import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/phone_utils.dart';

class TrustedContactsScreen extends StatefulWidget {
  const TrustedContactsScreen({Key? key}) : super(key: key);

  @override
  State<TrustedContactsScreen> createState() => _TrustedContactsScreenState();
}

class _TrustedContactsScreenState extends State<TrustedContactsScreen> {
  List<Map<String, dynamic>> _contactsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    List<Map<String, dynamic>> loaded = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('wosafe_contacts_json') ??
          prefs.getString('homesafe_emergency_contacts');

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map) {
              final name = item['name']?.toString() ?? '';
              final phone = item['phone']?.toString() ?? '';
              final tag = item['relation']?.toString() ?? item['tag']?.toString() ?? 'Contact';
              final loc = item['location']?.toString() ?? 'Primary Contact';
              if (name.isNotEmpty && phone.isNotEmpty) {
                loaded.add({
                  'name': name,
                  'phone': phone,
                  'tag': tag,
                  'avatar': name[0].toUpperCase(),
                  'location': loc,
                });
              }
            }
          }
        }
      }

      // Check AuthProvider if list is still empty
      if (loaded.isEmpty && mounted) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final userContacts = auth.currentUser?.emergencyContacts;
        if (userContacts != null && userContacts.isNotEmpty) {
          for (var c in userContacts) {
            if (c.name.isNotEmpty && c.phone.isNotEmpty) {
              loaded.add({
                'name': c.name,
                'phone': c.phone,
                'tag': c.relation,
                'avatar': c.name[0].toUpperCase(),
                'location': 'Primary Contact',
              });
            }
          }
        }
      }

      // Append official rescue & safety helplines requested by user
      _appendHelplines(loaded);

      setState(() {
        _contactsList = loaded;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading contacts: $e');
      setState(() => _isLoading = false);
    }
  }

  void _appendHelplines(List<Map<String, dynamic>> list) {
    if (!list.any((c) => c['name'].toString().contains('Singapen'))) {
      list.add({
        'name': '🦁 Singapen Athiradi Padai',
        'phone': '1091 / 044-23452359',
        'tag': 'Rescue Unit',
        'avatar': '🦁',
        'location': 'Women Safety Action Force (24/7)',
      });
    }
    if (!list.any((c) => c['name'].toString().contains('Police'))) {
      list.add({
        'name': '👮 Tambaram Police Station',
        'phone': '044-22260100 / 100',
        'tag': 'Police',
        'avatar': '👮',
        'location': 'GST Road, Tambaram (1.2 km)',
      });
    }
    if (!list.any((c) => c['name'].toString().contains('Hospital'))) {
      list.add({
        'name': '🏥 Global Hospital (OMR)',
        'phone': '044-44777000 / 108',
        'tag': 'Hospital',
        'avatar': '🏥',
        'location': 'Perumbakkam / OMR (800m)',
      });
    }
    if (!list.any((c) => c['name'].toString().contains('Cab'))) {
      list.add({
        'name': '🚖 Women Safe Cab Service',
        'phone': '044-28889999',
        'tag': 'Cab Service',
        'avatar': '🚖',
        'location': 'Thalambur Safe Corridor (500m)',
      });
    }
  }

  Future<void> _persistContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userOnly = _contactsList.where((c) {
        final name = c['name'].toString();
        return !name.startsWith('🦁') && !name.startsWith('👮') && !name.startsWith('🏥') && !name.startsWith('🚖');
      }).map((c) => {
        'name': c['name'],
        'phone': c['phone'],
        'relation': c['tag'],
        'location': c['location'],
      }).toList();

      final encoded = json.encode(userOnly);
      await prefs.setString('wosafe_contacts_json', encoded);
      await prefs.setString('homesafe_emergency_contacts', encoded);
    } catch (e) {
      debugPrint('Error saving contacts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
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
              'Contacts',
              style: TextStyle(
                color: Color(0xFFE91E63),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Info Banner
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
                                child: const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFFE91E63),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Your trusted contacts will be notified with your live GPS location in an emergency.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFE91E63),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const Icon(Icons.info_outline, color: Color(0xFFE91E63), size: 18),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 2. Section Header: "My Emergency Contacts"
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'My Emergency Contacts',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                              ),
                            ),
                            Text(
                              '${_contactsList.length} Connected',
                              style: const TextStyle(fontSize: 11, color: Color(0xFFE91E63), fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Contact Cards List
                        if (_contactsList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'No contacts added yet. Tap below to add your trusted contact.',
                                style: TextStyle(color: isDark ? Colors.white60 : Colors.grey),
                              ),
                            ),
                          )
                        else
                          ..._contactsList.map((contact) => _buildContactCard(contact, isDark)),

                        const SizedBox(height: 16),

                        // 3. "+ Add New Contact" Button
                        Container(
                          width: double.infinity,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE91E63),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE91E63).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _showAddContactDialog(context, isDark),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Add New Contact',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. "During an emergency, we will:" Footer Card
                        Container(
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
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFF0F5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.phone_in_talk_rounded,
                                  color: Color(0xFFE91E63),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'During an emergency , we will:',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text('• Send instant SOS SMS and call alerts to your contacts', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                    const SizedBox(height: 2),
                                    const Text('• Share your high-precision live GPS tracking link', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                    const SizedBox(height: 2),
                                    const Text('• Auto-notify Singapen Athiradi Padai & Tambaram Police', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
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
      },
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, bool isDark) {
    final tag = contact['tag']?.toString() ?? 'Contact';
    final isPrimary = tag == 'Primary' || tag == 'Family';
    final isSpecial = tag == 'Police' || tag == 'Rescue Unit' || tag == 'Hospital';

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
      child: Row(
        children: [
          // Circle Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSpecial ? const Color(0xFFE3F2FD) : const Color(0xFFFFF0F5),
              shape: BoxShape.circle,
              border: Border.all(color: isSpecial ? Colors.blue : const Color(0xFFFFD1DC)),
            ),
            child: Center(
              child: contact['avatar'].toString().length > 1
                  ? Text(contact['avatar'], style: const TextStyle(fontSize: 18))
                  : Text(
                      contact['avatar'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isSpecial ? Colors.blue[800] : const Color(0xFFE91E63),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name'],
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  contact['phone'],
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? const Color(0xFFE91E63)
                            : (isSpecial ? Colors.blue : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: (isPrimary || isSpecial) ? Colors.white : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        contact['location'] ?? 'Chennai',
                        style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Call Button
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: Color(0xFFE91E63), size: 22),
            onPressed: () {
              makePhoneCall(contact['phone'], context);
            },
          ),
        ],
      ),
    );
  }

  void _showAddContactDialog(BuildContext context, bool isDark) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final locCtrl = TextEditingController(text: 'Karanai / Thalambur, Chennai');
    final tagCtrl = TextEditingController(text: 'Friend');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Trusted Contact', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Contact Name', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone Number (+91)', prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: tagCtrl,
                decoration: const InputDecoration(labelText: 'Relation / Tag (e.g. Sister, Friend, Doctor)', prefixIcon: Icon(Icons.label_outline)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(labelText: 'Area / Location', prefixIcon: Icon(Icons.location_on_outlined)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63)),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && phoneCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _contactsList.insert(0, {
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'tag': tagCtrl.text.trim(),
                    'avatar': nameCtrl.text.trim()[0].toUpperCase(),
                    'location': locCtrl.text.trim(),
                  });
                });
                _persistContacts();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    content: Text('✓ ${nameCtrl.text.trim()} added to your trusted contacts!'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter name and phone number')),
                );
              }
            },
            child: const Text('Save Contact', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
