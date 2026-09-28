// 공용 위젯 — 프로토타입의 카드 · 칩 · 버튼 · 진행 바 등을 재사용 가능한 형태로.
//
// 화면 파일들은 이 위젯을 조합해 만듭니다.

import 'dart:math' as math;

import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// 텍스트 헬퍼

TextStyle t(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = AppColor.text,
  double? sp,
  double? h,
}) => GoogleFonts.notoSansKr(
  fontSize: size,
  fontWeight: w,
  color: c,
  letterSpacing: sp,
  height: h,
);

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
}

class ScreenScroll extends StatelessWidget {
  const ScreenScroll({
    super.key,
    required this.children,
    this.horizontal = 16,
    this.top = 6,
  });

  final List<Widget> children;
  final double horizontal;
  final double top;

  @override
  Widget build(BuildContext context) => ListView(
    padding: EdgeInsets.fromLTRB(horizontal, top, horizontal, 28),
    children: [
      for (final c in children) ...[
        c,
        const SizedBox(height: AppSpace.cardGap),
      ],
    ],
  );
}

// 컨테이너

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = 18,
    this.radius = AppRadius.card,
    this.color = AppColor.surface,
    this.border,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final double padding;
  final double radius;
  final Color color;
  final Color? border;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AppShadow.card,
        border: border == null ? null : Border.all(color: border!, width: 1.5),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}

/// 카드 안 옅은 서브 블록
class SunkenBox extends StatelessWidget {
  const SunkenBox({
    super.key,
    required this.child,
    this.padding = 13,
    this.radius = 18,
    this.color = AppColor.surfaceSunken,
  });

  final Widget child;
  final double padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}

class IconTile extends StatelessWidget {
  const IconTile(
    this.emoji, {
    super.key,
    this.size = 28,
    this.radius = 10,
    this.bg = AppColor.primaryTint,
    this.fontSize = 14,
    this.shadow = false,
  });

  final String emoji;
  final double size;
  final double radius;
  final Color bg;
  final double fontSize;
  final bool shadow;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow ? AppShadow.tile : null,
    ),
    child: Text(emoji, style: TextStyle(fontSize: fontSize)),
  );
}

// 헤더

/// 하단 탭 루트 화면의 제목 행
class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.trailing,
  });

  final String emoji;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
    child: Row(
      children: [
        IconTile(emoji, size: 30, radius: 11, fontSize: 15),
        const SizedBox(width: 9),
        Text(
          title,
          style: t(20, w: FontWeight.w900, c: AppColor.textStrong, sp: -0.3),
        ),
        const Spacer(),
        ?trailing,
      ],
    ),
  );
}

/// 서브 화면의 뒤로 + 제목 행
class SubHeader extends StatelessWidget {
  const SubHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.onBack,
    this.trailing,
  });

  final String emoji;
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, right: 4, bottom: 2),
    child: Row(
      children: [
        if (onBack != null)
          GestureDetector(
            onTap: onBack,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 26,
              height: AppSize.minTapTarget,
              alignment: Alignment.centerLeft,
              child: Text('‹', style: t(20, c: AppColor.text)),
            ),
          ),
        IconTile(emoji),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t(17, w: FontWeight.w900, c: AppColor.textStrong),
          ),
        ),
        const Spacer(),
        ?trailing,
      ],
    ),
  );
}

class CardHeader extends StatelessWidget {
  const CardHeader({
    super.key,
    required this.emoji,
    required this.title,
    this.action,
    this.onAction,
    this.subtitle,
  });

  final String emoji;
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          IconTile(emoji, size: 26, fontSize: 13),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: t(15, w: FontWeight.w900)),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(action!, style: t(12, c: AppColor.textFaint)),
            ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 5),
        Text(subtitle!, style: t(11, c: AppColor.textGhost)),
      ],
    ],
  );
}

// 선택 컴포넌트

class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: AppSize.chipPad,
      decoration: AppDeco.chip(selected: selected),
      child: Text(
        label,
        style: t(
          12,
          w: selected ? FontWeight.w700 : FontWeight.w500,
          c: selected ? AppColor.primaryDark : AppColor.textMuted,
        ),
      ),
    ),
  );
}

class ChipWrap extends StatelessWidget {
  const ChipWrap({
    super.key,
    required this.options,
    required this.isSelected,
    required this.onPick,
  });

