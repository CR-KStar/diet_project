import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/icons/app_icons.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/ui/core/ui/widgets/widgets.dart';
import 'package:diet_project/ui/record/viewmodel/exercise_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 저장한 운동 기록 한 건을 고치거나 지우는 시트. 저장을 눌러야 반영된다.
class ExerciseEditSheet extends StatefulWidget {
  const ExerciseEditSheet({super.key, required this.log});

  final ExerciseLog log;

  @override
  State<ExerciseEditSheet> createState() => _ExerciseEditSheetState();
}

class _ExerciseEditSheetState extends State<ExerciseEditSheet> {
  late String _type = widget.log.type;
  late int _minutes = widget.log.minutes;
  late ExerciseIntensity _intensity = widget.log.intensity;

  int get _kcal => ExerciseViewModel.kcalFor(
    type: _type,
    minutes: _minutes,
    intensity: _intensity,
  );

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final canSave = _type.trim().isNotEmpty && _minutes >= 1;
    return SheetScaffold(
      title: '운동 수정',
      subtitle: '${widget.log.time} 기록',
      leading: const Icon(AppIcons.exercise, color: AppIconColors.exercise),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('운동 종류', style: t(AppFontSize.f12, c: AppColor.textMuted)),
          const SizedBox(height: AppSpace.s8),
          AppTextField(
            value: _type,
            hint: '예: 달리기',
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('운동 시간', style: t(AppFontSize.f12, c: AppColor.textMuted)),
          const SizedBox(height: AppSpace.s8),
          NumberField(
            value: _minutes,
            unit: '분',
            min: 0,
            max: 600,
            onChanged: (v) => setState(() => _minutes = v.toInt()),
          ),
          const SizedBox(height: AppSpace.s16),
          Text('강도', style: t(AppFontSize.f12, c: AppColor.textMuted)),
          const SizedBox(height: AppSpace.s8),
          SegmentedRow(
            options: [for (final i in ExerciseIntensity.values) i.label],
            value: _intensity.label,
            onChanged: (label) => setState(
              () => _intensity = ExerciseIntensity.values.firstWhere(
                (i) => i.label == label,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.s12),
          Text(
            '소모 칼로리 약 $_kcal kcal',
            style: t(AppFontSize.f13, w: FontWeight.w700, c: AppColor.primary),
          ),
          const SizedBox(height: AppSpace.s16),
          PrimaryButton(
            label: '저장',
            enabled: canSave,
            onTap: canSave
                ? () {
                    s.updateExercise(
                      widget.log.id,
                      type: _type,
                      minutes: _minutes,
                      intensity: _intensity,
                    );
                    Navigator.of(context).pop();
                  }
                : null,
          ),
          TextLink(
            label: '운동 기록 삭제',
            color: AppColor.alertText,
            onTap: () async {
              final ok = await confirmDialog(
                context,
                title: '운동 기록을 삭제할까요?',
                message:
                    '"${widget.log.type} ${widget.log.minutes}분" 기록이 지워져요. 되돌릴 수 없어요.',
                confirmLabel: '삭제',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              s.deleteExercise(widget.log.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
