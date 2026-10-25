import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'config/dev_api_host.dart';
import 'data/mock_data.dart';
import 'screens/home/home_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'services/api_config.dart';
import 'services/auth_service.dart';
import 'services/fabricare_api_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const envHost = String.fromEnvironment('API_HOST');
  if (envHost.isNotEmpty) {
    ApiConfig.hostOverride = envHost;
  } else if (kDebugMode &&
      const bool.fromEnvironment('USE_LOCAL_API') &&
      kDevApiHostOverride != null) {
    ApiConfig.hostOverride = kDevApiHostOverride;
  }

  await FabricCareApiService.instance.init();
  await AppData.instance.init();
  await AuthService.instance.init();
  void syncHistoryAccount() => AppData.instance
      .setUserId(AuthService.instance.currentUser?.id.toString());
  syncHistoryAccount();
  AuthService.instance.addListener(syncHistoryAccount);
  runApp(const FabriCareApp());
}

class FabriCareApp extends StatelessWidget {
  const FabriCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FabriCare',
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

/// Routes to home when a session exists, otherwise onboarding/login flow.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        if (AuthService.instance.isLoggedIn) {
          return const HomeShell();
        }
        return const OnboardingScreen();
      },
    );
  }
}
