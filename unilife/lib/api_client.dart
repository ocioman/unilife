import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unilife/model/user_model.dart';

import 'model/exam.dart';
import 'model/grade.dart';


//TODO: sicurezza password e correttezza email

class ApiClient{
  final SupabaseClient _supabase=Supabase.instance.client;
  late String currUuid;

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

          currUuid=res.user!.id; //evito il join nelle query per i fetch
          //uso il bang perché a questo punto sono sicuro che user non sia null, altrimenti avrei già catturato l'eccezione
          return UserModel.fromJson(resJson);
    }on AuthException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<List<Exam>> fetchExams() async{
    try{
        List<dynamic> resJson=await _supabase
            .from('exams')
            .select()
            .eq('userID', currUuid);

        return resJson.map((examJson)=>Exam.fromJson(examJson)).toList();
    }on AuthException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }

  Future<List<Grade>> fetchGrades() async{
    try{
      List<dynamic> resJson=await _supabase
          .from('grades')
          .select()
          .eq('userID', currUuid);

      return resJson.map((gradesJson)=>Grade.fromJson(gradesJson)).toList();
    }on AuthException{
      rethrow;
    }catch(e){
      rethrow;
    }
  }
}