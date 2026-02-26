// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Class _$ClassFromJson(Map<String, dynamic> json) => Class(
  classID: (json['classID'] as num).toInt(),
  userID: json['userID'] as String,
  day: $enumDecode(_$DayOfTheWeekEnumMap, json['day']),
  classType: json['classType'] as String,
  from: const HoursMinsConverter().fromJson(json['from'] as String),
  to: const HoursMinsConverter().fromJson(json['to'] as String),
  room: json['room'] as String,
  profName: json['profName'] as String?,
  profSurname: json['profSurname'] as String?,
  profEmail: json['profEmail'] as String?,
);

Map<String, dynamic> _$ClassToJson(Class instance) => <String, dynamic>{
  'classID': instance.classID,
  'userID': instance.userID,
  'day': _$DayOfTheWeekEnumMap[instance.day]!,
  'classType': instance.classType,
  'from': const HoursMinsConverter().toJson(instance.from),
  'to': const HoursMinsConverter().toJson(instance.to),
  'room': instance.room,
  'profName': instance.profName,
  'profSurname': instance.profSurname,
  'profEmail': instance.profEmail,
};

const _$DayOfTheWeekEnumMap = {
  DayOfTheWeek.monday: 'monday',
  DayOfTheWeek.tuesday: 'tuesday',
  DayOfTheWeek.wednesday: 'wednesday',
  DayOfTheWeek.thursday: 'thursday',
  DayOfTheWeek.friday: 'friday',
  DayOfTheWeek.saturday: 'saturday',
  DayOfTheWeek.sunday: 'sunday',
};
