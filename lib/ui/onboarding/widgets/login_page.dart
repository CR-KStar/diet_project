import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app_state.dart';
import '../../../common.dart';
import '../../core/ui/themes/theme_tokens.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  /// 로그인에 성공하면 홈(온보딩을 마친 계정) 또는 계정 연결(처음 가입) 화면으로, 실패하면 이유를 토스트로 알려준다.
  /// (사용자가 로그인 창을 닫아 취소한 경우에는 아무것도 하지 않는다.)
  Future<void> _signIn(BuildContext context, LoginProvider provider) async {
    final s = context.read<AppState>();
    final ok = await s.signIn(provider);
    if (!context.mounted) return;
    if (ok) {
      s.goAfterLogin();
    } else if (s.authError != null) {
      toast(context, s.authError!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
          children: [
            Center(child: IconTile('🌱', size: 72, radius: 24, fontSize: 34)),
            const SizedBox(height: AppSpace.s26),
            Text(
              '오늘의 한 끼, 기록부터',
              textAlign: TextAlign.center,
              style: t(
                24,
                w: FontWeight.w900,
                c: AppColor.textStrong,
                sp: -0.5,
              ),
            ),
            const SizedBox(height: AppSpace.s8),
            Text(
              '사진 한 장으로 시작하는\n가벼운 다이어트 관리',
              textAlign: TextAlign.center,
              style: t(AppFontSize.f13, c: AppColor.textFaint, h: 1.6),
            ),
            const SizedBox(height: AppSpace.s30),
            _ProviderButton(
              label: 'Google로 계속하기',
              bg: AppColor.surface,
              fg: AppColor.text,
              badgeBg: const Color(0xFFF1F3F4),
              badge: Text(
                'G',
                style: t(
                  AppFontSize.f14,
                  w: FontWeight.w900,
                  c: const Color(0xFF4285F4),
                ),
              ),
              shadow: AppShadow.card,
              onTap: () => _signIn(context, LoginProvider.google),
            ),
            const SizedBox(height: AppSpace.s11),
            _ProviderButton(
              label: 'Apple로 계속하기',
              bg: const Color(0xFF111111),
              fg: Colors.white,
              badgeBg: const Color(0xFF2A2A2A),
              badge: const Text(
                '\uF8FF',
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              shadow: const [],
              chevron: const Color(0xFF5A5A5A),
              onTap: () => _signIn(context, LoginProvider.apple),
            ),
            const SizedBox(height: AppSpace.s26),
            AppCard(
              padding: 16,
              radius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '비밀번호 없이 로그인해요',
                    style: t(AppFontSize.f12, w: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSpace.s9),
                  for (final line in const [
                    '기존 계정이면 바로 홈으로, 처음이면 계정 연결 화면으로 이동해요',
                    '이메일과 비밀번호를 따로 관리하지 않아 분실 걱정이 없어요',
                  ]) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpace.s7),
                      child: Text(
                        '· $line',
                        style: t(
                          AppFontSize.f11,
                          c: AppColor.textFaint,
                          h: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.s56),
            Text(
              'Google · Apple 계정으로만 로그인해요.\n건강 기록은 암호화되어 본인만 조회할 수 있어요.',
              textAlign: TextAlign.center,
              style: t(AppFontSize.f10, c: const Color(0xFFB2B9BE), h: 1.7),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final Color badgeBg;
  final Widget badge;
  final List<BoxShadow> shadow;
  final Color? chevron;
  final VoidCallback onTap;

  const _ProviderButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.badgeBg,
    required this.badge,
    required this.shadow,
    this.chevron,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s18,
              vertical: AppSpace.s16,
            ),
            child: Row(
              children: [
                Container(
                  width: AppSpace.s26,
                  height: AppSpace.s26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: badge,
                ),
                const SizedBox(width: AppSpace.s12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
                Text(
                  '›',
                  style: TextStyle(
                    fontSize: 14,
                    color: chevron ?? AppColor.iconGhost,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
