class ClockInAPI {
  String? currentStatus;
  String? message;
  bool? ok;

  ClockInAPI({this.currentStatus, this.message, this.ok});

  ClockInAPI.fromJson(Map<String, dynamic> json) {
    // Handle currentStatus as either String or other types
    if (json['current_status'] is String) {
      currentStatus = json['current_status'];
    } else if (json['current_status'] != null) {
      // Convert non-string values to string
      currentStatus = json['current_status'].toString();
    } else {
      currentStatus = null;
    }

    // Handle message as either String or other types
    if (json['message'] is String) {
      message = json['message'];
    } else if (json['message'] != null) {
      // Convert non-string values to string
      message = json['message'].toString();
    } else {
      message = null;
    }

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
    // Handle currentStatus as either String or other types
    if (json['current_status'] is String) {
      currentStatus = json['current_status'];
    } else if (json['current_status'] != null) {
      // Convert non-string values to string
      currentStatus = json['current_status'].toString();
    } else {
      currentStatus = null;
    }

    // Handle message as either String or other types
    if (json['message'] is String) {
      message = json['message'];
    } else if (json['message'] != null) {
      // Convert non-string values to string
      message = json['message'].toString();
    } else {
      message = null;
    }

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
    // Handle currentStatus as either String or other types
    if (json['current_status'] is String) {
      currentStatus = json['current_status'];
    } else if (json['current_status'] != null) {
      // Convert non-string values to string
      currentStatus = json['current_status'].toString();
    } else {
      currentStatus = null;
    }

    // Handle message as either String or other types
    if (json['message'] is String) {
      message = json['message'];
    } else if (json['message'] != null) {
      // Convert non-string values to string
      message = json['message'].toString();
    } else {
      message = null;
    }

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
    // Handle currentStatus as either String or other types
    if (json['current_status'] is String) {
      currentStatus = json['current_status'];
    } else if (json['current_status'] != null) {
      // Convert non-string values to string
      currentStatus = json['current_status'].toString();
    } else {
      currentStatus = null;
    }

    // Handle message as either String or other types
    if (json['message'] is String) {
      message = json['message'];
    } else if (json['message'] != null) {
      // Convert non-string values to string
      message = json['message'].toString();
    } else {
      message = null;
    }

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
