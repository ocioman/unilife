import 'package:json_annotation/json_annotation.dart';
import 'package:unilife/model/hours_mins.dart';

class HoursMinsConverter implements JsonConverter<HoursMins, String>{
  const HoursMinsConverter();

  @override
  HoursMins fromJson(String json) {
    final parts = json.split(':');
    return HoursMins(
      hours: int.parse(parts[0]),
      mins: int.parse(parts[1]),
      secs: int.parse(parts[2]),
    );
  }

  @override
  String toJson(HoursMins object)=>object.toSqlTime();
}