import 'package:flutter/material.dart';

/// Brand palette sampled from the NayaSantha logo and the approved mockups.
class AppColors {
  AppColors._();

  // Core brand greens (logo leaf gradient runs light -> deep).
  static const Color leaf = Color(0xFF5CB338); // bright "Naya" green
  static const Color primary = Color(0xFF1E8E3E); // action green
  static const Color forest = Color(0xFF0F4C2A); // deep "Santha" green
  static const Color forestDark = Color(0xFF0A3A20); // sidebar / admin chrome

  // Surfaces
  static const Color background = Color(0xFFF5F9F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEDF4EA);
  static const Color border = Color(0xFFDCE6D8);

  // Text
  static const Color textPrimary = Color(0xFF16261C);
  static const Color textSecondary = Color(0xFF5E7266);
  static const Color textOnDark = Color(0xFFF3F8F1);

  // Semantic / status chips used across order + inventory states.
  static const Color success = Color(0xFF2E9E5B);
  static const Color info = Color(0xFF2A7DE1);
  static const Color warning = Color(0xFFE08A00);
  static const Color danger = Color(0xFFD64545);

  // Produce accents for category tiles and charts.
  static const Color tomato = Color(0xFFE2483B);
  static const Color carrot = Color(0xFFF08A24);
  static const Color turmeric = Color(0xFFE9B824);
  static const Color aubergine = Color(0xFF7B4B94);

  static const List<Color> chartSeries = <Color>[
    primary,
    turmeric,
    carrot,
    aubergine,
    info,
  ];

  static const LinearGradient leafGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[leaf, forest],
  );
}
