import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
const apiKey = "AIzaSyCCGeITRzeGBOrjDEaVqwM0H6Ug-NtqmcU";

class GoogleMapsServices{
  Future<Map<String, dynamic>> getRouteCoordinates(LatLng l1, LatLng l2)async{
    String url = "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude},${l2.longitude}&key=$apiKey";
    print(url);
    http.Response response = await http.get(url);
    Map values = jsonDecode(response.body);
    return { "route": values["routes"][0]["overview_polyline"]["points"], "distance": values["routes"][0]["legs"][0]["distance"]["value"]};
  }
  
  Future autocompletePlacesByName(String keyword, double lat, double lng) async {
    String language = 'en';
    List results = [];

    // String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$keyword&types=geocode&language=$language&key=$apiKey";
    // String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$keyword&types=geocode&language=$language&components=country:in&key=$apiKey";
    // String url = "https://maps.googleapis.com/maps/api/place/textsearch/json?location=$lat,$lng&radius=50000&query=$keyword&key=$apiKey";
    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$keyword&type=geocode&types=address&types=establishment&language=my&key=AIzaSyCCGeITRzeGBOrjDEaVqwM0H6Ug-NtqmcU&location=$lat,$lng&radius=5000&components=country:in";
    String urladdress = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$keyword&types=address&language=my&key=AIzaSyCCGeITRzeGBOrjDEaVqwM0H6Ug-NtqmcU&location=$lat,$lng&radius=5000&components=country:in";
    String urlestablishment = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$keyword&types=establishment&language=my&key=AIzaSyCCGeITRzeGBOrjDEaVqwM0H6Ug-NtqmcU&location=$lat,$lng&radius=5000&components=country:in";
    
    http.Response response1 = await http.get(url);
    var values1 = jsonDecode(response1.body);
    values1 = values1['predictions'];
    http.Response response2 = await http.get(urladdress);
    var values2 = jsonDecode(response2.body);
    values2 = values2['predictions'];
    http.Response response3 = await http.get(urlestablishment);
    var values3 = jsonDecode(response3.body);
    values3 = values3['predictions'];

    var resp = values1+values2+values3;

    // print(response.body);
    // values = jsonDecode(values);
    print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    print(resp);
    print("++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
    if(resp.length > 0){
      for(var i=0; i < resp.length; i++){
        results.add({
          "name": resp[i]["description"],
          "place_id": resp[i]["place_id"],
          // "lat": values[i]["geometry"]["location"]["lat"],
          // "lng": values[i]["geometry"]["location"]["lng"],
        });  
      }
    }
    return results;//values["routes"][0]["overview_polyline"]["points"];
  }
  
  Future latLngByPlaceId(String placeid) async {
    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeid&fields=geometry&key=$apiKey";
    http.Response response = await http.get(url);
    Map values = jsonDecode(response.body);
    return values["result"]["geometry"]["location"];
  }
}