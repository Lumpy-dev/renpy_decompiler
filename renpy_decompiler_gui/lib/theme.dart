import 'package:flutter/material.dart';

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static MaterialScheme lightScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xff904a4a),
      surfaceTint: Color(0xff904a4a),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffffdad8),
      onPrimaryContainer: Color(0xff3b080c),
      secondary: Color(0xff775655),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffffdad8),
      onSecondaryContainer: Color(0xff2c1515),
      tertiary: Color(0xff745a2f),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xffffdeac),
      onTertiaryContainer: Color(0xff281900),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff410002),
      background: Color(0xfffff8f7),
      onBackground: Color(0xff231919),
      surface: Color(0xfffff8f7),
      onSurface: Color(0xff231919),
      surfaceVariant: Color(0xfff4dddc),
      onSurfaceVariant: Color(0xff524342),
      outline: Color(0xff857372),
      outlineVariant: Color(0xffd7c1c0),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff382e2d),
      inverseOnSurface: Color(0xffffedeb),
      inversePrimary: Color(0xffffb3b1),
      primaryFixed: Color(0xffffdad8),
      onPrimaryFixed: Color(0xff3b080c),
      primaryFixedDim: Color(0xffffb3b1),
      onPrimaryFixedVariant: Color(0xff733334),
      secondaryFixed: Color(0xffffdad8),
      onSecondaryFixed: Color(0xff2c1515),
      secondaryFixedDim: Color(0xffe6bdbb),
      onSecondaryFixedVariant: Color(0xff5d3f3e),
      tertiaryFixed: Color(0xffffdeac),
      onTertiaryFixed: Color(0xff281900),
      tertiaryFixedDim: Color(0xffe4c18d),
      onTertiaryFixedVariant: Color(0xff5a4319),
      surfaceDim: Color(0xffe8d6d5),
      surfaceBright: Color(0xfffff8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0ef),
      surfaceContainer: Color(0xfffceae9),
      surfaceContainerHigh: Color(0xfff6e4e3),
      surfaceContainerHighest: Color(0xfff0dedd),
    );
  }

  ThemeData light() {
    return theme(lightScheme().toColorScheme());
  }

  static MaterialScheme lightMediumContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xff6e2f30),
      surfaceTint: Color(0xff904a4a),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xffaa5f5f),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff593b3b),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff8f6c6b),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff563f16),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff8c7042),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff8c0009),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffda342e),
      onErrorContainer: Color(0xffffffff),
      background: Color(0xfffff8f7),
      onBackground: Color(0xff231919),
      surface: Color(0xfffff8f7),
      onSurface: Color(0xff231919),
      surfaceVariant: Color(0xfff4dddc),
      onSurfaceVariant: Color(0xff4e3f3f),
      outline: Color(0xff6c5b5a),
      outlineVariant: Color(0xff897676),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff382e2d),
      inverseOnSurface: Color(0xffffedeb),
      inversePrimary: Color(0xffffb3b1),
      primaryFixed: Color(0xffaa5f5f),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff8d4747),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff8f6c6b),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff745453),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff8c7042),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff71582c),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffe8d6d5),
      surfaceBright: Color(0xfffff8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0ef),
      surfaceContainer: Color(0xfffceae9),
      surfaceContainerHigh: Color(0xfff6e4e3),
      surfaceContainerHighest: Color(0xfff0dedd),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme().toColorScheme());
  }

  static MaterialScheme lightHighContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.light,
      primary: Color(0xff440f12),
      surfaceTint: Color(0xff904a4a),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff6e2f30),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff341b1b),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff593b3b),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff301f00),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff563f16),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff4e0002),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff8c0009),
      onErrorContainer: Color(0xffffffff),
      background: Color(0xfffff8f7),
      onBackground: Color(0xff231919),
      surface: Color(0xfffff8f7),
      onSurface: Color(0xff000000),
      surfaceVariant: Color(0xfff4dddc),
      onSurfaceVariant: Color(0xff2e2120),
      outline: Color(0xff4e3f3f),
      outlineVariant: Color(0xff4e3f3f),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff382e2d),
      inverseOnSurface: Color(0xffffffff),
      inversePrimary: Color(0xffffe6e5),
      primaryFixed: Color(0xff6e2f30),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff521a1b),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff593b3b),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff402625),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff563f16),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff3d2902),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffe8d6d5),
      surfaceBright: Color(0xfffff8f7),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfffff0ef),
      surfaceContainer: Color(0xfffceae9),
      surfaceContainerHigh: Color(0xfff6e4e3),
      surfaceContainerHighest: Color(0xfff0dedd),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme().toColorScheme());
  }

  static MaterialScheme darkScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffb3b1),
      surfaceTint: Color(0xffffb3b1),
      onPrimary: Color(0xff571d1f),
      primaryContainer: Color(0xff733334),
      onPrimaryContainer: Color(0xffffdad8),
      secondary: Color(0xffe6bdbb),
      onSecondary: Color(0xff442929),
      secondaryContainer: Color(0xff5d3f3e),
      onSecondaryContainer: Color(0xffffdad8),
      tertiary: Color(0xffe4c18d),
      onTertiary: Color(0xff412d05),
      tertiaryContainer: Color(0xff5a4319),
      onTertiaryContainer: Color(0xffffdeac),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      background: Color(0xff1a1111),
      onBackground: Color(0xfff0dedd),
      surface: Color(0xff1a1111),
      onSurface: Color(0xfff0dedd),
      surfaceVariant: Color(0xff524342),
      onSurfaceVariant: Color(0xffd7c1c0),
      outline: Color(0xffa08c8b),
      outlineVariant: Color(0xff524342),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xfff0dedd),
      inverseOnSurface: Color(0xff382e2d),
      inversePrimary: Color(0xff904a4a),
      primaryFixed: Color(0xffffdad8),
      onPrimaryFixed: Color(0xff3b080c),
      primaryFixedDim: Color(0xffffb3b1),
      onPrimaryFixedVariant: Color(0xff733334),
      secondaryFixed: Color(0xffffdad8),
      onSecondaryFixed: Color(0xff2c1515),
      secondaryFixedDim: Color(0xffe6bdbb),
      onSecondaryFixedVariant: Color(0xff5d3f3e),
      tertiaryFixed: Color(0xffffdeac),
      onTertiaryFixed: Color(0xff281900),
      tertiaryFixedDim: Color(0xffe4c18d),
      onTertiaryFixedVariant: Color(0xff5a4319),
      surfaceDim: Color(0xff1a1111),
      surfaceBright: Color(0xff423736),
      surfaceContainerLowest: Color(0xff140c0c),
      surfaceContainerLow: Color(0xff231919),
      surfaceContainer: Color(0xff271d1d),
      surfaceContainerHigh: Color(0xff322827),
      surfaceContainerHighest: Color(0xff3d3232),
    );
  }

  ThemeData dark() {
    return theme(darkScheme().toColorScheme());
  }

  static MaterialScheme darkMediumContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xffffb9b7),
      surfaceTint: Color(0xffffb3b1),
      onPrimary: Color(0xff340407),
      primaryContainer: Color(0xffcb7a79),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xffebc1bf),
      onSecondary: Color(0xff261010),
      secondaryContainer: Color(0xffad8886),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xffe8c690),
      onTertiary: Color(0xff211400),
      tertiaryContainer: Color(0xffaa8c5c),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffbab1),
      onError: Color(0xff370001),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      background: Color(0xff1a1111),
      onBackground: Color(0xfff0dedd),
      surface: Color(0xff1a1111),
      onSurface: Color(0xfffff9f9),
      surfaceVariant: Color(0xff524342),
      onSurfaceVariant: Color(0xffdcc6c5),
      outline: Color(0xffb29e9d),
      outlineVariant: Color(0xff927f7e),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xfff0dedd),
      inverseOnSurface: Color(0xff322827),
      inversePrimary: Color(0xff743435),
      primaryFixed: Color(0xffffdad8),
      onPrimaryFixed: Color(0xff2c0104),
      primaryFixedDim: Color(0xffffb3b1),
      onPrimaryFixedVariant: Color(0xff5e2324),
      secondaryFixed: Color(0xffffdad8),
      onSecondaryFixed: Color(0xff200b0b),
      secondaryFixedDim: Color(0xffe6bdbb),
      onSecondaryFixedVariant: Color(0xff4a2f2e),
      tertiaryFixed: Color(0xffffdeac),
      onTertiaryFixed: Color(0xff1a0f00),
      tertiaryFixedDim: Color(0xffe4c18d),
      onTertiaryFixedVariant: Color(0xff48320a),
      surfaceDim: Color(0xff1a1111),
      surfaceBright: Color(0xff423736),
      surfaceContainerLowest: Color(0xff140c0c),
      surfaceContainerLow: Color(0xff231919),
      surfaceContainer: Color(0xff271d1d),
      surfaceContainerHigh: Color(0xff322827),
      surfaceContainerHighest: Color(0xff3d3232),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme().toColorScheme());
  }

  static MaterialScheme darkHighContrastScheme() {
    return const MaterialScheme(
      brightness: Brightness.dark,
      primary: Color(0xfffff9f9),
      surfaceTint: Color(0xffffb3b1),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffffb9b7),
      onPrimaryContainer: Color(0xff000000),
      secondary: Color(0xfffff9f9),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffebc1bf),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xfffffaf7),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xffe8c690),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xfffff9f9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffbab1),
      onErrorContainer: Color(0xff000000),
      background: Color(0xff1a1111),
      onBackground: Color(0xfff0dedd),
      surface: Color(0xff1a1111),
      onSurface: Color(0xffffffff),
      surfaceVariant: Color(0xff524342),
      onSurfaceVariant: Color(0xfffff9f9),
      outline: Color(0xffdcc6c5),
      outlineVariant: Color(0xffdcc6c5),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xfff0dedd),
      inverseOnSurface: Color(0xff000000),
      inversePrimary: Color(0xff4e1719),
      primaryFixed: Color(0xffffe0de),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffffb9b7),
      onPrimaryFixedVariant: Color(0xff340407),
      secondaryFixed: Color(0xffffe0de),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffebc1bf),
      onSecondaryFixedVariant: Color(0xff261010),
      tertiaryFixed: Color(0xffffe3ba),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xffe8c690),
      onTertiaryFixedVariant: Color(0xff211400),
      surfaceDim: Color(0xff1a1111),
      surfaceBright: Color(0xff423736),
      surfaceContainerLowest: Color(0xff140c0c),
      surfaceContainerLow: Color(0xff231919),
      surfaceContainer: Color(0xff271d1d),
      surfaceContainerHigh: Color(0xff322827),
      surfaceContainerHighest: Color(0xff3d3232),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme().toColorScheme());
  }

  ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: textTheme.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        scaffoldBackgroundColor: colorScheme.background,
        canvasColor: colorScheme.surface,
      );

  List<ExtendedColor> get extendedColors => [];
}

