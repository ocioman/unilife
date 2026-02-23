import 'package:json_annotation/json_annotation.dart';
import 'package:unilife/model/grade.dart';

import 'exam.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel{
  String userID;
  String name1;
  String? name2;
  String surname1;
  String? surname2;
  String email;
  List<Grade>? grades;
  List<Exam>? exams;

  UserModel({
    required this.userID,
    required this.name1,
    this.name2,
    required this.surname1,
    this.surname2,
    required this.email,
    this.grades,
    this.exams,
  });

  factory UserModel.fromJson(Map<String, dynamic> json)=>_$UserModelFromJson(json);

  Map<String, dynamic> toJson()=>_$UserModelToJson(this);
}