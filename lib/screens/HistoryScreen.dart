import 'package:flutter/material.dart';
import '../widgets/SideDrawerWidget.dart';
import '../resources/UserRepository.dart';
import '../services/UserApiService.dart';

class HistoryScreen extends StatefulWidget {
  @override
  HistoryScreenState createState() => HistoryScreenState();
}

class HistoryScreenState extends State<HistoryScreen> {
  var userServices = new UserApiService();
  var userRepository = new UserRepository();

  var user;
  var usertrips = null;

  @override
  void initState() {
    // TODO: implement initState
    getUserData();
    super.initState();
  }

  getUserData() async {
    var userdata = await userRepository.fetchUserFromDB();
    usertrips = await userServices.alltrips(userdata.auth_key);
    print("<<<<<<<<<<<<<<<<11111>>>>>>>>>>>>>>>>.");
    print(usertrips);
    setState((){
      user = userdata;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Trip History'),
      ),
      body: new Container(
        child: new Column(
          children: <Widget>[
            // headWidget(),
            // paymentAndcoupons(),
            listWidgets()
          ],
        )
      ),
    );
  }

  Widget listWidgets(){
    print("++++++++++++++++++++++++++++++++++++++");
    print(usertrips);
    
    if(usertrips == null){
      return Center(child: CircularProgressIndicator());
    }else{

      List<Widget> alltrips = [];

      for(var i = 0; i < usertrips.length; i++ ){
        print("!!!!!!!!!!!!!!!!!");
        print(usertrips[i]);

        alltrips.add(
          tWidget(
            usertrips[i]["destination"].toString(),
            usertrips[i]["date"].toString(),
            usertrips[i]["booking_id"],
            usertrips[i]["amount"] != null  ? usertrips[i]["amount"].toString(): "0" ,
            usertrips[i]["trip_status"]
          )
        );
      }

      print("adsadsadadasdsadsadasdsasdasdasd");
      print(alltrips);
      return Flexible(
        child:ListView(
          children: alltrips
        )
      );

    }

  }

  Widget tWidget(String destination, String date, String bookingID, String amount, String trip_status){
    return new Card(
      child: GestureDetector(
        onTap: (){
          print("Container clicked");
        },
        child: new Column(
          children: <Widget>[
            ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Drop Location: "+destination,style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.025,color: Colors.black)),
                  Text(date,style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
                  Text(bookingID,style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.015,color: Colors.black)),
                ],
              ),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(amount ,style: TextStyle(fontSize: MediaQuery.of(context).size.height * 0.03,color: Colors.black)),
                  Text(trip_status,style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.red)),
                ],
              )
            )
          ],
        )
      )
    );
  }
}