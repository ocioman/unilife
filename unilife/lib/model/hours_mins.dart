//Questa classe mi serve perché dart non ha un tipo hh:mm che possa essere serializzato in json
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'hours_mins.g.dart';

@JsonSerializable()
class HoursMins {
  int hours; 
  int mins;

  @JsonKey(defaultValue: 0)
  final int secs;

  HoursMins({
    required this.hours, 
    required this.mins, 
    this.secs = 0,
  });

  /*dato che l'ora verrà presa da un widget il tipo ritornato sarà sicuramente DateTime quindi non
    ha senso fare il parsing a mano 
  */
  factory HoursMins.fromTimeOfDay(TimeOfDay time) =>
      HoursMins(hours: time.hour, mins: time.minute);

  factory HoursMins.fromJson(Map<String, dynamic> json)=>_$HoursMinsFromJson(json);

  Map<String, dynamic> toJson()=>_$HoursMinsToJson(this);
  
  //per l'invio di un oggetto Class al DB
  String toSqlTime(){
    return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
