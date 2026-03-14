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
  bool _obscurePassword=true;
  bool _obscureNewPassword=true;
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

  Future<void> _updateEmail(BuildContext dialogContext, void Function(void Function()) setDialogState) async{
    final String newEmail=_newEmailController.text.trim();
    final String password=_passwordController.text.trim();

    if(newEmail.isEmpty || password.isEmpty){
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          title: Text('Errore'),
          description: Text('Compila tutti i campi.'),
        )
      );
      return;
    }

    final navigator = Navigator.of(dialogContext);

    setDialogState(()=>_isLoadingDialog=true);

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
      if (mounted) setDialogState(() => _isLoadingDialog = false);
    }
  }

  Future<void> _updatePassword(BuildContext dialogContext, void Function(void Function()) setDialogState) async{
    String? oldPassword=_passwordController.text.trim();
    String? newPassword=_newPasswordController.text.trim();

    if(oldPassword.isEmpty || newPassword.isEmpty){
      ShadToaster.of(context).show(
          const ShadToast.destructive(
            title: Text('Errore'),
            description: Text('Compila tutti i campi.'),
          )
      );
      return;
    }

    final navigator = Navigator.of(dialogContext);

    setDialogState(()=>_isLoadingDialog=true);

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
      if (mounted) setDialogState(() => _isLoadingDialog = false);
    }
  }

  void _showUpdateEmailDialog(){
    _isLoadingDialog=false;
    _newEmailController.clear();
    _passwordController.clear();
    _obscurePassword=true;

    showDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: false, //questo determina se con un tap fuori dal dialog posso chiuderlo
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Modifica Email',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: const Icon(Icons.close, color: Colors.white54, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text('Nuova Email', style: TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(height: 6),
                            ShadInput(
                              controller: _newEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: ShadDecoration(
                                border: ShadBorder.all(
                                  color: const Color(0xFF666666),
                                  width: 1.5,
                                  radius: BorderRadius.circular(8),
                                ),
                                focusedBorder: ShadBorder.all(
                                  color: Colors.white,
                                  width: 1.5,
                                  radius: BorderRadius.circular(8),
                                ),
                                disableSecondaryBorder: true,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Inserisci la tua password per confermare',
                              style: TextStyle(color: Colors.white, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            ShadInput(
                              controller: _passwordController,
                              padding:  EdgeInsets.only(left: 12, top: 2, bottom: 2, right: 12),
                              obscureText: _obscurePassword,
                              decoration: ShadDecoration(
                                border: ShadBorder.all(
                                  color: const Color(0xFF666666),
                                  width: 1.5,
                                  radius: BorderRadius.circular(8),
                                ),
                                focusedBorder: ShadBorder.all(
                                  color: Colors.white,
                                  width: 1.5,
                                  radius: BorderRadius.circular(8),
                                ),
                                disableSecondaryBorder: true,
                              ),
                              trailing: ShadIconButton.ghost(
                                width: 24,
                                height: 24,
                                padding: EdgeInsets.zero,
                                onPressed: ()=>
                                    setDialogState(()=> _obscurePassword=!_obscurePassword),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 21,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ShadButton.outline(
                            child: const Text('Annulla'),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          const SizedBox(width: 8),
                          ShadButton(
                            onPressed:
                            _isLoadingDialog?null:()=>_updateEmail(dialogContext, setDialogState),
                            leading:
                            _isLoadingDialog
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                                : null,
                            child: const Text('Salva'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
        )
    );
  }

  void _showUpdatePasswordDialog(){
    _isLoadingDialog=false;
    _passwordController.clear();
    _newPasswordController.clear();
    _obscurePassword=true;
    _obscureNewPassword=true;

    showDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: false,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return Dialog(
                backgroundColor: const Color(0xFF18181B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Modifica Password',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(dialogContext).pop(),
                            child: const Icon(Icons.close, color: Colors.white54, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            const Text('Password Attuale', style: TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(height: 6),
                            ShadInput(
                              controller: _passwordController,
                              padding: EdgeInsets.only(left: 12, top: 2, bottom: 2, right: 12),
                              obscureText: _obscurePassword,
                              decoration: ShadDecoration(
                                border: ShadBorder.all(
                                  color: const Color(0xFF666666),
                                  width: 1.5,
                                  radius: BorderRadius.circular(8),
                                ),
                                focusedBorder: ShadBorder.all(
                                  color: Colors.white,
                                  width: 1.5,
                                  radius: BorderRadius.circular(8),
                                ),
                                disableSecondaryBorder: true,
                              ),
                              trailing: ShadIconButton.ghost(
                                width: 24,
                                height: 24,
                                padding: EdgeInsets.zero,
                                onPressed: ()=>
                                    setDialogState(()=> _obscurePassword=!_obscurePassword),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 21,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text('Nuova Password', style: TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(height: 6),
                            ShadInput(
                              controller: _newPasswordController,
                              padding: EdgeInsets.only(left: 12, top: 2, bottom: 2, right: 12),
                              obscureText: _obscureNewPassword,
                              decoration: ShadDecoration(
                                border: ShadBorder.all(
                                  color: const Color(0xFF666666),
                                  width: 1.5,
                                  radius: BorderRadius.circular(8),
                                ),
                                focusedBorder: ShadBorder.all(
                                  color: Colors.white,
                                  width: 1.5,
                                  radius: BorderRadius.circular(8),
                                ),
                                disableSecondaryBorder: true,
                              ),
                              trailing: ShadIconButton.ghost(
                                width: 24,
                                height: 24,
                                padding: EdgeInsets.zero,
                                onPressed: ()=>
                                    setDialogState(()=> _obscureNewPassword=!_obscureNewPassword),
                                icon: Icon(
                                  _obscureNewPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 21,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ShadButton.outline(
                            child: const Text('Annulla'),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          const SizedBox(width: 8),
                          ShadButton(
                            onPressed:
                            _isLoadingDialog?null:()=>_updatePassword(dialogContext, setDialogState),
                            leading:
                            _isLoadingDialog
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                                : null,
                            child: const Text('Salva'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
        )
    );
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
              return GestureDetector(
                onTap: _goBack,
                child: Container(
                  color: Colors.transparent, // Necessario per prendere i tap ovunque
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.arrow_back),
                ),
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
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: ()=>_showUpdateEmailDialog(),
                      leading: const Icon(Icons.email, size: 18),
                      child: const Text('Modifica Email'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: ()=>_showUpdatePasswordDialog(),
                      leading: const Icon(Icons.lock, size: 18),
                      child: const Text('Modifica Password'),
                    ),
                  )
                ],
              ),
            ),
        ),
      ),
    );
  }

}