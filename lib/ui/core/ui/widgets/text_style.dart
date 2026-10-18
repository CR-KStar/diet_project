import 'package:diet_project/ui/core/ui/themes/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

TextStyle t(
  double size, {
  FontWeight w = FontWeight.w400,
  Color c = AppColor.text,
  double? sp,
  double? h,
}) => GoogleFonts.notoSansKr(
  fontSize: size,
  fontWeight: w,
  color: c,
  letterSpacing: sp,
  height: h,
);
