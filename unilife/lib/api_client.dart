import 'package:email_validator/email_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unilife/model/class.dart';
import 'package:unilife/model/hours_mins.dart';
import 'package:unilife/model/user_model.dart';

import 'model/invalid_email_exception.dart';
import 'model/exam.dart';
import 'model/grade.dart';

class ApiClient{
  final SupabaseClient _supabase;

  ApiClient({required SupabaseClient supabase}):_supabase=supabase;

  String get _uid=>_supabase.auth.currentUser!.id;

  Future<void> signUp({required String email, required String password, required String nome1, String? nome2,
    required String cognome}) async{
    try{
      if(!EmailValidator.validate(email)){
        throw const InvalidEmailException('Email non valida');
      }

      await _supabase.auth.signUp(
        email: email,
        password: password,
        data:{
          'first_name': nome1,
          'second_name': nome2,
          'last_name': cognome,
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

      Map<String, dynamic> resJson=await _supabase
          .from('users')
          .select()
          .eq('userID', _uid)
          .single(); //single così non mi ritorna una lista di Map<String, dynamic> con un solo elemento

      return UserModel.fromJson(resJson);
    }on AuthException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<void> signOutUser() async {
    try{
      await _supabase.auth.signOut();
    }on AuthException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<void> updateEmail({required String newEmail, required String password}) async{
    if(!EmailValidator.validate(newEmail)){
      throw const InvalidEmailException('Email non valida');
    }
    try{
      await _supabase.auth.signInWithPassword(
          email: _supabase.auth.currentUser!.email!,
          password: password,
      );

      await _supabase.auth.updateUser(
        UserAttributes(email: newEmail),
      );

    }on AuthException{
      rethrow;
    }on PostgrestException{
      rethrow;
    }catch(e) {
      rethrow;
    }
  }

  Future<void> updatePassword({required String oldPassword, required String newPassword}) async{
    try{
      await _supabase.auth.signInWithPassword(
        email: _supabase.auth.currentUser!.email!,
        password: oldPassword,
      );

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    }on AuthException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<void> updatePersonalData({String? name1, String? name2, String? surname}) async{
    try{
      Map<String, dynamic> update;

      if(name1 != null && name1.isNotEmpty) {
        update = {'name1': name1};
      }else if(name2!=null && name2.isNotEmpty){
        update={'name2':name2};
      }else{
        update={'surname':surname};
      }

      await _supabase
        .from('users')
        .update(update)
        .eq('userID', _uid);

    }on AuthException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<List<Exam>> fetchExams() async{
    try{
      List<Map<String, dynamic>> resJson=
          await _supabase
              .from('exams')
              .select()
              .eq('userID', _uid);

      /*
        Rimosso il for in e la lista, tramite questo return creo un iterable lazy con un'istruzione globale
        di mapping (in questo caso la deserializzazione) che dice cosa fare su ogni elemento e non la eseguo
        finché uno o più elementi non vengono richiesti (viene eseguita solo sugli elementi richiesti).
        Dato che .toList(); itera su tutti gli elementi dell'iterable (e quindi li richiede tutti),
        ogni elemento di resJson viene messo nella nuova lista deserializzato. + easy
        a discapito di un po' di readability, se avessi 10000 elementi nella lista e volessi eseguire la deserializzazione
        solo per i primi 5 sarebbe molto comodo
       */
      return resJson.map((element)=>Exam.fromJson(element)).toList();

    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<List<Grade>> fetchGrades() async{
    try{

      List<Map<String, dynamic>> resJson=await _supabase
          .from('grades')
          .select()
          .eq('userID', _uid);
      
      return resJson.map((element)=>Grade.fromJson(element)).toList();
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<List<Class>> fetchClasses() async{
    try{
      List<Map<String, dynamic>> resJson=await _supabase
          .from('classes')
          .select()
          .eq('userID', _uid);

      return resJson.map((element)=>Class.fromJson(element)).toList();
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<Exam> addExam({required DateTime due, required String courseName, required Priority priority, required HoursMins time}) async{
    try{
      Map<String, dynamic> resJson=await _supabase
            .from('exams')
            .insert({
              'userID': _uid,
              'due': due.toIso8601String(),
              'time': time.toSqlTime(),
              'courseName': courseName,
              'priority': priority.name,
            }).select()
            .single();

      return Exam.fromJson(resJson);
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<Grade> addGrade({required String examName, double? value, required bool isPartial, int? parentGradeID,
    bool? isCompleted, int? weight, int? cfu,}) async{
    try{
      Map<String, dynamic> resJson=await _supabase
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
          .select()
          .single();

      return Grade.fromJson(resJson);
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  Future<Class> addClass({required DayOfTheWeek day, required String classType, required HoursMins from,
  required HoursMins to, required String room, String? profName, String? profSurname, String? profEmail}) async{
    try{
      Map<String, dynamic> resJson=await _supabase
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
        }).select()
        .single();

        return Class.fromJson(resJson);
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
      Map<String, dynamic> resJson=await _supabase
          .from('grades')
          .select('gradeID')
          .eq('userID', _uid)
          .eq('examName', examName)
          .eq('isPartial', true)
          .isFilter('parentGradeID', null)
          .single();

      return resJson['gradeID'] as int;
    }on PostgrestException{
      rethrow;
    }catch (e){
      rethrow;
    }
  }

  //ogni esame padre avrà un menù a tendina con una lista di esami parziali all'interno
  Future<List<Grade>> fetchPartialGrades(int parentGradeID) async{
    try{
      List<Map<String, dynamic>> resJson=await _supabase
          .from('grades')
          .select()
          .eq('userID', _uid)
          .eq('isPartial', true)
          .eq('parentGradeID', parentGradeID);

      return resJson.map((element)=>Grade.fromJson(element)).toList();
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
      List<Grade> grades=await fetchPartialGrades(parentGradeID);
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
      Map<String, dynamic> toUpdateJson=await _supabase
          .from('grades')
          .select()
          .eq('gradeID', gradeID)
          .single();

      Grade toUpdate=Grade.fromJson(toUpdateJson);

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

  Future<void> updateExam({required int examID, DateTime? due, String? courseName, Priority? priority, HoursMins? time}) async{
    try{
      Map<String, dynamic> toUpdateJson=await _supabase
          .from('exams')
          .select()
          .eq('examID', examID)
          .single();

      Exam toUpdate=Exam.fromJson(toUpdateJson);

      Map<dynamic, dynamic> updates={
        'due': due?.toIso8601String()??toUpdate.due.toIso8601String(),
        'courseName': courseName??toUpdate.courseName,
        'priority': priority?.name??toUpdate.priority.name,
        'time': time?.toSqlTime()??toUpdate.time.toSqlTime(),
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
      Map<String, dynamic> updateJson=await _supabase
          .from('classes')
          .select()
          .eq('classID', classID)
          .single();

        Class toUpdate=Class.fromJson(updateJson);

        Map<String, dynamic> updates={
          'day': day?.value??toUpdate.day.value,
          'classType': classType??toUpdate.classType,
          'from': from?.toSqlTime()??toUpdate.from.toSqlTime(),
          'to': to?.toSqlTime()??toUpdate.to.toSqlTime(),
          'room': room??toUpdate.room,
          'profName': profName,
          'profSurname': profSurname,
          'profEmail': profEmail,
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
      Map<String, dynamic> resJson=await _supabase
          .from('grades')
          .delete()
          .eq('gradeID', gradeID)
          .select()
          .single();
      
      resJson['examName']??='Eliminato';
      resJson['userID']??=_uid;
      resJson['isPartial']??=false;
      
      return Grade.fromJson(resJson);
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
          final double finalGrade=(v['final_grade'] as num?)?.toDouble() ?? 0.0;
          final int cfu=(v['cfu'] as num?)?.toInt()??0;
          sumPartialGrades+=finalGrade;
          sumPartialCfu+=cfu;
        }
      }

      if(resNormal.isNotEmpty){
        for(var v in resNormal){
          final double val=(v['value'] as num?)?.toDouble()??0.0;
          final int cfu = (v['cfu'] as num?)?.toInt()??0;
          sumNormalGrades+=val*cfu;
          sumNormalCfu+=cfu;
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
