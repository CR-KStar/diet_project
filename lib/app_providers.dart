import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/viewmodel/navigation_view_model.dart';
import 'package:diet_project/ui/growth/viewmodel/plant_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/ai_consent_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/mission_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/notification_inbox_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/today_view_model.dart';
import 'package:diet_project/ui/home/viewmodel/recommendation_view_model.dart';
import 'package:diet_project/ui/onboarding/viewmodel/auth_view_model.dart';
import 'package:diet_project/ui/onboarding/viewmodel/profile_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/bowl_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/exercise_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/meal_draft_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/meal_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/photo_analysis_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/records_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/routine_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/water_view_model.dart';
import 'package:diet_project/ui/record/viewmodel/weight_view_model.dart';
import 'package:diet_project/ui/report_settings/viewmodel/report_view_model.dart';
import 'package:diet_project/ui/social/viewmodel/challenge_view_model.dart';
import 'package:diet_project/ui/social/viewmodel/friend_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

/// 앱 전체에 AppState와, 화면이 직접 구독하는 ViewModel들을 내려준다.
///
/// 화면은 필요한 ViewModel만 `context.watch<FriendViewModel>()`처럼 구독하고, 화면 이동은 NavigationViewModel에, 여러 기능을
/// 엮는 동작만 AppState에 부탁한다. 앱(main.dart)과 위젯 테스트가 같은 구성을 쓴다.
class AppProviders extends StatelessWidget {
  const AppProviders({super.key, required this.state, required this.child});

  final AppState state;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<NavigationViewModel>.value(
          value: state.navigationViewModel,
        ),
        ChangeNotifierProvider<AuthViewModel>.value(value: state.authViewModel),
        ChangeNotifierProvider<AiConsentViewModel>.value(
          value: state.aiConsentViewModel,
        ),
        ChangeNotifierProvider<NotificationInboxViewModel>.value(
          value: state.notificationInboxViewModel,
        ),
        ChangeNotifierProvider<ProfileViewModel>.value(
          value: state.profileViewModel,
        ),
        ChangeNotifierProvider<WaterViewModel>.value(
          value: state.waterViewModel,
        ),
        ChangeNotifierProvider<WeightViewModel>.value(
          value: state.weightViewModel,
        ),
        ChangeNotifierProvider<ExerciseViewModel>.value(
          value: state.exerciseViewModel,
        ),
        ChangeNotifierProvider<MealViewModel>.value(value: state.mealViewModel),
        ChangeNotifierProvider<MealDraftViewModel>.value(
          value: state.mealDraftViewModel,
        ),
        ChangeNotifierProvider<BowlViewModel>.value(value: state.bowlViewModel),
        ChangeNotifierProvider<RoutineViewModel>.value(
          value: state.routineViewModel,
        ),
        ChangeNotifierProvider<PlantViewModel>.value(
          value: state.plantViewModel,
        ),
        ChangeNotifierProvider<PhotoAnalysisViewModel>.value(
          value: state.photoAnalysisViewModel,
        ),
        ChangeNotifierProvider<MissionViewModel>.value(
          value: state.missionViewModel,
        ),
        ChangeNotifierProvider<RecordsViewModel>.value(
          value: state.recordsViewModel,
        ),
        ChangeNotifierProvider<TodayViewModel>.value(
          value: state.todayViewModel,
        ),
        ChangeNotifierProvider<ReportViewModel>.value(
          value: state.reportViewModel,
        ),
        ChangeNotifierProvider<RecommendationViewModel>.value(
          value: state.recommendationViewModel,
        ),
        ChangeNotifierProvider<FriendViewModel>.value(
          value: state.friendViewModel,
        ),
        ChangeNotifierProvider<ChallengeViewModel>.value(
          value: state.challengeViewModel,
        ),
      ],
      child: child,
    );
  }
}
