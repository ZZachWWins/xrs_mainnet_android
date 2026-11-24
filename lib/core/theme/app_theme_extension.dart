import 'package:flutter/material.dart';

class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Decoration? heroDecoration;
  final TextStyle? balanceStyle;
  final Color? glassColor;
  final Decoration? navbarDecoration;
  final double? surfaceBlur;
  final Color? accentGlowColor;

  const AppThemeExtension({
    this.heroDecoration,
    this.balanceStyle,
    this.glassColor,
    this.navbarDecoration,
    this.surfaceBlur,
    this.accentGlowColor,
  });

  @override
  AppThemeExtension copyWith({
    Decoration? heroDecoration,
    TextStyle? balanceStyle,
    Color? glassColor,
    Decoration? navbarDecoration,
    double? surfaceBlur,
    Color? accentGlowColor,
  }) {
    return AppThemeExtension(
      heroDecoration: heroDecoration ?? this.heroDecoration,
      balanceStyle: balanceStyle ?? this.balanceStyle,
      glassColor: glassColor ?? this.glassColor,
      navbarDecoration: navbarDecoration ?? this.navbarDecoration,
      surfaceBlur: surfaceBlur ?? this.surfaceBlur,
      accentGlowColor: accentGlowColor ?? this.accentGlowColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      heroDecoration: Decoration.lerp(heroDecoration, other.heroDecoration, t),
      balanceStyle: TextStyle.lerp(balanceStyle, other.balanceStyle, t),
      glassColor: Color.lerp(glassColor, other.glassColor, t),
      navbarDecoration: Decoration.lerp(navbarDecoration, other.navbarDecoration, t),
      surfaceBlur: (surfaceBlur ?? 0) + ((other.surfaceBlur ?? 0) - (surfaceBlur ?? 0)) * t,
      accentGlowColor: Color.lerp(accentGlowColor, other.accentGlowColor, t),
    );
  }
}
