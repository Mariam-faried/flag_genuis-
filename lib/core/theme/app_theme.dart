import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/question_model.dart';

class AppTheme {
  static const Color night = Color(0xFF050B1A);
  static const Color nightAccent = Color(0xFF09163A);
  static const Color panel = Color(0xFF0D1533);
  static const Color panelSoft = Color(0xFF1A2347);
  static const Color shimmerBase = Color(0xFF1A2347);
  static const Color shimmerHighlight = Color(0xFF2A3560);
  static const Color card = Color(0xFF1A2140);
  static const Color textPrimary = Color(0xFFF4F6FF);
  static const Color textSecondary = Color(0xFF9AA4C5);
  static const Color accentYellow = Color(0xFFFFD439);
  static const Color accentOrange = Color(0xFFFF8C36);
  static const Color accentBlue = Color(0xFF2563EB);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFF97373);
  static const Color outline = Color(0xFF5A6CAA);
  static const double radiusSm = 14.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 22.0;
  static const double radiusXl = 28.0;
  static const Color onGold = Color(0xFF111111);
  static const Color onBlue = textPrimary;
  static const Color medalGold = Color(0xFFE2B100);
  static const Color medalSilver = Color(0xFF7E8B96);
  static const Color medalBronze = Color(0xFFB26C2F);
  static const Color modeFlag = Color(0xFF33237D);
  static const Color modeCapital = Color(0xFF11503D);
  static const Color modePopulation = Color(0xFF5E3714);
  static const Color modeRegion = Color(0xFF113D75);
  static const Color modeRandom = Color(0xFF2A1F5E);
  static const Color modeExplorer = Color(0xFF233C5C);
  static const LinearGradient appBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [night, nightAccent, night],
  );
  static const LinearGradient homeBackgroundBaseGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1430), Color(0xFF070F24), Color(0xFF040916)],
    stops: [0, 0.55, 1],
  );
  static const LinearGradient homeBackgroundVeilGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x00000000), Color(0x26020A1A), Color(0x66020A1A)],
    stops: [0, 0.64, 1],
  );
  static const LinearGradient deepSpaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF040914), Color(0xFF0B1740), night],
  );
  static const LinearGradient homeHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF142C53), Color(0xFF1A3B66), Color(0xFF132B4D)],
  );
  static const Color homeHeaderBorder = Color(0xFF314F75);
  static const LinearGradient homeHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF17366C), Color(0xFF1A4A89), Color(0xFF1D356B)],
  );
  static const Color homeHeroBorder = Color(0xFF355EA3);
  static const LinearGradient homeDailyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D2556), Color(0xFF25204A), Color(0xFF1A1F43)],
  );
  static const LinearGradient homeSectionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF111B3C), Color(0xFF0C1734)],
  );
  static const LinearGradient homeExplorerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2C56), Color(0xFF122145)],
  );
  static const Color homeCardBorder = Color(0xFF466190);
  static const Color homeTextureLine = Color(0x17D5E6FF);
  static const Color homeTextureAccent = Color(0x127FB4FF);
  static const LinearGradient profileHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F2C57), Color(0xFF0E3A57), Color(0xFF0D2945)],
  );
  static const LinearGradient leaderboardHeroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF321661), Color(0xFF3A1471), Color(0xFF27124F)],
  );
  static const Color leaderboardHeroBorder = Color(0xFF57318C);
  static const LinearGradient flagQuizGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentBlue, Color(0xFF1E3A8A)],
  );
  static const LinearGradient capitalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22C55E), Color(0xFF166534)],
  );
  static const LinearGradient populationGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8C36), Color(0xFFB45309)],
  );
  static const LinearGradient regionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
  );
  static const LinearGradient randomMixGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFF0891B2)],
  );
  static const LinearGradient homeFlagGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3F71CC), Color(0xFF3257AC)],
  );
  static const LinearGradient homeCapitalGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF25956D), Color(0xFF196245)],
  );
  static const LinearGradient homePopulationGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD17A39), Color(0xFFA55A24)],
  );
  static const LinearGradient homeRegionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D94D1), Color(0xFF286AAC)],
  );
  static const LinearGradient homeRandomMixGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A63CC), Color(0xFF2C7CA7)],
  );
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [panelSoft, panel],
  );
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentYellow, accentOrange],
  );
  static const BoxShadow glowYellow = BoxShadow(
    color: Color(0x59FFD439),
    blurRadius: 24,
    spreadRadius: 1,
    offset: Offset(0, 8),
  );
  static const BoxShadow glowBlue = BoxShadow(
    color: Color(0x4D3B82F6),
    blurRadius: 24,
    spreadRadius: 1,
    offset: Offset(0, 8),
  );
  static const BoxShadow glowOrange = BoxShadow(
    color: Color(0x59FF8C36),
    blurRadius: 24,
    spreadRadius: 1,
    offset: Offset(0, 8),
  );
  static const BoxShadow cardShadow = BoxShadow(
    color: Colors.black54,
    blurRadius: 20,
    offset: Offset(0, 10),
  );
  static const BoxShadow homeCardShadow = BoxShadow(
    color: Color(0x52010614),
    blurRadius: 18,
    offset: Offset(0, 8),
  );
  static const Color timerGreen = success;
  static const Color timerYellow = accentOrange;
  static const Color timerRed = danger;

  static LinearGradient modeColor(QuizMode mode) {
    return switch (mode) {
      QuizMode.flag => flagQuizGradient,
      QuizMode.capital => capitalGradient,
      QuizMode.population => populationGradient,
      QuizMode.region => regionGradient,
      QuizMode.randomMix => randomMixGradient,
    };
  }

  static LinearGradient homeModeColor(QuizMode mode) {
    return switch (mode) {
      QuizMode.flag => homeFlagGradient,
      QuizMode.capital => homeCapitalGradient,
      QuizMode.population => homePopulationGradient,
      QuizMode.region => homeRegionGradient,
      QuizMode.randomMix => homeRandomMixGradient,
    };
  }

  static Color modeBackgroundColor(QuizMode mode) {
    return switch (mode) {
      QuizMode.flag => modeFlag,
      QuizMode.capital => modeCapital,
      QuizMode.population => modePopulation,
      QuizMode.region => modeRegion,
      QuizMode.randomMix => modeRandom,
    };
  }

  static ThemeData premiumDark() {
    final colorScheme = const ColorScheme.dark(
      primary: accentYellow,
      onPrimary: onGold,
      secondary: accentBlue,
      onSecondary: onBlue,
      tertiary: accentOrange,
      onTertiary: onGold,
      error: danger,
      onError: Color(0xFF150404),
      surface: panel,
      onSurface: textPrimary,
    );

    final textTheme =
        GoogleFonts.nunitoTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.baloo2(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          displayMedium: GoogleFonts.baloo2(
            fontSize: 40,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineLarge: GoogleFonts.baloo2(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineMedium: GoogleFonts.baloo2(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          headlineSmall: GoogleFonts.baloo2(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          titleLarge: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
          titleMedium: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
          bodyLarge: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          bodyMedium: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
          bodySmall: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
          labelLarge: GoogleFonts.nunito(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: night,
      textTheme: textTheme,
      dividerColor: outline,
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        elevation: 8,
        color: card,
        shadowColor: Colors.black54,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panelSoft,
        hintStyle: textTheme.bodyLarge?.copyWith(color: textSecondary),
        labelStyle: textTheme.bodyLarge?.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: accentYellow, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: danger),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: accentYellow,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
            if (states.contains(WidgetState.pressed)) {
              return accentOrange.withValues(alpha: 0.22);
            }
            return null;
          }),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: outline),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accentBlue,
          foregroundColor: colorScheme.onSecondary,
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelSoft,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: panelSoft,
        selectedColor: accentYellow.withValues(alpha: 0.25),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: panel,
        indicatorColor: accentYellow.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.nunito(
            fontWeight: FontWeight.w700,
            color: selected ? accentYellow : textSecondary,
          );
        }),
      ),
    );
  }
}
