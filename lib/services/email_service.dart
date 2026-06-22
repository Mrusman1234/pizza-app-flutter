import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _resendApiKey = dotenv.env['RESEND_API_KEY'] ?? '';
  final String _fromEmail = 'onboarding@resend.dev'; // Replace with verified domain

  Future<bool> sendInvitationEmail({
    required String targetEmail,
    required String name,
    required String invitationLink,
    required String restaurantName,
  }) async {
    debugPrint('📧 [EMAIL] Starting sendInvitationEmail to $targetEmail');

    // 1. Try Firebase Trigger Email Extension
    try {
      debugPrint('⏳ [EMAIL] Step 1: Adding document to "mail" collection...');
      await _db.collection('mail').add({
        'to': [targetEmail],
        'message': {
          'subject': 'Invitation to join $restaurantName Admin Panel',
          'html': _buildHtml(name, restaurantName, invitationLink),
        },
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [EMAIL] Successfully added to "mail" collection');
      return true; 
    } catch (e) {
      debugPrint('ℹ️ [EMAIL] Firestore Trigger Email failed/not found: $e. Falling back to Resend API.');
    }

    // 2. Fallback to Resend API
    if (_resendApiKey.isEmpty) {
      debugPrint('⚠️ [EMAIL] RESEND_API_KEY is missing. Simulation mode.');
      return true;
    }

    try {
      debugPrint('⏳ [EMAIL] Step 2: Calling Resend API...');
      final response = await http.post(
        Uri.parse('https://api.resend.com/emails'),
        headers: {
          'Authorization': 'Bearer $_resendApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromEmail,
          'to': targetEmail,
          'subject': 'Invitation to join $restaurantName Admin Panel',
          'html': _buildHtml(name, restaurantName, invitationLink),
        }),
      );

      debugPrint('📡 [EMAIL] Resend API Response Code: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [EMAIL] Sent successfully via Resend');
        return true;
      } else {
        debugPrint('❌ [EMAIL] Resend API Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [EMAIL] Error calling Resend: $e');
      return false;
    }
  }

  String _buildHtml(String name, String restaurantName, String invitationLink) {
    return '''
      <div style="font-family: sans-serif; max-width: 600px; margin: auto;">
        <h2>Hello, $name!</h2>
        <p>You have been invited to join the <strong>$restaurantName</strong> team as a Restaurant Admin.</p>
        <p>To accept this invitation and set up your account, please click the button below:</p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="$invitationLink" style="background-color: #E8401C; color: white; padding: 12px 24px; text-decoration: none; border-radius: 8px; font-weight: bold;">Accept Invitation</a>
        </div>
        <p>If the button doesn't work, copy and paste this link into your browser:</p>
        <p>$invitationLink</p>
        <p>This invitation will expire in 7 days.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;">
        <p style="color: #888; fontSize: 12px;">This is an automated message from Pizza Hub Vehari.</p>
      </div>
    ''';
  }
}
