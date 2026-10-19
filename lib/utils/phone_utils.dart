import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Launches the native phone dialer with prefilled emergency contact number,
/// and copies the number to clipboard so it's always ready to paste.
Future<bool> makePhoneCall(String phoneNumber, [BuildContext? context]) async {
  try {
    // If format is like "1091 / 044-23452359", take the first valid number
    String firstPart = phoneNumber.split('/')[0].trim();
    String cleanNumber = firstPart.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.isEmpty) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid phone number'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }

    // Always copy number to clipboard so it can be pasted anywhere
    await Clipboard.setData(ClipboardData(text: cleanNumber));

    final Uri uri = Uri.parse('tel:$cleanNumber');

    bool launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        debugPrint('Fallback launch error: $e');
      }
    }

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Calling $cleanNumber (Number also copied to clipboard)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    return launched;
  } catch (e) {
    debugPrint('Error launching dialer: $e');
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dialer: Number $phoneNumber copied to clipboard. Dial directly!'),
          backgroundColor: const Color(0xFFE91E63),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
}

/// Initiates a direct phone call using the native emergency channel (with fallback to dialer)
Future<bool> directEmergencyCall(String phoneNumber, [BuildContext? context]) async {
  try {
    String firstPart = phoneNumber.split('/')[0].trim();
    String cleanNumber = firstPart.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanNumber.isEmpty) return false;

    // Always copy number to clipboard as failsafe
    await Clipboard.setData(ClipboardData(text: cleanNumber));

    const platform = MethodChannel('wosafe/emergency_channel');
    try {
      final success = await platform.invokeMethod<bool>('makeDirectCall', {'phone': cleanNumber});
      if (success == true) return true;
    } catch (e) {
      debugPrint('Native direct call exception: $e');
    }

    // Fallback to standard dialer
    return await makePhoneCall(cleanNumber, context);
  } catch (e) {
    debugPrint('directEmergencyCall error: $e');
    return false;
  }
}

