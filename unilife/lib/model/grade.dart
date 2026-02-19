import 'package:json_annotation/json_annotation.dart';

part 'grade.g.dart';

@JsonSerializable()
class Grade{
  final int gradeID; //pk
  final int userID; //fk
  String examName;
  double? value;
  final bool isPartial;
  int? parentGradeID;
  bool? isCompleted;

  /*
  Con parentGradeID realizzo una relazione ricorsiva -> creo una vista contenente solo i voti con isCompleted e isPartial
  =true e poi creo una vista con funzione di aggregazione avg per i vari esami parziali -> faccio un join e ottengo solo
  le medie degli esami di cui sono stati svolti tutti i parziali
   */

  Grade({
    required this.gradeID,
    required this.userID,
    required this.examName,
    this.value,
    required this.isPartial,
    this.parentGradeID,
    this.isCompleted,
  });

  factory Grade.fromJson(Map<String, dynamic> json)=>_$GradeFromJson(json);

  Map<String, dynamic> toJson()=>_$GradeToJson(this);
}