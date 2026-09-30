import 'package:diet_project/app_shell.dart';
import 'package:diet_project/data/auth/mock_auth_service.dart';
import 'package:diet_project/data/auth/firebase_auth_service.dart';
import 'package:diet_project/data/repositories/firestore_challenge_repository.dart';
import 'package:diet_project/data/repositories/challenge_repository.dart';
import 'package:diet_project/data/repositories/firestore_friend_repository.dart';
import 'package:diet_project/data/repositories/friend_repository.dart';
import 'package:diet_project/data/repositories/firestore_profile_repository.dart';
import 'package:diet_project/data/repositories/firestore_record_repository.dart';
import 'package:diet_project/data/repositories/firestore_water_repository.dart';
import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/data/repositories/record_repository.dart';
import 'package:diet_project/data/repositories/water_repository.dart';
import 'package:diet_project/data/repositories/profile_repository.dart';
import 'package:diet_project/firebase_options.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/ui/record/viewmodel/water_view_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'data/auth/auth_service.dart';

/// 기본은 Firebase(실제 로그인 · 저장)다. 화면만 확인할 땐 아래 옵션으로 끈다.
///   flutter run --dart-define=USE_FIREBASE=false
const _useFirebase = bool.fromEnvironment('USE_FIREBASE', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AuthService auth = MockAuthService();
  ProfileRepository profiles = MemoryProfileRepository();
  WaterRepository water = MemoryWaterRepository();
  RecordRepository<WeightEntry>? weight;
  RecordRepository<ExerciseLog>? exercise;
  RecordRepository<MealLog>? meals;
  RecordRepository<Bowl>? bowls;
  RecordRepository<Routine>? routines;
  RecordRepository<Plant>? plant;
  RecordRepository<DexEntry>? dex;
  FriendRepository? friends;
  ChallengeRepository? challenges;
  if (_useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    auth = FirebaseAuthService();
    profiles = FirestoreProfileRepository();
    water = FirestoreWaterRepository();
    weight = FirestoreRecordRepository('weight', weightCodec);
    exercise = FirestoreRecordRepository('exercise', exerciseCodec);
    meals = FirestoreRecordRepository('meals', mealCodec);
    bowls = FirestoreRecordRepository('bowls', bowlCodec);
    routines = FirestoreRecordRepository('routines', routineCodec);
    plant = FirestoreRecordRepository('plant', plantCodec);
    dex = FirestoreRecordRepository('dexEntries', dexEntryCodec);
    friends = FirestoreFriendRepository();
    challenges = FirestoreChallengeRepository();
  }

  debugPrint(
    '[앱 시작] 로그인 방식: ${_useFirebase ? 'Firebase (저장됨)' : 'Mock (저장 안 됨)'}',
  );

  final waterViewModel = WaterViewModel(waterRepo: water);

  final state = AppState(
    auth: auth,
    profiles: profiles,
    waterViewModel: waterViewModel,
    weightRepo: weight,
    exerciseRepo: exercise,
    mealRepo: meals,
    bowlRepo: bowls,
    routineRepo: routines,
    plantRepo: plant,
    dexRepo: dex,
    friendRepo: friends,
    challengeRepo: challenges,
  );

  await state.restoreSession();

  state.addListener(() {
    final message = state.takeNotice();
    if (message == null) return;
    messengerKey.currentState
      ?..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: state),
        ChangeNotifierProvider.value(value: waterViewModel),
      ],
      child: const MyApp(),
    ),
  );
}

/// 화면 밖에서 스낵바를 띄우기 위한 키.
final messengerKey = GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diet Project',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: buildAppTheme(),
      // 이 앱은 Navigator 라우트 대신 AppState.screen 문자열로 화면을
      // 바꾸는 구조라서, 기본 뒤로가기(Navigator pop)가 걸 게 없어 안드로이드
      // 시스템 뒤로가기를 누르면 곧장 앱이 꺼져버린다. 그래서 시스템
      // 뒤로가기를 직접 가로채 AppState.handleSystemBack()에 맡기고, 정말
      // 더 갈 곳이 없을 때만 SystemNavigator.pop()으로 앱을 종료한다.
      home: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          final handled = context.read<AppState>().handleSystemBack();
          if (!handled) SystemNavigator.pop();
        },
        child: const AppShell(),
      ),
    );
  }
}
