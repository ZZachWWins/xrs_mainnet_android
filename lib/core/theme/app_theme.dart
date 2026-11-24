import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:xeris_wallet/core/theme/app_theme_extension.dart';

enum AppThemeMode { system, light, dark, solar, cyberpunk }

class AppColors {
  // Primary brand colors
  static const Color brandBlue = Color(0xFF0019A5);
  static const Color brandVibrant = Color(0xFF8FA3FF);
  
  // Dark Theme Backgrounds
  static const Color brandNavy = Color(0xFF010414);
  static const Color brandMidnight = Color(0xFF050B2B);
  static const Color brandSpace = Color(0xFF0A123D);
  static const Color brandDeep = Color(0xFF000B4F);
  
  // Light Theme Backgrounds
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);
  
  // Solar — warm amber, refined gold
  static const Color solarBg = Color(0xFF0E0C0A);
  static const Color solarSurface = Color(0xFF19150F);
  static const Color solarPrimary = Color(0xFFC49A3A);
  static const Color solarSecondary = Color(0xFF8C7355);
  static const Color solarText = Color(0xFFF5F0E8);

  // Violet — deep purple, calm indigo
  static const Color cyberBg = Color(0xFF0C0A14);
  static const Color cyberSurface = Color(0xFF15121F);
  static const Color cyberPrimary = Color(0xFF8B5CF6);
  static const Color cyberSecondary = Color(0xFF6366F1);
  static const Color cyberText = Color(0xFFF5F3FF);
  
  // Common Colors
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF22C55E);

  // Aliases
  static const Color brandLight = Color(0xFFF0F2F5);
  static const Color brandMuted = Color(0xFF4E5BA6);
  static const Color textBody = Color(0xFF94A3B8);
  static const Color brandError = error;
  static const Color brandSuccess = success;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.brandNavy,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.brandBlue,
        secondary: AppColors.brandVibrant,
        surface: AppColors.brandSpace,
        onSurface: AppColors.brandLight,
        error: AppColors.error,
      ),
      extensions: [
        AppThemeExtension(
          heroDecoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.brandMidnight, AppColors.brandNavy],
            ),
          ),
          balanceStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700),
          glassColor: Colors.white.withValues(alpha: 0.04),
          navbarDecoration: BoxDecoration(
            color: AppColors.brandMidnight,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          surfaceBlur: 0.0,
          accentGlowColor: AppColors.brandVibrant.withValues(alpha: 0.12),
        ),
      ],
      textTheme: _buildTextTheme(AppColors.brandLight, Color(0xFF94A3B8)),
      cardTheme: _buildCardTheme(AppColors.brandSpace, Colors.white.withValues(alpha: 0.05)),
      elevatedButtonTheme: _buildButtonTheme(AppColors.brandLight, AppColors.brandDeep),
      appBarTheme: _buildAppBarTheme(Brightness.dark, AppColors.brandLight),
    );
  }

  static ThemeData get lightTheme {
    const onSurfaceColor = Color(0xFF0F172A);
    const secondaryTextColor = Color(0xFF475569); // Darker grey for better contrast

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandBlue,
        secondary: Color(0xFF4E5BA6), // Slightly darker secondary for visibility
        surface: AppColors.lightSurface,
        onSurface: onSurfaceColor,
        error: AppColors.error,
      ),
      extensions: [
        AppThemeExtension(
          heroDecoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
          ),
          balanceStyle: GoogleFonts.plusJakartaSans(color: onSurfaceColor, fontWeight: FontWeight.w800),
          glassColor: Colors.black.withValues(alpha: 0.03),
          navbarDecoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          surfaceBlur: 10.0,
          accentGlowColor: AppColors.brandBlue.withValues(alpha: 0.1),
        ),
      ],
      textTheme: _buildTextTheme(onSurfaceColor, secondaryTextColor),
      cardTheme: _buildCardTheme(AppColors.lightSurface, AppColors.lightBorder),
      elevatedButtonTheme: _buildButtonTheme(AppColors.brandBlue, Colors.white),
      appBarTheme: _buildAppBarTheme(Brightness.light, onSurfaceColor),
    );
  }

  static ThemeData get solarTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.solarBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.solarPrimary,
        secondary: AppColors.solarSecondary,
        surface: AppColors.solarSurface,
        onSurface: AppColors.solarText,
        error: AppColors.error,
      ),
      extensions: [
        AppThemeExtension(
          heroDecoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF19150F), AppColors.solarBg],
            ),
          ),
          balanceStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.solarPrimary,
            fontWeight: FontWeight.w700,
          ),
          glassColor: AppColors.solarPrimary.withValues(alpha: 0.06),
          navbarDecoration: BoxDecoration(
            color: AppColors.solarSurface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.solarPrimary.withValues(alpha: 0.15)),
          ),
          surfaceBlur: 0.0,
          accentGlowColor: AppColors.solarPrimary.withValues(alpha: 0.08),
        ),
      ],
      textTheme: _buildTextTheme(AppColors.solarText, AppColors.solarText.withValues(alpha: 0.5)),
      cardTheme: _buildCardTheme(AppColors.solarSurface, AppColors.solarPrimary.withValues(alpha: 0.08)),
      elevatedButtonTheme: _buildButtonTheme(AppColors.solarPrimary, AppColors.solarBg),
      appBarTheme: _buildAppBarTheme(Brightness.dark, AppColors.solarText),
    );
  }

  static ThemeData get cyberpunkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.cyberBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.cyberPrimary,
        secondary: AppColors.cyberSecondary,
        surface: AppColors.cyberSurface,
        onSurface: AppColors.cyberText,
        error: AppColors.error,
      ),
      extensions: [
        AppThemeExtension(
          heroDecoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF15121F), AppColors.cyberBg],
            ),
          ),
          balanceStyle: GoogleFonts.plusJakartaSans(
            color: AppColors.cyberPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            shadows: [
              Shadow(color: AppColors.cyberPrimary.withValues(alpha: 0.25), blurRadius: 16),
            ],
          ),
          glassColor: AppColors.cyberPrimary.withValues(alpha: 0.06),
          navbarDecoration: BoxDecoration(
            color: AppColors.cyberSurface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.cyberPrimary.withValues(alpha: 0.15)),
          ),
          surfaceBlur: 0.0,
          accentGlowColor: AppColors.cyberPrimary.withValues(alpha: 0.08),
        ),
      ],
      textTheme: _buildTextTheme(AppColors.cyberText, AppColors.cyberText.withValues(alpha: 0.5)),
      cardTheme: _buildCardTheme(AppColors.cyberSurface, AppColors.cyberPrimary.withValues(alpha: 0.1)),
      elevatedButtonTheme: _buildButtonTheme(AppColors.cyberPrimary, Colors.white),
      appBarTheme: _buildAppBarTheme(Brightness.dark, AppColors.cyberText),
    );
  }

  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w800, letterSpacing: -1.0),
      displayMedium: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      headlineLarge: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.bold),
      bodyLarge: GoogleFonts.inter(color: primaryColor, fontSize: 16),
      bodyMedium: GoogleFonts.inter(color: secondaryColor, fontSize: 14),
      labelLarge: GoogleFonts.inter(color: primaryColor, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      labelSmall: GoogleFonts.inter(color: secondaryColor, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4),
    );
  }

  static CardThemeData _buildCardTheme(Color color, Color borderColor) {
    return CardThemeData(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
        side: BorderSide(color: borderColor),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
    );
  }

  static ElevatedButtonThemeData _buildButtonTheme(Color bgColor, Color textColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(Brightness brightness, Color textColor) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textColor),
      titleTextStyle: GoogleFonts.plusJakartaSans(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
    );
  }
}
