import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:myan_lyca_client/services/CabTypeService.dart';
import 'package:myan_lyca_client/widgets/SideDrawerWidget.dart';
import '../services/GoogleMapApiService.dart';
// import '../widgets/CabTypeWidget.dart';
// import '../widgets/PaymentTypeWidget.dart';
import '../resources/UserRepository.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:qrscan/qrscan.dart' as scanner;
import 'package:flutter/cupertino.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingScreen extends StatefulWidget {
  @override
  State<BookingScreen> createState() => BookingScreenState();
}

enum ConfirmAction { CANCEL, ACCEPT }

class BookingScreenState extends State<BookingScreen> {
  bool loading = true;

  GoogleMapController mapController;
  GoogleMapsServices _googleMapsServices = GoogleMapsServices();
  Completer<GoogleMapController> _controller = Completer();
  var location = new Location();
  
  final Set<Marker> _markers = {};
  final Set<Polyline> _polyLines = {};
  Set<Polyline> get polyLines => _polyLines;
    
  static LatLng latLng;
  LatLng selectedCurrentLocation;
  LatLng selectedDestination;
  String selectedDestinationText;

  LocationData currentLocation;

  bool onCabSelectStep = true;
  bool onPaymentSelectStep = false;
  bool onDriverSideConfirmationStep = false;
  bool isDriverArrivedandStartedTrip = false;
  bool rideStarted = false;
  bool istripStarted = false;
  bool isTripCompleted = false;

  int tripDistance = 0;
  Timer _every10Sec = null;
  String _selectedPaymentMethod = "Wallet";

  BitmapDescriptor driverIcon;
  BitmapDescriptor destLocIcon;
  BitmapDescriptor curLocIcon;
  
  bool completeTripPOPUPShown = false;
  var userRepository = new UserRepository();
  
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final TextEditingController _typeAheadController = TextEditingController();

  String selectedCabTypeOption;
  String selectedCabTypeRate;
  bool _cabTypeBtnEnable = false;
  bool waitingForDriverConfirmation = false;
  // Map<String, bool> availCabCheckSign = {};
  var apiData;
  var cabTypeData;
  var user;
  var bookingId = null;
  var bookedDriverId = "";
  var bookedTripData = null;

  var availableCabsType;
  var cabbookingService = new CabTypeService();

