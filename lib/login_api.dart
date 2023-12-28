import 'dart:convert';

import 'package:http/http.dart' as http;

class LoginApi {
  static Future<bool> login(String user, String password) async {
    var url =
        "https://656242f5dcd355c08324b3e3.mockapi.io/users?username=$user&password=$password";
    var header = {"Content-Type": "application/json"};

    Map params = {
      "username": user,
      "senha": password,
    };

    var _body = json.encode(params);
    print("json enviado : $_body");

    var response = await http.get(Uri.parse(url), headers: header);

    if (response.statusCode == 200 && response.body != "[]") {
      //Apenas para vermos a resposta do mockApi, o "print" nao seria usado em produção
      print('response status: ${response.statusCode}');
      print('response body: ${response.body}');
      return true;
    } else {
      return false;
    }
  }
}
