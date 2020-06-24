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
      merchantId: 'MERCHANT_ID',
      isSandbox: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    var paymentToken = 'PAYMENT_TOKEN';
    var cvv = '123';
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
                    creditCardNumber: '4242424242424242',
                    expiryMonth: 7,
                    expiryYear: 2024,
                    cvv: cvv,
                    storeCard: true,
                  );
                  print('transactionId: ${response.transactionId}');
                  print('error: ${response.errorMessage}');
                },
              ),
              RaisedButton(
                child: Text('pay with token'),
                onPressed: () async {
                  var response = await CcppFlutterPlugin.paymentWithToken(
                    paymentToken: paymentToken,
                    cardToken: 'CARD_TOKEN',
                    cvv: cvv,
                  );
                  print('transactionId: ${response.transactionId}');
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
