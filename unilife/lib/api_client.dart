import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unilife/model/user_model.dart';


//TODO: sicurezza password e correttezza email

class ApiClient{
  final SupabaseClient _supabase=Supabase.instance.client;

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
    } on AuthException catch (e) { //eccezione causata da supabase (password, email ecc...)
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
    }on AuthException catch(e){
      rethrow;
    }catch(e){
      rethrow;
    }
  }
}