class MaterialScheme {
  const MaterialScheme({
    required this.brightness,
    required this.primary,
    required this.surfaceTint,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.shadow,
    required this.scrim,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.primaryFixed,
    required this.onPrimaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixedVariant,
    required this.secondaryFixed,
    required this.onSecondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixedVariant,
    required this.tertiaryFixed,
    required this.onTertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixedVariant,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
  });

  final Brightness brightness;
  final Color primary;
  final Color surfaceTint;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;
  final Color secondary;
  final Color onSecondary;
  final Color secondaryContainer;
  final Color onSecondaryContainer;
  final Color tertiary;
  final Color onTertiary;
  final Color tertiaryContainer;
  final Color onTertiaryContainer;
  final Color error;
  final Color onError;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color surfaceVariant;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color shadow;
  final Color scrim;
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inversePrimary;
  final Color primaryFixed;
  final Color onPrimaryFixed;
  final Color primaryFixedDim;
  final Color onPrimaryFixedVariant;
  final Color secondaryFixed;
  final Color onSecondaryFixed;
  final Color secondaryFixedDim;
  final Color onSecondaryFixedVariant;
  final Color tertiaryFixed;
  final Color onTertiaryFixed;
  final Color tertiaryFixedDim;
  final Color onTertiaryFixedVariant;
  final Color surfaceDim;
  final Color surfaceBright;
  final Color surfaceContainerLowest;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
}

extension MaterialSchemeUtils on MaterialScheme {
  ColorScheme toColorScheme() {
    return ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: onSecondary,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: onSecondaryContainer,
      tertiary: tertiary,
      onTertiary: onTertiary,
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      background: background,
      onBackground: onBackground,
      surface: surface,
      onSurface: onSurface,
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: onSurfaceVariant,
      outline: outline,
      outlineVariant: outlineVariant,
      shadow: shadow,
      scrim: scrim,
      inverseSurface: inverseSurface,
      onInverseSurface: inverseOnSurface,
      inversePrimary: inversePrimary,
    );
  }
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
