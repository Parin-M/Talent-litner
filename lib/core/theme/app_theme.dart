import 'package:flutter/material.dart';

class ThemeOption {
  final String name;
  final Color primary;
  final Color secondary;
  final Color background;
  const ThemeOption(this.name, this.primary, this.secondary, this.background);
}

class AppTheme {
  static const themes = <ThemeOption>[
    ThemeOption('Sky', Color(0xFF3F51B5), Color(0xFF64B5F6), Color(0xFFEFF3FF)),
    ThemeOption('Ocean', Color(0xFF0277BD), Color(0xFF26C6DA), Color(0xFFEAF8FC)),
    ThemeOption('Mint', Color(0xFF00897B), Color(0xFF4DB6AC), Color(0xFFECFAF7)),
    ThemeOption('Emerald', Color(0xFF2E7D32), Color(0xFF66BB6A), Color(0xFFF0F9F0)),
    ThemeOption('Lime', Color(0xFF689F38), Color(0xFFAFB42B), Color(0xFFF7FBEA)),
    ThemeOption('Gold', Color(0xFFEF6C00), Color(0xFFFFB300), Color(0xFFFFF5E7)),
    ThemeOption('Coral', Color(0xFFE64A19), Color(0xFFFF7043), Color(0xFFFFF0EB)),
    ThemeOption('Rose', Color(0xFFC2185B), Color(0xFFEC407A), Color(0xFFFFEEF5)),
    ThemeOption('Lilac', Color(0xFF6A1B9A), Color(0xFFAB47BC), Color(0xFFF8EEFF)),
    ThemeOption('Lavender', Color(0xFF5E35B1), Color(0xFF7E57C2), Color(0xFFF1EEFF)),
    ThemeOption('Indigo', Color(0xFF3949AB), Color(0xFF7986CB), Color(0xFFEEF0FF)),
    ThemeOption('Purple', Color(0xFF7B1FA2), Color(0xFFBA68C8), Color(0xFFF8EDFF)),
    ThemeOption('Red', Color(0xFFC62828), Color(0xFFEF5350), Color(0xFFFFEEEE)),
    ThemeOption('Earth', Color(0xFF6D4C41), Color(0xFFA1887F), Color(0xFFF8F2EF)),
    ThemeOption('Turquoise', Color(0xFF00796B), Color(0xFF26A69A), Color(0xFFE9FAF6)),
    ThemeOption('Icy Blue', Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFEDF6FF)),
    ThemeOption('Dark Green', Color(0xFF33691E), Color(0xFF7CB342), Color(0xFFF0F7EC)),
    ThemeOption('Berry', Color(0xFFAD1457), Color(0xFFD81B60), Color(0xFFFFEDF4)),
    ThemeOption('Graphite', Color(0xFF37474F), Color(0xFF78909C), Color(0xFFF0F3F5)),
    ThemeOption('Pure Glass', Color(0xFF536DFE), Color(0xFFB388FF), Color(0xFFEAF0FF)),
    ThemeOption('Sunrise', Color(0xFFF4511E), Color(0xFFFFB300), Color(0xFFFFF2E8)),
    ThemeOption('Sunset', Color(0xFFD84315), Color(0xFFE91E63), Color(0xFFFFEEF0)),
    ThemeOption('Peach', Color(0xFFFF7043), Color(0xFFFFAB91), Color(0xFFFFF3EF)),
    ThemeOption('Apricot', Color(0xFFFF8F00), Color(0xFFFFCC80), Color(0xFFFFF6E9)),
    ThemeOption('Sand', Color(0xFF8D6E63), Color(0xFFD7CCC8), Color(0xFFFAF6F2)),
    ThemeOption('Bronze', Color(0xFF795548), Color(0xFFA1887F), Color(0xFFF8F3EF)),
    ThemeOption('Copper', Color(0xFFAD4E00), Color(0xFFFF8A50), Color(0xFFFFF1EA)),
    ThemeOption('Ruby', Color(0xFF9B1B30), Color(0xFFE57373), Color(0xFFFFF0F2)),
    ThemeOption('Wine', Color(0xFF6A1B3A), Color(0xFFAD4A70), Color(0xFFFCEEF4)),
    ThemeOption('Plum', Color(0xFF7B1FA2), Color(0xFFCE93D8), Color(0xFFF8F0FA)),
    ThemeOption('Orchid', Color(0xFF8E24AA), Color(0xFFE1BEE7), Color(0xFFFAF2FC)),
    ThemeOption('Violet Mist', Color(0xFF512DA8), Color(0xFF9575CD), Color(0xFFF2EEFC)),
    ThemeOption('Midnight', Color(0xFF283593), Color(0xFF5C6BC0), Color(0xFFEEF0FF)),
    ThemeOption('Navy', Color(0xFF0D47A1), Color(0xFF5472D3), Color(0xFFEDF3FF)),
    ThemeOption('Arctic', Color(0xFF00838F), Color(0xFF4DD0E1), Color(0xFFEAFBFC)),
    ThemeOption('Glacier', Color(0xFF0277BD), Color(0xFF80DEEA), Color(0xFFEAF8FC)),
    ThemeOption('Forest', Color(0xFF1B5E20), Color(0xFF43A047), Color(0xFFEDF8EE)),
    ThemeOption('Pine', Color(0xFF1B4332), Color(0xFF52B788), Color(0xFFEDF8F2)),
    ThemeOption('Moss', Color(0xFF556B2F), Color(0xFF8FBC8F), Color(0xFFF3F7ED)),
    ThemeOption('Olive', Color(0xFF6B7A1D), Color(0xFFA4B64C), Color(0xFFF5F8E9)),
    ThemeOption('Sage', Color(0xFF558B6E), Color(0xFFA8C3B0), Color(0xFFF0F6F1)),
    ThemeOption('Teal', Color(0xFF00695C), Color(0xFF26A69A), Color(0xFFEAF8F5)),
    ThemeOption('Aqua', Color(0xFF00838F), Color(0xFF4DD0E1), Color(0xFFEAFBFC)),
    ThemeOption('Cyan', Color(0xFF0097A7), Color(0xFF4DD0E1), Color(0xFFEAFBFD)),
    ThemeOption('Azure', Color(0xFF1976D2), Color(0xFF64B5F6), Color(0xFFEDF5FF)),
    ThemeOption('Cobalt', Color(0xFF304FFE), Color(0xFF7986FF), Color(0xFFF0F1FF)),
    ThemeOption('Sapphire', Color(0xFF1565C0), Color(0xFF42A5F5), Color(0xFFEEF6FF)),
    ThemeOption('Amethyst', Color(0xFF6A1B9A), Color(0xFFBA68C8), Color(0xFFF8EEFF)),
    ThemeOption('Charcoal', Color(0xFF263238), Color(0xFF546E7A), Color(0xFFEEF2F4)),
    ThemeOption('Slate', Color(0xFF455A64), Color(0xFF90A4AE), Color(0xFFF0F4F6)),
  ];

  static ThemeData build(int index, {String mode = 'aero', bool glass = true, double glassOpacity = .62}) {
    final t = themes[index.clamp(0, themes.length - 1).toInt()];
    final dark = mode == 'dark' || mode == 'amoled';
    final amoled = mode == 'amoled';
    final aero = mode == 'aero';
    final brightness = dark ? Brightness.dark : Brightness.light;
    final baseScheme = ColorScheme.fromSeed(seedColor: t.primary, brightness: brightness);
    final background = amoled ? Colors.black : dark ? const Color(0xFF101114) : aero ? const Color(0xFFEAF0FA) : t.background;
    final surface = amoled ? const Color(0xFF000000) : dark ? const Color(0xFF181A1F) : aero ? Colors.white.withValues(alpha: glass ? glassOpacity.clamp(.30, .90) : .96) : Colors.white;
    final scheme = baseScheme.copyWith(primary: dark ? t.secondary : t.primary, surface: surface, onSurface: dark ? Colors.white : const Color(0xFF202124));
    return ThemeData(
      useMaterial3: false, brightness: brightness, colorScheme: scheme, primaryColor: t.primary,
      scaffoldBackgroundColor: background, fontFamily: 'sans-serif', visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? surface : aero ? Colors.white.withValues(alpha: .64) : t.primary,
        foregroundColor: dark || aero ? scheme.onSurface : Colors.white,
        elevation: dark ? 0 : (aero ? 1 : 4), scrolledUnderElevation: 2, centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface, elevation: dark ? 0 : (aero ? 1 : 3),
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(aero ? 12 : 4), side: BorderSide(color: scheme.outline.withValues(alpha: dark ? .30 : (aero ? .20 : .10)))),
      ),
      dialogTheme: DialogThemeData(backgroundColor: surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: dark ? surface : Colors.white.withValues(alpha: aero ? .80 : 1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: scheme.outline.withValues(alpha: .30))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: scheme.outline.withValues(alpha: .24))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: scheme.primary, width: 2)),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13))),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
      floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: scheme.primary, foregroundColor: scheme.onPrimary, shape: const CircleBorder(), elevation: 6),
      dividerTheme: DividerThemeData(color: scheme.outline.withValues(alpha: .20)),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 1)),
      snackBarTheme: SnackBarThemeData(backgroundColor: dark ? const Color(0xFF292A2D) : const Color(0xFF323232), contentTextStyle: const TextStyle(color: Colors.white), behavior: SnackBarBehavior.floating),
    );
  }
}
