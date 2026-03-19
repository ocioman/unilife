import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unilife/main.dart';
import 'package:unilife/model/password_validator.dart';

import 'login_page.dart';
import 'model/invalid_email_exception.dart';
import 'model/user_model.dart';

class Settings extends StatefulWidget{
  final UserModel _activeUser;

  const Settings({super.key, required activeUser}):
      _activeUser=activeUser;

  UserModel get activeUser=>_activeUser;

  set activeUserEmail(String email)=>_activeUser.email=email;
  set activeUserName1(String name1)=>_activeUser.name1=name1;
  set activeUserName2(String name2)=>_activeUser.name1=name2;
  set activeUserSurname1(String surname)=>_activeUser.surname=surname;

  @override
  State<StatefulWidget> createState()=>_SettingsState();
}

enum PersonalDataType{
  name1("name1"),
  name2("name2"),
  surname("surname");

  final String value;
  const PersonalDataType(this.value);
}

class _SettingsState extends State<Settings>{
  final _passwordController=TextEditingController();
  final _newPasswordController=TextEditingController();
  final _newEmailController=TextEditingController();
  final _newName1Controller=TextEditingController();
  final _newName2Controller=TextEditingController();
  final _newSurnameController=TextEditingController();

  bool _isLoadingDialog=false;
  bool _obscurePassword=true;
  bool _obscureNewPassword=true;
  bool _newPasswordTouched=false;
  String? _newPasswordError;
  @override
  void dispose(){
    _passwordController.dispose();
    _newPasswordController.dispose();
    _newEmailController.dispose();
    _newName1Controller.dispose();
    _newName2Controller.dispose();
    _newSurnameController.dispose();
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
    }on InvalidEmailException catch(e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore'),
          description: Text(e.message),
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

    final passError=PasswordValidator.validatePassword(newPassword);
    if(passError!=null){
      setDialogState((){
        _newPasswordTouched=true;
        _newPasswordError=passError;
      });
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

  Future<void> _updatePersonalData(PersonalDataType type, BuildContext dialogContext, void Function(void Function()) setDialogState) async{

    String? newPersonalData=(type.value=='name1')?_newName1Controller.text.trim():
    (type.value=='name2')?_newName2Controller.text.trim():_newSurnameController.text.trim();

    if(newPersonalData.isEmpty){
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
      (type.value=='name1')?await apiClient.updatePersonalData(name1: newPersonalData):
      (type.value=='name2')?await apiClient.updatePersonalData(name2: newPersonalData):
      await apiClient.updatePersonalData(surname: newPersonalData);

      if(!mounted) return;
      navigator.pop();
      setState(()=>(type.value=='name1')?widget.activeUser.name1=newPersonalData:
      (type.value=='name2')?widget.activeUser.name2=newPersonalData:widget.activeUser.surname=newPersonalData);
    }catch(e){
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore'),
          description: Text(
            'Impossibile modificare il ${(type.value=='name1' || type.value=='name2')?'nome':'cognome'}'
          ),
        ),
      );
    }finally{
      if (mounted) setDialogState(() => _isLoadingDialog = false);
    }
  }

  Future<void> _deleteAccount(void Function(void Function()) setDialogState) async{
    String? password=_passwordController.text.trim();

    if(password.isEmpty){
      if(!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore'),
          description: const Text('Compila tutti i campi.'),
        ),
      );
      return;
    }

    setDialogState(()=>_isLoadingDialog=true);

