import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/sunken_box.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

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

  /// 사용자가 소수점을 직접 입력했을 때만 보여준다 — 정수면 "52.0"이 아니라
  /// "52"로, 소수면("52.5") 그 소수를 그대로 보여준다.
  String _fmt(num v) {
    if (!widget.decimal) return v.toString();
    final d = v.toDouble();
    return d == d.roundToDouble() ? d.toInt().toString() : d.toStringAsFixed(1);
  }

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
        contentPadding: EdgeInsets.symmetric(vertical: AppSpace.s14),
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
            style: t(
              AppFontSize.f13,
              w: FontWeight.w500,
              c: AppColor.textFaint,
            ),
          );

    return SunkenBox(
      padding: 0,
      radius: 16,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
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
                    if (unit != null) ...[
                      const SizedBox(width: AppSpace.s6),
                      unit,
                    ],
                  ],
                ),
              )
            : Row(
                children: [
                  Expanded(child: field),
                  if (unit != null) ...[
                    const SizedBox(width: AppSpace.s6),
                    unit,
                  ],
                ],
              ),
      ),
    );
  }
}
