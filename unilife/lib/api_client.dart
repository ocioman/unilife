import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unilife/model/class.dart';
import 'package:unilife/model/hours_mins.dart';
import 'package:unilife/model/user_model.dart';

import 'model/exam.dart';
import 'model/grade.dart';

//TODO: sicurezza password e correttezza email

class ApiClient{
  final SupabaseClient _supabase;

  ApiClient({required SupabaseClient supabase}):_supabase=supabase;

  String get _uid=>_supabase.auth.currentUser!.id;

  Future<void> signUp({required String email, required String password, required String nome1, String? nome2,
    required String cognome1, String? cognome2,}) async{
    try{
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data:{
          'first_name': nome1,
          'second_name': nome2,
          'last_name': cognome1,
          'second_surname': cognome2,
        },
      );
    }on AuthException{
      //eccezione causata da supabase (password, email ecc...)
      rethrow; //rilancio l'eccezione alla UI così la gestisco con una snackbar
    }catch (e){
      //eccezione causata NON da supabase (tipo se non sono connesso ad internet ottengo una SocketException)
      rethrow;
    }
  }

  Future<UserModel> signIn({required String email, required String password,}) async{
    try{
      await _supabase.auth
          .signInWithPassword(email: email, password: password);

      List<dynamic> resJson=await _supabase
          .from('users')
          .select()
          .eq('userID', _uid);

      return UserModel.fromJson(resJson.first as Map<String, dynamic>);
    }on AuthException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<List<Exam>> fetchExams() async{
    try{
      List<Exam> exams=[];

      List<dynamic> resJson=
          await _supabase //tecnicamente ritorna una lista di Map<String, dynamic>
              .from('exams')
              .select()
              .eq('userID', _uid);

      for(var v in resJson){
        exams.add(Exam.fromJson(v as Map<String, dynamic>));
      }

      return exams;
    }on PostgrestException{
      rethrow;
    }catch (e){
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
    }catch (e){
      rethrow;
    }
  }

  Future<List<Class>> fetchClasses() async{
    try{
      List<Class> classes=[];

      List<dynamic> resJson=await _supabase
          .from('classes')
          .select()
          .eq('userID', _uid);

      for(var v in resJson){
        classes.add(Class.fromJson(v as Map<String, dynamic>));
      }

      return classes;
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<Exam> addExam({required DateTime due, required String courseName, required Priority priority,}) async{
    try{
      List<dynamic> resJson=await _supabase
            .from('exams')
            .insert({
              'userID': _uid,
              'due': due.toIso8601String(),
              'courseName': courseName,
              'priority': priority.name,
            }).select();

      return Exam.fromJson(resJson.first as Map<String, dynamic>);
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<Grade> addGrade({required String examName, double? value, required bool isPartial, int? parentGradeID,
    bool? isCompleted, int? weight, int? cfu,}) async{
    try{
      List<dynamic> resJson=await _supabase
          .from('grades').insert({
            'userID': _uid,
            'examName':
                examName, //reso unique in modo che postgres lanci un eccezione se ci sono due voti per lo stesso esame
            //oppure due esami padre/parziali con lo stesso nome
            'value': value,
            'isPartial': isPartial,
            'parentGradeID': parentGradeID,
            'isCompleted': isCompleted,
            'weight': weight,
            'cfu': cfu,
          })
          .select();

      return Grade.fromJson(resJson.first as Map<String, dynamic>);
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<Class> addClass({required DayOfTheWeek day, required String classType, required HoursMins from,
  required HoursMins to, required String room, String? profName, String? profSurname, String? profEmail}) async{
    try{
      List<dynamic> resJson=await _supabase
        .from('classes')
        .insert({
          'userID': _uid,
          'day': day.value,
          'classType': classType,
          'from': from.toSqlTime(),
          'to': to.toSqlTime(),
          'room': room,
          'profName': profName,
          'profSurname': profSurname,
          'profEmail': profEmail,
        }).select();

        return Class.fromJson(resJson.first as Map<String, dynamic>); 
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }


  /*quando devo inserire un esame parziale devo sapere il parentGradeID, ma dato che
    l'utente non conosce gli ID degli esami allora eseguo una query per ottenerlo tramite il nome (dato che è unique
    avrò una sola row)*/
  Future<int?> getParentGradeIdByName(String examName) async{
    try{
      List<dynamic> resJson=await _supabase
          .from('grades')
          .select('gradeID')
          .eq('userID', _uid)
          .eq('examName', examName)
          .eq('isPartial', true)
          .isFilter('parentGradeID', null);

      if(resJson.isNotEmpty){
        return resJson.first['gradeID'] as int;
      }
      return null;
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  //ogni esame padre avrà un menù a tendina con una lista di esami parziali all'interno
  Future<List<Grade>> fetchPartialGrades(int parentGradeID) async{
    try{
      List<Grade> grades=[];
      List<dynamic> resJson=await _supabase
          .from('grades')
          .select()
          .eq('userID', _uid)
          .eq('isPartial', true)
          .eq('parentGradeID', parentGradeID);

      for(var v in resJson){
        grades.add(Grade.fromJson(v as Map<String, dynamic>));
      }
      return grades;
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  /*se la somma dei pesi degli esami figli è =100 allora devo settare isCompleted dell'esame padre a true+
    devo controllare che il weight inserito sommato ai weight degli altri parziali non sia >100
   */
  Future<int> getTotalWeightForParent(int parentGradeID) async{
    try{
      final grades=await fetchPartialGrades(parentGradeID);
      int sum=0;
      for(var g in grades){
        sum+=g.weight??0;
      }
      return sum;
    }catch (e){
      rethrow;
    }
  }

  Future<void> updateGradeCompleted(int gradeID) async{
    try{
      await _supabase
          .from('grades')
          .update({'isCompleted': true})
          .eq('gradeID', gradeID)
          .eq('userID', _uid);
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<void> updateGradeNotCompleted(int gradeID) async{
    try{
      await _supabase
          .from('grades')
          .update({'isCompleted': false})
          .eq('gradeID', gradeID)
          .eq('userID', _uid);
    }on PostgrestException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<void> updateGrade({required int gradeID, String? examName, double? value, int? weight, int? cfu,}) async{
    try{
      List<dynamic> toUpdateJson=await _supabase
          .from('grades')
          .select()
          .eq('gradeID', gradeID);

      if(toUpdateJson.isEmpty) throw Exception("Voto non presente");

      Grade toUpdate=Grade.fromJson(
        toUpdateJson.first as Map<String, dynamic>,
      );

      Map<dynamic, dynamic> updates={
        'examName': examName??toUpdate.examName,
        'value': value??toUpdate.value,
        'weight': weight??toUpdate.weight,
        'cfu': cfu??toUpdate.cfu,
      };

      await _supabase
          .from('grades')
          .update(updates)
          .eq('gradeID', gradeID);
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<void> updateExam({required int examID, DateTime? due, String? courseName, Priority? priority,}) async{
    try{
      List<dynamic> toUpdateJson=await _supabase
          .from('exams')
          .select()
          .eq('examID', examID);

      if(toUpdateJson.isEmpty) throw Exception("Esame non presente");

      Exam toUpdate=Exam.fromJson(toUpdateJson.first as Map<String, dynamic>);

      Map<dynamic, dynamic> updates={
        'due': due?.toIso8601String()??toUpdate.due.toIso8601String(),
        'courseName': courseName??toUpdate.courseName,
        'priority': priority?.name??toUpdate.priority.name,
      };

      await _supabase
          .from('exams')
          .update(updates)
          .eq('examID', examID);
    } on PostgrestException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateClass({required int classID,  DayOfTheWeek? day,  String? classType,  HoursMins? from,
   HoursMins? to,  String? room, String? profName, String? profSurname, String? profEmail}) async{
    try{
        List<dynamic> updateJson=await _supabase
          .from('classes')
          .select()
          .eq('classID', classID);

        if(updateJson.isEmpty) throw Exception("Classe non trovata"); 

        Class toUpdate=Class.fromJson(updateJson.first as Map<String, dynamic>);

        Map<dynamic, dynamic> updates={
          'day': day?.value??toUpdate.day.value,
          'classType': classType??toUpdate.classType,
          'from': from?.toSqlTime()??toUpdate.from.toSqlTime(),
          'to': to?.toSqlTime()??toUpdate.to.toSqlTime(),
          'room': room??toUpdate.room,
          'profName': profName??toUpdate.profName,
          'profSurname': profSurname??toUpdate.profSurname,
          'profEmail': profEmail??toUpdate.profEmail,
        };

        await _supabase
          .from('classes')
          .update(updates)
          .eq('classID', classID);
    }on PostgrestException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<Grade> deleteGrade({required int gradeID})async{
    try{
      final resJson = await _supabase
          .from('grades')
          .delete()
          .eq('gradeID', gradeID)
          .select();
      
      if (resJson.isEmpty) {
        throw Exception("Voto non trovato o già eliminato");
      }
      
      final Map<String, dynamic> data=Map<String, dynamic>.from(resJson.first as Map);
      
      data['examName']??='Eliminato';
      data['userID']??=_uid;
      data['isPartial']??=false;
      
      return Grade.fromJson(data);
    }on PostgrestException {
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<void> deleteExam({required int examID}) async{
    try{
      await _supabase
          .from('exams')
          .delete()
          .eq('examID', examID);
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<void> deleteClass({required int classID}) async{
    try{
      await _supabase
        .from('classes')
        .delete()
        .eq('classID', classID); 
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
          final finalGrade = (v['final_grade'] as num?)?.toDouble() ?? 0.0;
          final cfu = (v['cfu'] as num?)?.toInt() ?? 0;
          sumPartialGrades += finalGrade;
          sumPartialCfu += cfu;
        }
      }

      if(resNormal.isNotEmpty){
        for(var v in resNormal){
          final val = (v['value'] as num?)?.toDouble() ?? 0.0;
          final cfu = (v['cfu'] as num?)?.toInt() ?? 0;
          sumNormalGrades += val * cfu;
          sumNormalCfu += cfu;
        }
      }

      if(sumPartialCfu!=0||sumNormalCfu!=0){
        return(sumPartialGrades+sumNormalGrades)/(sumPartialCfu+sumNormalCfu);
      }else{
        return 0.0;
      }
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }
}
