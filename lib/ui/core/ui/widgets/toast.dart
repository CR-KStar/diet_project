import 'package:flutter/material.dart';

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
}
