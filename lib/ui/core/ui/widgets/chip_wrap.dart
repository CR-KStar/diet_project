import 'package:flutter/material.dart';
import 'package:diet_project/ui/core/ui/widgets/select_chip.dart';

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
