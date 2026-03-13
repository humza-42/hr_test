class ExtraBreakApi {
  int? currentType;
  String? msg;
  bool? ok;

  ExtraBreakApi({this.currentType, this.msg, this.ok});

  ExtraBreakApi.fromJson(Map<String, dynamic> json) {
    currentType = json['current_type']?.toInt(); // ✅ safest way
    msg = json['msg'];
    ok = json['ok'];
  }

  Map<String, dynamic> toJson() {
    return {'current_type': currentType, 'msg': msg, 'ok': ok};
  }
}
