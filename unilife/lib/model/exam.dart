import 'package:json_annotation/json_annotation.dart';

part 'exam.g.dart';

@JsonSerializable()
class Exam{
  final int examID;
  DateTime due;
  String courseName;
  Priority priority;

  Exam({
    required this.examID, //facendo required this... rendo il parametro mandatory e lo assegno automaticamente all'attributo
    required this.due,
    required this.courseName,
    required this.priority
  });

  factory Exam.fromJson(Map<String, dynamic> json)=>_$ExamFromJson(json);

  Map<String, dynamic> toJson()=>_$ExamToJson(this);
}

@JsonEnum(valueField: 'value')
enum Priority {
  high('high'),
  medium('medium'),
  low('low');

  final String value;
  const Priority(this.value);
}