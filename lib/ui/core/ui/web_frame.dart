import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// 웹에서 폰 크기로 만든 화면이 브라우저 전체 폭으로 늘어나지 않도록,
/// 가운데에 폰 너비의 칸을 만들어 그 안에 앱을 보여준다.
/// 웹이 아니거나 화면이 이미 좁으면(폰 브라우저) 아무것도 하지 않는다.
class WebFrame extends StatelessWidget {
  const WebFrame({super.key, required this.child, this.showDemoNotice = false});

  final Widget child;

  /// 체험판(가짜 로그인 · 예시 데이터)일 때만 위쪽에 안내 띠를 보인다.
  final bool showDemoNotice;

  /// 이 너비보다 넓은 화면에서만 칸을 만든다.
  static const _phoneWidth = 460.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (!kIsWeb || width <= _phoneWidth) return child;

    return ColoredBox(
      color: const Color(0xFFE9EDEA),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _phoneWidth),
          child: Column(
            children: [
              if (showDemoNotice) const _DemoNotice(),
              Expanded(
                child: ClipRect(
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 24,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 웹 체험판임을 알리는 얇은 안내 띠.
class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    // Material 위에 두어야 글자에 기본 밑줄이 생기지 않는다.
    return Material(
      color: AppColor.primaryDark,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: const Text(
          '웹 체험판 · 예시 데이터로 둘러볼 수 있어요. 로그인과 AI 사진 분석은 앱에서 가능해요.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 11, height: 1.4),
        ),
      ),
    );
  }
}
