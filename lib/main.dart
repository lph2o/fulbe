import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('fr_FR', null);
  
  await Supabase.initialize(
    url: 'https://zhpzznanatsnvptmoqpf.supabase.co',
    publishableKey: 'sb_publishable_4PstkAbaWyXMCj4SB7rF6g_dj0J8psN',
  );

  runApp(const FulbeConnectApp());
}

class FulbeConnectApp extends StatelessWidget {
  const FulbeConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fulɓe Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.authGate,
      onGenerateRoute: generateRoute,
    );
  }
}
