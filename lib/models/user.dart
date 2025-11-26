import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String gender;
  final String type;
  final String token;
  //final List<dynamic> cart;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.gender,
    required this.type,
    required this.token,
    //required this.cart,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'gender': gender,
      'type': type,
      'token': token,
      //'cart': cart,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      gender: map['gender'] ?? '',
      type: map['type'] ?? '',
      token: map['token'] ?? '',
      // cart: List<Map<String, dynamic>>.from(
      //   map['cart']?.map(
      //     (x) => Map<String, dynamic>.from(x),
      //   ),
      // ),
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? gender,
    String? type,
    String? token,
    //List<dynamic>? cart,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      type: type ?? this.type,
      token: token ?? this.token,
      //cart: cart ?? this.cart,
    );
  }
}