  final List<String> options;
  final bool Function(String) isSelected;
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: options
        .map(
          (o) => SelectChip(
            label: o,
            selected: isSelected(o),
            onTap: () => onPick(o),
          ),
        )
        .toList(),
  );
}

/// 균등 분할 세그먼트 (전체/반절/1/3 등)
class SegmentedRow extends StatelessWidget {
  const SegmentedRow({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: options.map((o) {
      final on = o == value;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: o == options.last ? 0 : 8),
          child: GestureDetector(
            onTap: () => onChanged(o),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: on ? AppColor.primaryTint : AppColor.surfaceSunken,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: on ? AppColor.primary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Text(
                o,
                style: t(
                  13,
                  w: on ? FontWeight.w700 : FontWeight.w500,
                  c: on ? AppColor.primaryDark : AppColor.textFaint,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

/// 화면 상단 알약 탭 (식물/도감, 활동/챌린지/친구 추가, 알림/개인정보)
/// 카테고리 필터 — 글자 크기만큼만 차지하는 알약 버튼(전체 너비를 채우지 않음).
/// 알림/오늘의 미션처럼 항목 수가 가변적인 필터에 씁니다. 가로로 넘치면 스크롤돼요.
class FilterTabs extends StatelessWidget {
  const FilterTabs({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final o in options) ...[
          GestureDetector(
            onTap: () => onChanged(o),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: o == value ? AppColor.primary : AppColor.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: o == value ? null : AppShadow.card,
              ),
              child: Text(
                o,
                style: t(
                  12,
                  w: o == value ? FontWeight.w700 : FontWeight.w500,
                  c: o == value ? Colors.white : AppColor.textFaint,
                ),
              ),
            ),
          ),
          if (o != options.last) const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

class PillTabs extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: options.map((o) {
        final on = o == value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: o == options.last ? 0 : 8),
            child: GestureDetector(
              onTap: () => onChanged(o),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: on ? AppColor.primary : AppColor.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: on ? null : AppShadow.card,
                ),
                child: Text(
                  o,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t(
                    13,
                    w: on ? FontWeight.w700 : FontWeight.w500,
                    c: on ? Colors.white : AppColor.textFaint,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

/// 가로 스크롤 칩 (알림 시간 선택 등)
class ScrollChips extends StatelessWidget {
  const ScrollChips({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 46,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(width: 7),
      itemBuilder: (_, i) {
        final o = options[i];
        final on = o == value;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: on ? AppColor.primary : AppColor.surfaceSunken,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              o,
              style: t(
                13,
                w: on ? FontWeight.w900 : FontWeight.w500,
                c: on ? Colors.white : AppColor.textMuted,
              ),
            ),
          ),
        );
      },
    ),
  );
}

class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 44,
  });

  final bool value;
  final VoidCallback onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * 26 / 44;
    final knob = h - 6;
    return GestureDetector(
      onTap: onChanged,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: AppSize.minTapTarget,
        child: Center(
          child: Container(
            width: width,
            height: h,
            padding: const EdgeInsets.all(3),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? AppColor.primary : AppColor.toggleOff,
              borderRadius: BorderRadius.circular(h / 2),
            ),
            child: Container(
              width: knob,
              height: knob,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CheckDot extends StatelessWidget {
  const CheckDot({super.key, required this.on, this.size = 20, this.radius});

  final bool on;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: on ? AppColor.primary : const Color(0xFFEDEFF1),
      borderRadius: BorderRadius.circular(radius ?? size / 2),
    ),
    child: Text(
      '✓',
      style: TextStyle(
        fontSize: size * 0.55,
        color: on ? Colors.white : AppColor.iconGhost,
      ),
    ),
  );
}

// 버튼

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: AppSize.buttonPad,
      decoration: AppDeco.primaryButton(enabled: enabled),
      child: Text(
        label,
        style: t(
          15,
          w: FontWeight.w700,
          c: enabled ? Colors.white : AppColor.textGhost,
        ),
      ),
    ),
  );
}

/// 보조 액션 — 버튼 대신 조용한 텍스트 링크 (높이 46)
class TextLink extends StatelessWidget {
  const TextLink({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppColor.textFaint,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    behavior: HitTestBehavior.opaque,
    child: SizedBox(
      height: AppSize.textLinkHeight,
      child: Center(
        child: Text(label, style: t(12, c: color)),
      ),
    ),
  );
}

/// 확인 · 취소를 묻는 대화상자. 확인을 누르면 true, 그 밖(취소 · 바깥 터치)은 false.
/// [destructive]가 true면 확인 버튼을 경고 색으로 보여줍니다 (삭제처럼 되돌릴 수 없는 동작).
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: t(16, w: FontWeight.w800)),
      content: Text(message, style: t(13, c: AppColor.textMuted, h: 1.6)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text('취소', style: t(14, c: AppColor.textFaint)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            confirmLabel,
            style: t(
              14,
              w: FontWeight.w700,
              c: destructive ? AppColor.alertText : AppColor.primaryDark,
            ),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

class SmallButton extends StatelessWidget {
  const SmallButton({
    super.key,
    required this.label,
    this.onTap,
    this.bg = AppColor.primaryTint,
    this.fg = AppColor.primaryDark,
  });

  final String label;
  final VoidCallback? onTap;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: t(11, w: FontWeight.w700, c: fg),
      ),
    ),
  );
}

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.bg = AppColor.primaryTint,
    this.fg = AppColor.primaryDark,
    this.fontSize = 10,
  });

