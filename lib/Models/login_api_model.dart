class LoginAPI {
  String? token;
  String? name;
  bool? ok;
  String? role;
  User? user;

  LoginAPI({this.token, this.name, this.ok, this.role, this.user});

  LoginAPI.fromJson(Map<String, dynamic> json) {
    // Handle token as either String or other types
    if (json['token'] is String) {
      token = json['token'];
    } else if (json['token'] != null) {
      // Convert non-string values to string
      token = json['token'].toString();
    } else {
      token = null;
    }

    // Handle name as either String or other types
    if (json['name'] is String) {
      name = json['name'];
    } else if (json['name'] != null) {
      // Convert non-string values to string
      name = json['name'].toString();
    } else {
      name = null;
    }

    ok = json['ok'];

    // Handle role as either String or other types
    if (json['role'] is String) {
      role = json['role'];
    } else if (json['role'] != null) {
      // Convert non-string values to string
      role = json['role'].toString();
    } else {
      role = null;
    }

    user = json['user'] != null ? User.fromJson(json['user']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['token'] = token;
    data['name'] = name;
    data['ok'] = ok;
    data['role'] = role;
    data['user'] = user?.toJson();
    return data;
  }
}

class User {
  int? id;
  String? name;
  String? email;
  String? role;
  int? companyId;

  User({this.id, this.name, this.email, this.role, this.companyId});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    role = json['role'];
    companyId = json['company_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['email'] = email;
    data['role'] = role;
    data['company_id'] = companyId;
    return data;
  }
}
