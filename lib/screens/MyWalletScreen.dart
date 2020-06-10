import 'dart:convert';

import 'package:flutter/material.dart';
import '../resources/UserRepository.dart';
import '../services/UserApiService.dart';

class MyWalletScreen extends StatefulWidget {
  @override
  MyWalletScreenState createState() => MyWalletScreenState();
}

class MyWalletScreenState extends State<MyWalletScreen> {
  var user;
  var userwalletData = null;

  var userServices = new UserApiService();
  var userRepository = new UserRepository();
  
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
        body: new Column(
          children: <Widget>[
            headWidget(),
            paymentAndcoupons(),
            listWidgets()
          ],
        )
      );
  }

  getUserData() async {
    var userdata = await userRepository.fetchUserFromDB();
    var userwd = await userServices.getUserWalletAmountByAccessToken(userdata.auth_key);
    print(userwd);
    setState((){
      user = userdata;
      userwalletData = userwd;
    });
  }

  Widget headWidget(){
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
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ],
            ),
            Row(
              children: <Widget>[
                SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                Text('Balance',style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.02,color: Colors.white,fontWeight: FontWeight.w200)),
                SizedBox(width: MediaQuery.of(context).size.width * 0.45),
                Text('Expires',style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.02,color: Colors.white,fontWeight: FontWeight.w200)),
              ],
            ),
            Row(
              children: <Widget>[
                SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                Text(( userwalletData != null ? (userwalletData["currency_type"] != null ? userwalletData["currency_type"].toString(): "K") : "K") +" "+ ( userwalletData != null ? (userwalletData["wallet_balance"] != null ? userwalletData["wallet_balance"].toString(): "0") : "0") ,style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.02,color: Colors.white)),
                SizedBox(width: MediaQuery.of(context).size.width * 0.45),
                Text(( userwalletData != null ? (userwalletData["last_update_date"] != null ? userwalletData["last_update_date"].toString(): "Never Expiring") : "Never Expiring"),style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.02,color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget paymentAndcoupons(){
    return Container(
      child: Card(
        margin: EdgeInsets.zero,
        child: Column(
          children: <Widget>[
            ListTile(
              // leading: FlutterLogo(),
              title: Text('Payment Methods'),
              trailing: Icon(Icons.chevron_right,color: Colors.black),
            ),
            ListTile(
              // leading: FlutterLogo(),
              title: Text('Coupons'),
              trailing: Icon(Icons.chevron_right,color: Colors.black),
            )
          ],
        ),
      ),
      decoration: BoxDecoration(
          boxShadow: <BoxShadow>[
            BoxShadow(
                color: Colors.black54,
                blurRadius: 2.0,
                offset: Offset(0.0, 0.75)
            )
          ],
        color: Colors.black
      )
    );
  }

  Widget listWidgets(){
    return Flexible(
      child: FutureBuilder(
        future: userServices.getUserWalletTransactionsByAccessToken(),
        builder: (context, snapshot){

          if(snapshot.hasData){            
            var temp = json.decode(snapshot.data.body);
            if (temp['success'].toString() == "true") {
              temp = temp['data'];
              return ListView.builder(
                itemCount: temp.length,
                itemBuilder: (context, index) {
              print("AAAAAAAAAAAAAAAAAAAAAAAAAAa");
                  return Column(
                    children: <Widget>[
                      ListTile(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(temp[index]["transaction_date"].toString(),style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
                            Text('00.30 AM',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.01,color: Colors.black)),
                          ],
                        ),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('RS 25',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
                            Text('Expired',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.010,color: Colors.red)),
                          ],
                        )
                      )
                    ],
                  );
                }
              );
            }

          }else{
            return Container();
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