  final String text;
  final Color bg;
  final Color fg;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: t(fontSize, w: FontWeight.w700, c: fg),
    ),
  );
}

/// 바텀 시트용 커스텀 스캐폴드
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.onClose,
    this.leading,
    this.trailing,
    this.padding = 20,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onClose;

  /// 제목 왼쪽 아이콘 (예: 물방울 아이콘)
  final Widget? leading;

  /// 오른쪽 끝에 표시할 위젯 — 지정하면 닫기(✕) 버튼 대신 이걸 보여줍니다.
  final Widget? trailing;
  final double padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColor.surface,
      borderRadius: AppRadius.sheetR,
    ),
    padding: EdgeInsets.fromLTRB(
      padding,
      14,
      padding,
      padding + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColor.disabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t(18, w: FontWeight.w900)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: t(12, c: AppColor.textFaint)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else if (onClose != null)
              GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColor.surfaceSunken,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '✕',
                    style: TextStyle(fontSize: 16, color: AppColor.textGhost),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        child,
      ],
    ),
  );
}

// 진행 표시

class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = AppColor.primary,
    this.height = AppSize.barBase,
    this.track = AppColor.divider,
    this.gradient,
  });

  final double value; // 0..1
  final Color color;
  final double height;
  final Color track;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: Container(
      height: height,
      color: track,
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: gradient == null ? color : null,
            gradient: gradient,
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
      ),
    ),
  );
}

/// 도넛 링 — 홈 칼로리, 영양소 비율, 식물 축
class Ring extends StatelessWidget {
  const Ring({
    super.key,
    required this.size,
    required this.segments,
    this.thickness = 11,
    this.track = const Color(0xFFE9F0EA),
    this.center,
  });

  final double size;

  /// (비율 0..1, 색) 목록 — 순서대로 이어 그립니다.
  final List<({double value, Color color})> segments;
  final double thickness;
  final Color track;
  final Widget? center;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _RingPainter(
        segments: segments,
        thickness: thickness,
        track: track,
      ),
      child: center == null ? null : Center(child: center),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.segments,
    required this.thickness,
    required this.track,
  });

  final List<({double value, Color color})> segments;
  final double thickness;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      thickness / 2,
      thickness / 2,
      size.width - thickness,
      size.height - thickness,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..color = track;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);

    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = math.pi * 2 * s.value.clamp(0, 1);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..color = s.color;
      canvas.drawArc(rect, start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => true;
}

