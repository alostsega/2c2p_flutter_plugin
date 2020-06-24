import 'dart:collection';

class CcppResult {
  String transactionId;
  String errorMessage;

  CcppResult({
    this.transactionId,
    this.errorMessage,
  });

  factory CcppResult.fromJson(Map<String, dynamic> json) {
    return CcppResult(
      transactionId: json['transactionId'] as String,
      errorMessage: json['errorMessage'] as String,
    );
  }
}
