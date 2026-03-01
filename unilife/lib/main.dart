import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'api_client.dart';
import 'login_page.dart';

late final ApiClient apiClient;

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bzvlywpbmlelqcsnkklj.supabase.co',
    anonKey: 'sb_publishable_xlSSwoM1l4ArAfQHdsCFGQ_umcYkzBa',
  );

  final supabase=Supabase.instance.client;

  apiClient=ApiClient(supabase: supabase);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context){
    return ShadApp(
      title: 'Unilife',
      theme: ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadZincColorScheme.dark(),
      ),
      home: const LoginPage(),
    );
  }
}