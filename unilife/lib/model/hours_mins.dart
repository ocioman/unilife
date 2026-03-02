//Questa classe mi serve perché dart non ha un tipo hh:mm che possa essere serializzato in json
import 'package:flutter/material.dart';

class HoursMins {
  int hours; 
  int mins;

  final int secs;

  HoursMins({
    required this.hours, 
    required this.mins, 
    this.secs = 0,
  });

  //l'ora verrà presa da un widget che probabilmente restituirà un oggetto TimeOfDay
  factory HoursMins.fromTimeOfDay(TimeOfDay time) =>
      HoursMins(hours: time.hour, mins: time.minute);
  
  //questo mi serve per il converter per serializzare/deserializzare in hh:mm:ss e non h:m:s
  String toSqlTime(){
    return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }
}
