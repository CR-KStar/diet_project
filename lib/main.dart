import 'package:diet_project/app_shell.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/auth/firebase_auth_service.dart';
import 'package:diet_project/firebase_options.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';

/// Firebase를 설정하기 전에는 가짜 로그인(MockAuthService)으로 앱이 그대로 돌아갑니다.
/// `flutterfire configure`까지 마친 뒤에는 이렇게 실행하면 실제 로그인이 켜집니다.
///
///   flutter run --dart-define=USE_FIREBASE=true --dart-define=GOOGLE_SERVER_CLIENT_ID=<웹 클라이언트 ID>
const _useFirebase = bool.fromEnvironment('USE_FIREBASE');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthService auth = MockAuthService();
  if (_useFirebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    auth = FirebaseAuthService();
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppState(auth: auth),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diet Project',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppShell(),
    );
  }
}
