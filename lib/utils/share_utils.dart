import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShareUtils {
  /// Builds the standardized emergency / live tracking dispatch message
  static String buildEmergencyMessage({
    required double latitude,
    required double longitude,
    required String address,
    String? userName,
  }) {
    final name = (userName != null && userName.trim().isNotEmpty)
        ? userName.trim()
        : 'Protected User';

    return '🚨 EMERGENCY WOSAFE ALERT!\n'
        '$name needs help and is sharing live GPS location:\n'
        '📍 Area: $address\n'
        '🗺️ Google Maps: https://maps.google.com/?q=$latitude,$longitude\n'
        '🔴 Live Telemetry: http://10.22.178.147:3000/track/USER_001\n'
        'Sent via WOSAFE Emergency System';
  }

  /// Direct automated SOS dispatch to Emergency Contacts and Police
  /// Dispatches via Native background SMS directly (no popups/selection sheets)
  /// Fallback to direct SMS intent if native background SMS permission is pending
  static Future<void> autoDispatchEmergencyDirectly({
    required double latitude,
    required double longitude,
    required String address,
    String? userName,
    BuildContext? context,
  }) async {
    final message = buildEmergencyMessage(
      latitude: latitude,
      longitude: longitude,
      address: address,
      userName: userName,
    );

    // Retrieve saved emergency contacts
    List<String> targetPhones = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('wosafe_contacts_json') ?? prefs.getString('homesafe_emergency_contacts');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map && item['phone'] != null) {
              final p = item['phone'].toString().split('/')[0].trim().replaceAll(RegExp(r'[^\d+]'), '');
              if (p.isNotEmpty) targetPhones.add(p);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error reading contacts for auto dispatch: $e');
    }

    // If no custom contacts found, fallback to police helpline
    if (targetPhones.isEmpty) {
      targetPhones.add('1091');
    }

    bool sentAnyDirect = false;
    const platform = MethodChannel('wosafe/emergency_channel');

    for (final phone in targetPhones) {
      try {
        final success = await platform.invokeMethod<bool>('sendDirectSms', {
          'phone': phone,
          'message': message,
        });
        if (success == true) {
          sentAnyDirect = true;
          debugPrint('✓ Background SMS sent directly to: $phone');
        }
      } catch (e) {
        debugPrint('Direct SMS attempt failed for $phone: $e');
      }
    }

    // If background SMS was not permitted by OS or failed, launch direct SMS intent to first contact
    if (!sentAnyDirect && targetPhones.isNotEmpty) {
      await shareViaSms(
        message: message,
        phoneNumber: targetPhones.first,
        context: context,
      );
    }
  }

  /// Shares location link via WhatsApp (direct to a phone or open WhatsApp chat)
  static Future<bool> shareViaWhatsApp({
    required String message,
    String? phoneNumber,
    BuildContext? context,
  }) async {
    try {
      String cleanPhone = '';
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        if (cleanPhone.startsWith('0')) cleanPhone = cleanPhone.substring(1);
        if (!cleanPhone.startsWith('+') && cleanPhone.length == 10) {
          cleanPhone = '91$cleanPhone'; // Default India country code
        }
        cleanPhone = cleanPhone.replaceAll('+', '');
      }

      final encoded = Uri.encodeComponent(message);
      Uri uri;
      if (cleanPhone.isNotEmpty) {
        uri = Uri.parse('https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded');
      } else {
        uri = Uri.parse('https://api.whatsapp.com/send?text=$encoded');
      }

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF25D366),
            content: Text('✓ Opening WhatsApp with live location alert...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return launched;
    } catch (e) {
      debugPrint('WhatsApp share error: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $e')),
        );
      }
      return false;
    }
  }

  /// Shares location link via native SMS app
  static Future<bool> shareViaSms({
    required String message,
    String? phoneNumber,
    BuildContext? context,
  }) async {
    try {
      String cleanPhone = '';
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        cleanPhone = phoneNumber.split('/')[0].trim().replaceAll(RegExp(r'[^\d+]'), '');
      }

      final encoded = Uri.encodeComponent(message);
      final uri = Uri.parse(cleanPhone.isNotEmpty ? 'sms:$cleanPhone?body=$encoded' : 'sms:?body=$encoded');

      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF10B981),
            content: Text('✓ Opening SMS Messages with live location alert...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return launched;
    } catch (e) {
      debugPrint('SMS share error: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open Messages: $e')),
        );
      }
      return false;
    }
  }

  /// Shares location via Android system share sheet (WhatsApp, Telegram, Gmail, etc.)
  static Future<void> shareViaSystem({
    required String message,
    BuildContext? context,
  }) async {
    try {
      await Share.share(
        message,
        subject: '🚨 EMERGENCY WOSAFE ALERT - Live Location',
      );
    } catch (e) {
      debugPrint('System share error: $e');
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: message));
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFE91E63),
            content: Text('✓ Live location alert copied to clipboard!'),
          ),
        );
      }
    }
  }

  /// Opens an interactive bottom sheet for the user to select WhatsApp, SMS, or All Apps
  static Future<void> showLocationShareModal(
    BuildContext context, {
    required double latitude,
    required double longitude,
    required String address,
    String? userName,
    bool isDark = false,
  }) async {
    final message = buildEmergencyMessage(
      latitude: latitude,
      longitude: longitude,
      address: address,
      userName: userName,
    );

    // Retrieve saved contacts to present 1-tap WhatsApp options
    List<Map<String, String>> contacts = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('wosafe_contacts_json') ?? prefs.getString('homesafe_emergency_contacts');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final decoded = json.decode(jsonStr);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map && item['phone'] != null && item['phone'].toString().isNotEmpty) {
              contacts.add({
                'name': item['name']?.toString() ?? 'Contact',
                'phone': item['phone'].toString(),
              });
            }
          }
        }
      }
    } catch (_) {}

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFFFFF0F5), shape: BoxShape.circle),
                  child: const Icon(Icons.share_location_rounded, color: Color(0xFFE91E63), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share Live Location',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                        ),
                      ),
                      Text(
                        'Send real-time GPS link to emergency contacts',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. WhatsApp Button
            _buildShareOptionTile(
              icon: Icons.chat_rounded,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFF25D366),
              title: 'Share via WhatsApp',
              subtitle: 'Send live map link to chats or WhatsApp status',
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                shareViaWhatsApp(message: message, context: context);
              },
            ),

            // 1B. Quick Contacts Direct WhatsApp Chips (if user has contacts saved)
            if (contacts.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: contacts.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                  itemBuilder: (c, i) {
                    final cName = contacts[i]['name']!;
                    final cPhone = contacts[i]['phone']!;
                    return ActionChip(
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE8F8EE),
                      side: const BorderSide(color: Color(0xFF25D366)),
                      avatar: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF25D366), size: 14),
                      label: Text(
                        'Send to $cName',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF25D366)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        shareViaWhatsApp(message: message, phoneNumber: cPhone, context: context);
                      },
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 10),

            // 2. SMS Text Message Button
            _buildShareOptionTile(
              icon: Icons.sms_rounded,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFF3B82F6),
              title: 'Share via SMS Message',
              subtitle: 'Works offline without internet data connection',
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                shareViaSms(
                  message: message,
                  phoneNumber: contacts.isNotEmpty ? contacts.first['phone'] : null,
                  context: context,
                );
              },
            ),

            const SizedBox(height: 10),

            // 3. System Share (All Apps)
            _buildShareOptionTile(
              icon: Icons.share_rounded,
              iconColor: Colors.white,
              iconBgColor: const Color(0xFFE91E63),
              title: 'More Apps (System Share)',
              subtitle: 'Share via Telegram, Gmail, or copy to clipboard',
              isDark: isDark,
              onTap: () {
                Navigator.pop(ctx);
                shareViaSystem(message: message, context: context);
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  static Widget _buildShareOptionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E1B4B)),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}
