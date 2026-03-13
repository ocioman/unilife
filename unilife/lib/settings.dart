import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unilife/main.dart';

import 'model/user_model.dart';

class Settings extends StatefulWidget{
  final UserModel _activeUser;

  const Settings({super.key, required activeUser}):
      _activeUser=activeUser;

  UserModel get activeUser=>_activeUser;

  set activeUserEmail(String email)=>_activeUser.email=email;

  @override
  State<StatefulWidget> createState()=>_SettingsState();
}

class _SettingsState extends State<Settings>{
  final _passwordController=TextEditingController();
  final _newPasswordController=TextEditingController();
  final _newEmailController=TextEditingController();
  bool _isLoadingDialog=false;

  @override
  void dispose(){
    _passwordController.dispose();
    _newPasswordController.dispose();
    _newEmailController.dispose();
    super.dispose();
  }

  void _goBack(){
      if(!mounted) return;
      Navigator.of(context).pop();
  }

  Future<void> _updateEmail(BuildContext dialogContext) async{
    final String newEmail=_newEmailController.text.trim();
    final String password=_passwordController.text.trim();

    if(newEmail.isEmpty || password.isEmpty){
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Compila tutti i campi.'),
        )
      );
    }

    final navigator = Navigator.of(dialogContext);

    setState(()=>_isLoadingDialog=true);

    try{
        await apiClient.updateEmail(
            newEmail: newEmail,
            password: password
        );
        if(!mounted) return;
        navigator.pop();
        widget.activeUserEmail=newEmail;
    }on AuthException{
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Password errata.'),
        ),
      );
    }catch(e){
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile modificare l\'email.'),
        ),
      );
    }finally{
      if (mounted) setState(() => _isLoadingDialog = false);
    }
  }

  Future<void> _updatePassword(BuildContext dialogContext) async{
    String? oldPassword=_passwordController.text.trim();
    String? newPassword=_newPasswordController.text.trim();

    if(oldPassword.isEmpty || newPassword.isEmpty){
      ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Compila tutti i campi.'),
          )
      );
    }

    final navigator = Navigator.of(dialogContext);

    setState(()=>_isLoadingDialog=true);

    try{
      await apiClient.updatePassword(
          oldPassword: oldPassword,
          newPassword: newPassword
      );
      if(!mounted) return;
      navigator.pop();
    }on AuthException{
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Password errata.'),
        ),
      );
    }catch(e){
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Impossibile modificare la password.'),
        ),
      );
    }finally{
      newPassword=null;
      oldPassword=null;
      if (mounted) setState(() => _isLoadingDialog = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text(
          'Impostazioni',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: Builder(
            builder: (context){
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _goBack,
              );
            }
        ),
      ),
      body: ShadToaster(
        child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Center(
                      child: const Text(
                          'Sicurezza Account',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                          ),
                      ),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                ],
              ),
            ),
        ),
      ),
    );
  }

}