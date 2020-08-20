import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'dart:io';
import 'package:async/async.dart';

class UserApiService {
  String base_url = 'http://mltaxi.codeartweb.com/api/user/';

  Future<Map<String, dynamic>> getUserByAccessToken(String accessToken) async {
    final response =
        await http.get(base_url + "user-data?access_token=" + accessToken);
    var temp;

    if (response.statusCode == 200) {
      temp = json.decode(response.body);
    } else {
      throw Exception('Failed call get getUserByAccessToken method');
    }

    if (temp['success'].toString() == 'true') {
      temp = temp['data'];
      temp = temp['user'];
      return temp;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>> updateUserByAccessToken(
      String accessToken, Map data) async {
    final http.Response response = await http.post(
      base_url + "edit-profile?access_token=" + accessToken,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
      },
      body: json.encode(data),
    );
    var temp = json.decode(response.body);
    if (temp['success'].toString() == 'true') {
      temp = temp['data'];
      temp = temp['user'];
      temp['auth_key'] =
          accessToken; //returning same auth key as this will be same but not returend in API
      return temp;
    } else {
      throw Exception('Failed to fetch login data API');
    }
  }

  // Future<Map<String,dynamic>> updateImageByAccessToken(String accessToken, filename, url) async {
  //   var request = http.MultipartRequest('POST', Uri.parse(url));
  //   request.files.add(await http.MultipartFile.fromPath('picture', filename));
  //   var response = await request.send();
  //   print(response.reasonPhrase);
  //   return null;
  //   // var temp = json.decode(response.reasonPhrase);

  //   // if (temp['success'].toString() == 'true') {
  //   //   temp = temp['data'];
  //   //   temp = temp['user'];
  //   //   return temp;
  //   // } else {
  //   //   throw Exception('Failed to fetch login data API');
  //   // }
  // }

  updateImageByAccessToken(String accessToken, imageFile) async {
    var request = http.MultipartRequest('POST',
        Uri.parse(base_url + "upload-image?access_token=" + accessToken));
    request.files
        .add(await http.MultipartFile.fromPath('Users[avatar]', imageFile));

    var response = await request.send();
    var respStr = await response.stream.bytesToString();

    var temp = json.decode(respStr);

    if (temp['success'].toString() == 'true') {
      temp = temp['data'];
      temp = temp['user'];
      return temp;
    } else {
      throw Exception('Failed to fetch login data API');
    }
  }

  Future<Map<String, dynamic>> payDriverByAccessToken(String accessToken,
      String driver_id, String amount, String booking_id) async {
    print(base_url + "pay-to-driverby-wallet?access_token=" + accessToken);
    print({"driver_id": driver_id, "amount": amount, "booking_id": booking_id});
    final http.Response response = await http.post(
      base_url + "pay-to-driverby-wallet?access_token=" + accessToken,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
      },
      body: json.encode(
          {"driver_id": driver_id, "amount": amount, "booking_id": booking_id}),
    );
    var temp = json.decode(response.body);
    
    return json.decode(response.body);
  }

  Future ratingSubmitForDriver(String accessToken, String booking_id,
      String feedback, String rating, String type) async {
    final http.Response response = await http.post(
      base_url + "rating-submit-by-user?access_token=" + accessToken,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
      },
      body: json.encode({
        "type": type,
        "rating": rating,
        "feedback": feedback,
        "booking_id": booking_id
      }),
    );
    return json.decode(response.body);
  }

  Future availCoupon(String accessToken, String promo_code) async {
    final http.Response response = await http.post(
      base_url + "redeem-coupon?access_token=" + accessToken,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
      },
      body: json.encode({"promo_code": promo_code}),
    );

    var temp = json.decode(response.body);
    if (temp['success'].toString() == 'true') {
      temp = temp["data"];
      // temp = temp["discount"];
      return temp;
    } else {
      return false;
    }
  }

  Future alltrips(String accessToken) async {
    final response = await http.get(
        base_url + "total-rides?access_token=" + accessToken + "&type=user");
    var temp;

    if (response.statusCode == 200) {
      temp = json.decode(response.body);
    } else {
      throw Exception('Failed call get getwalletAmountByAccessToken method');
    }

    if (temp['success'].toString() == 'true') {
      temp = temp['data'];
      temp = temp['users'];
      return temp;
    } else {
      throw Exception('Failed to fetch previous trips by API');
    }
  }

  Future getUserWalletAmountByAccessToken(String accessToken) async {
    final response =
        await http.get(base_url + "wallet-balance?access_token=" + accessToken);
    var temp;

    if (response.statusCode == 200) {
      temp = json.decode(response.body);
    } else {
      throw Exception('Failed call get getwalletAmountByAccessToken method');
    }

    if (temp['success'].toString() == 'true') {
      temp = temp['data'];
      return temp;
    } else {
      throw Exception('Failed to fetch wallet amount data API');
    }
  }

  Future getUserWalletTransactionsByAccessToken(String accessToken) async {
    return http.get(base_url + "payments-details?access_token=" + accessToken);
    // var temp;

    // if (response.statusCode == 200) {
    //   temp = json.decode(response.body);
    // } else {
    //   throw Exception('Failed call get getwalletAmountByAccessToken method');
    // }

    // if (temp['success'].toString() == 'true') {
    //   temp = temp['data'];
    //   return temp;
    // } else {
    //   throw Exception('Failed to fetch wallet amount data API');
    // }
  }
}
