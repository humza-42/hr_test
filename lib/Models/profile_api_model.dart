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
    department = json['department'];
    designation = json['designation'];
    email = json['email'];
    gender = json['gender'];
    name = json['name'];
    phone = json['phone'];
    profilePicture = json['profile_picture'];
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
