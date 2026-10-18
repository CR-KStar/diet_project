import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

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
