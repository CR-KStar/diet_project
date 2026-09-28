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
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

  final state = AppState(
    auth: auth,
    profiles: profiles,
    waterRepo: water,
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

  runApp(ChangeNotifierProvider.value(value: state, child: const MyApp()));
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
      home: const AppShell(),
    );
  }
}
