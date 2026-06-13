import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsService {
  static const String _baseInviteUrl = 'https://travelers.app/join';
  
  /// Send SMS invite via phone's SMS app
  Future<void> sendSmsInvite({
    required String phoneNumber,
    required String inviteCode,
    required String origin,
    required String destination,
    required String scheduleInfo,
  }) async {
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    final message = _buildInviteMessage(inviteCode, origin, destination, scheduleInfo);
    
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: formattedPhone,
      query: 'body=${Uri.encodeComponent(message)}',
    );
    
    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      throw Exception('Could not send SMS to $formattedPhone');
    }
  }
  
  /// Send SMS via backend API (for automated replies)
  Future<void> sendAutomatedSms({
    required String phoneNumber,
    required String message,
  }) async {
    // In production, call your backend API
    // For now, simulate
    debugPrint('📱 SMS to $phoneNumber: $message');
    
    // TODO: Integrate with Africa's Talking or Twilio API
    // Example:
    // final response = await http.post(
    //   Uri.parse('https://api.africastalking.com/version1/messaging'),
    //   headers: {'apiKey': 'YOUR_API_KEY'},
    //   body: {'to': phoneNumber, 'message': message},
    // );
  }
  
  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+254${cleaned.substring(1)}';
    }
    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }
  
  String _buildInviteMessage(String inviteCode, String origin, String destination, String scheduleInfo) {
    return '🚐 Travelers Invite!\n\n'
        'Join my group ride from $origin to $destination.\n'
        'Schedule: $scheduleInfo\n\n'
        'Tap to join: $_baseInviteUrl?code=$inviteCode\n'
        'Or reply YES to confirm.';
  }
}