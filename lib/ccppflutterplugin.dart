import 'dart:async';

import 'package:ccppflutterplugin/ccpp_result.dart';
import 'package:flutter/services.dart';

class CcppFlutterPlugin {
  static const MethodChannel _channel = const MethodChannel('co.ichob/ccpp');

  static Future<void> initialize({
    String merchantId,
    bool isSandbox,
  }) async {
    await _channel.invokeMethod('initialize', {
      'merchantId': merchantId,
      'isSandBox': isSandbox,
    });
  }

  static Future<CcppResult> paymentWithCreditCard({
    String paymentToken,
    String creditCardNumber,
    int expiryMonth,
    int expiryYear,
    String cvv,
    bool storeCard,
  }) async {
    var args = {
      'paymentToken': paymentToken,
      'ccNumber': creditCardNumber,
      'expMonth': expiryMonth,
      'expYear': expiryYear,
      'cvv': cvv,
      'storeCard': storeCard,
    };
    var response = await _channel.invokeMethod('paymentWithCreditCard', args);
    return CcppResult.fromJson(Map<String, dynamic>.from(response));
  }

  static Future<CcppResult> paymentWithToken({
    String paymentToken,
    String cardToken,
    String cvv,
  }) async {
    var args = {
      'paymentToken': paymentToken,
      'cardToken': cardToken,
      'cvv': cvv
    };
    var response = await _channel.invokeMethod('paymentWithToken', args);
    return CcppResult.fromJson(Map<String, dynamic>.from(response));
  }
}
