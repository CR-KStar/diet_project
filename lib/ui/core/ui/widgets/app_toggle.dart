import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            padding: const EdgeInsets.all(AppSpace.s3),
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
