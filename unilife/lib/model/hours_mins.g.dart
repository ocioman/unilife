// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hours_mins.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HoursMins _$HoursMinsFromJson(Map<String, dynamic> json) => HoursMins(
  hours: (json['hours'] as num).toInt(),
  mins: (json['mins'] as num).toInt(),
  secs: (json['secs'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$HoursMinsToJson(HoursMins instance) => <String, dynamic>{
  'hours': instance.hours,
  'mins': instance.mins,
  'secs': instance.secs,
};
