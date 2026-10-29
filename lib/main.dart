import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_scope.dart';
import 'core/network/api_service.dart';
import 'core/session/session_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/motion.dart';
import 'core/theme/tokens.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/shell/app_shell.dart';
import 'shared/widgets/crescendo_logo.dart';
import 'shared/widgets/feedback.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light.copyWith(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: CrColors.bg2,
  ));
  final session = SessionController(ApiService())..restore();
  runApp(CrescendoApp(session: session));
}

class CrescendoApp extends StatelessWidget {
  const CrescendoApp({super.key, required this.session});

  final SessionController session;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: session,
      child: MaterialApp(
        title: 'Crescendo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        scrollBehavior: const CrescendoScrollBehavior(),
        home: const _Root(),
      ),
    );
  }
}

/// Splash while the saved session is checked, then login or the main tabs.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    if (session.isRestoring) {
      return const Scaffold(body: Center(child: CrescendoLogo(size: 30)));
    }
    if (session.startupError != null) {
      return Scaffold(body: ErrorView(message: session.startupError!, onRetry: session.restore));
    }
    return session.isLoggedIn ? const AppShell() : const AuthScreen();
  }
}
