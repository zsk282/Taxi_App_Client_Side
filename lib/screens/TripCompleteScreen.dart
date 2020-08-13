import 'package:flutter/material.dart';
import '../widgets/SideDrawerWidget.dart';
import '../resources/UserRepository.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:myan_lyca_client/services/CabTypeService.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class TripCompleteScreen extends StatefulWidget {
  @override
  TripCompleteScreenState createState() => TripCompleteScreenState();
}

class TripCompleteScreenState extends State<TripCompleteScreen> {
  var user = null;
  var userRepository = new UserRepository();
  var bookedTripData = null;

  var cabbookingService = new CabTypeService();

  @override
  void initState() {
    // TODO: implement initState
    getUserData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: new AppBar(
          title: new Text('Trip Completed'),
        ),
        body: Container(
            child: SingleChildScrollView(
          child: Container(),
        ))

        // Column(
        //   children: [
        //     Stack(
        //       children: <Widget>[
        //         Container(
        //           width: MediaQuery.of(context).size.width,
        //           height: MediaQuery.of(context).size.width * 0.30,
        //           decoration: BoxDecoration(
        //             image: DecorationImage(
        //               image: AssetImage("assets/images/sidebar-bg.png"),
        //               fit: BoxFit.cover,
        //             ),
        //           ),
        //           child: Container()
        //         ),
        //         Center(
        //           child: Container(
        //             margin: EdgeInsets.only(top:MediaQuery.of(context).size.width * 0.15),
        //             width: MediaQuery.of(context).size.width * 0.3,
        //             height: MediaQuery.of(context).size.width * 0.3,
        //             decoration: new BoxDecoration(
        //                 shape: BoxShape.circle,
        //                 image: new DecorationImage(
        //                     fit: BoxFit.cover,
        //                     image: new NetworkImage(
        //                       "http://3.128.103.238/media/default/default_car_image.png" //+user.profile_image
        //                     )
        //                 )
        //             )
        //           )
        //         )
        //       ],
        //     ),
        //     Container(
        //       width: MediaQuery.of(context).size.width * 0.80,
        //       child: Container()
        //     )
        //   ],
        // )
        );
  }

  getUserData() async {
    var userdata = await userRepository.fetchUserFromDB();
    var data = await cabbookingService.getBookingIdDataByAccessToken(
        userdata.auth_key, "MLT1592046751158");

    setState(() {
      user = userdata;
      bookedTripData = data;
    });
  }
}
