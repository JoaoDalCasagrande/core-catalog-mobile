import 'package:flutter/material.dart';

/// Paleta copiada dos tokens CSS do front-end web (catalog.module.css etc.).
class AppColors {
  static const brand = Color(0xFF0E5C4A);
  static const brand2 = Color(0xFF2E7D6B);
  static const brand3 = Color(0xFF5E9E8E);
  static const brand4 = Color(0xFF93BFB3);
  static const ruler5 = Color(0xFFB7D3CB);

  static const bgPage = Color(0xFFE6EAEB);
  static const bgSurface = Color(0xFFF8F9F9);
  static const bgRaised = Color(0xFFFFFFFF);
  static const bgSunken = Color(0xFFDCE1E3);
  static const bgBrandTint = Color(0xFFD5E8E2);

  static const borderSubtle = Color(0xFFC3CBCE);
  static const borderStrong = Color(0xFF7C888E);

  static const textPrimary = Color(0xFF1B2327);
  static const textSecondary = Color(0xFF566268);

  static const alertBg = Color(0xFFFBEAEA);
  static const alertText = Color(0xFF8A1F1F);

  /// Cores da régua por categoria, como em builds/[id]/page.tsx.
  static const categoryColors = <String, Color>{
    'CPU': brand,
    'GPU': brand2,
    'RAM': brand3,
    'Armazenamento': brand4,
  };
  static const fallbackColors = <Color>[ruler5, brand3, brand2];

  static Color forCategory(String category, int index) =>
      categoryColors[category] ??
      fallbackColors[index % fallbackColors.length];
}

class AppFonts {
  static const sans = 'IBMPlexSans';
  static const condensed = 'IBMPlexSansCondensed';
}

/// Estilos de texto reutilizados nas telas.
class AppText {
  static const pageTitle = TextStyle(
    fontFamily: AppFonts.condensed,
    fontWeight: FontWeight.w600,
    fontSize: 30,
    height: 1.15,
    color: AppColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontFamily: AppFonts.condensed,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static const subtitle = TextStyle(
    fontSize: 15,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const secondary = TextStyle(
    fontSize: 13,
    color: AppColors.textSecondary,
  );

  static const itemName = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.brand,
    primary: AppColors.brand,
    onPrimary: Colors.white,
    secondary: AppColors.brand2,
    onSecondary: Colors.white,
    surface: AppColors.bgSurface,
    onSurface: AppColors.textPrimary,
    error: AppColors.alertText,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: AppFonts.sans,
    scaffoldBackgroundColor: AppColors.bgSurface,
    dividerColor: AppColors.borderSubtle,
  );
}

/// Decoração padrão dos campos de formulário (borda de 4px como no web).
InputDecoration appInputDecoration({
  String? label,
  String? hint,
  String? helper,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    errorMaxLines: 3,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: AppColors.bgRaised,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: border(AppColors.borderStrong),
    enabledBorder: border(AppColors.borderStrong),
    focusedBorder: border(AppColors.brand, 2),
    errorBorder: border(AppColors.alertText),
    focusedErrorBorder: border(AppColors.alertText, 2),
    disabledBorder: border(AppColors.borderSubtle),
  );
}

/// Caixa com borda suave e fundo branco usada como "card" nas telas.
BoxDecoration appCardDecoration({Color color = AppColors.bgRaised}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: AppColors.borderSubtle),
  );
}
