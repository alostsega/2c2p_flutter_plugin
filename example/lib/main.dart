import 'package:flutter/material.dart';
import 'dart:async';

import 'package:ccppflutterplugin/ccppflutterplugin.dart';

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
      merchantId: 'JT01',
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
                  var transactionId =
                      await CcppFlutterPlugin.paymentWithCreditCard(
                    paymentToken: paymentToken,
                    creditCardNumber: '4242424242424242',
                    expiryMonth: 7,
                    expiryYear: 2024,
                    cvv: cvv,
                    storeCard: true,
                  );
                  print(transactionId);
                },
              ),
              RaisedButton(
                child: Text('pay with token'),
                onPressed: () async {
                  var transactionId = await CcppFlutterPlugin.paymentWithToken(
                    paymentToken: paymentToken,
                    cardToken: 'CARD_TOKEN',
                    cvv: cvv,
                  );
                  print(transactionId);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