    try{
      await apiClient.deleteAccount(password: password);
      if(!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_)=>const LoginPage()),
      );
    }on AuthException{
      if(!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore'),
          description: const Text('Password Errata.'),
        )
      );
    }catch (e){
      if(!context.mounted) return;
      ShadToaster.of(context).show(
          ShadToast.destructive(
            title: const Text('Errore'),
            description: const Text('Impossibile eliminare l\'account'),
          )
      );
    }finally{
      if(mounted) setDialogState(()=>_isLoadingDialog=false);
      password=null;
    }
  }

  void _showUpdatePersonalDataDialog({required PersonalDataType type}){
    _isLoadingDialog=false;

    (type.value=='name1')?_newName1Controller.clear():
    (type.value=='name2')?_newName2Controller.clear():_newSurnameController.clear();

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
                          Expanded(
                            child: Text(
                              'Modifica il ${(type.value=='name1')?'nome':(type.value=='name2')?'secondo nome':'cognome'}',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                            Text(
                                'Nuovo ${(type.value=='name1' || type.value=='name2')?'Nome':'Cognome'}',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                            ),
                            const SizedBox(height: 6),
                            ShadInput(
                              controller: (type.value=='name1')?_newName1Controller:
                              (type.value=='name2')?_newName2Controller:_newSurnameController,
                              keyboardType: TextInputType.text,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ShadButton.outline(
                            child: const Text('Annulla', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                          const SizedBox(width: 8),
                          ShadButton(
                            onPressed:
                            _isLoadingDialog?null:
                            (type.value=='name1')?()=>_updatePersonalData(PersonalDataType.name1, dialogContext, setDialogState):
                            (type.value=='name2')?()=>_updatePersonalData(PersonalDataType.name2, dialogContext, setDialogState):
                            ()=>_updatePersonalData(PersonalDataType.surname, dialogContext, setDialogState),
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
                            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            const Text('Nuova Email', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
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
                            child: const Text('Annulla', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
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
    _newPasswordTouched=false;
    _newPasswordError=null;

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
                            const Text('Password Attuale', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                            const Text('Nuova Password', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            ShadInput(
                              controller: _newPasswordController,
                              padding: const EdgeInsets.only(left: 12, top: 2, bottom: 2, right: 12),
                              obscureText: _obscureNewPassword,
                              onChanged: (password){
                                setDialogState((){
                                  _newPasswordTouched=true;
                                  _newPasswordError=PasswordValidator.validatePassword(password);
                                });
                              },
                              decoration: ShadDecoration(
                                hasError: _newPasswordError!=null&&_newPasswordTouched,
                                errorStyle: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                ),
                                border: ShadBorder.all(
                                  color: (_newPasswordError!=null&&_newPasswordTouched)?Colors.red:const Color(0xFF666666),
                                  width: 1.5,
                                  radius: BorderRadius.circular(8),
                                ),
                                focusedBorder: ShadBorder.all(
                                  color: (_newPasswordError!=null&&_newPasswordTouched)?Colors.red:Colors.white,
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
                            if (_newPasswordError!=null&&_newPasswordTouched)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text(
                                  _newPasswordError!,
                                  style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
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
                            child: const Text('Annulla', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showDeleteAccountDialog(){
    _isLoadingDialog=false;
    _passwordController.clear();
    showDialog(
        context: context,
        barrierColor: Colors.black54,
        barrierDismissible: false,
        builder: (dialogContext)=>StatefulBuilder(
          builder: (context, setDialogState){
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
                            'Eliminazione Account',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4,),
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text('Inserisci la tua password per confermare (L\'AZIONE NON È REVERSIBILE)', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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
                        ShadButton(
                          child: const Text('Annulla', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                        const SizedBox(width: 8),
                        ShadButton.outline(
                          onPressed:
                            _isLoadingDialog?null:()=>_deleteAccount(setDialogState),
                            leading:
                            _isLoadingDialog
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : null,
                          backgroundColor: const Color(0xFFED4337),
                          hoverBackgroundColor: const Color(0xFFC0392B),
                          pressedBackgroundColor: const Color(0xFFC0392B),
                          child: const Text('Elimina', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        ),
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
                      'Informazioni Personali',
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Nome:  ${widget.activeUser.name1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ShadButton(
                          onPressed: () => _showUpdatePersonalDataDialog(type: PersonalDataType.name1),
                          child: const Text('Modifica', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  if (widget.activeUser.name2 != null && widget.activeUser.name2!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Secondo Nome:  ${widget.activeUser.name2}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ShadButton(
                            onPressed: () => _showUpdatePersonalDataDialog(type: PersonalDataType.name2),
                            child: const Text('Modifica', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Cognome:  ${widget.activeUser.surname}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ShadButton(
                          onPressed: () => _showUpdatePersonalDataDialog(type: PersonalDataType.surname),
                          child: const Text('Modifica', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Divider(
                    indent: 5,
                    endIndent: 5,
                    color: Colors.white54,
                    thickness: 0.0,
                  ),
                  SizedBox(
                    height: 15,
                  ),
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
                      child: const Text('Modifica Email', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: ()=>_showUpdatePasswordDialog(),
                      leading: const Icon(Icons.lock, size: 18),
                      child: const Text('Modifica Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      onPressed: () => _showDeleteAccountDialog(),
                      backgroundColor: const Color(0xFFED4337),
                      hoverBackgroundColor: const Color(0xFFC0392B),
                      pressedBackgroundColor: const Color(0xFFC0392B),
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, size: 20, color: Colors.white,),
                          const SizedBox(width: 8),
                          const Text(
                            "Elimina Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ),
        ),
      ),
    );
  }

}