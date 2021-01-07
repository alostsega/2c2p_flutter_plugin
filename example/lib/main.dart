import 'package:ccppflutterplugin/ccppflutterplugin.dart';
import 'package:flutter/material.dart';
import 'dart:async';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initCcppPlugin();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initCcppPlugin() async {
    await CcppFlutterPlugin.initialize(
      isSandbox: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    var paymentToken = 'PAYMENT_TOKEN';
    var securityCode = '123';
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              RaisedButton(
                child: Text('pay'),
                onPressed: () async {
                  var response = await CcppFlutterPlugin.paymentWithCreditCard(
                    paymentToken: paymentToken,
                    creditCardNumber: '4111111111111111',
                    expiryMonth: 7,
                    expiryYear: 2024,
                    securityCode: securityCode,
                    storeCard: true,
                  );
                  print('invoiceNo: ${response.invoiceNo}');
                  print('error: ${response.errorMessage}');
                },
              ),
              RaisedButton(
                child: Text('pay with token'),
                onPressed: () async {
                  var response = await CcppFlutterPlugin.paymentWithToken(
                    paymentToken: paymentToken,
                    cardToken: 'CARD_TOKEN',
                    securityCode: securityCode,
                  );
                  print('invoiceNo: ${response.invoiceNo}');
                  print('error: ${response.errorMessage}');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
