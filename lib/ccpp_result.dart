import 'dart:collection';

class CcppResult {
  String? invoiceNo;
  String? errorMessage;

  CcppResult({
    this.invoiceNo,
    this.errorMessage,
  });

  factory CcppResult.fromJson(Map<String, dynamic> json) {
    return CcppResult(
      invoiceNo: json['invoiceNo'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
