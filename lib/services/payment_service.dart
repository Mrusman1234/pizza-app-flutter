import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  // ─── JazzCash Credentials (sandbox) ───────────────────────────────────────
  static const String _jcMerchantId   = 'YOUR_MERCHANT_ID';
  static const String _jcPassword     = 'YOUR_PASSWORD';
  static const String _jcIntegritySalt = 'YOUR_INTEGRITY_SALT';
  static const String _jcUrl =
      'https://sandbox.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction';

  // ─── EasyPaisa Credentials (sandbox) ──────────────────────────────────────
  static const String _epStoreId     = 'YOUR_STORE_ID';
  static const String _epHashKey     = 'YOUR_HASH_KEY';
  static const String _epUrl =
      'https://easypaystg.easypaisa.com.pk/easypay/Index';

  // ══════════════════════════════════════════════════════════════════════════
  // JAZZCASH — Mobile Wallet payment
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> payWithJazzCash({
    required String mobileNumber,   // 03001234567
    required double amount,          // PKR
    required String orderId,
  }) async {
    final String txnDateTime =
        DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
    final String txnRefNo = 'T$txnDateTime';
    final String amountStr = (amount * 100).toInt().toString(); // paisas

    // Build secure hash (HMAC-SHA256)
    final String hashString =
        '$_jcIntegritySalt&$txnDateTime&$_jcMerchantId&$mobileNumber'
        '&$txnRefNo&$amountStr&PKR&$_jcPassword';
    final String secureHash = _hmacSha256(_jcIntegritySalt, hashString);

    final Map<String, dynamic> body = {
      "pp_Version": "2.0",
      "pp_TxnType": "MWALLET",
      "pp_Language": "EN",
      "pp_MerchantID": _jcMerchantId,
      "pp_Password": _jcPassword,
      "pp_MobileNumber": mobileNumber,
      "pp_CNIC": "",
      "pp_TxnRefNo": txnRefNo,
      "pp_Amount": amountStr,
      "pp_TxnCurrency": "PKR",
      "pp_TxnDateTime": txnDateTime,
      "pp_BillReference": orderId,
      "pp_Description": "Pizza Order $orderId",
      "pp_SecureHash": secureHash,
    };

    try {
      final response = await http.post(
        Uri.parse(_jcUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final result = jsonDecode(response.body);
      return {
        'success': result['pp_ResponseCode'] == '000',
        'message': result['pp_ResponseMessage'] ?? 'Unknown error',
        'txnRef': txnRefNo,
        'raw': result,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EASYPAISA — Mobile Account payment
  // ══════════════════════════════════════════════════════════════════════════
  static Future<Map<String, dynamic>> payWithEasyPaisa({
    required String mobileNumber,   // 03001234567
    required double amount,
    required String orderId,
  }) async {
    final String txnDateTime =
        DateTime.now().toString().replaceAll(RegExp(r'[^0-9]'), '').substring(0, 14);
    final String amountStr = amount.toStringAsFixed(2);

    // Build hash
    final String hashInput =
        'amount=$amountStr&orderRefNum=$orderId'
        '&paymentMethod=MA_PAY_PAGE&storeId=$_epStoreId'
        '&timeStamp=$txnDateTime&token=$_epHashKey';
    final String hash = _sha256Hash(hashInput);

    final Map<String, dynamic> body = {
      "storeId": _epStoreId,
      "amount": amountStr,
      "postBackURL": "https://yourapp.com/payment-callback",
      "orderRefNum": orderId,
      "expiryDate": txnDateTime,
      "autoRedirect": 0,
      "paymentMethod": "MA_PAY_PAGE",
      "mobileAccountNo": mobileNumber,
      "emailAddress": "",
      "timeStamp": txnDateTime,
      "encryptedHashRequest": hash,
    };

    try {
      final response = await http.post(
        Uri.parse(_epUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      final result = jsonDecode(response.body);
      return {
        'success': result['responseCode'] == '0000',
        'message': result['responseDesc'] ?? 'Unknown error',
        'txnRef': orderId,
        'raw': result,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static String _hmacSha256(String key, String data) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString().toUpperCase();
  }

  static String _sha256Hash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }
}
