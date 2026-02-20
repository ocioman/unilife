// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exam _$ExamFromJson(Map<String, dynamic> json) => Exam(
  examID: (json['examID'] as num).toInt(),
  userID: json['userID'] as String,
  due: DateTime.parse(json['due'] as String),
  courseName: json['courseName'] as String,
  priority: $enumDecode(_$PriorityEnumMap, json['priority']),
);

Map<String, dynamic> _$ExamToJson(Exam instance) => <String, dynamic>{
  'examID': instance.examID,
  'userID': instance.userID,
  'due': instance.due.toIso8601String(),
  'courseName': instance.courseName,
  'priority': _$PriorityEnumMap[instance.priority]!,
};

const _$PriorityEnumMap = {
  Priority.high: 'high',
  Priority.medium: 'medium',
  Priority.low: 'low',
};
