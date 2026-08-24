import 'package:flutter/material.dart';

import 'app.dart';
import 'core/app_config.dart';
import 'core/app_theme.dart';
import 'data/supabase_service.dart';
import 'ui/setup/setup_guide_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.isConfigured) {
    runApp(
      MaterialApp(
        title: 'ourbills',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const SetupGuidePage(),
      ),
    );
    return;
  }
  await SupabaseService.initialize(
    AppConfig.supabaseUrl,
    AppConfig.supabaseAnonKey,
  );
  runApp(const OurBillsApp());
}
