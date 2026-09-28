import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
// firebase_auth에도 User 클래스가 있어서 LoginProvider만 가져온다.
import 'package:diet_project/domain/models/models.dart' show AuthAccount, LoginProvider;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'auth_service.dart';

/// Firebase Auth로 Google · Apple 로그인을 처리하는 인증 서비스.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Android는 Google Cloud의 웹 OAuth 클라이언트 ID가 필요하다. 기본값은
  /// google-services.json의 값이고, 다른 프로젝트를 쓸 때만 --dart-define으로 바꾼다.
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '119913712586-epl9cif5kq1civbksslj144hrthcbjqr.apps.googleusercontent.com',
  );

  Future<void>? _googleReady;

  @override
  AuthAccount? get currentAccount {
    final user = _auth.currentUser;
    if (user == null) return null;
    final provider = _providerOf(user);
    if (provider == null) return null;
    return AuthAccount(
      uid: user.uid,
      provider: provider,
      displayName: user.displayName,
      email: user.email,
    );
  }

  @override
  Future<AuthAccount?> restoreAccount() async {
    try {
      await _auth.authStateChanges().first.timeout(const Duration(seconds: 3));
    } on TimeoutException {
      // 3초 넘으면 지금 알 수 있는 상태로 진행한다.
    }
    return currentAccount;
  }

  @override
  Future<AuthAccount?> signIn(LoginProvider provider) async {
    try {
      final fresh = switch (provider) {
        LoginProvider.google => await _googleCredential(),
        LoginProvider.apple => await _appleCredential(),
      };
      if (fresh == null) return null;

      final result = await _auth.signInWithCredential(fresh.credential);
      final user = result.user;
      if (user == null) throw const AuthFailure('로그인 정보를 받지 못했어요. 다시 시도해 주세요.');

      // Apple은 이름을 첫 로그인 때만 주므로 그때 저장한다.
      final name = fresh.name;
      if (name != null && (user.displayName ?? '').isEmpty) {
        await user.updateDisplayName(name);
      }

      return AuthAccount(
        uid: user.uid,
        provider: provider,
        displayName: name ?? user.displayName,
        email: user.email,
        isNewUser: result.additionalUserInfo?.isNewUser ?? false,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure('로그인에 실패했어요. (${e.code})');
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (_googleReady != null) await GoogleSignIn.instance.signOut();
  }

  @override
  Future<void> deleteAccount({Future<void> Function()? beforeDelete}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 순서: 본인 확인 → 데이터 삭제 → 계정 삭제.
      final apple = _providerOf(user) == LoginProvider.apple;
      final fresh = apple
          ? await _appleCredential()
          : await _googleCredential();
      if (fresh == null) throw const AuthFailure('본인 확인이 취소되어 계정을 삭제하지 못했어요.');
      await user.reauthenticateWithCredential(fresh.credential);

      if (apple) {
        await _auth.revokeTokenWithAuthorizationCode(fresh.authorizationCode!);
      }

      await beforeDelete?.call();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure('계정을 삭제하지 못했어요. (${e.code})');
    }
    if (_googleReady != null) await GoogleSignIn.instance.signOut();
  }

  static LoginProvider? _providerOf(User user) {
    for (final info in user.providerData) {
      if (info.providerId == 'google.com') return LoginProvider.google;
      if (info.providerId == 'apple.com') return LoginProvider.apple;
    }
    return null;
  }

  /// 사용자가 취소하면 null.
  Future<_Fresh?> _googleCredential() async {
    try {
      await (_googleReady ??= GoogleSignIn.instance.initialize(
        serverClientId: _googleServerClientId.isEmpty
            ? null
            : _googleServerClientId,
      ));
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure('Google 인증 정보를 받지 못했어요. 다시 시도해 주세요.');
      }
      return _Fresh(GoogleAuthProvider.credential(idToken: idToken));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AuthFailure('Google 로그인에 실패했어요. (${e.code.name})');
    }
  }

  /// 사용자가 취소하면 null.
  Future<_Fresh?> _appleCredential() async {
    // iOS · macOS의 기기 내 로그인만 지원한다.
    final onApplePlatform =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (!onApplePlatform) {
      throw const AuthFailure(
        'Apple 로그인은 iPhone · iPad에서만 쓸 수 있어요. Google로 계속해 주세요.',
      );
    }

    final rawNonce = _randomNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = apple.identityToken;
      if (idToken == null) {
        throw const AuthFailure('Apple 인증 정보를 받지 못했어요. 다시 시도해 주세요.');
      }
      return _Fresh(
        OAuthProvider('apple.com').credential(
          idToken: idToken,
          rawNonce: rawNonce,
          accessToken: apple.authorizationCode,
        ),
        name: apple.givenName ?? apple.familyName,
        authorizationCode: apple.authorizationCode,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw AuthFailure('Apple 로그인에 실패했어요. (${e.code.name})');
    }
  }

  static String _randomNonce([int length = 32]) {
    const chars =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

/// 방금 받은 로그인 자격 증명과 그때만 받을 수 있는 부가 정보.
class _Fresh {
  const _Fresh(this.credential, {this.name, this.authorizationCode});

  final AuthCredential credential;
  final String? name;
  final String? authorizationCode;
}
