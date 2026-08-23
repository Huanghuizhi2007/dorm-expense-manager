import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_controller.dart';
import '../../state/dorm_controller.dart';
import '../auth/login_page.dart';
import '../setup/splash_page.dart';
import 'home_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final dorm = context.watch<DormController>();

    if (auth.isInitializing) return const SplashPage();
    final profile = auth.profile;
    if (profile == null) return const LoginPage();

    final future = dorm.bootstrap(profile.id);
    return FutureBuilder<void>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            dorm.dormitories.isEmpty &&
            dorm.currentDormitory == null) {
          return const SplashPage();
        }
        return const HomeShell();
      },
    );
  }
}

