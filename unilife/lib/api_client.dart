import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unilife/model/user_model.dart';

import 'model/exam.dart';
import 'model/grade.dart';


//TODO: sicurezza password e correttezza email

class ApiClient{
  final SupabaseClient _supabase=Supabase.instance.client;

  String get _uid=>_supabase.auth.currentUser!.id;

  Future<void> signUp({required String email, required String password, required String nome1, String? nome2, required String cognome1, String? cognome2,})async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': nome1,
          'second_name': nome2,
          'last_name': cognome1,
          'second_surname': cognome2,
        },
      );
    } on AuthException { //eccezione causata da supabase (password, email ecc...)
      rethrow; //rilancio l'eccezione alla UI così la gestisco con una snackbar
    }catch(e){ //eccezione causata NON da supabase (tipo se non sono connesso ad internet ottengo una SocketException)
      rethrow;
    }
  }

  Future<UserModel> signIn({required String email, required String password}) async{
    AuthResponse res;
    try{
      res=await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      User? user=res.user;
      if(user==null) throw Exception("Login fallito: utente nullo"); //teoricamente non dovrebbe succedere perché catturo già l'eccezione di supabase
      final String uuid=user.id;

      final resJson=await _supabase
          .from('users')
          .select('''
               *,
               grades(*), 
               exams(*)
               ''') //join tra users, grades ed exams where userID=uuid
          .eq('userID', uuid)
          .single();

      return UserModel.fromJson(resJson);
    }on AuthException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<List<Exam>> fetchExams() async{
    try{
      List<Exam> exams=[];

      List<dynamic> resJson=await _supabase //tecnicamente ritorna una lista di Map<String, dynamic>
          .from('exams')
          .select()
          .eq('userID', _uid);

      for(var v in resJson){
        exams.add(Exam.fromJson(v as Map<String, dynamic>));
      }

      return exams;

    }on PostgrestException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<List<Grade>> fetchGrades() async{
    try{
      List<Grade> grades=[];

      List<dynamic> resJson=await _supabase
          .from('grades')
          .select()
          .eq('userID', _uid);

      for(var v in resJson){
        grades.add(Grade.fromJson(v as Map<String, dynamic>));
      }

      return grades;
    }on PostgrestException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<Exam> addExam({required DateTime due, required String courseName, required Priority priority}) async{
    try{
      List<dynamic> resJson=await _supabase
          .from('exams')
          .insert({'userID': _uid, 'due': due.toIso8601String(), 'courseName': courseName, 'priority': priority.name})
          .select();

      return Exam.fromJson(resJson.first as Map<String, dynamic>);
    }on PostgrestException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<Grade> addGrade({required String examName, double? value, required bool isPartial, int? parentGradeID, bool? isCompleted, int? weight, int? cfu}) async{
    try{
      List<dynamic> resJson=await _supabase
          .from('grades')
          .insert({
        'userID': _uid,
        'examName': examName,
        'value': value,
        'isPartial': isPartial,
        'parentGradeID': parentGradeID,
        'isCompleted': isCompleted,
        'weight': weight,
        'cfu': cfu
      })
          .select();

      return Grade.fromJson(resJson.first as Map<String, dynamic>);
    }on PostgrestException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<double> computeAvg() async{
    try{
        double sumPartialGrades=0;
        double sumNormalGrades=0;
        int sumPartialCfu=0;
        int sumNormalCfu=0;

        List<Map<String, dynamic>> resPartials=await _supabase
            .from('completed_parent_exams_grades')
            .select();

        List<Map<String, dynamic>> resNormal=await _supabase
            .from('grades')
            .select()
            .eq('isPartial', false);

        if(resPartials.isNotEmpty){
          for(var v in resPartials){
            sumPartialGrades+=(v['final_grade'] as num).toDouble();
            sumPartialCfu+=(v['cfu'] as num).toInt();
          }
        }

        if(resNormal.isNotEmpty){
          for(var v in resNormal){
            sumNormalGrades+=(v['value'] as num).toDouble()*(v['cfu'] as num).toInt();
            sumNormalCfu+=(v['cfu'] as num).toInt();
          }
        }

        if(sumPartialCfu!=0||sumNormalCfu!=0){
          return (sumPartialGrades+sumNormalGrades)/(sumPartialCfu+sumNormalCfu);
        }else{
          return 0.0;
        }
    }on PostgrestException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }
}