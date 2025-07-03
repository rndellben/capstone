class User {
  final String uid;
  final String name;
  final String email;
  final String username;
  final String phone;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.username,
    required this.phone,
  });

  // ✅ Create factory constructor for JSON to User object
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      uid: json['uid'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  // ✅ Convert User object to JSON
  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "username": username,
      "phone": phone,
    };
  }
}