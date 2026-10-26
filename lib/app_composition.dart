import 'package:diet_project/app_dependencies.dart';
import 'package:diet_project/config/firestore_collections.dart';
import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/auth/impl/firebase_auth_service.dart';
import 'package:diet_project/data/auth/impl/mock_auth_service.dart';
import 'package:diet_project/data/repositories/impl/firestore_activity_feed_repository.dart';
import 'package:diet_project/data/repositories/impl/firestore_challenge_repository.dart';
import 'package:diet_project/data/repositories/impl/firestore_friend_repository.dart';
import 'package:diet_project/data/repositories/impl/firestore_profile_repository.dart';
import 'package:diet_project/data/repositories/impl/firestore_record_repository.dart';
import 'package:diet_project/data/repositories/impl/firestore_water_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_activity_feed_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_challenge_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_friend_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_profile_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_record_repository.dart';
import 'package:diet_project/data/repositories/impl/memory_water_repository.dart';
import 'package:diet_project/data/repositories/record_codecs.dart';
import 'package:diet_project/data/services/ai_consent_store.dart';
import 'package:diet_project/data/services/app_icon_service.dart';
import 'package:diet_project/data/services/impl/cloud_meal_analysis_service.dart';
import 'package:diet_project/data/services/impl/cloud_meal_recommendation_service.dart';
import 'package:diet_project/data/services/impl/file_meal_photo_store.dart';
import 'package:diet_project/data/services/impl/local_notification_service.dart';
import 'package:diet_project/data/services/impl/memory_meal_photo_store.dart';
import 'package:diet_project/data/services/impl/memory_ai_consent_store.dart';
import 'package:diet_project/data/services/impl/platform_app_icon_service.dart';
import 'package:diet_project/data/services/meal_analysis_service.dart';
import 'package:diet_project/data/services/meal_photo_store.dart';
import 'package:diet_project/data/services/meal_recommendation_service.dart';
import 'package:diet_project/data/services/notification_service.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/repositories/activity_feed_repository.dart';
import 'package:diet_project/domain/repositories/challenge_repository.dart';
import 'package:diet_project/domain/repositories/friend_repository.dart';
import 'package:diet_project/domain/repositories/profile_repository.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';
import 'package:diet_project/domain/repositories/water_repository.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// 어떤 구현을 끼울지 고르는 곳 — 앱(main.dart)과 테스트가 여기서 조립한다.
// AppState는 이 구현들을 모르고 AppDependencies(인터페이스)만 받는다.

/// 서버 없이 도는 구성 — 기록은 메모리에만 남고 로그인은 가짜다.
/// 웹 체험판(`USE_FIREBASE=false`)과 테스트가 쓴다. 바꾸고 싶은 것만 넘기면 된다.
AppDependencies memoryDependencies({
  AuthService? auth,
  ProfileRepository? profiles,
  WaterRepository? waterRepo,
  RecordRepository<WeightEntry>? weightRepo,
  RecordRepository<ExerciseLog>? exerciseRepo,
  RecordRepository<MealLog>? mealRepo,
  RecordRepository<Bowl>? bowlRepo,
  RecordRepository<Routine>? routineRepo,
  RecordRepository<Plant>? plantRepo,
  RecordRepository<DexEntry>? dexRepo,
  FriendRepository? friendRepo,
  ChallengeRepository? challengeRepo,
  ActivityFeedRepository? activityFeedRepo,
  AiConsentStore? aiConsentStore,
  MealAnalysisService? mealAnalysisService,
  MealRecommendationService? mealRecommendationService,
  NotificationService? notificationService,
  AppIconService? appIconService,
  MealPhotoStore? mealPhotoStore,
  DateTime Function()? now,
}) {
  return AppDependencies(
    auth: auth ?? MockAuthService(),
    profiles: profiles ?? MemoryProfileRepository(),
    waterRepo: waterRepo ?? MemoryWaterRepository(),
    weightRepo: weightRepo ?? MemoryRecordRepository(weightCodec),
    exerciseRepo: exerciseRepo ?? MemoryRecordRepository(exerciseCodec),
    mealRepo: mealRepo ?? MemoryRecordRepository(mealCodec),
    bowlRepo: bowlRepo ?? MemoryRecordRepository(bowlCodec),
    routineRepo: routineRepo ?? MemoryRecordRepository(routineCodec),
    plantRepo: plantRepo ?? MemoryRecordRepository(plantCodec),
    dexRepo: dexRepo ?? MemoryRecordRepository(dexEntryCodec),
    friendRepo: friendRepo ?? MemoryFriendRepository(),
    challengeRepo: challengeRepo ?? MemoryChallengeRepository(),
    activityFeedRepo: activityFeedRepo ?? MemoryActivityFeedRepository(),
    aiConsentStore: aiConsentStore ?? MemoryAiConsentStore(),
    mealAnalysisService: mealAnalysisService ?? CloudMealAnalysisService(),
    mealRecommendationService:
        mealRecommendationService ?? CloudMealRecommendationService(),
    notificationService: notificationService ?? LocalNotificationService(),
    appIconService: appIconService ?? PlatformAppIconService(),
    mealPhotoStore: mealPhotoStore ?? MemoryMealPhotoStore(),
    now: now ?? DateTime.now,
  );
}

/// 실제 서비스 구성 — Firebase 로그인과 Firestore 저장.
/// Firebase 초기화는 호출하기 전에 끝나 있어야 한다.
AppDependencies firebaseDependencies({required AiConsentStore aiConsentStore}) {
  return memoryDependencies(
    auth: FirebaseAuthService(),
    profiles: FirestoreProfileRepository(),
    waterRepo: FirestoreWaterRepository(),
    weightRepo: FirestoreRecordRepository(
      FirestoreCollections.weight,
      weightCodec,
    ),
    exerciseRepo: FirestoreRecordRepository(
      FirestoreCollections.exercise,
      exerciseCodec,
    ),
    mealRepo: FirestoreRecordRepository(FirestoreCollections.meals, mealCodec),
    bowlRepo: FirestoreRecordRepository(FirestoreCollections.bowls, bowlCodec),
    routineRepo: FirestoreRecordRepository(
      FirestoreCollections.routines,
      routineCodec,
    ),
    plantRepo: FirestoreRecordRepository(
      FirestoreCollections.plant,
      plantCodec,
    ),
    dexRepo: FirestoreRecordRepository(
      FirestoreCollections.dexEntries,
      dexEntryCodec,
    ),
    friendRepo: FirestoreFriendRepository(),
    challengeRepo: FirestoreChallengeRepository(),
    activityFeedRepo: FirestoreActivityFeedRepository(),
    aiConsentStore: aiConsentStore,
    // 사진은 이 기기 안에만 보관한다. 웹은 파일을 쓸 수 없어 새로고침하면 사라진다.
    mealPhotoStore: kIsWeb ? MemoryMealPhotoStore() : FileMealPhotoStore(),
  );
}
