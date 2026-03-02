import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState()=> _SignupPageState();
}

class _SignupPageState extends State<SignupPage>{
  final _nomeController=TextEditingController();
  final _secondoNomeController=TextEditingController();
  final _cognomeController=TextEditingController();
  final _emailController=TextEditingController();
  final _passwordController=TextEditingController();
  bool _obscurePassword=true;
  bool _isLoading=false;

  @override
  void dispose() {
    _nomeController.dispose();
    _secondoNomeController.dispose();
    _cognomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final nome=_nomeController.text.trim();
    final cognome=_cognomeController.text.trim();
    final email=_emailController.text.trim();
    final password=_passwordController.text;
    final secondoNome=_secondoNomeController.text.trim();

    if(nome.isEmpty||cognome.isEmpty||email.isEmpty||password.isEmpty) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore'),
          description: const Text('Compila tutti i campi obbligatori.'),
        ),
      );
      return;
    }

    setState(()=> _isLoading=true);
    try{
      await apiClient.signUp(
        email: email,
        password: password,
        nome1: nome,
        nome2: secondoNome.isEmpty ? null : secondoNome,
        cognome1: cognome,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_)=>const LoginPage(showSuccessToast: true),
        ),
        (route)=>false,
      );
    }on AuthException catch(e){
      if(!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore di registrazione'),
          description: Text(e.message),
        ),
      );
    }catch(e){
      if(!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore'),
          description: const Text('Si è verificato un errore. Riprova.'),
        ),
      );
    }finally{
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: ShadToaster(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 16),
                SvgPicture.asset(
                  'assets/logos/logo.svg',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF232323),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF333333)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nome',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 6),
                      ShadInput(
                        controller: _nomeController,
                        placeholder: const Text('Inserisci il tuo nome'),
                        keyboardType: TextInputType.name,
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
                      const Text('Secondo nome (opzionale)',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 6),
                      ShadInput(
                        controller: _secondoNomeController,
                        placeholder: const Text('Inserisci il tuo secondo nome'),
                        keyboardType: TextInputType.name,
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
                      const Text('Cognome',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 6),
                      ShadInput(
                        controller: _cognomeController,
                        placeholder: const Text('Inserisci il tuo cognome'),
                        keyboardType: TextInputType.name,
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
                      // Email
                      const Text('Email',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 6),
                      ShadInput(
                        controller: _emailController,
                        placeholder: const Text('Inserisci la tua email'),
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
                      const Text('Password',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 6),
                      ShadInput(
                        controller: _passwordController,
                        padding:  EdgeInsets.only(left: 12, top: 2, bottom: 2, right: 12),
                        placeholder: const Text('Inserisci la tua password'),
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
                          onPressed:()=>
                              setState(()=> _obscurePassword=!_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 18,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ShadButton(
                          onPressed: _isLoading ? null : _signUp,
                          leading: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.person_add_outlined, size: 18),
                          child: const Text('Registrati'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: GestureDetector(
                          onTap: ()=> Navigator.of(context).pop(),
                          child: const Text(
                            'Hai già un account? Accedi ora!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
