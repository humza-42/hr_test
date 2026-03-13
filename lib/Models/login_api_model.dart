class LoginAPI {
  String? apiToken;
  String? name;
  bool? ok;
  String? role;
  int? userId;

  LoginAPI({this.apiToken, this.name, this.ok, this.role, this.userId});

  LoginAPI.fromJson(Map<String, dynamic> json) {
    apiToken = json['api_token'];
    name = json['name'];
    ok = json['ok'];
    role = json['role'];
    userId = json['user_id'] != null
        ? (json['user_id'] is double
              ? (json['user_id'] as double).toInt()
              : json['user_id'] as int?)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['api_token'] = apiToken;
    data['name'] = name;
    data['ok'] = ok;
    data['role'] = role;
    data['user_id'] = userId;
    return data;
  }
}
