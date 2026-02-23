// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  userID: json['userID'] as String,
  name1: json['name1'] as String,
  name2: json['name2'] as String?,
  surname1: json['surname1'] as String,
  surname2: json['surname2'] as String?,
  email: json['email'] as String,
  grades:
      (json['grades'] as List<dynamic>?)
          ?.map((e) => Grade.fromJson(e as Map<String, dynamic>))
          .toList(),
  exams:
      (json['exams'] as List<dynamic>?)
          ?.map((e) => Exam.fromJson(e as Map<String, dynamic>))
          .toList(),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'userID': instance.userID,
  'name1': instance.name1,
  'name2': instance.name2,
  'surname1': instance.surname1,
  'surname2': instance.surname2,
  'email': instance.email,
  'grades': instance.grades,
  'exams': instance.exams,
};
