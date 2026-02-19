import 'package:json_annotation/json_annotation.dart';

part 'grade.g.dart';

@JsonSerializable()
class Grade{
  final int gradeID;
  String examName;
  double? value;
  final bool isPartial;
  int? parentGradeID;
  bool? isCompleted;

  Grade({
    required this.gradeID,
    required this.examName,
    this.value,
    required this.isPartial,
    this.parentGradeID,
    this.isCompleted,
  });

  factory Grade.fromJson(Map<String, dynamic> json)=>_$GradeFromJson(json);

  Map<String, dynamic> toJson()=>_$GradeToJson(this);
}