/// 막대그래프
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.bars,
    this.height = 132,
    this.showValue = true,
  });

  final List<({String label, int value, int pct})> bars;
  final double height;
  final bool showValue;

  Color _color(int pct) => pct >= 85
      ? AppColor.alert
      : pct >= 70
      ? AppColor.primary
      : AppColor.secondary;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: bars.map((b) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (showValue)
                  Text(
                    AppStateFormat.comma(b.value),
                    style: t(9, c: AppColor.textGhost),
                  ),
                const SizedBox(height: 6),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.bottomCenter,
                    heightFactor: (b.pct / 100).clamp(0.02, 1),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _color(b.pct),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(7),
                          bottom: Radius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(b.label, style: t(10, c: AppColor.textFaint)),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

/// 체중 라인 그래프 (목표선 점선 + 영역 채우기)
class WeightLineChart extends StatelessWidget {
  const WeightLineChart({
    super.key,
    required this.series,
    required this.goal,
    this.height = 128,
  });

  final List<({String label, double kg})> series;
  final double goal;
  final double height;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _LinePainter(series: series, goal: goal),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: series
            .map((s) => Text(s.label, style: t(10, c: AppColor.textGhost)))
            .toList(),
      ),
    ],
  );
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.series, required this.goal});

  final List<({String label, double kg})> series;
  final double goal;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final values = series.map((s) => s.kg).toList();
    final lo = math.min(values.reduce(math.min), goal) - 0.4;
    final hi = values.reduce(math.max) + 0.4;

    double y(double v) => 12 + (hi - v) / (hi - lo) * (size.height - 24);
    double x(int i) => 6 + i * ((size.width - 12) / (series.length - 1));

    // 가이드 라인
    final guide = Paint()
      ..color = AppColor.divider
      ..strokeWidth = 1;
    for (final gy in [12.0, size.height / 2, size.height - 12]) {
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), guide);
    }

    // 목표선 (점선)
    final gp = Paint()
      ..color = AppColor.secondary
      ..strokeWidth = 1.5;
    final gyGoal = y(goal);
    for (double dx = 0; dx < size.width; dx += 10) {
      canvas.drawLine(Offset(dx, gyGoal), Offset(dx + 5, gyGoal), gp);
    }

    // 영역 + 선
    final path = Path()..moveTo(x(0), y(values[0]));
    for (var i = 1; i < values.length; i++) {
      path.lineTo(x(i), y(values[i]));
    }
    final area = Path.from(path)
      ..lineTo(x(values.length - 1), size.height)
      ..lineTo(x(0), size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()..color = AppColor.primary.withValues(alpha: 0.10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColor.primary,
    );

    // 마지막 점
    final last = Offset(x(values.length - 1), y(values.last));
    canvas.drawCircle(last, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(
      last,
      4.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColor.primary,
    );
  }

  @override
  bool shouldRepaint(_LinePainter old) => true;
}

// 입력

/// 숫자 직접 입력 — 스피너 없음, 범위 clamp
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.value,
    required this.onChanged,
    this.unit,
    this.fontSize = 22,
    this.color = AppColor.primary,
    this.decimal = false,
    this.center = false,
    this.min = 0,
    this.max = 100000,
  });

  final num value;
  final void Function(num) onChanged;
  final String? unit;
  final double fontSize;
  final Color color;
  final bool decimal;
  final bool center;
  final num min;
  final num max;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  late final TextEditingController _c = TextEditingController(
    text: _fmt(widget.value),
  );

  /// 이 필드에 포커스가 있는(직접 타이핑 중인) 동안은 외부 값으로 텍스트를 덮어쓰지 않습니다.
  /// (덮어쓰면 커서가 맨 앞으로 튀어서 다음 입력이 엉뚱한 자리에 끼어듭니다.)
  late final FocusNode _focus = FocusNode()
    ..addListener(() {
      if (!_focus.hasFocus) {
        final formatted = _fmt(widget.value);
        if (_c.text != formatted) _c.text = formatted;
      }
    });

  String _fmt(num v) => widget.decimal ? v.toStringAsFixed(1) : v.toString();

  @override
  void didUpdateWidget(NumberField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus &&
        widget.value != old.value &&
        _fmt(widget.value) != _c.text) {
      _c.text = _fmt(widget.value);
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: _c,
      focusNode: _focus,
      keyboardType: widget.decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: [
        widget.decimal
            ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            : FilteringTextInputFormatter.digitsOnly,
      ],
      textAlign: widget.center ? TextAlign.center : TextAlign.start,
      decoration: const InputDecoration(
        filled: false,
        border: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(vertical: 14),
        isDense: true,
      ),
      style: t(widget.fontSize, w: FontWeight.w900, c: widget.color, sp: -0.5),
      onChanged: (s) {
        final v = widget.decimal
            ? (double.tryParse(s) ?? 0)
            : (int.tryParse(s) ?? 0);
        widget.onChanged(v.clamp(widget.min, widget.max));
      },
    );
    final unit = widget.unit == null
        ? null
        : Text(
            widget.unit!,
            style: t(13, w: FontWeight.w500, c: AppColor.textFaint),
          );

    return SunkenBox(
      padding: 0,
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        // center: true — 숫자 + 단위를 한 덩어리로 박스 정중앙에 배치
        // center: false — 숫자 입력창이 남는 폭을 다 차지하고 단위는 오른쪽에 붙음
        child: widget.center
            ? Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    IntrinsicWidth(child: field),
                    if (unit != null) ...[const SizedBox(width: 6), unit],
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(child: field),
                  if (unit != null) ...[const SizedBox(width: 6), unit],
                ],
              ),
      ),
    );
  }
}

