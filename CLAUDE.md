# CLAUDE.md

이 저장소에서 작업할 때 Claude Code가 먼저 읽는 안내예요. 제품 소개는 `README.md`, 구조 규칙은
`ARCHITECTURE.md`에 있고, 여기에는 **작업할 때 알아야 할 것**만 적어요.

## 이 앱은

밋그린 — 사진 한 장으로 식단을 기록하고(AI 분석), 기록이 식물 성장으로 이어지는 다이어트 앱.
Flutter + Firebase(Auth · Firestore · Cloud Functions). iOS는 출시됐고 Android는 비공개 테스트 중이에요.
사용자는 한국어로 대화하고 한국어 답을 원해요. 학습 중인 개발자라 단계별 설명을 좋아해요.

## 명령

```bash
flutter pub get
flutter analyze                          # 에러 · 경고 0개를 유지한다
dart format lib test
flutter test                             # 전체 (현재 411개, 모두 통과해야 한다)
flutter test test/<파일>.dart            # 파일 하나만
flutter run -d chrome --dart-define=USE_FIREBASE=false   # 서버 없이 화면 확인(가짜 로그인 · 예시 데이터)
cd functions && npm run build            # Cloud Functions 컴파일
```

환경: Flutter 3.44 (stable), Dart `^3.12.2`, Node 24(functions).

## 구조 — 반드시 지킨다 (자세한 것은 ARCHITECTURE.md)

`ui → domain ← data` **한 방향 참조.**

- `lib/domain/` — 모델(파일 하나에 클래스 하나) · 저장소 인터페이스 · 계산 규칙(`rules/`). **Flutter · Firebase · ui · data를 import하지 않는다.**
- `lib/data/` — 인터페이스의 구현은 `impl/` 폴더에 둔다(Firestore · 메모리 · Cloud Functions · 기기 기능). 저장 형식 변환(Map)은 codec이 한다.
- `lib/ui/<기능>/viewmodel/` — ViewModel(`ChangeNotifier`). `lib/ui/<기능>/pages/` — 화면.
- `lib/ui/core/ui/widgets/` — 공용 위젯, 위젯 하나에 파일 하나. `widgets.dart`로 한 번에 import.
- `lib/ui/core/ui/icons/app_icons.dart` — 화면 장식 아이콘은 이모지가 아니라 여기의 Flutter 아이콘. 식물 · 음식 · 그릇처럼 **내용 그림**만 이모지를 쓴다.
- `lib/ui/core/ui/themes/theme_tokens.dart` — 색 · 간격 · 모서리 · 그림자 토큰. 이미 토큰이 있는 값을 화면에 직접 쓰지 않는다.
- `lib/config/` — 사이트 주소 · 함수 이름 · Firestore 컬렉션 이름 같은 고정값. 문자열을 코드에 흩뿌리지 않는다.
- `lib/utils/date_format.dart` — 날짜 키(`yyyy-MM-dd`) · 월 키 · 시각 문자열은 여기 함수만 쓴다.

### 상태와 화면

- 화면은 필요한 ViewModel만 `context.watch<XxxViewModel>()`로 구독한다. 이벤트 핸들러 안에서는 `context.read`를 쓴다.
  새 ViewModel은 `AppState`에서 만들고, `AppState`에 public getter를 열고, `lib/app_providers.dart`에 provider를 추가한다.
- `AppState`(`lib/app_state.dart`)는 **상태를 들고 있는 곳이 아니다.** 여러 ViewModel을 엮는 동작(`logMeal` · `logExercise` · `onWaterAdded` · 로그인 …), 기기 알림 예약, ViewModel 연결만 맡는다. 새 상태는 AppState가 아니라 알맞은 ViewModel에 둔다.
- 화면 이동은 `NavigationViewModel`(`lib/ui/core/viewmodel/`) — `Navigator`가 아니라 `screen` 문자열 하나로 바꾼다. 화면에서는 `context.read<NavigationViewModel>().go(id)`. 이동할 때 다른 기능이 해야 할 일(식물 날짜 맞추기 · 시트 닫기)은 `onNavigated`로 AppState가 이어 준다.
- 다른 기록을 읽어 **계산만 하는** ViewModel(리포트 · 미션 · 오늘 수치 · 기록 달력)은 기록을 들고 있지 않고 `...Inputs`/`...Snapshot` 함수로 받는다. 기록이 바뀌면 AppState가 `refresh()`로 알린다.
- 화면은 AppState의 forwarder 대신 해당 ViewModel의 값을 직접 읽는 것을 우선한다.

