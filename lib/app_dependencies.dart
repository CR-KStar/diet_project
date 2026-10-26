import 'package:diet_project/data/auth/auth_service.dart';
import 'package:diet_project/data/services/ai_consent_store.dart';
import 'package:diet_project/data/services/app_icon_service.dart';
import 'package:diet_project/data/services/meal_analysis_service.dart';
import 'package:diet_project/data/services/meal_photo_store.dart';
import 'package:diet_project/data/services/meal_recommendation_service.dart';
import 'package:diet_project/data/services/notification_service.dart';
import 'package:diet_project/domain/models/models.dart';
import 'package:diet_project/domain/repositories/activity_feed_repository.dart';
import 'package:diet_project/domain/repositories/block_repository.dart';
import 'package:diet_project/domain/repositories/challenge_repository.dart';
import 'package:diet_project/domain/repositories/friend_repository.dart';
import 'package:diet_project/domain/repositories/profile_repository.dart';
import 'package:diet_project/domain/repositories/record_repository.dart';
import 'package:diet_project/domain/repositories/report_repository.dart';
import 'package:diet_project/domain/repositories/water_repository.dart';

/// AppState가 일하는 데 필요한 저장소 · 서비스 모음 — 전부 인터페이스(계약)다.
///
/// 어떤 구현(Firebase · 메모리 · 기기 기능)을 끼울지는 AppState가 정하지 않는다.
/// 그 선택은 `app_composition.dart`가 하고, 앱(main.dart)과 테스트가 그 결과를 넘겨준다.
class AppDependencies {
  const AppDependencies({
    required this.auth,
    required this.profiles,
    required this.waterRepo,
    required this.weightRepo,
    required this.exerciseRepo,
    required this.mealRepo,
    required this.bowlRepo,
    required this.routineRepo,
    required this.plantRepo,
    required this.dexRepo,
    required this.friendRepo,
    required this.challengeRepo,
    required this.activityFeedRepo,
    required this.blockRepo,
    required this.reportRepo,
    required this.aiConsentStore,
    required this.mealAnalysisService,
    required this.mealRecommendationService,
    required this.notificationService,
    required this.appIconService,
    required this.mealPhotoStore,
    this.now = DateTime.now,
  });

  final AuthService auth;
  final ProfileRepository profiles;
  final WaterRepository waterRepo;
  final RecordRepository<WeightEntry> weightRepo;
  final RecordRepository<ExerciseLog> exerciseRepo;
  final RecordRepository<MealLog> mealRepo;
  final RecordRepository<Bowl> bowlRepo;
  final RecordRepository<Routine> routineRepo;
  final RecordRepository<Plant> plantRepo;
  final RecordRepository<DexEntry> dexRepo;
  final FriendRepository friendRepo;
  final ChallengeRepository challengeRepo;
  final ActivityFeedRepository activityFeedRepo;
  final BlockRepository blockRepo;
  final ReportRepository reportRepo;
  final AiConsentStore aiConsentStore;
  final MealAnalysisService mealAnalysisService;
  final MealRecommendationService mealRecommendationService;
  final NotificationService notificationService;
  final AppIconService appIconService;
  final MealPhotoStore mealPhotoStore;

  /// 테스트에서 날짜를 고정할 수 있도록 시계를 주입받는다.
  final DateTime Function() now;
}
