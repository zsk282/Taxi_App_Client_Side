import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../resources/UserRepository.dart';

class SideDrawerWidget extends StatefulWidget {
  @override
  State<SideDrawerWidget> createState() {
    return SideDrawerWidgetState();
  }
}

class SideDrawerWidgetState extends State<SideDrawerWidget> {
  int _selectedDrawerIndex = 0;
  var userRepository = new UserRepository();
  var user;
  @override
  void initState() {
    // TODO: implement initState
    getUserData();
    super.initState();
  }

  getUserData() async {
    var userdata = await userRepository.fetchUserFromDB();
    setState(() {
      user = userdata;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
              flex: 1,
              child: new GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.pushNamed(context, '/EditProfileScreen');
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: DrawerHeader(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/images/sidebar-bg.png"),
                              fit: BoxFit.cover)),
                      child: Container(
                        child: Row(
                          children: [
                            Container(
                                width: MediaQuery.of(context).size.width * 0.2,
                                height:
                                    MediaQuery.of(context).size.height * 0.1,
                                decoration: new BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: new DecorationImage(
                                        fit: BoxFit.cover,
                                        image: new NetworkImage(user != null
                                            ? (user.profile_image != null
                                                ? "http://mltaxi.codeartweb.com/" +
                                                    user.profile_image
                                                : "")
                                            : "http://mltaxi.codeartweb.com/media/profileimage/profile-pic.jpg")))),
                            Container(
                              margin: EdgeInsets.only(
                                  left:
                                      MediaQuery.of(context).size.width * 0.03,
                                  right:
                                      MediaQuery.of(context).size.width * 0.03),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    user != null
                                        ? (user.first_name != null
                                            ? user.first_name
                                            : "")
                                        : "",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    user != null
                                        ? (user.mobile != null
                                            ? user.mobile
                                            : "")
                                        : "",
                                    style: TextStyle(color: Colors.white),
                                  )
                                ],
                              ),
                            ),
                            Container(
                                alignment: Alignment.centerRight,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size:
                                            MediaQuery.of(context).size.width *
                                                0.05)
                                  ],
                                ))
                          ],
                        ),
                      ),
                    ),
                  ))),
          Expanded(
            flex: 3,
            child: ListView(children: [
              ListTile(
                title: Text("Home"),
                leading: Icon(Icons.home),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/BookingScreen');
                },
              ),
              ListTile(
                title: Text("My Wallet"),
                leading: Icon(Icons.account_balance_wallet),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/MyWalletScreen');
                },
              ),
              // ListTile(
              //   title: Text("QR Code"),
              //   leading: Icon(Icons.code),
              //   onTap: () {
              //     Navigator.of(context).pop();
              //     Navigator.pushNamed(context, '/QRScanner');
              //   },
              // ),
              ListTile(
                title: Text("History"),
                leading: Icon(Icons.history),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/HistoryScreen');
                },
              ),
              // ListTile(
              //   title: Text("Notification"),
              //   leading: Icon(Icons.notifications),
              //   onTap: () {
              //     Navigator.of(context).pop();
              //     Navigator.pushNamed(context, '/NotificationScreen');
              //   },
              // ),
              ListTile(
                leading: Icon(Icons.card_giftcard),
                title: Text("Invite Friends"),
                onTap: () {
                  // Navigator.of(context).pop();
                  // Navigator.pushNamed(context, '/InviteScreen');
                  launch("http://myanlycataxi.com");
                },
              ),
              // ListTile(
              //   leading: Icon(Icons.settings),
              //   title: Text("Settings"),
              //   onTap: () {
              //     Navigator.of(context).pop();
              //     Navigator.pushNamed(context, '/SettingsScreen');
              //   },
              // ),
              ListTile(
                leading: Icon(Icons.exit_to_app),
                title: Text("Logout"),
                onTap: () {
                  userRepository.logoutUser();
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/');
                },
              )
            ]),
          )
        ],
      ),
    );
  }
}
