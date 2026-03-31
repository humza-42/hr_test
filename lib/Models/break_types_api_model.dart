class BreakTypesAPI {
  List<Data>? data;
  bool? ok;

  BreakTypesAPI({this.data, this.ok});

  BreakTypesAPI.fromJson(Map<String, dynamic> json) {
    if (json['data'] != null) {
      data = <Data>[];
      json['data'].forEach((v) {
        data!.add(new Data.fromJson(v));
      });
    }
    ok = json['ok'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    data['ok'] = this.ok;
    return data;
  }
}

class Data {
  int? id;
  String? name;
  bool? professional;

  Data({this.id, this.name, this.professional});

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'] != null
        ? (json['id'] is double
              ? (json['id'] as double).toInt()
              : json['id'] as int?)
        : null;
    // Handle name as either String or other types
    if (json['name'] is String) {
      name = json['name'];
    } else if (json['name'] != null) {
      // Convert non-string values to string
      name = json['name'].toString();
    } else {
      name = null;
    }
    professional = json['professional'] is bool
        ? json['professional'] as bool
        : (json['professional'] is String
              ? (json['professional'] == 'true' || json['professional'] == '1')
              : null);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['professional'] = this.professional;
    return data;
  }
}