/// 텍스트 직접 입력
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint,
    this.fontSize = 14,
    this.maxLines = 1,
    this.minHeight,
  });

  final String value;
  final void Function(String) onChanged;
  final String? hint;
  final double fontSize;
  final int maxLines;
  final double? minHeight;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final TextEditingController _c = TextEditingController(
    text: widget.value,
  );
  final FocusNode _focus = FocusNode();

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    // 포커스가 있는(직접 타이핑 중인) 동안은 덮어쓰지 않음 — 커서 튐 방지
    if (!_focus.hasFocus && widget.value != _c.text) _c.text = widget.value;
  }

  @override
  void dispose() {
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: widget.minHeight ?? 0),
    child: TextField(
      controller: _c,
      focusNode: _focus,
      maxLines: widget.maxLines,
      minLines: widget.maxLines > 1 ? 3 : 1,
      onChanged: widget.onChanged,
      style: t(
        widget.fontSize,
        w: FontWeight.w500,
        h: widget.maxLines > 1 ? 1.6 : null,
      ),
      decoration: InputDecoration(hintText: widget.hint),
    ),
  );
}

/// 드래그 가능한 슬라이더 (목표 체중 등). `onChanged`를 생략하면 드래그가 안 되는
/// 읽기 전용 위치 표시 바로 동작합니다(예: 체중 기록의 목표 체중 위치 표시).
class DragSlider extends StatelessWidget {
  const DragSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    this.onChanged,
    this.step = 0.1,
  });

  final double value;
  final double min;
  final double max;
  final double step;
  final void Function(double)? onChanged;

  @override
  Widget build(BuildContext context) {
    final ratio = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, box) {
        void update(double dx) {
          final cb = onChanged;
          if (cb == null) return;
          final r = (dx / box.maxWidth).clamp(0.0, 1.0);
          final raw = min + r * (max - min);
          cb((raw / step).round() * step);
        }

        final track = SizedBox(
          width: double.infinity,
          height: AppSize.minTapTarget,
          child: Center(
            child: SizedBox(
              width: box.maxWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ProgressBar(value: ratio, height: 6),
                  Positioned(
                    left: ratio * box.maxWidth - 10,
                    top: -7,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColor.primary, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4D4CAF50),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (onChanged == null) return track;

        return GestureDetector(
          onHorizontalDragStart: (d) => update(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
          behavior: HitTestBehavior.opaque,
          child: track,
        );
      },
    );
  }
}

// 기타

/// 사진 플레이스홀더 — 대각선 스트라이프
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    super.key,
    required this.height,
    this.label,
    this.radius = 20,
    this.child,
  });

  final double height;
  final String? label;
  final double radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    width: double.infinity,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFF2F5F6),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: CustomPaint(
      painter: _StripePainter(),
      child: Center(
        child:
            child ??
            (label == null
                ? null
                : Text(
                    label!,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      color: AppColor.textFaint,
                      letterSpacing: 0.5,
                    ),
                  )),
      ),
    ),
  );
}

class _StripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFFE9EDEF)
      ..strokeWidth = 10;
    for (double x = -size.height; x < size.width + size.height; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), p);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => false;
}

class RowBetween extends StatelessWidget {
  const RowBetween(
    this.label,
    this.value, {
    super.key,
    this.valueColor = AppColor.text,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: t(12, c: AppColor.textFaint)),
        Text(
          value,
          style: t(12, w: FontWeight.w700, c: valueColor),
        ),
      ],
    ),
  );
}

/// 숫자 콤마 포맷 — `AppState.comma`가 이 구현을 그대로 감싸 화면에 노출한다.
abstract final class AppStateFormat {
  static String comma(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (m) => '${m[1]},',
  );
}
