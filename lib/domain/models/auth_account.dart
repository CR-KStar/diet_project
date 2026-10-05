import 'enums.dart';

/// 로그인에 성공한 계정.
class AuthAccount {
  const AuthAccount({
    required this.uid,
    required this.provider,
    this.displayName,
    this.email,
    this.isNewUser = false,
  });

  final String uid;
  final LoginProvider provider;
  final String? displayName;
  final String? email;
  final bool isNewUser;
} // -> model
