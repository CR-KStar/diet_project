# 밋그린 구조 안내

화면(UI) · 도메인 · 데이터 세 층으로 나누고, **참조는 한쪽 방향으로만** 간다.

```
ui  ──▶  domain  ◀──  data
```

- `ui`는 `domain`과 `data`의 **인터페이스**를 안다.
- `data`는 `domain`을 안다. (`ui`는 모른다.)
- `domain`은 아무것도 모른다. Flutter도, Firebase도, 화면도 import하지 않는다.
- 실제 구현(Firebase · 가짜 · 기기 기능)을 고르는 곳은 `main.dart`(와 AppState의 기본값)뿐이다.

## 폴더

```
lib/
  main.dart                     어떤 구현을 쓸지 고르고 앱을 시작한다 (조립하는 곳)
  app_state.dart                여러 ViewModel을 엮는 동작(식단 기록, 로그인 …) + 시스템 뒤로가기
  app_providers.dart            AppState와 모든 ViewModel을 화면에 내려준다
  app_shell.dart                하단 탭 · 빠른 기록 시트 등 앱 껍데기

  config/                       고정 설정값 (사이트 주소, 함수 이름, Firestore 컬렉션 이름 …)
  utils/                        날짜 · 숫자 포맷 같은 작은 도구

  domain/
    models/                     모델 — 파일 하나에 클래스 하나. models.dart로 한 번에 import
    repositories/               저장소 인터페이스 (계약)
    rules/                      계산 규칙 (DietRules)

  data/
    auth/                       AuthService(인터페이스) · AuthFailure · impl/(Firebase, 가짜)
    repositories/               저장 형식 변환(codec) · impl/(Firestore, 메모리)
    services/                   서비스 인터페이스 · impl/(Cloud Functions, 기기 알림, 앱 아이콘 …)

  ui/
    core/ui/widgets/            공용 위젯 (위젯 하나에 파일 하나), 테마
    core/viewmodel/             NavigationViewModel — 지금 화면 · 서브 모드 · 이동 기록
    <기능>/viewmodel/           ViewModel — 화면의 상태와 동작
    <기능>/pages/               화면(page)
```

## 규칙

1. **인터페이스와 구현은 파일을 나눈다.** 구현은 `impl/` 아래에 둔다.
2. **모델은 파일 하나에 클래스 하나.** 화면 문구(label)는 enum이 직접 가진다.
3. **저장 모양(Map 변환)은 data의 codec이 한다.** 도메인 모델은 저장 방법을 모른다.
4. **화면은 자기 ViewModel만 구독한다** (`context.watch<XxxViewModel>()`).
   화면 이동은 `NavigationViewModel`에, 여러 기능을 엮는 동작만 AppState에 부탁한다.
5. **여러 ViewModel을 엮는 동작**(예: 식단 기록 → 활동 피드 · 챌린지 진행 · 앱 아이콘)은 AppState가 맡는다.
6. **다른 기록을 읽어 계산만 하는 것**(리포트 · 미션 · 오늘 수치 · 달력)은 기록을 직접 들고 있지 않고,
   AppState가 넘겨주는 값으로 계산한다. 기록이 바뀌면 AppState가 다시 계산하라고 알린다.
7. 테스트는 가짜 구현(`Memory…`, 테스트용 fake)을 끼워서 한다.
