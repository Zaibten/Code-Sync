import 'dart:convert';

import 'package:pictureai/constants/global_variables.dart';
import 'package:http/http.dart' as http;

import '../apikey/apikey.dart';

class API {
  static final url = Uri.parse("https://api.openai.com/v1/images/generations");

  static final headers = {
    "Content-Type": "application/json",
    "Authorization": "Bearer $apikey"
  };

  static generateImage(String text, String size) async {
    var res = await http.post(
      url,
      headers: headers,
      body: jsonEncode(
        {"prompt": text, "n": 1, "size": size},
      ),
    );
    if (res.statusCode == 200) {
      var data = jsonDecode(res.body.toString());
      return data['data'][0]['url'].toString();
    } else {
      print('Failed to fetch the image');
    }
  }
}
