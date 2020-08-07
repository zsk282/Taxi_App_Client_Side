import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/AuthApiService.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../resources/UserRepository.dart';
import 'package:device_info/device_info.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  createState() {
    return LoginState();
  }
}

class LoginState extends State<LoginScreen> {
  String countryMobileCode;
  String mobileNumber;
  String otp;
  String deviceOTP;
  String userAccessToken;

  bool isOtp = false;
  bool allowGetOtp = false;
  bool allowloginCall = false;
  var isAlreadySociallyLogin = null;

  UserRepository userRepository = new UserRepository();
  var googleSignedInVal = null;
  var socialMediaRegister = false;
  var facebookValues = null;
  var loginObj = new AuthApiService();

  final facebookLogin = FacebookLogin();

  GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
      // 'https://www.googleapis.com/auth/user.emails.readonly',
      // 'https://www.googleapis.com/auth/user.phonenumbers.readonly',
      // 'https://www.googleapis.com/auth/userinfo.email',
    ],
  );

  @override
  void initState() {
    // TODO: implement initState
    isOtp = false;
    allowGetOtp = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/signup-bg.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              whiteLogo(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              whitePlainText(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              mobileNumberInput(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              Visibility(visible: !socialMediaRegister, child: divider()),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              Visibility(
                  visible: !socialMediaRegister, child: facebookLoginButton()),
              Visibility(
                  visible: !socialMediaRegister, child: googleLoginButton()),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              consent(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            ],
          )),
    );
  }

  Widget facebookLoginButton() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      child: SignInButtonBuilder(
        text: 'Continue with Facebook',
        icon: FontAwesomeIcons.facebookF,
        onPressed: () async {
          print("11111111111111111111111111");
          final result = await facebookLogin.logIn(['email']);
          final token = result.accessToken.token;
          final graphResponse = await http.get(
              'https://graph.facebook.com/v2.12/me?fields=name,first_name,last_name,email&access_token=${token}');
          final profile = json.decode(graphResponse.body);

          if (profile != null) {
            print(">>>>> Login by facebook login");
            print(profile);
            isAlreadySociallyLogin =
                await loginObj.getSocialLogin(profile['id'], "facebook");

            if (isAlreadySociallyLogin != null) {
              print("already logged in earlier with facebook");
              print(isAlreadySociallyLogin);
              LoginWithSocialId(isAlreadySociallyLogin["users"]["auth_key"]);
            } else {
              setState(() {
                facebookValues = profile;
                socialMediaRegister = true;
              });
            }
          }
        },
        backgroundColor: Color(0xFF3B5998),
        // width: MediaQuery.of(context).size.width * 0.5,
      ),
    );
  }

  Widget googleLoginButton() {
    return Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: SignInButtonBuilder(
          text: 'Continue with Google',
          icon: FontAwesomeIcons.google,
          onPressed: () {
            // Navigator.pushReplacementNamed(context, '/BookingScreen');
            print("called for GMAIL authentication");
            _handleSignIn();
          },
          backgroundColor: Color.fromRGBO(234, 54, 39, 0.54),
          // width: MediaQuery.of(context).size.width * 0.5,
        ));
  }

  Future<void> _handleSignIn() async {
    try {
      googleSignedInVal = await _googleSignIn.signIn();
      print(googleSignedInVal);
      if (googleSignedInVal != null) {
        isAlreadySociallyLogin =
            await loginObj.getSocialLogin(googleSignedInVal.id, "gmail");

        if (isAlreadySociallyLogin != null) {
          print("already logged in earlier GMAIL");
          print(isAlreadySociallyLogin);
          LoginWithSocialId(isAlreadySociallyLogin["users"]["auth_key"]);
        } else {
          setState(() {
            print("Gmail Sign in passed");
            print(googleSignedInVal);
            socialMediaRegister = true;
          });
        }
      }
    } catch (error) {
      print(">>>>>>>>>>>>>>>>>>>>");
      print(error);
    }
  }

  Widget divider() {
    return Container(
        margin: EdgeInsets.only(top: 30.0),
        child: Center(
            child: Row(
          children: <Widget>[
            // Text('OR',style: TextStyle(fontSize: 17.0,color: Colors.white)),
            SizedBox(
                height: MediaQuery.of(context).size.width * 0.001,
                child: Container(
                  margin: new EdgeInsetsDirectional.only(
                      start: MediaQuery.of(context).size.width * 0.16,
                      end: 0.0),
                  // height: 1.0,
                  width: MediaQuery.of(context).size.width * 0.3,
                  color: Colors.white,
                )),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(width: 0.7, color: Colors.white),
                shape: BoxShape.circle,
                // You can use like this way or like the below line
                //borderRadius: new BorderRadius.circular(30.0),
                // color: Colors.white,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text('OR',
                      style: TextStyle(fontSize: 15.0, color: Colors.white))
                ],
              ),
            ),
            SizedBox(
                height: MediaQuery.of(context).size.width * 0.001,
                child: Container(
                  margin: new EdgeInsetsDirectional.only(
                      start: 0.0, end: MediaQuery.of(context).size.width * 0.1),
                  // height: 1.0,
                  width: MediaQuery.of(context).size.width * 0.3,
                  color: Colors.white,
                )),
          ],
        )));
  }

  Widget consent() {
    return Center(
        child: Container(
      // margin: EdgeInsets.only(top:MediaQuery.of(context).size.height * 0.1),
      child: Column(children: <Widget>[
        Text(
          "By signing up you agree to our",
          style: TextStyle(
              color: Colors.white,
              // height: 1,
              fontSize: MediaQuery.of(context).size.width * 0.02),
        ),
        Text(
          "Terms of use",
          style: TextStyle(
              color: Colors.white,
              // height: 2,
              fontSize: MediaQuery.of(context).size.width * 0.02),
        ),
      ]),
    ));
  }

  Widget mobileNumberInput() {
    if (isOtp) {
      // if mobile number is entered already and now entering OTP
      return Container(
        alignment: Alignment(0.0, 0.0),
        child: Wrap(
          children: <Widget>[
            Container(
                width: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 1.0, color: Colors.white),
                  ),
                ),
                child: TextField(
                  onChanged: (value) {
                    if (value.length == 6) {
                      print(
                          '<<<<<<<<<<<<<<<<<<<<<<<< $value >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
                      setState(() {
                        otp = value;
                        allowloginCall = true;
                      });
                    } else {
                      print('Mobile less than 10 taking no action');
                    }
                  },
                  autocorrect: true,
                  style: new TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontWeight: FontWeight.w400),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(6),
                    WhitelistingTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                      hintText: 'Enter OTP',
                      hintStyle: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.04,
                          color: Colors.white),
                      border: InputBorder.none,
                      suffixIcon: Visibility(
                        visible: isOtp,
                        child: IconButton(
                            color: Colors.white,
                            icon: Icon(Icons.keyboard_arrow_right,
                                color: Colors.white),
                            onPressed: () {
                              validateOtpAndGetAccessToken(mobileNumber, otp);
                            }),
                      )),
                ))
          ],
        ),
      );
    } else {
      // entering mobile number first step of login
      return Container(
        alignment: Alignment(0.0, 0.0),
        child: Wrap(
          children: <Widget>[
            Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 1.0, color: Colors.white),
                  ),
                ),
                child: CountryCodePicker(
                  onChanged: (value) {
                    countryMobileCode = value.dialCode;
                  },
                  // Initial selection and favorite can be one of code ('IT') OR dial_code('+39')
                  initialSelection: 'MM',
                  //  favorite: ['+39','FR'],
                  // optional. Shows only country name and flag
                  showCountryOnly: false,
                  // optional. Shows only country name and flag when popup is closed.
                  showOnlyCountryWhenClosed: false,
                  // optional. aligns the flag and the Text left
                  alignLeft: false,
                  textStyle: TextStyle(
                      fontSize: MediaQuery.of(context).size.height * 0.02,
                      color: Colors.white),
                )),
            Container(
                width: MediaQuery.of(context).size.width * 0.5,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(width: 1.0, color: Colors.white),
                  ),
                ),
                child: TextField(
                  onChanged: (value) {
                    if (value.length == 10) {
                      print(
                          '<<<<<<<<<<<<<<<<<<<<<<<< $value >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>');
                      mobileNumber = value;
                      // getOtp(countryMobileCode,mobileNumber);
                      setState(() {
                        allowGetOtp = true;
                      });
                    } else {
                      setState(() {
                        allowGetOtp = false;
                      });
                      print('Mobile less than 10 taking no action');
                    }
                  },
                  autocorrect: true,
                  style: new TextStyle(
                      color: Colors.white,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontWeight: FontWeight.w400),
                  textAlign: TextAlign.left,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: <TextInputFormatter>[
                    LengthLimitingTextInputFormatter(10),
                    WhitelistingTextInputFormatter.digitsOnly
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter your mobile number',
                    hintStyle: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        color: Colors.white),
                    border: InputBorder.none,
                    suffixIcon: Visibility(
                      visible: allowGetOtp,
                      child: IconButton(
                          color: Colors.white,
                          icon: Icon(Icons.keyboard_arrow_right,
                              color: Colors.white),
                          onPressed: () {
                            getOtp(countryMobileCode, mobileNumber);
                            setState(() {
                              isOtp = true;
                            });
                          }),
                    ),
                  ),
                ))
          ],
        ),
      );
    }
  }

  Widget background() {
    return Container(
        decoration: BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/images/signup-bg.png"),
        fit: BoxFit.cover,
      ),
    ));
  }

  Widget whiteLogo() {
    return Container(
      margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.3,
          right: MediaQuery.of(context).size.width * 0.3),
      child: Image.asset("assets/images/logo-white.png"),
    );
  }

  Widget whitePlainText() {
    return Container(
        child: Text(
      socialMediaRegister
          ? "Enter Mobile Number to Continue"
          : "Login/Signup With",
      style: TextStyle(
          color: Colors.white,
          // height: MediaQuery.of(context).size.width * 0.005,
          fontSize: MediaQuery.of(context).size.width * 0.05),
    ));
  }

  getOtp(String countryMobileCode, String mobileNumber) async {
    String deviceId = await _getId();

    print(">>>>>>>>>>>>>> mobile NUMEBR" + mobileNumber);
    print(">>>>>>>>>>>>> device ID" + deviceId);

    String fname = "";
    String lname = "";
    String email = "";
    String sId = "";
    String sName = "";

    if (googleSignedInVal != null) {
      fname = googleSignedInVal != null
          ? (googleSignedInVal.displayName != null
              ? googleSignedInVal.displayName
              : "")
          : "";
      lname = googleSignedInVal != null
          ? (googleSignedInVal.displayName != null
              ? googleSignedInVal.displayName
              : "")
          : "";
      email = googleSignedInVal != null
          ? (googleSignedInVal.email != null ? googleSignedInVal.email : "")
          : "";
      sId = googleSignedInVal != null
          ? (googleSignedInVal.id != null ? googleSignedInVal.id : "")
          : "";
      sName = googleSignedInVal != null ? "gmail" : "";
    }

    if (facebookValues != null) {
      fname = facebookValues != null
          ? (facebookValues['first_name'] != null
              ? facebookValues['first_name']
              : "")
          : "";
      lname = facebookValues != null
          ? (facebookValues['last_name'] != null
              ? facebookValues['last_name']
              : "")
          : "";
      email = facebookValues != null
          ? (facebookValues['email'] != null ? facebookValues['email'] : "")
          : "";
      sId = facebookValues != null
          ? (facebookValues['id'] != null ? facebookValues['id'] : "")
          : "";
      sName = facebookValues != null ? "facebook" : "";
    }

    deviceOTP = await loginObj.getOTP(countryMobileCode, mobileNumber, deviceId,
        fname, lname, email, sId, sName);
    print(">>>>>>>>>>>> OTP IS: $deviceOTP <<<<<<<<<<<<<");
    // Fluttertoast.showToast(
    //     msg: "Test Login OTP: $deviceOTP",
    //     toastLength: Toast.LENGTH_LONG,
    //     gravity: ToastGravity.BOTTOM,
    //     timeInSecForIosWeb: 5,
    //     backgroundColor: Colors.white,
    //     textColor: Colors.red,
    //     fontSize: MediaQuery.of(context).size.width * 0.050);
  }

  validateOtpAndGetAccessToken(String countryMobileCode, String otp) async {
    userAccessToken = await loginObj.validateOTP(mobileNumber, otp);
    print('>>> OTP VALIDATION: $userAccessToken <<<<<<<<<<<<<<<');

    var userID = await userRepository.loginUser(userAccessToken);

    print('>>>> User id: $userID Logged in in application <<<<<<< ');
    if (userAccessToken != null) {
      Navigator.pushReplacementNamed(context, '/BookingScreen');
    } else {
      print(' ERROROR IN fetching user Details');
    }
  }

  LoginWithSocialId(String userAccessToken) async {
    var userID = await userRepository.loginUser(userAccessToken);

    print('>>>> User id: $userID Logged in in application <<<<<<< ');
    if (userAccessToken != null) {
      Navigator.pushReplacementNamed(context, '/BookingScreen');
    } else {
      print(' ERROROR IN fetching user Details');
    }
  }

  Future<String> _getId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.androidId; // unique ID on Android
    }
  }
}
