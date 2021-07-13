import 'dart:async';

import 'package:ccppflutterplugin/ccpp_result.dart';
import 'package:flutter/services.dart';

class CcppFlutterPlugin {
  static const MethodChannel _channel = const MethodChannel('co.ichob/ccpp');

  static Future<void> initialize({
    required bool isSandbox,
  }) async {
    await _channel.invokeMethod('initialize', {
      'isSandBox': isSandbox,
    });
  }

  static Future<CcppResult> paymentWithCreditCard({
    required String paymentToken,
    required String creditCardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String securityCode,
    required bool storeCard,
  }) async {
    var args = {
      'paymentToken': paymentToken,
      'ccNumber': creditCardNumber,
      'expMonth': expiryMonth,
      'expYear': expiryYear,
      'securityCode': securityCode,
      'storeCard': storeCard,
    };
    var response = await _channel.invokeMethod('paymentWithCreditCard', args);
    return CcppResult.fromJson(Map<String, dynamic>.from(response));
  }

  static Future<CcppResult> paymentWithToken({
    required String paymentToken,
    required String cardToken,
    required String securityCode,
  }) async {
    var args = {
      'paymentToken': paymentToken,
      'cardToken': cardToken,
      'securityCode': securityCode
    };
    var response = await _channel.invokeMethod('paymentWithToken', args);
    return CcppResult.fromJson(Map<String, dynamic>.from(response));
  }
}
