import 'package:diet_project/app_state.dart';
import 'package:diet_project/ui/core/ui/icons/app_icons.dart';
import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:diet_project/ui/core/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 저장한 체중 기록 한 건을 고치거나 지우는 시트. 저장을 눌러야 반영된다.
class WeightEditSheet extends StatefulWidget {
  const WeightEditSheet({super.key, required this.entry});

  final WeightEntry entry;

  @override
  State<WeightEditSheet> createState() => _WeightEditSheetState();
}

class _WeightEditSheetState extends State<WeightEditSheet> {
  late double _kg = widget.entry.kg;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final canSave = _kg >= 20;
    return SheetScaffold(
      title: '체중 수정',
      subtitle: '${widget.entry.time} 기록',
      leading: const Icon(AppIcons.weight, color: AppIconColors.weight),
      onClose: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('체중', style: t(AppFontSize.f12, c: AppColor.textMuted)),
          const SizedBox(height: AppSpace.s8),
          NumberField(
            value: _kg,
            unit: 'kg',
            decimal: true,
            min: 0,
            max: 300,
            onChanged: (v) => setState(() => _kg = v.toDouble()),
          ),
          const SizedBox(height: AppSpace.s16),
          PrimaryButton(
            label: '저장',
            enabled: canSave,
            onTap: canSave
                ? () {
                    s.updateWeight(widget.entry.id, _kg);
                    Navigator.of(context).pop();
                  }
                : null,
          ),
          TextLink(
            label: '체중 기록 삭제',
            color: AppColor.alertText,
            onTap: () async {
              final ok = await confirmDialog(
                context,
                title: '체중 기록을 삭제할까요?',
                message:
                    '${widget.entry.kg.toStringAsFixed(1)}kg 기록이 지워져요. 되돌릴 수 없어요.',
                confirmLabel: '삭제',
                destructive: true,
              );
              if (!ok || !context.mounted) return;
              s.deleteWeight(widget.entry.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
