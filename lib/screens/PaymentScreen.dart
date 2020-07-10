import 'package:flutter/material.dart';
import '../widgets/SideDrawerWidget.dart';
import 'package:flutter_credit_card/credit_card_form.dart';
import 'package:flutter_credit_card/credit_card_model.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import '../services/PaymentApiService.dart';
import '../resources/UserRepository.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PaymentScreen extends StatefulWidget {
  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;

  var paymentService = new PaymentApiService();
  var user = null;
  var userRepository = new UserRepository();
  String amount = null;

  @override
  void initState() {
    // TODO: implement initState
    getUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('Recharge wallet'),
        ),
        drawer: SideDrawerWidget(),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              CreditCardWidget(
                cardNumber: cardNumber,
                expiryDate: expiryDate,
                cardHolderName: cardHolderName,
                cvvCode: cvvCode,
                showBackView: isCvvFocused,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      Container(
                          width: MediaQuery.of(context).size.width * 0.92,
                          child: TextField(
                            onChanged: (value) {
                              amount = value;
                            },
                            textAlign: TextAlign.left,
                            decoration: new InputDecoration(
                              hintText: 'Enter Amount to add',
                              border: new OutlineInputBorder(
                                borderRadius: const BorderRadius.all(
                                  const Radius.circular(0.0),
                                ),
                                borderSide: new BorderSide(
                                  color: Colors.black,
                                  width: 1.0,
                                ),
                              ),
                            ),
                          )),
                      CreditCardForm(
                        onCreditCardModelChange: onCreditCardModelChange,
                      )
                    ],
                  ),
                ),
              ),
              RaisedButton(
                color: Colors.red,
                textColor: Colors.white,
                padding: EdgeInsets.all(5.0),
                onPressed: () async {
                  print(cardNumber);
                  var split = expiryDate.split("/");
                  print(split[0] != null ? split[0] : 0);
                  print(split[1] != null ? split[1] : 0);
                  print(cvvCode);
                  print(amount);

                  // hardcoded for now for testign purposes
                  var payment = await paymentService.addInWalletByAccessToken(
                      user.auth_key,
                      cardNumber.replaceAll(new RegExp(r"\s+"), ""),
                      split[0] != null ? split[0] : 0,
                      split[1] != null ? split[1] : 0,
                      cvvCode,
                      amount != null ? amount.toString() : "0",
                      "MMK"); //this is hardcoded for now

                  if (payment != null) {
                    if (payment["transaction_id"] != null) {
                      Fluttertoast.showToast(
                          msg: "Transaction Successful",
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 5,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.050);
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, '/MyWalletScreen');
                    } else {
                      return Fluttertoast.showToast(
                          msg: "Wallet Recharge Failed, Error in Transaction",
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.CENTER,
                          timeInSecForIosWeb: 5,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.050);
                    }
                  } else {
                    return Fluttertoast.showToast(
                        msg: "Wallet Recharge Failed, Error in Transaction",
                        toastLength: Toast.LENGTH_LONG,
                        gravity: ToastGravity.CENTER,
                        timeInSecForIosWeb: 5,
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                        fontSize: MediaQuery.of(context).size.width * 0.050);
                  }
                },
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.70,
                  height: MediaQuery.of(context).size.height * 0.07,
                  child: Center(
                    child: Text(
                      'Make Payment',
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.050),
                    ),
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04)
            ],
          ),
        ));
  }

  void onCreditCardModelChange(CreditCardModel creditCardModel) async {
    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }

  getUserData() async {
    var userdata = await userRepository.fetchUserFromDB();
    setState(() {
      user = userdata;
      // _getCabData();
    });
  }
}
