class ClockInAPI {
  String? currentStatus;
  String? message;
  bool? ok;

  ClockInAPI({this.currentStatus, this.message, this.ok});

  ClockInAPI.fromJson(Map<String, dynamic> json) {
    currentStatus = json['current_status'];
    message = json['message'];
    ok = json['ok'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_status'] = this.currentStatus;
    data['message'] = this.message;
    data['ok'] = this.ok;
    return data;
  }
}

class ClockOutAPI {
  String? currentStatus;
  String? message;
  bool? ok;

  ClockOutAPI({this.currentStatus, this.message, this.ok});

  ClockOutAPI.fromJson(Map<String, dynamic> json) {
    currentStatus = json['current_status'];
    message = json['message'];
    ok = json['ok'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_status'] = this.currentStatus;
    data['message'] = this.message;
    data['ok'] = this.ok;
    return data;
  }
}

class StartBreakAPI {
  String? currentStatus;
  String? message;
  bool? ok;

  StartBreakAPI({this.currentStatus, this.message, this.ok});

  StartBreakAPI.fromJson(Map<String, dynamic> json) {
    currentStatus = json['current_status'];
    message = json['message'];
    ok = json['ok'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_status'] = this.currentStatus;
    data['message'] = this.message;
    data['ok'] = this.ok;
    return data;
  }
}

class BreakEndAPI {
  String? currentStatus;
  String? message;
  bool? ok;

  BreakEndAPI({this.currentStatus, this.message, this.ok});

  BreakEndAPI.fromJson(Map<String, dynamic> json) {
    currentStatus = json['current_status'];
    message = json['message'];
    ok = json['ok'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['current_status'] = this.currentStatus;
    data['message'] = this.message;
    data['ok'] = this.ok;
    return data;
  }
}