### 의존성 주입 · 테스트

- 저장소 · 서비스는 인터페이스 뒤에 두고, 테스트에서는 메모리 구현이나 가짜(`implements`)를 끼운다. `AppState(dependencies: …)`가 `AppDependencies`(인터페이스 모음)를 받고, 어떤 구현을 끼울지는 `lib/app_composition.dart`(`memoryDependencies` · `firebaseDependencies`)에서만 고른다. 테스트는 `AppState(dependencies: memoryDependencies(mealRepo: fake, now: () => …))`처럼 바꿀 것만 넘긴다. AppState · ViewModel에서 `impl/` 구현 클래스를 import하지 않는다.
- 날짜가 걸린 기능은 `now: () => DateTime(...)`을 주입해서 고정한다. `DateTime.now()`를 직접 부르지 않는다.
- 새 동작에는 테스트를 같이 쓴다. 화면이 ViewModel을 구독하는지 확인하는 위젯 테스트는 `test/screen_binding_test.dart`를 참고한다. 위젯 테스트는 `AppProviders(state: ..., child: ...)`로 감싼다.
- 테스트용 글꼴이 실제보다 커서 `overflowed` 경고가 나는 화면이 있다(`screen_binding_test`는 무시하도록 처리). 실제 오버플로 여부는 웹 데모로 확인한다.

## 도메인 규칙은 한곳에

- 칼로리 보정 계수 · 식물 성장 규칙(돌보기 충전 · 축 점수 · 시듦) · 상한 같은 값은 `lib/domain/rules/diet_rules.dart`에 있다.
- 도감 조건은 `lib/domain/rules/dex_rules.dart`. 아직 셀 수 없는 조건은 `comingSoonIds`에 있고 화면에 "준비 중"으로 보인다.
- 식물 성장 규칙(기록하면 돌보기 충전 → 누르면 경험치 + 축 점수, 이틀 쉬면 시듦)은 `Plant`(`domain/models/plant.dart`)와 `PlantViewModel`이 맡는다.

## 가짜 데이터를 만들지 않는다

예전에 가짜 친구 · 가짜 알림 · 지어낸 화분 · 하드코딩된 안내 문구가 화면에 있어서 하나씩 걷어냈다.
화면에 보이는 숫자 · 목록은 실제 기록에서 계산하고, 없으면 **빈 상태 안내**를 보여준다. 예시 데이터는
가짜 로그인(웹 체험판)에서만 보인다.

## 문자열이 계약인 곳

화면 문구와 일부 맵 키가 한국어 문자열이다 — 예: 돌보기 이름 `'물 주기'`(`DietRules.careExp` · 식물 `cares`의 키),
도감 등급 `'일반' · '희귀' · '전설'`, 약관 이름(`ProfileViewModel.terms`의 키, 저장된 값과 이어짐).
이 문자열을 바꾸면 저장된 데이터와 맞지 않을 수 있으니 바꿀 때는 저장 형식(`record_codecs.dart`)까지 확인한다.

## 커밋 · 푸시

- 작은 단계로 나눠 커밋하고, 커밋 전에 `flutter analyze`와 `flutter test`를 돌린다.
- 푸시는 사용자가 한다(GitHub 인증). 배포(Functions · Hosting · 규칙 · 스토어)는 사용자가 확인한 뒤에만 한다.
- 비밀 값(API 키 · 키스토어 · `.p8`)은 저장소에 넣지 않는다. `android/key.properties`와 `*.jks`는 `.gitignore`에 있다.