  @override
  void initState(){
    loading = true;

    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(48, 48)), 'assets/images/drop-location.png')
        .then((onValue) {
      destLocIcon = onValue;
    });
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(48, 48)), 'assets/images/pick-location.png')
        .then((onValue) {
      curLocIcon = onValue;
    });
    BitmapDescriptor.fromAssetImage(ImageConfiguration(size: Size(48, 48)), 'assets/images/taxi.png')
        .then((onValue) {
          print('>>>><<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<, driver icon generated <<<<<');
      driverIcon = onValue;
    });

    getLocation();

    getUserData();
    
    if(_every10Sec == null){
      _every10Sec = new Timer.periodic(const Duration(seconds:10), (Timer t) => updateMarkersOfDriversNearMe());
    }

    new Timer.periodic(const Duration(seconds:3), (Timer t) => updateCurrentTripStatus());
    
    location.onLocationChanged.listen((  currentLocation) {
      latLng =  LatLng(currentLocation.latitude, currentLocation.longitude);
      print(" >>>>>>>>> current Location:$latLng <<<<<<<<<<<<");
      
      if(loading){
        setState(() {
          loading = false;
        });
      }
    });

    super.initState();
  }

  getUserData() async {
    var userdata = await userRepository.fetchUserFromDB();
    availableCabsType = await CabTypeService().getAvailableCabs(userdata.auth_key);
    setState((){
      user = userdata;
      // _getCabData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SideDrawerWidget(),
      // appBar: AppBar(),
      body: Center(
        child: Stack(
          children: <Widget>[
            googleMap(),
            setMyLocation(),
            // pickupLocationSearch(),
            dropLocationSearch(),
            Visibility(
              visible: onCabSelectStep,
              child: cabTypeWidget(),
            ),
            Visibility(
              visible: onPaymentSelectStep,
              child: paymentMethodSelectWidget(),
            ),
            Visibility(
              visible: onDriverSideConfirmationStep,
              child: waitingForDriverConfirmationWidget(),
            ),
            Visibility(
              visible: isDriverArrivedandStartedTrip,
              child: isDriverArrivedandStartedTripWidget(),
            ),
            Visibility(
              visible: istripStarted,
              child: tripStartedWidget(),
            ),
            Visibility(
              visible: isTripCompleted,
              child: completeTripPopUp(),
            ),
          ],
        ),
      )
    );
  }
  
  resetToCabSelectStep(){
    print("MOVE TO PAYMENT STEP");
    print(tripDistance);
  }

  moveToPaymentStep(){
    print("MOVE TO PAYMENT STEP");
    print(tripDistance);
  }

  getLocation() async {
    if(loading){
      currentLocation = await location.getLocation();
      selectedCurrentLocation = LatLng(currentLocation.latitude, currentLocation.longitude);
      cameraMove(currentLocation.latitude, currentLocation.longitude);
      _addMarker("cur_loc",LatLng(currentLocation.latitude, currentLocation.longitude));
    }else{
      // cameraMove(currentLocation.latitude, currentLocation.longitude);
      _addMarker("cur_loc",latLng);
    }
  }

  void onCameraMove(CameraPosition position) {
    latLng = position.target;
  }

  Future<void> cameraMove(double lat, double lng) async {
    final c = await _controller.future;
    final p = CameraPosition(target: LatLng(lat, lng), zoom: 14);
    c.animateCamera(CameraUpdate.newCameraPosition(p));
}

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  void drawPolylineRequest() async {
    Map<String, dynamic> routeData = await _googleMapsServices.getRouteCoordinates(selectedCurrentLocation, selectedDestination);
    createRoute(routeData["route"],routeData["distance"]);
    cameraMove(selectedDestination.latitude, selectedDestination.longitude);
    _addMarker("dest_loc",selectedDestination);
  }

  void createRoute(String encondedPoly, dynamic distance) {
    // set cab type widget back again 
    setState(() {
      onCabSelectStep = true;
      onPaymentSelectStep = false;
    });
    // trip distance used to calculate estimated fares
    tripDistance = distance;
    _polyLines.remove('ongoingTrip');
    _polyLines.add(Polyline(
      polylineId: PolylineId('ongoingTrip'),
      width: 3,
      points: _convertToLatLng(_decodePoly(encondedPoly)),
      color: Colors.black)
    );
  }

  void _addMarker(String markerId, LatLng location){
    BitmapDescriptor icon;
    bool isDraggable = false;

    if(markerId == "cur_loc"){
      icon = curLocIcon;
      isDraggable = true;
    }else if(markerId == "dest_loc"){
      isDraggable = true;
      icon = destLocIcon;
    }else{
      icon = driverIcon;
    }

    setState(() {
      // remove previous markers of this driver
      _markers.removeWhere((m) => m.markerId.value == markerId);
      // add new marker 
      _markers.add(Marker(
          markerId: MarkerId(markerId),
          position: location,
          // infoWindow: InfoWindow(title: address, snippet: "go here"),
          icon: icon,
          draggable: isDraggable,
          onDragEnd: ((value) {
            print(">>>>>>>>>>>>>>>>>> updating current location <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            if(markerId == "cur_loc" ){
              selectedCurrentLocation = value;
            }
          })
        )
      );
    });
  }

  void updateMarkersOfDriversNearMe() async {
    print("user.auth_key");
    print(user.auth_key);
    var drivers = await cabbookingService.getNearbyCabs(user.auth_key, currentLocation.latitude.toString(), currentLocation.longitude.toString());
    if(drivers.length > 0){
      for(var i=0; i<drivers.length;i++){
        if(drivers[i] != null){
          if( drivers[i]["latitude"] != null && double.parse(drivers[i]["longitude"]) != null ){
            print("Updateing Driver "+ drivers[i]["driver_id"] + " <<<<<<<<<<<<<<<<<<<<<<");
            _addMarker('driver-'+drivers[i]["driver_id"], LatLng(double.parse(drivers[i]["latitude"]), double.parse(drivers[i]["longitude"])) );
          }
        }
      }
    }
  }

  Widget googleMap(){
    return loading ? Container(color: Colors.white,child: Center(child: CircularProgressIndicator())): GoogleMap(
      // myLocationEnabled: true,
      polylines: polyLines,
        markers: _markers,
        mapType: MapType.normal,
      initialCameraPosition: CameraPosition(
        target: latLng,
        zoom: 14.0,
      ),
      onCameraMove:  onCameraMove,
      onMapCreated: (mapController) {
        _controller.complete(mapController);
      },
    );
  }

  Widget setMyLocation(){
    return Container(
      height: MediaQuery.of(context).size.height * 0.73,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FlatButton(
                onPressed: () {
                  getLocation();
                  cameraMove(currentLocation.latitude, currentLocation.longitude);
                  // drawPolylineRequest();
                },
                child: new Icon(
                  Icons.my_location,
                  color: Colors.black,
                  size: 20.0,
                ),
                shape: new CircleBorder(),
                color: Colors.white,
              ),
              Container(
              child: RaisedButton(
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
                onPressed: ()async { 
                  if(bookedDriverId != ""){
                    bookedDriverId = "";
                    setState(() {
                      onCabSelectStep = true;
                      onPaymentSelectStep = false;
                      onDriverSideConfirmationStep = false;
                      rideStarted = false;
                    });
                  }else{
                    await _scanQR();
                  }
                },
                textColor: Colors.white,
                color: Colors.red,
                padding: EdgeInsets.fromLTRB(5, 0, 5, 0),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0,0,0,0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[ 
                        Container(
                          color: Colors.red,
                          padding: EdgeInsets.fromLTRB(10, 4, 4, 4),
                          child: Text( bookedDriverId != "" ? "Unselect Scanned Driver" : 'Start Trip By Scan Code', style: TextStyle(color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(4, 0, 10, 0),
                          child: bookedDriverId != "" ? Icon(Icons.cancel) : Image.asset(
                            "assets/images/qr-code.png",
                            width: MediaQuery.of(context).size.width * 0.05
                          ),
                        ),
                      ],
                    )
                  )
                )
              )
            ],
          )
        ],
      )
    );
    // return Positioned(
    //   top: MediaQuery.of(context).size.height * 0.68,
    //   // left: MediaQuery.of(context).size.width * 0.52,
    //   child: 
    // );
  }
  Widget pickupLocationSearch(){
    return Positioned(
      top: 30.0,
      left: 15.0,
      right: 15.0,
      child: Container(
        height: 45.0,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: "Pickup Location",
            border: InputBorder.none,
            
          ),
        ),
      )
    );
  }

  Widget dropLocationSearch(){
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.05,
      left: MediaQuery.of(context).size.width * 0.03,
      right: MediaQuery.of(context).size.width * 0.03,
      child: Container(
        height: 45.0,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          color: Colors.white
        ),
        child: Container(
          color: Colors.white,
          child: Row(
            children: <Widget>[
              IconButton(
                splashColor: Colors.grey,
                icon: Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState.openDrawer();
                },
              ),
              Expanded(
                child: TypeAheadField(
                  textFieldConfiguration: TextFieldConfiguration(
                    controller: this._typeAheadController,
                    // autofocus: true,
                    // style: TextStyle(
                    //   fontStyle: FontStyle.italic
                    // ),
                    decoration: InputDecoration(
                      hintText: 'Where to?',
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    )
                  ),
                  suggestionsCallback: (pattern) async {
                    if(pattern != ""){
                      return await autoSearch(pattern);
                    }
                  },
                  itemBuilder: (context, suggestion) {
                    if(suggestion['name'] != null){
                      return ListTile(
                        title: Text(suggestion['name']),
                      );
                    }
                  },
                  onSuggestionSelected: (suggestion) async {
                    // var destCoord = await _googleMapsServices.latLngByPlaceId(suggestion['place_id']);
                    this._typeAheadController.text = suggestion["name"];
                    selectedDestination = LatLng(suggestion["lat"],suggestion["lng"]);
                    selectedDestinationText = suggestion["name"];
                    drawPolylineRequest();
                  },
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  autoSearch(keyword) async {
    var address = await _googleMapsServices.autocompletePlacesByName(keyword, currentLocation.latitude, currentLocation.longitude);
    print(address);
    return address;
  }

  List _decodePoly(String poly) {
    var list = poly.codeUnits;
    var lList = new List();
    int index = 0;
    int len = poly.length;
    int c = 0;
     do {
      var shift = 0;
      int result = 0;

      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
       if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

     for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    print(lList.toString());

    return lList;
  }

  void selectThisCab(id, title, price){
    setState((){
      selectedCabTypeRate = price;
      // availCabCheckSign[title] = true; //not needed now
      selectedCabTypeOption = id;
      if(tripDistance > 0){
        _cabTypeBtnEnable = true;
      }else{
        _cabTypeBtnEnable = false;
      }
    });
  }

  cabTypeWidget(){
    List<Widget> loopedChild = [];
    if(availableCabsType != null ){
      for(var i= 0; i < availableCabsType.length; i++){
        loopedChild.add(
          availCab(
            availableCabsType[i]['id'],
            availableCabsType[i]['image'],
            availableCabsType[i]['car_type'],
            availableCabsType[i]['status'] == "1" ? true : false,
            availableCabsType[i]['price'],
            // availCabCheckSign[availableCabsType[i]['car_type']],
            selectedCabTypeOption
          )
        );
      }
      return fixedLayout(loopedChild);
    }else{
      return fixedLayout(<Widget>[CircularProgressIndicator()]);
    }
  }

  Widget fixedLayout(List<Widget> loopedChild){
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.75,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.25,
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.white
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: loopedChild
            ),
            RaisedButton( 
              color: Colors.red,
              textColor: Colors.white,
              padding: EdgeInsets.all(5.0),
              onPressed: !_cabTypeBtnEnable ? null : (){
                setState(() {
                  onCabSelectStep = false;
                  onPaymentSelectStep = true;
                });
                moveToPaymentStep();
              },
              child: Container(
                width: MediaQuery.of(context).size.width * 0.70,
                child: Center(
                  child: Text(
                    'CONTINUE',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.030
                    ),
                  ),
                ),
              ),
            )
          ],
        )
      )
    );
  }

  Widget availCab(id, String img, String title, bool isAvail, price, showCheck){
    return GestureDetector(
      onTap: (){
        print("CABBB SELECTED $price");
        print(_cabTypeBtnEnable);
        selectThisCab(id, title, price);
      },
      child: Stack(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).size.height * 0.03,
              left : MediaQuery.of(context).size.width * 0.02,
              right : MediaQuery.of(context).size.width * 0.02
            ),
            child: Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    Image.network(
                      "http://mltaxi.codeartweb.com/"+img,
                      width: MediaQuery.of(context).size.width * 0.20
                    ),
                    SizedBox(height:MediaQuery.of(context).size.width * 0.030),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.035,
                        fontWeight: FontWeight.w900
                      ),
                    ),
                    Text(
                      isAvail ? "Avaiable" : "No Cabs",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.030,
                        color: isAvail ? Colors.green : Colors.red,
                        // fontWeight: FontWeight.w700
                      ),
                    )
                  ]
                ),
              ],
            )
          ),    
          !(showCheck == id) ? Container() : Positioned(
            bottom: MediaQuery.of(context).size.height * 0.075,
            right: MediaQuery.of(context).size.width * 0.007,
            child: Icon(Icons.check, color: Colors.red,size: 40)
          )   
        ],
      )
    );
  }

  Widget paymentMethodSelectWidget(){
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.75,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.25,
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.white
        ),
        child: Stack(
          children: <Widget>[
            Visibility(
              visible: waitingForDriverConfirmation,
              child: LinearProgressIndicator(),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Visibility(
                  visible: waitingForDriverConfirmation,
                  child: Center(
                    child: Text(
                      bookedDriverId != "" ? "Waiting for Driver to accept trip" : "Finding Nearby Cabs", 
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.050,
                        fontWeight: FontWeight.w500
                      )
                    )
                  )
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // LinearProgressIndicator(),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: new Container (
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                  value: _selectedPaymentMethod,
                                  items: [
                                    DropdownMenuItem(
                                      child: Container(
                                        child: Row(
                                          children: <Widget>[
                                            Image.asset(
                                              "assets/images/wallet.png",
                                              width: MediaQuery.of(context).size.width * 0.15
                                            ),
                                            Text("Wallet")
                                          ],
                                        ),
                                      ),
                                      value: "Wallet"
                                    ),
                                    DropdownMenuItem(
                                      child: Container(
                                        child: Row(
                                          children: <Widget>[
                                            Image.asset(
                                              "assets/images/payment@3x.png",
                                              width: MediaQuery.of(context).size.width * 0.15
                                            ),
                                            Text("Cash")
                                          ],
                                        ),
                                      ),
                                      value: "Cash"
                                    ),
                                  ],
                                  onChanged: (selectedItem){
                                    setState((){
                                      _selectedPaymentMethod = selectedItem;
                                    });
                                  }
                                )
                              ) 
                            )
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            "assets/images/payment@3x.png",
                            width: MediaQuery.of(context).size.width * 0.15
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                          Text("K "+
                            ((((tripDistance != 0 ? tripDistance : 0) * (selectedCabTypeRate != null ? int.parse(selectedCabTypeRate): 0 ))/1000) ).round().toString(),
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width * 0.050,
                              fontWeight: FontWeight.w500
                            ),
                          )
                        ],
                      ),
                    )
                    
                  ]
                ),
                SizedBox(height:MediaQuery.of(context).size.height * 0.030),  
                RaisedButton( 
                  color: Colors.red,
                  textColor: Colors.white,
                  padding: EdgeInsets.all(5.0),
                  onPressed: () async {
                    setState(() {
                      onCabSelectStep = false;
                      onPaymentSelectStep = true;
                      onDriverSideConfirmationStep = false;
                      waitingForDriverConfirmation = true;
                    });
                  await createTrip();
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.70,
                    child: Center(
                      child: Text(
                        'REQUEST TO GO',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.030
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        )
      )
    );
  }

  Widget isDriverArrivedandStartedTripWidget(){
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.75,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.25,
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.white
        ),
        child: Stack(
          children: <Widget>[
            Visibility(
              visible: true,
              child:LinearProgressIndicator() 
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Text(
                    bookedDriverId != "" ? "Waiting for driver confirmation" : "Driver arriving shortly", 
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.050,
                      fontWeight: FontWeight.w500
                    )
                  )
                ),
                SizedBox(height:20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            "assets/images/car@3x.png",
                            width: MediaQuery.of(context).size.width * 0.15
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                          Column(
                            children: <Widget>[
                              Text(
                                bookedTripData != null ? bookedTripData["driver_name"] : "",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.030,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              RatingBar(
                                initialRating: bookedTripData != null ? bookedTripData["driver_rating"] : 0,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                // itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                                itemBuilder: (context, _) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemSize: MediaQuery.of(context).size.width * 0.060,
                                onRatingUpdate: (rating) {
                                  print(rating);
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            "assets/images/car@3x.png",
                            width: MediaQuery.of(context).size.width * 0.15
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                          Column(
                            children: <Widget>[
                              Text( bookedTripData != null ? bookedTripData["car_number"] : "",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.030,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              Text(bookedTripData != null ? bookedTripData["car_name"] : "",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.020,
                                  color: Colors.grey
                                  // fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                    
                  ]
                ),
                SizedBox(height:MediaQuery.of(context).size.height * 0.030),  
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Visibility(
                      visible: rideStarted,
                      child: RaisedButton( 
                        color: Colors.red,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(5.0),
                        onPressed: () async {
                          print(bookedTripData != null ? bookedTripData["driver_contact_number"] : "");
                          String url = "tel:"+ (bookedTripData != null ? bookedTripData["driver_contact_number"] : "");   
                            if (await canLaunch(url)) {
                              await launch(url);
                            } else {
                              throw 'Could not launch $url';
                            } 
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.40,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(Icons.local_phone,color:Colors.white),
                                Text(
                                  'CALL DRIVER',
                                  style: TextStyle(
                                    fontSize: MediaQuery.of(context).size.width * 0.030
                                  ),
                                )
                              ]
                            ),
                          ),
                        ),
                      ),
                    ),  
                    Visibility(visible: rideStarted, child: SizedBox(width:10)),
                    Visibility(
                      visible: rideStarted,
                      child: RaisedButton( 
                        color: Colors.red,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(5.0),
                        onPressed: () async {
                          cancleTrip();
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.40,
                          child: Center(
                            child: Text(
                              'CANCLE TRIP',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.030
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),  
                  ],
                )
              ],
            )
          ],
        )
      )
    );
  }

  Widget tripStartedWidget(){
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.75,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.25,
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.white
        ),
        child: Stack(
          children: <Widget>[
            Visibility(
              visible: false,
              child:LinearProgressIndicator() 
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Text(
                    "Trip Started, Enjoy the Trip !", 
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.050,
                      fontWeight: FontWeight.w500
                    )
                  )
                ),
                SizedBox(height:20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            "assets/images/car@3x.png",
                            width: MediaQuery.of(context).size.width * 0.15
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                          Column(
                            children: <Widget>[
                              Text(
                                bookedTripData != null ? bookedTripData["driver_name"] : "",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.030,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              RatingBar(
                                initialRating: bookedTripData != null ? bookedTripData["driver_rating"] : 0,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                // itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                                itemBuilder: (context, _) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemSize: MediaQuery.of(context).size.width * 0.060,
                                onRatingUpdate: (rating) {
                                  print(rating);
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            "assets/images/car@3x.png",
                            width: MediaQuery.of(context).size.width * 0.15
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                          Column(
                            children: <Widget>[
                              Text( bookedTripData != null ? bookedTripData["car_number"] : "",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.030,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              Text(bookedTripData != null ? bookedTripData["car_name"] : "",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.020,
                                  color: Colors.grey
                                  // fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                    
                  ]
                ),
                SizedBox(height:MediaQuery.of(context).size.height * 0.030),  
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Visibility(
                      visible: istripStarted,
                      child: RaisedButton( 
                        color: Colors.red,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(5.0),
                        onPressed: () async {
                          completedTrip();
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.80,
                          child: Center(
                            child: Text(
                              'END TRIP',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.030
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),  
                  ],
                )
              ],
            )
          ],
        )
      )
    );
  }

  Widget waitingForDriverConfirmationWidget(){
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.75,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.25,
        width: MediaQuery.of(context).size.width,
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.white
        ),
        child: Stack(
          children: <Widget>[
            Visibility(
              visible: waitingForDriverConfirmation,
              child:LinearProgressIndicator() 
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            "assets/images/car@3x.png",
                            width: MediaQuery.of(context).size.width * 0.15
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                          Column(
                            children: <Widget>[
                              Text(
                                bookedTripData != null ? bookedTripData["driver_name"] : "",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.030,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              RatingBar(
                                initialRating: bookedTripData != null ? bookedTripData["driver_rating"] : 0,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                // itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                                itemBuilder: (context, _) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemSize: MediaQuery.of(context).size.width * 0.060,
                                onRatingUpdate: (rating) {
                                  print(rating);
                                },
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(
                            "assets/images/car@3x.png",
                            width: MediaQuery.of(context).size.width * 0.15
                          ),
                          SizedBox(width: MediaQuery.of(context).size.width * 0.05),
                          Column(
                            children: <Widget>[
                              Text( bookedTripData != null ? bookedTripData["car_number"] : "",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.030,
                                  fontWeight: FontWeight.w500
                                ),
                              ),
                              Text(bookedTripData != null ? bookedTripData["car_name"] : "",
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.020,
                                  color: Colors.grey
                                  // fontWeight: FontWeight.w500
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    )
                    
                  ]
                ),
                SizedBox(height:MediaQuery.of(context).size.height * 0.030),  
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Visibility(
                      visible: !rideStarted,
                      child: RaisedButton( 
                        color: Colors.white,
                        textColor: Colors.red,
                        padding: EdgeInsets.all(5.0),
                        onPressed: () async {
                          await cabbookingService.updateByTripID(user.auth_key, bookedTripData["booking_id"], "0"); //change 3 to unavailable
                          print("trip canclled");
                          cancleTrip();
                        // bookRideAndCretaeTrip();
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.40,
                          child: Center(
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.030
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Visibility(visible: !rideStarted, child: SizedBox(width:10)),
                    Visibility(
                      visible: !rideStarted,
                      child: RaisedButton( 
                        color: Colors.red,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(5.0),
                        onPressed: () async {
                          var userdata = await userRepository.fetchUserFromDB();
                          print("Accepting rider from user end");
                          await cabbookingService.updateByTripID(userdata.auth_key, bookedTripData["booking_id"],"7");
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.40,
                          child: Center(
                            child: Text(
                              'CONFIRM',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.030
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: rideStarted,
                      child: RaisedButton( 
                        color: Colors.red,
                        textColor: Colors.white,
                        padding: EdgeInsets.all(5.0),
                        onPressed: () async {
                          // var userdata = await userRepository.fetchUserFromDB();
                          // await cabbookingService.updateByTripID(userdata.auth_key, bookedTripData["booking_id"],"1");
                          // cameraMove(currentLocation.latitude, currentLocation.longitude);
                          print("call cancle trip >>>>>");
                          rideStarted = true;
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.40,
                          child: Center(
                            child: Text(
                              'CANCLE TRIP',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width * 0.030
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),  
                  ],
                )
              ],
            )
          ],
        )
      )
    );
  }

  // not of any use
  endTrip() async {
    await completedTrip();
    _polyLines.clear();
    _markers.removeWhere((m) => m.markerId.value == "dest_loc");
    cameraMove(currentLocation.latitude, currentLocation.longitude);
    setState(() {
      // bookedTripData = null;
      onCabSelectStep = false;
      onPaymentSelectStep = false;
      onDriverSideConfirmationStep = false;
      rideStarted = false;
      waitingForDriverConfirmation = false;
      isDriverArrivedandStartedTrip = false;
      istripStarted = false;
    });
  }

  cancleTrip() async {
    await cabbookingService.updateByTripID(user.auth_key, bookedTripData["booking_id"], "0");
    _polyLines.clear();
    _markers.removeWhere((m) => m.markerId.value == "dest_loc");
    cameraMove(currentLocation.latitude, currentLocation.longitude);
    setState(() {
      isTripCompleted = false;
      bookedTripData = null;
      onCabSelectStep = true;
      onPaymentSelectStep = false;
      onDriverSideConfirmationStep = false;
      rideStarted = false;
      waitingForDriverConfirmation = false;
      isDriverArrivedandStartedTrip = false;
      istripStarted = false;
    });
  }

  completedTrip() async {
    var trip_amount = ((((tripDistance != 0 ? tripDistance : 0) * (selectedCabTypeRate != null ? int.parse(selectedCabTypeRate): 0 ))/1000) ).round().toString();
    await cabbookingService.updateByTripID(user.auth_key, bookedTripData["booking_id"],"2");
    await cabbookingService.updateTripAmountByTripID(user.auth_key,bookedTripData["booking_id"],trip_amount,bookedTripData["status"].toString());
    setState(() {
      istripStarted = false;
      isTripCompleted = true;
      onCabSelectStep = false;
      onPaymentSelectStep = false;
      onDriverSideConfirmationStep = false;
      rideStarted = false;
      waitingForDriverConfirmation = false;
      isDriverArrivedandStartedTrip = false;
    });
  }

  completeTripPopUp(){
    return Visibility(
      visible: isTripCompleted,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Center(
                child: Container(
                  margin: EdgeInsets.only(top:50),
                  width: MediaQuery.of(context).size.width * 0.95,
                  child:Card(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                        Text(
                          "Trip completed!", 
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.060,
                            // fontWeight: FontWeight.w200
                          )
                        ),
                        // SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                        // Text(
                        //   bookedTripData != null ? bookedTripData["driver_name"] : "", 
                        //   style: TextStyle(
                        //     fontSize: MediaQuery.of(context).size.width * 0.040,
                        //     // fontWeight: FontWeight.w200
                        //   )
                        // ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                        Text(
                          "How is your trip?", 
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.060,
                            // fontWeight: FontWeight.w200
                          )
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                        Text(
                          "Your feedback will help in improving driving experience", 
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width * 0.030,
                            // fontWeight: FontWeight.w200
                          )
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                        RatingBar(
                          initialRating: bookedTripData != null ? bookedTripData["driver_rating"] : 0,
                          minRating: 1,
                          direction: Axis.horizontal,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.red,
                          ),
                          itemSize: MediaQuery.of(context).size.width * 0.080,
                          onRatingUpdate: (rating) {
                            print(rating);
                          },
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                        RaisedButton( 
                          color: Colors.red,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(5.0),
                          onPressed: () async {
                            print("review done");
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.50,
                            child: Center(
                              child: Text(
                                'Write Review',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.030
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                        RaisedButton( 
                          color: Colors.red,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(5.0),
                          onPressed: () async {
                            _paymentDialog(context);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.50,
                            child: Center(
                              child: Text(
                                'Pay Driver',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.030
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                        RaisedButton( 
                          color: Colors.red,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(5.0),
                          onPressed: () async {
                            _polyLines.clear();
                            _markers.removeWhere((m) => m.markerId.value == "dest_loc");
                            cameraMove(currentLocation.latitude, currentLocation.longitude);
                            setState(() {
                              isTripCompleted = false;
                              bookedTripData = null;
                              onCabSelectStep = true;
                              onPaymentSelectStep = false;
                              onDriverSideConfirmationStep = false;
                              rideStarted = false;
                              waitingForDriverConfirmation = false;
                              isDriverArrivedandStartedTrip = false;
                              istripStarted = false;
                            });
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.50,
                            child: Center(
                              child: Text(
                                'Exit',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width * 0.030
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                      ],
                    )
                  ),
                )
              ),
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.3,
                  height: MediaQuery.of(context).size.height * 0.15,
                  decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      image: new DecorationImage(
                          fit: BoxFit.cover,
                          image: new NetworkImage( 
                              user != null 
                                ? (user.profile_image != null ? "http://mltaxi.codeartweb.com/"+user.profile_image: "")
                                : "http://mltaxi.codeartweb.com/media/profileimage/profile-pic.jpg"
                          )
                      )
                  )
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  createTrip() async {
    // onCabSelectStep = false;
    // onPaymentSelectStep = false;
    // onDriverSideConfirmationStep = false;
    // waitingForDriverConfirmation = true;

    var tempbookId = await cabbookingService.createTripID(
      user.auth_key,
      selectedCabTypeOption.toString(),
      "User Current Location",
      currentLocation.latitude.toString(),
      currentLocation.longitude.toString(),
      selectedDestinationText != null ? selectedDestinationText : "Unknown",
      selectedDestination.latitude.toString(),
      selectedDestination.longitude.toString(),
      "w",
      ((((tripDistance != 0 ? tripDistance : 0) * (selectedCabTypeRate != null ? int.parse(selectedCabTypeRate): 0 ))/1000) ).round(),
      bookedDriverId
    );

    bookingId = tempbookId["booking_id"];
    bookedTripData = await cabbookingService.getBookingIdDataByAccessToken(user.auth_key, bookingId);

    print("!!!!!!!!!!!!! TRIP GENERATED:  $bookingId !!!!!!!!!!!!!!");

    // for(var i = 0; i < 50 ; i++){
    //   print(bookedTripData); 
    //   // if( bookedTripData["driver_id"] != null && bookedTripData["status"] == 6 ){
    //   if( bookedTripData["driver_id"] != null ){
    //     print(">>>>>>>>>>>>> DRIVER ACCEPETED CAB <<<<<<<<<<<<<<"+ bookedTripData["driver_id"].toString());
    //     setState(() {
    //       // bookedDriverId = 69;//temp["driver_id"];
    //       onCabSelectStep = false;
    //       onPaymentSelectStep = false;
    //       onDriverSideConfirmationStep = true;
    //       waitingForDriverConfirmation = false;
    //     });
    //     break;
    //   }else{
    //     await new Future.delayed(const Duration(seconds : 5));
    //   }
    // }
    // print("!!!!!!!!!!!!! TRIP GENERATED: END  $bookingId !!!!!!!!!!!!!!");
  }

  driverConfirmed(){
    // if( bookedTripData["driver_id"] != null && bookedTripData["status"] == 6 ){
    print(">>>>>>>>>>>>> DRIVER ACCEPETED CAB <<<<<<<<<<<<<<"+ bookedTripData["driver_id"].toString());
    setState(() {
      // bookedDriverId = 69;//temp["driver_id"];
      onCabSelectStep = false;
      onPaymentSelectStep = false;
      onDriverSideConfirmationStep = true;
      waitingForDriverConfirmation = false;
    });
  }

  tripStarted(){
    setState((){
      istripStarted = true;
      onCabSelectStep = false;
      onPaymentSelectStep = false;
      onDriverSideConfirmationStep = false;
      waitingForDriverConfirmation = false;

      
    });
  }
  
  updateCurrentTripStatus() async {
    print("::::::::");
    print(bookedTripData);
    print("::::::::");

    if(bookedTripData != null){
      bookedTripData = await cabbookingService.getBookingIdDataByAccessToken(user.auth_key, bookedTripData["booking_id"]);

      // cancled trip
      if(bookedTripData["status"] == 0){
        cancleTrip();
      }
      // trip started
      if(bookedTripData["status"] == 1  && bookedTripData["driver_id"] != null){
        tripStarted();
      }

      // trip complted
      if(bookedTripData["status"] == 2){
        if(!completeTripPOPUPShown){
          completeTripPOPUPShown = true;
          completedTrip();
        }
      }

      // trip unaviaklbe
      if(bookedTripData["status"] == 3){
        cancleTrip();
      }

      // trip free
      if(bookedTripData["status"] == 4){
        cancleTrip();
      }

      // trip booking pending for all online drivers
      if(bookedTripData["status"] == 5){
        
      }

      // booking confirmed by driver
      if(bookedTripData["status"] == 6 && bookedTripData["driver_id"] != null){
          driverConfirmed();
      }
      
      // booking confirmed by user now waiting for driver to start ride
      if(bookedTripData["status"] == 7 && bookedTripData["driver_id"] != null){
        cameraMove(currentLocation.latitude, currentLocation.longitude);
        rideStarted = true;
        waitingForDriverConfirmation = false;
        isDriverArrivedandStartedTrip = true;

        setState((){});
      }
    }
  }

  Future<String> _paymentDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false, // dialog is dismissible with a tap on the barrier
      builder: (BuildContext context) {
        return AlertDialog(
          title: Column(
            children: <Widget>[
              Text('Pay driver from wallet',style: TextStyle(fontSize: 30)),
              Text('Trip total amount: '+ bookedTripData["amount"],style: TextStyle(fontSize: 20))
            ],
          ),
          content: new Row(
            children: <Widget>[
              new Expanded(
                child: new TextField(
                  style: new TextStyle(
                    // color: Colors.white,
                    fontSize:  MediaQuery.of(context).size.width * 0.1,
                    fontWeight: FontWeight.w400
                  ),
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: new InputDecoration(
                    labelStyle: TextStyle(
                      fontSize: 30,
                    ),
                    labelText: 'Amount (K)', hintText: bookedTripData["amount"]),
                  onChanged: (value) {
                    print(value);
                  },
                )
              )
            ],
          ),
          actions: <Widget>[
            RaisedButton(
              color: Colors.grey,
              textColor: Colors.white,
              padding: EdgeInsets.all(10.0),
              child: const Text('Cancel',style: TextStyle(fontSize: 20)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            RaisedButton(
              color: Colors.green,
              textColor: Colors.white,
              padding: EdgeInsets.all(10.0),
              child: const Text('Pay',style: TextStyle(fontSize: 20)),
              onPressed: () {
                // Navigator.of(context).pop(teamName);
              },
            )
          ],
        );
      },
    );
  }

  Future _scanQR() async {
    try {
      String cameraScanResult = await scanner.scan();
      print("Scannnnnnnn on booking page");
      print(cameraScanResult);
      bookedDriverId = cameraScanResult;
      setState(() {
        
      });
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
  void dispose() {
    _every10Sec.cancel();
    _every10Sec = null;
    super.dispose();
  }
} 