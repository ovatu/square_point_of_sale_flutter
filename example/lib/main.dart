import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:square_pos/square_pos.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool? _canRequest;
  String? _message;
  SquarePosPaymentResponse? _response;

  @override
  void initState() {
    super.initState();
    initSquarePOS();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initSquarePOS() async {
    await SquarePos.init('test', 'test');

    bool? canRequest;
    String? message;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      canRequest = await SquarePos.canRequest;
      message = (canRequest == true)
          ? 'Square POS installed'
          : 'Square POS not installed';
    } on PlatformException {
      message = 'Failed to check is Square POS is installed.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _canRequest = canRequest;
      _message = message;
    });
  }

  _requestPayment() async {
    var request = SquarePosPaymentRequest(
        money: SquarePosMoney(amountCents: 100, currencyCode: "USD"),
        supportedTenderTypes: [
          SquarePosTenderType.card,
          SquarePosTenderType.cardOnFile,
          SquarePosTenderType.squareGiftCard
        ]);
    var response = await SquarePos.requestPayment(request);

    setState(() {
      _response = response;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
            child: Column(children: [
          Text('Can Request: $_canRequest\n'),
          Text('Message: $_message\n'),
          if (_canRequest ?? false)
            TextButton(
                onPressed: () => _requestPayment(),
                child: Text('Request: \$1.00')),
          if (_response != null) Text('Response: $_response\n'),
        ])),
      ),
    );
  }
}
