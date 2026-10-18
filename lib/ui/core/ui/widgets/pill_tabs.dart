import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/text_style.dart';

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
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.s4),
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
                padding: const EdgeInsets.symmetric(vertical: AppSpace.s12),
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
                    AppFontSize.f13,
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
