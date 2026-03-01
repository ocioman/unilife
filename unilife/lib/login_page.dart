import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'signup_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  final bool showSuccessToast;
  const LoginPage({super.key, this.showSuccessToast = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showSuccessToast) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ShadToaster.of(context).show(
          ShadToast(
            title: const Text('Registrazione avvenuta con successo'),
            description: const Text('Accedi con le tue credenziali'),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore'),
          description: const Text('Inserisci email e password.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await apiClient.signIn(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore di accesso'),
          description: Text(e.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('Errore'),
          description: const Text('Si è verificato un errore. Riprova.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: ShadToaster(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Logo
                SvgPicture.asset(
                  'assets/logos/logo.svg',
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 48),
                // Card
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
                      // Password
                      const Text('Password',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      const SizedBox(height: 6),
                      ShadInput(
                        controller: _passwordController,
                        padding:  EdgeInsets.only(left: 12, top: 2.5, bottom: 2.5, right: 12),
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
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 21,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Login button
                      SizedBox(
                        width: double.infinity,
                        child: ShadButton(
                          onPressed: _isLoading ? null : _login,
                          leading: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.black),
                                )
                              : const Icon(Icons.person_outline, size: 18),
                          child: const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Signup link
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const SignupPage(),
                            ));
                          },
                          child: const Text(
                            'Non hai un account? Registrati ora!',
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