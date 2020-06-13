import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:flutter/services.dart';
import './BookingScreen.dart';

class QRScanner extends StatefulWidget {
  @override
  QRScannerState createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner> {
  Uint8List bytes = Uint8List(0);
  TextEditingController _inputController;
  TextEditingController _outputController;

  @override
  initState() {
    super.initState();
    this._inputController = new TextEditingController();
    this._outputController = new TextEditingController();

    _scanQR();
  }

  String scannedDriverID = null;
  Future _scanQR() async {
    try {
      String cameraScanResult = await scanner.scan();
      print("Scannnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnnn");
      print(cameraScanResult);

      // Navigator.pop(context, cameraScanResult);
      // Navigator.of(context).push(MaterialPageRoute(builder: (context) => BookingScreen(cameraScanResult)));

      // setState(() {
      //   scannedDriverID = cameraScanResult; 
      //   // setting string result with cameraScanResult
      //   // data will come here so write code here
      // });
    } on PlatformException catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}