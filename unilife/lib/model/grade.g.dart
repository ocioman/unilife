// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Grade _$GradeFromJson(Map<String, dynamic> json) => Grade(
  gradeID: (json['gradeID'] as num).toInt(),
  userID: json['userID'] as String,
  examName: json['examName'] as String,
  value: (json['value'] as num?)?.toDouble(),
  isPartial: json['isPartial'] as bool,
  parentGradeID: (json['parentGradeID'] as num?)?.toInt(),
  isCompleted: json['isCompleted'] as bool?,
);

Map<String, dynamic> _$GradeToJson(Grade instance) => <String, dynamic>{
  'gradeID': instance.gradeID,
  'userID': instance.userID,
  'examName': instance.examName,
  'value': instance.value,
  'isPartial': instance.isPartial,
  'parentGradeID': instance.parentGradeID,
  'isCompleted': instance.isCompleted,
};
