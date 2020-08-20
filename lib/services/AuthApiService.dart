/**
 * Call API and get resposne from there no modification here in response other than parsing
 */
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiService {
  String base_url = 'http://mltaxi.codeartweb.com/api/';

  Future<String> getOTP(
      String countryMobileCode,
      String mobileNumber,
      String deviceId,
      String fname,
      String lname,
      String email,
      String sId,
      String sName) async {
    final http.Response response = await http.post(
      base_url + 'login/index',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
      },
      body: jsonEncode({
        "Users": {"mobile": mobileNumber, "device_id": deviceId}
      }),
    );

    var temp = json.decode(response.body);
    print(temp);
    if (temp['success'].toString() == 'true') {
      temp = temp['data'];
      temp = temp['user'];
      temp = temp['otp'].toString();
      return temp;
    } else {
      var otp = await this.registerUser(countryMobileCode, mobileNumber,
          deviceId, fname, lname, email, sId, sName);
      return otp;
      // throw Exception('Failed to fetch login data API');
    }
  }

  getSocialLogin(String socialId, String socialType) async {
    final http.Response response = await http.post(
      base_url + 'user/get-user-social-status',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
      },
      body: jsonEncode({"social_id": socialId, "social_type": socialType}),
    );

    var temp = json.decode(response.body);
    print("SOCAILL MEDIA LOGIN CHECK ");
    print(temp);
    if (temp['success'].toString() == 'true') {
      temp = temp['data'];
      return temp;
    } else {
      return null;
      // throw Exception('Failed to fetch login data API');
    }
  }

  Future<String> registerUser(
      String countryCode,
      String mobileNumber,
      String deviceId,
      String fname,
      String lname,
      String email,
      String sId,
      String sName) async {
    print("???????????????????????????");
    print(jsonEncode({
      "Users": {
        "first_name": fname,
        "last_name": lname,
        "email": email,
        "countryCode": countryCode,
        "mobile": mobileNumber,
        "device_id": deviceId,
        "social_id": sId,
        "social_type": sName,
      }
    }));
    final http.Response response = await http.post(
      base_url + 'register/sign-up',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
      },
      body: jsonEncode({
        "Users": {
          "first_name": fname,
          "last_name": lname,
          "email": email,
          "countryCode": countryCode,
          "mobile": mobileNumber,
          "device_id": deviceId,
          "social_id": sId,
          "social_type": sName,
        }
      }),
    );

    var temp = json.decode(response.body);
    if (temp['success'].toString() == 'true') {
      temp = temp['data'];
      temp = temp['user'];
      temp = temp['otp'].toString();
      return temp;
    } else {
      throw Exception('Failed to fetch user and also unable to register');
    }
  }

  Future<String> validateOTP(String mobile, String otp) async {
    final http.Response response = await http.post(
      base_url + 'login/verify-otp',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
      },
      body: json.encode({
        "MobileLoginForm": {"username": mobile, "otp": otp}
      }),
    );
    var temp = json.decode(response.body);
    print(temp);

    if (temp['success'].toString() == "true") {
      temp = temp['data'];
      temp = temp['users'];
      temp = temp['auth_key'];
      return temp;
      // return 'a50ff92ea1f23e1fabac067d0d7c074b';//temp;
    } else {
      // return 'a50ff92ea1f23e1fabac067d0d7c074b';//temp;
      throw Exception('Failed to fetch Login step 2 data API');
    }
  }
}
