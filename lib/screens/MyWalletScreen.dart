import 'dart:convert';

import 'package:flutter/material.dart';
import '../resources/UserRepository.dart';
import '../services/UserApiService.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyWalletScreen extends StatefulWidget {
  @override
  MyWalletScreenState createState() => MyWalletScreenState();
}

class MyWalletScreenState extends State<MyWalletScreen> {
  var user;
  var userwalletData = null;

  var userServices = new UserApiService();
  var userRepository = new UserRepository();
  String redeemCode = null;

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text('My Wallet'),
        ),
        // drawer: SideDrawerWidget(),
        body: user == null
            ? Center(child: CircularProgressIndicator())
            : new Column(
                children: <Widget>[
                  headWidget(),
                  paymentAndcoupons(),
                  listWidgets()
                ],
              ));
  }

  getUserData() async {
    var userdata = await userRepository.fetchUserFromDB();
    var userwd =
        await userServices.getUserWalletAmountByAccessToken(userdata.auth_key);
    print(userwd);
    setState(() {
      user = userdata;
      userwalletData = userwd;
    });
  }

  Widget headWidget() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/sidebar-bg.png"),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              // crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                    flex: 1,
                    child: Column(
                      children: <Widget>[
                        Text('Balance',
                            style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.027,
                                color: Colors.white,
                                fontWeight: FontWeight.w200)),
                        Text(
                            (userwalletData != null
                                    ? (userwalletData["currency_type"] != null
                                        ? userwalletData["currency_type"]
                                            .toString()
                                        : "K")
                                    : "K") +
                                " " +
                                (userwalletData != null
                                    ? (userwalletData["wallet_balance"] != null
                                        ? userwalletData["wallet_balance"]
                                            .toString()
                                        : "0")
                                    : "0"),
                            style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.027,
                                color: Colors.white)),
                      ],
                    )),
                Expanded(
                    flex: 2,
                    child: Column(
                      children: <Widget>[
                        // Text('Expires on',style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.027,color: Colors.white,fontWeight: FontWeight.w200)),
                        // Text(( userwalletData != null ? (userwalletData["last_update_date"] != null ? userwalletData["last_update_date"].toString(): "Never Expiring") : "Never Expiring"),style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.027,color: Colors.white)),
                      ],
                    )),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1)
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget paymentAndcoupons() {
    return Container(
        child: Card(
          margin: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              ListTile(
                // leading: FlutterLogo(),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/PaymentByCardScreen');
                },
                title: Text('Add Amount in Wallet'),
                trailing: Icon(Icons.chevron_right, color: Colors.black),
              ),
              ListTile(
                title: Container(
                    width: MediaQuery.of(context).size.width * 0.5,
                    child: TextField(
                      onChanged: (value) {
                        redeemCode = value;
                      },
                      decoration: InputDecoration(
                        hintText: "Enter Coupon Code here",
                        border: InputBorder.none,
                      ),
                    )),
                trailing: RaisedButton(
                  onPressed: () async {
                    if (redeemCode != null) {
                      print("rdeenm coupon" + redeemCode);
                      var res = await userServices.availCoupon(
                          user.auth_key, redeemCode);
                      print(res);
                      if (res != false) {
                        // todo add api call to add in wallet
                        Fluttertoast.showToast(
                            msg: "Redeemption Successful",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 5,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize:
                                MediaQuery.of(context).size.width * 0.050);
                      } else {
                        Fluttertoast.showToast(
                            msg: "Invalid Coupon code!",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 5,
                            backgroundColor: Colors.red,
                            textColor: Colors.white,
                            fontSize:
                                MediaQuery.of(context).size.width * 0.050);
                      }
                    } else {
                      Fluttertoast.showToast(
                          msg: "Enter valid Coupon code",
                          toastLength: Toast.LENGTH_LONG,
                          gravity: ToastGravity.BOTTOM,
                          timeInSecForIosWeb: 5,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.050);
                    }
                  },
                  child: Text('Redeem', style: TextStyle(fontSize: 20)),
                ),
              )
            ],
          ),
        ),
        decoration: BoxDecoration(boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.black54, blurRadius: 2.0, offset: Offset(0.0, 0.75))
        ], color: Colors.black));
  }

  Widget listWidgets() {
    return Flexible(
        child: FutureBuilder(
      future: userServices.getUserWalletTransactionsByAccessToken(
          user != null ? user.auth_key : ""),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          var temp = json.decode(snapshot.data.body);
          if (temp['success'].toString() == "true") {
            temp = temp['data'];
            return ListView.builder(
                itemCount: temp.length,
                itemBuilder: (context, index) {
                  if (temp[index] != null) {
                    return Column(
                      children: <Widget>[
                        ListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(temp[index]['transaction_description'],
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.027,
                                        color: Colors.black)),
                                Text(temp[index]["transaction_date"].toString(),
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.02,
                                        color: Colors.black)),
                              ],
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                    (temp[index]["credit_amount"] != null
                                        ? temp[index]["credit_amount"]
                                            .toString()
                                        : temp[index]["debit_amount"]
                                            .toString()),
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.027,
                                        color: (temp[index]["credit_amount"] !=
                                                null
                                            ? Colors.green
                                            : Colors.red))),
                                Text(
                                    temp[index]["credit_amount"] != null
                                        ? "Credited"
                                        : "Paid",
                                    style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.height *
                                                0.010,
                                        color: (temp[index]["credit_amount"] !=
                                                null
                                            ? Colors.green
                                            : Colors.red))),
                              ],
                            )),
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.01)
                      ],
                    );
                  } else {
                    return Center(child: Text("No Data to Show"));
                  }
                });
          }
        } else {
          return Container(child: CircularProgressIndicator());
        }
      },
    )

        // child:ListView(
        //   children: <Widget>[
        //     // hardcoded box for spacing
        //     SizedBox(height: 20),
        //     ListTile(
        //       title: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: <Widget>[
        //           Text('Aug, 23 2019',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
        //           Text('00.30 AM',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.01,color: Colors.black)),
        //         ],
        //       ),
        //       trailing: Column(
        //         crossAxisAlignment: CrossAxisAlignment.start,
        //         children: <Widget>[
        //           Text('RS 25',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
        //           Text('Expired',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.010,color: Colors.red)),
        //         ],
        //       )
        //     ),
        //   ]
        // )
        );
  }
}
