import 'dart:async';

import 'package:flutter/services.dart';

class CcppFlutterPlugin {
  static const MethodChannel _channel = const MethodChannel('co.ichob/ccpp');

  static Future<void> initialize({
    String merchantId,
    bool isSandbox,
  }) async {
    var result = await _channel.invokeMethod('initialize', {
      'merchantId': merchantId,
      'isSandBox': isSandbox,
    });
    print(result);
  }

  static Future<String> paymentWithCreditCard({
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
    var transactionId =
        await _channel.invokeMethod('paymentWithCreditCard', args);
    return transactionId;
  }

  static Future<String> paymentWithToken({
    String paymentToken,
    String cardToken,
    String cvv,
  }) async {
    var args = {
      'paymentToken': paymentToken,
      'cardToken': cardToken,
      'cvv': cvv
    };
    var transactionId = await _channel.invokeMethod('paymentWithToken', args);
    return transactionId;
  }
}
