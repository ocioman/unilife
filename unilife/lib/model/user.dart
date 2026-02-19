import 'package:json_annotation/json_annotation.dart';
import 'package:unilife/model/grade.dart';

import 'exam.dart';

part 'user.g.dart';

@JsonSerializable()
class User{
  final int userID;
  String name1;
  String? name2;
  String surname1;
  String? surname2;
  String email;
  String password;
  List<Grade>? grades;
  List<Exam>? exams;

  User({
    required this.userID,
    required this.name1,
    this.name2,
    required this.surname1,
    this.surname2,
    required this.email,
    required this.password,
    this.grades,
    this.exams,
  });

  factory User.fromJson(Map<String, dynamic> json)=>_$UserFromJson(json);

  Map<String, dynamic> toJson()=>_$UserToJson(this);
}