import 'package:diet_project/domain/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:diet_project/data/auth/auth_failure.dart';
import 'package:diet_project/data/auth/auth_service.dart';

/// 로그인 · 로그아웃 · 계정 삭제를 담당한다 — 진행 중 표시(중복 탭 방지)와
/// 실패했을 때 사용자에게 보여줄 문구까지.
///
/// 로그인한 뒤 무엇을 불러오고, 로그아웃 · 삭제 뒤 무엇을 비우는지(여러 ViewModel이 얽힌
/// 순서가 중요한 부분)는 AppState가 맡고, 호출할 때 함수로 넘겨받는다.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this._auth});

  final AuthService _auth;

  /// 가짜 로그인(Mock)일 때만 true — 이때는 예시 기록을 그대로 보여준다.
  bool get isDemo => _auth.isDemo;

  /// 로그인한 계정 (로그인 전에는 null)
  AuthAccount? get account => _account;
  set account(AuthAccount? value) {
    _account = value;
    notifyListeners();
  }

  AuthAccount? _account;

  /// 로그인 방식 이름 ('Google' · 'Apple') — 온보딩 첫 화면에 보여준다.
  String provider = 'Google';

  /// 로그인 버튼 중복 탭 방지.
  bool signingIn = false;

  /// 계정 삭제가 진행 중인 동안 true — 버튼 중복 탭을 막는다.
  bool deleting = false;

  /// 마지막 로그인 · 계정 삭제 · 내 정보 저장 실패 문구 (화면이 토스트로 보여주고 비운다)
  String? authError;

  /// 로그인한다. [enter]는 로그인에 성공한 계정으로 앱 상태를 채우는 일이다.
  /// 성공 true, 취소 false, 실패 false + [authError].
  Future<bool> signIn(
    LoginProvider provider, {
    required Future<bool> Function(AuthAccount account) enter,
  }) async {
    if (signingIn) return false;
    signingIn = true;
    authError = null;
    notifyListeners();
    try {
      final result = await _auth.signIn(provider);
      if (result == null) return false;
      return await enter(result);
    } on AuthFailure catch (e) {
      authError = e.message;
      return false;
    } catch (e, stack) {
      debugPrint('로그인 중 예상치 못한 오류: $e\n$stack');
      authError = '로그인 중 문제가 생겼어요. 잠시 후 다시 시도해 주세요.';
      return false;
    } finally {
      signingIn = false;
      notifyListeners();
    }
  }

  /// 앱을 켤 때 이전에 로그인한 계정이 남아 있으면 돌려준다 (없으면 null).
  Future<AuthAccount?> restoreAccount() => _auth.restoreAccount();

  Future<void> signOut() => _auth.signOut();

  /// 계정을 삭제한다. 삭제 전에 [deleteUserData]로 이 계정의 저장된 정보를 지우고,
  /// 다 끝나면 [afterDelete]를 부른다. 성공하면 true, 실패하면 false([authError]에 사용자용 문구).
  Future<bool> deleteAccount({
    required String? uid,
    required Future<void> Function(String uid) deleteUserData,
    required void Function() afterDelete,
  }) async {
    if (deleting) return false;
    deleting = true;
    authError = null;
    notifyListeners();
    try {
      await _auth.deleteAccount(
        beforeDelete: uid == null ? null : () => deleteUserData(uid),
      );
      afterDelete();
      return true;
    } on AuthFailure catch (e) {
      authError = e.message;
      return false;
    } catch (e, stack) {
      debugPrint('계정 삭제 중 예상치 못한 오류: $e\n$stack');
      authError = '계정을 삭제하지 못했어요. 네트워크를 확인하고 다시 시도해 주세요.';
      return false;
    } finally {
      deleting = false;
      notifyListeners();
    }
  }
}
