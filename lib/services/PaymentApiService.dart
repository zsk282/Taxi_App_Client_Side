/**
 * Call API and get resposne from there no modification here in response other than parsing
 */
import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentApiService {
  String base_url = 'http://3.128.103.238/api/payment';

  Future addInWalletByAccessToken(
    String accessToken,
    String card_number,
    String exp_month,
    String exp_year,
    String security_Code,
    String amount,
    String currency,
  ) async {
    print({
      "card_number": card_number,
      "exp_month": exp_month,
      "exp_year": exp_year,
      "security_Code": security_Code,
      "amount": amount,
      "currency": currency,
    });
    final http.Response response = await http.post(
      base_url + '/pay?access_token=' + accessToken,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': '*/*',
      },
      body: json.encode({
        "card_number": card_number,
        "exp_month": exp_month,
        "exp_year": exp_year,
        "security_Code": security_Code,
        "amount": amount,
        "currency": currency,
      }),
    );
    print(response.body);
    var temp = json.decode(response.body);
    print(temp);

    if (temp['success'].toString() == "true") {
      temp = temp['data'];
      return temp;
    } else {
      return null;
      // throw Exception('Failed to update trip by paymetn by card API');
    }
  }
}
