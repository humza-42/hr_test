class DashboardAPI {
  Data? data;
  bool? ok;

  DashboardAPI({this.data, this.ok});

  DashboardAPI.fromJson(Map<String, dynamic> json) {
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
  Attendance? attendance;
  String? breakStartTime;
  String? checkIn;
  bool? checkOut;
  String? currentSessionTime;
  String? currentStatus;
  Null? holidayInfo;
  int? lastSessionStatus;
  LeaveSummary? leaveSummary;
  List<MonthlyRecords>? monthlyRecords;
  bool? onBreak;
  int? professionalBreak;
  int? remainingHours;
  String? today;
  int? totalBreakTime;
  List<WeeklyRecords>? weeklyRecords;

  Data({
    this.attendance,
    this.breakStartTime,
    this.checkIn,
    this.checkOut,
    this.currentSessionTime,
    this.currentStatus,
    this.holidayInfo,
    this.lastSessionStatus,
    this.leaveSummary,
    this.monthlyRecords,
    this.onBreak,
    this.professionalBreak,
    this.remainingHours,
    this.today,
    this.totalBreakTime,
    this.weeklyRecords,
  });

  Data.fromJson(Map<String, dynamic> json) {
    attendance = json['attendance'] != null
        ? new Attendance.fromJson(json['attendance'])
        : null;
    // Handle break_start_time as either String or bool
    if (json['break_start_time'] is bool) {
      breakStartTime = json['break_start_time'] == true ? 'true' : null;
    } else if (json['break_start_time'] is String) {
      breakStartTime = json['break_start_time'];
    } else {
      breakStartTime = null;
    }
    // Handle check_in as either String or bool
    if (json['check_in'] is bool) {
      // API returned boolean - convert to string representation
      checkIn = json['check_in'] == true ? 'Clocked In' : null;
    } else if (json['check_in'] is String) {
      checkIn = json['check_in'];
    } else {
      checkIn = null;
    }
    // Handle check_out as either bool or other types
    if (json['check_out'] is bool) {
      checkOut = json['check_out'];
    } else if (json['check_out'] is String) {
      // If API returns string, convert to bool
      checkOut = json['check_out'].toString().isNotEmpty;
    } else {
      checkOut = null;
    }
    // Handle current_session_time as either String or bool
    if (json['current_session_time'] is bool) {
      currentSessionTime = json['current_session_time'] == true ? 'true' : null;
    } else if (json['current_session_time'] is String) {
      currentSessionTime = json['current_session_time'];
    } else {
      currentSessionTime = null;
    }
    // Handle current_status as either String or bool
    if (json['current_status'] is bool) {
      currentStatus = json['current_status'] == true ? 'true' : 'false';
    } else if (json['current_status'] is String) {
      currentStatus = json['current_status'];
    } else {
      currentStatus = null;
    }
    holidayInfo = json['holiday_info'];
    lastSessionStatus = json['last_session_status'] != null
        ? (json['last_session_status'] is double
              ? (json['last_session_status'] as double).toInt()
              : (json['last_session_status'] is bool
                    ? (json['last_session_status'] as bool ? 1 : 0)
                    : json['last_session_status'] as int?))
        : null;
    leaveSummary = json['leave_summary'] != null
        ? new LeaveSummary.fromJson(json['leave_summary'])
        : null;
    if (json['monthly_records'] != null) {
      monthlyRecords = <MonthlyRecords>[];
      json['monthly_records'].forEach((v) {
        monthlyRecords!.add(new MonthlyRecords.fromJson(v));
      });
    }
    onBreak = json['on_break'];
    professionalBreak = json['professional_break'] != null
        ? (json['professional_break'] is double
              ? (json['professional_break'] as double).toInt()
              : (json['professional_break'] is bool
                    ? (json['professional_break'] as bool ? 1 : 0)
                    : json['professional_break'] as int?))
        : null;
    remainingHours = json['remaining_hours'] != null
        ? (json['remaining_hours'] is double
              ? (json['remaining_hours'] as double).toInt()
              : (json['remaining_hours'] is bool
                    ? (json['remaining_hours'] as bool ? 1 : 0)
                    : json['remaining_hours'] as int?))
        : null;
    // Handle today as either String or bool
    if (json['today'] is bool) {
      today = json['today'] == true ? 'true' : null;
    } else if (json['today'] is String) {
      today = json['today'];
    } else {
      today = null;
    }
    totalBreakTime = json['total_break_time'] != null
        ? (json['total_break_time'] is double
              ? (json['total_break_time'] as double).toInt()
              : json['total_break_time'] as int?)
        : null;
    if (json['weekly_records'] != null) {
      weeklyRecords = <WeeklyRecords>[];
      json['weekly_records'].forEach((v) {
        weeklyRecords!.add(new WeeklyRecords.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.attendance != null) {
      data['attendance'] = this.attendance!.toJson();
    }
    data['break_start_time'] = this.breakStartTime;
    data['check_in'] = this.checkIn;
    data['check_out'] = this.checkOut;
    data['current_session_time'] = this.currentSessionTime;
    data['current_status'] = this.currentStatus;
    data['holiday_info'] = this.holidayInfo;
    data['last_session_status'] = this.lastSessionStatus;
    if (this.leaveSummary != null) {
      data['leave_summary'] = this.leaveSummary!.toJson();
    }
    if (this.monthlyRecords != null) {
      data['monthly_records'] = this.monthlyRecords!
          .map((v) => v.toJson())
          .toList();
    }
    data['on_break'] = this.onBreak;
    data['professional_break'] = this.professionalBreak;
    data['remaining_hours'] = this.remainingHours;
    data['today'] = this.today;
    data['total_break_time'] = this.totalBreakTime;
    if (this.weeklyRecords != null) {
      data['weekly_records'] = this.weeklyRecords!
          .map((v) => v.toJson())
          .toList();
    }
    return data;
  }
}

class Attendance {
  String? date;
  int? id;
  String? status;

  Attendance({this.date, this.id, this.status});

  Attendance.fromJson(Map<String, dynamic> json) {
    // Handle date as either String or bool
    if (json['date'] is bool) {
      date = json['date'] == true ? 'true' : null;
    } else if (json['date'] is String) {
      date = json['date'];
    } else {
      date = null;
    }
    id = json['id'] != null
        ? (json['id'] is double
              ? (json['id'] as double).toInt()
              : json['id'] as int?)
        : null;
    // Handle status as either String or bool
    if (json['status'] is bool) {
      status = json['status'] == true ? 'true' : 'false';
    } else if (json['status'] is String) {
      status = json['status'];
    } else {
      status = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['id'] = this.id;
    data['status'] = this.status;
    return data;
  }
}

class LeaveSummary {
  int? taken;
  int? total;
  Type? type;

  LeaveSummary({this.taken, this.total, this.type});

  LeaveSummary.fromJson(Map<String, dynamic> json) {
    taken = json['taken'] != null
        ? (json['taken'] is double
              ? (json['taken'] as double).toInt()
              : json['taken'] as int?)
        : null;
    total = json['total'] != null
        ? (json['total'] is double
              ? (json['total'] as double).toInt()
              : json['total'] as int?)
        : null;
    type = json['type'] != null ? new Type.fromJson(json['type']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['taken'] = this.taken;
    data['total'] = this.total;
    if (this.type != null) {
      data['type'] = this.type!.toJson();
    }
    return data;
  }
}

class Type {
  int? annual;
  int? casual;
  int? sick;
  int? unpaid;

  Type({this.annual, this.casual, this.sick, this.unpaid});

  Type.fromJson(Map<String, dynamic> json) {
    annual = json['annual'] != null
        ? (json['annual'] is double
              ? (json['annual'] as double).toInt()
              : json['annual'] as int?)
        : null;
    casual = json['casual'] != null
        ? (json['casual'] is double
              ? (json['casual'] as double).toInt()
              : json['casual'] as int?)
        : null;
    sick = json['sick'] != null
        ? (json['sick'] is double
              ? (json['sick'] as double).toInt()
              : json['sick'] as int?)
        : null;
    unpaid = json['unpaid'] != null
        ? (json['unpaid'] is double
              ? (json['unpaid'] as double).toInt()
              : json['unpaid'] as int?)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['annual'] = this.annual;
    data['casual'] = this.casual;
    data['sick'] = this.sick;
    data['unpaid'] = this.unpaid;
    return data;
  }
}

class MonthlyRecords {
  int? attendanceId;
  String? date;
  double? hours;
  bool? isFuture;
  bool? isWorkingDay;
  String? status;

  MonthlyRecords({
    this.attendanceId,
    this.date,
    this.hours,
    this.isFuture,
    this.isWorkingDay,
    this.status,
  });

  MonthlyRecords.fromJson(Map<String, dynamic> json) {
    attendanceId = json['attendance_id'] != null
        ? (json['attendance_id'] is double
              ? (json['attendance_id'] as double).toInt()
              : json['attendance_id'] as int?)
        : null;
    // Handle date as either String or bool
    if (json['date'] is bool) {
      date = json['date'] == true ? 'true' : null;
    } else if (json['date'] is String) {
      date = json['date'];
    } else {
      date = null;
    }
    hours = json['hours'] != null
        ? (json['hours'] is int
              ? (json['hours'] as int).toDouble()
              : json['hours'] as double?)
        : null;
    isFuture = json['is_future'];
    isWorkingDay = json['is_working_day'];
    // Handle status as either String or bool
    if (json['status'] is bool) {
      status = json['status'] == true ? 'true' : 'false';
    } else if (json['status'] is String) {
      status = json['status'];
    } else {
      status = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['attendance_id'] = this.attendanceId;
    data['date'] = this.date;
    data['hours'] = this.hours;
    data['is_future'] = this.isFuture;
    data['is_working_day'] = this.isWorkingDay;
    data['status'] = this.status;
    return data;
  }
}

class WeeklyRecords {
  String? date;
  String? day;
  double? hours;
  bool? isFuture;
  bool? isWorkingDay;
  int? target;
  String? formattedHours;

  WeeklyRecords({
    this.date,
    this.day,
    this.hours,
    this.isFuture,
    this.isWorkingDay,
    this.target,
    this.formattedHours,
  });

  WeeklyRecords.fromJson(Map<String, dynamic> json) {
    // Handle date as either String or bool
    if (json['date'] is bool) {
      date = json['date'] == true ? 'true' : null;
    } else if (json['date'] is String) {
      date = json['date'];
    } else {
      date = null;
    }
    // Handle day as either String or bool
    if (json['day'] is bool) {
      day = json['day'] == true ? 'true' : null;
    } else if (json['day'] is String) {
      day = json['day'];
    } else {
      day = null;
    }
    hours = json['hours'] != null
        ? (json['hours'] is int
              ? (json['hours'] as int).toDouble()
              : json['hours'] as double?)
        : null;
    isFuture = json['is_future'];
    isWorkingDay = json['is_working_day'];
    target = json['target'] != null
        ? (json['target'] is double
              ? (json['target'] as double).toInt()
              : json['target'] as int?)
        : null;
    // Handle formatted_hours as either String or bool
    if (json['formatted_hours'] is bool) {
      formattedHours = json['formatted_hours'] == true ? 'true' : null;
    } else if (json['formatted_hours'] is String) {
      formattedHours = json['formatted_hours'];
    } else {
      formattedHours = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['date'] = this.date;
    data['day'] = this.day;
    data['hours'] = this.hours;
    data['is_future'] = this.isFuture;
    data['is_working_day'] = this.isWorkingDay;
    data['target'] = this.target;
    data['formatted_hours'] = this.formattedHours;
    return data;
  }
}
