import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  @override
  NotificationScreenState createState() => NotificationScreenState();
}

class NotificationScreenState extends State<NotificationScreen> {
  @override
  initState() {
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan Myan Code"),
      ),
      body:  new Column(
        children: <Widget>[
          listWidgets()
        ],
      )
    );
  }

  Widget listWidgets(){
    return Flexible(
      child:ListView(
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Email Signup Notification',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
            trailing: Icon(Icons.check_box, color: Colors.green),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Cab booking Confirmation',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
            trailing: Icon(Icons.check_box, color: Colors.green),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Trip Completed',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
            trailing: Icon(Icons.check_box, color: Colors.green),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Cab Cancelled',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
            trailing: Icon(Icons.warning, color: Colors.yellow),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Payment Pending',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
            trailing: Icon(Icons.payment, color: Colors.red),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Email Signup Notification',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
            trailing: Icon(Icons.check_box, color: Colors.green),
          ),
          ListTile(
            leading: Icon(Icons.email),
            title: Text('Cab booking Confirmation',style: TextStyle(fontSize:  MediaQuery.of(context).size.height * 0.02,color: Colors.black)),
            trailing: Icon(Icons.check_box, color: Colors.green),
          ),
        ]
      )
    );
  }
}