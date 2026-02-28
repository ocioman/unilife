import 'package:json_annotation/json_annotation.dart';

part 'grade.g.dart';

@JsonSerializable()
class Grade{
  final int gradeID; //pk
  final String userID; //fk
  String examName;
  double? value;
  final bool isPartial;
  int? parentGradeID;
  bool? isCompleted;
  int? weight; //per gli esami parziali
  int? cfu;  //per gli esami completi

  /*
  Con parentGradeID realizzo una relazione ricorsiva
  Creo una vista con gli id e i cfu degli esami padre completi (quindi isPartial=true, isCompleted=true, e parentGradeID=null),
  creo una vista con gli esami parziali (isPartial=true e parentGradeID=valore)
  selezionando solo il voto e il peso ed eseguo il join tra le due viste

   */

  Grade({
    required this.gradeID,
    required this.userID,
    required this.examName,
    this.value,
    required this.isPartial,
    this.parentGradeID,
    this.isCompleted,
    this.weight,
  });

  factory Grade.fromJson(Map<String, dynamic> json)=>_$GradeFromJson(json);

  Map<String, dynamic> toJson()=>_$GradeToJson(this);
}