class GetProfileAPI {
  Data? data;
  bool? ok;

  GetProfileAPI({this.data, this.ok});

  GetProfileAPI.fromJson(Map<String, dynamic> json) {
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
    ok = json['ok'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['ok'] = this.ok;
    return data;
  }
}

class Data {
  String? department;
  String? designation;
  String? email;
  String? gender;
  String? name;
  String? phone;
  String? profilePicture;
  int? userId;

  Data({
    this.department,
    this.designation,
    this.email,
    this.gender,
    this.name,
    this.phone,
    this.profilePicture,
    this.userId,
  });

  Data.fromJson(Map<String, dynamic> json) {
    // Handle department as either String or other types
    if (json['department'] is String) {
      department = json['department'];
    } else if (json['department'] != null) {
      // Convert non-string values to string
      department = json['department'].toString();
    } else {
      department = null;
    }

    // Handle designation as either String or other types
    if (json['designation'] is String) {
      designation = json['designation'];
    } else if (json['designation'] != null) {
      // Convert non-string values to string
      designation = json['designation'].toString();
    } else {
      designation = null;
    }

    // Handle email as either String or other types
    if (json['email'] is String) {
      email = json['email'];
    } else if (json['email'] != null) {
      // Convert non-string values to string
      email = json['email'].toString();
    } else {
      email = null;
    }

    // Handle gender as either String or other types
    if (json['gender'] is String) {
      gender = json['gender'];
    } else if (json['gender'] != null) {
      // Convert non-string values to string
      gender = json['gender'].toString();
    } else {
      gender = null;
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

    // Handle phone as either String or other types
    if (json['phone'] is String) {
      phone = json['phone'];
    } else if (json['phone'] != null) {
      // Convert non-string values to string
      phone = json['phone'].toString();
    } else {
      phone = null;
    }

    // Handle profilePicture as either String or other types
    if (json['profile_picture'] is String) {
      profilePicture = json['profile_picture'];
    } else if (json['profile_picture'] != null) {
      // Convert non-string values to string
      profilePicture = json['profile_picture'].toString();
    } else {
      profilePicture = null;
    }

    userId = json['user_id'] != null
        ? (json['user_id'] is double
              ? (json['user_id'] as double).toInt()
              : json['user_id'] as int?)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['department'] = this.department;
    data['designation'] = this.designation;
    data['email'] = this.email;
    data['gender'] = this.gender;
    data['name'] = this.name;
    data['phone'] = this.phone;
    data['profile_picture'] = this.profilePicture;
    data['user_id'] = this.userId;
    return data;
  }
}
