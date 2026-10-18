import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:diet_project/ui/core/ui/widgets/progress_bar.dart';

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
                  ProgressBar(value: ratio, height: AppSpace.s6),
                  Positioned(
                    left: ratio * box.maxWidth - 10,
                    top: -7,
                    child: Container(
                      width: AppSpace.s20,
                      height: AppSpace.s20,
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
