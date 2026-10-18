import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';

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
