import 'package:json_annotation/json_annotation.dart';
import 'package:unilife/model/hours_mins.dart';
import 'package:unilife/model/hours_mins_converter.dart';

part 'class.g.dart';

@JsonSerializable()
@HoursMinsConverter()
class Class {
  final int classID;
  final String userID; 
  DayOfTheWeek day;
  String classType;
  HoursMins from;
  HoursMins to;
  String room;
  String? profName;
  String? profSurname;
  String? profEmail;

  Class({
    required this.classID,
    required this.userID, 
    required this.day,
    required this.classType,
    required this.from,
    required this.to,
    required this.room,
    String? profName,
    String? profSurname,
    String? profEmail,
  }) : profName = profName ?? 'Nessun nome',
       profSurname = profSurname ?? 'Nessun cognome',
       profEmail = profEmail ?? 'Nessuna email';

  factory Class.fromJson(Map<String, dynamic> json) => _$ClassFromJson(json);

  Map<String, dynamic> toJson() => _$ClassToJson(this);
}

@JsonEnum()
enum DayOfTheWeek {
  monday('Monday'),
  tuesday('Tuesday'),
  wednesday('Wednesday'),
  thursday('Thursday'),
  friday('Friday'),
  saturday('Saturday'),
  sunday('Sunday');

  final String value;
  const DayOfTheWeek(this.value);
}
