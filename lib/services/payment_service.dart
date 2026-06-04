import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  late final String jazzCashMerchantId;
  late final String jazzCashPassword;
  late final String jazzCashIntegritySalt;
  
  late final String easyPaisaStoreId;
  late final String easyPaisaHashKey;

  static const String _jcUrl =
      'https://sandbox.jazzcash.com.pk/ApplicationAPI/API/2.0/Purchase/DoMWalletTransaction';
  static const String _epUrl =
      'https://easypaystg.easypaisa.com.pk/easypay/Index';

  PaymentService._internal() {
    // Load from .env if available, otherwise use sandbox defaults
    jazzCashMerchantId = dotenv.env['JAZZCASH_MERCHANT_ID'] ?? 'MC00000000';
    jazzCashPassword = dotenv.env['JAZZCASH_PASSWORD'] ?? 'password';
    jazzCashIntegritySalt = dotenv.env['JAZZCASH_SALT'] ?? 'salt';

    easyPaisaStoreId = dotenv.env['EASYPAISA_STORE_ID'] ?? 'YOUR_STORE_ID';
    easyPaisaHashKey = dotenv.env['EASYPAISA_HASH_KEY'] ?? 'YOUR_HASH_KEY';
  }

  // ══════════════════════════════════════════════════════════════════════════
  // JAZZCASH — Mobile Wallet payment
  // ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> payWithJazzCash({
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
        '$jazzCashIntegritySalt&$txnDateTime&$jazzCashMerchantId&$mobileNumber'
        '&$txnRefNo&$amountStr&PKR&$jazzCashPassword';
    final String secureHash = _hmacSha256(jazzCashIntegritySalt, hashString);

    final Map<String, dynamic> body = {
      "pp_Version": "2.0",
      "pp_TxnType": "MWALLET",
      "pp_Language": "EN",
      "pp_MerchantID": jazzCashMerchantId,
      "pp_Password": jazzCashPassword,
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
      
      // In production, we don't trust this HTTP response alone.
      // We only use this to see if the wallet request was "Sent".
      final result = jsonDecode(response.body);
      
      return {
        'initiated': result['pp_ResponseCode'] == '000' || result['pp_ResponseCode'] == '124',
        'message': 'Waiting for bank confirmation...',
        'checkoutId': orderId, // This is actually our CheckoutId now
      };
    } catch (e) {
      return {'initiated': false, 'message': e.toString()};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // EASYPAISA — Mobile Account payment
  // ══════════════════════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> payWithEasyPaisa({
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
        '&paymentMethod=MA_PAY_PAGE&storeId=$easyPaisaStoreId'
        '&timeStamp=$txnDateTime&token=$easyPaisaHashKey';
    final String hash = _sha256Hash(hashInput);

    final Map<String, dynamic> body = {
      "storeId": easyPaisaStoreId,
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
  String _hmacSha256(String key, String data) {
    final hmac = Hmac(sha256, utf8.encode(key));
    return hmac.convert(utf8.encode(data)).toString().toUpperCase();
  }

  String _sha256Hash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }
}
