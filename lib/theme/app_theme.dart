import 'package:flutter/material.dart';

/// Цветовая палитра приложения для одной конкретной темы.
///
/// Подключается в [ThemeData] как [ThemeExtension] — это значит, что она
/// живёт внутри `Theme.of(context)` и переключение темы (тёмная/светлая)
/// сразу отражается во всём дереве виджетов, без ручной синхронизации.
/// Виджеты берут цвета через `AppColors.of(context)` вместо старых
/// статических констант.
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceHigh;
  final Color sidebar;
  final Color accent; // акцентный цвет (кнопка play, активные элементы)
  final Color onAccent; // цвет иконки/текста поверх accent
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color hoverOverlay;
  final Color sliderInactive;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color glassBorderStrong;
  final Color glassShadow;
  final Color scrollbarThumb;
  final Color accentGlow; // мягкое акцентное свечение (кнопка play, активные карточки)
  final Color glassHighlight; // тонкий блик по верхнему краю стеклянных поверхностей

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.sidebar,
    required this.accent,
    required this.onAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.hoverOverlay,
    required this.sliderInactive,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassBorderStrong,
    required this.glassShadow,
    required this.scrollbarThumb,
    required this.accentGlow,
    required this.glassHighlight,
  });

  static const dark = AppPalette(
    background: Color(0xFF121212), // не чистый чёрный — мягче для глаз
    surface: Color(0xFF181818),
    surfaceHigh: Color(0xFF282828), // заметно светлее — даёт ощущение слоёв
    sidebar: Color(0xFF0A0A0A), // чуть темнее фона — сайдбар "утоплен"
    accent: Color(0xFFE0294B),
    onAccent: Colors.black,
    textPrimary: Color(0xFFF2F2F2), // не чистый белый — меньше режет глаз
    textSecondary: Color(0xFFA7A7A7),
    divider: Colors.white12,
    hoverOverlay: Color(0x14FFFFFF), // белый, ~8% непрозрачности
    sliderInactive: Colors.white24,
    glassFill: Color(0x1FFFFFFF), // белый, ~12%
    glassFillStrong: Color(0x33FFFFFF), // белый, ~20%
    glassBorder: Color(0x2EFFFFFF), // белый, ~18%
    glassBorderStrong: Color(0x52FFFFFF), // белый, ~32%
    glassShadow: Color(0x59000000), // чёрный, ~35% — глубже тень на светлом фоне
    scrollbarThumb: Colors.white24,
    accentGlow: Color(0x4DE0294B), // акцент, ~30% — свечение под play-кнопкой и активными карточками
    glassHighlight: Color(0x26FFFFFF), // белый, ~15% — блик по верхнему краю стекла
  );

  static const light = AppPalette(
    background: Color(0xFFF7F7F7),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE9E9EC),
    sidebar: Color(0xFFFFFFFF),
    accent: Color(0xFFE0294B),
    onAccent: Colors.black,
    textPrimary: Color(0xFF121212),
    textSecondary: Color(0xFF5E5E5E),
    divider: Colors.black12,
    hoverOverlay: Color(0x0A000000), // чёрный, ~4%
    sliderInactive: Colors.black26,
    glassFill: Color(0x14000000), // чёрный, ~8%
    glassFillStrong: Color(0x1F000000), // чёрный, ~12%
    glassBorder: Color(0x1F000000), // чёрный, ~12%
    glassBorderStrong: Color(0x33000000), // чёрный, ~20%
    glassShadow: Color(0x26000000), // чёрный, ~15%
    scrollbarThumb: Colors.black26,
    accentGlow: Color(0x33E0294B), // акцент, ~20%
    glassHighlight: Color(0x59FFFFFF), // белый, ~35% — на светлом фоне блик нужен ярче
  );

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceHigh,
    Color? sidebar,
    Color? accent,
    Color? onAccent,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? hoverOverlay,
    Color? sliderInactive,
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassBorder,
    Color? glassBorderStrong,
    Color? glassShadow,
    Color? scrollbarThumb,
    Color? accentGlow,
    Color? glassHighlight,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceHigh: surfaceHigh ?? this.surfaceHigh,
      sidebar: sidebar ?? this.sidebar,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      hoverOverlay: hoverOverlay ?? this.hoverOverlay,
      sliderInactive: sliderInactive ?? this.sliderInactive,
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      glassBorderStrong: glassBorderStrong ?? this.glassBorderStrong,
      glassShadow: glassShadow ?? this.glassShadow,
      scrollbarThumb: scrollbarThumb ?? this.scrollbarThumb,
      accentGlow: accentGlow ?? this.accentGlow,
      glassHighlight: glassHighlight ?? this.glassHighlight,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceHigh: Color.lerp(surfaceHigh, other.surfaceHigh, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      hoverOverlay: Color.lerp(hoverOverlay, other.hoverOverlay, t)!,
      sliderInactive: Color.lerp(sliderInactive, other.sliderInactive, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBorderStrong: Color.lerp(glassBorderStrong, other.glassBorderStrong, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
      scrollbarThumb: Color.lerp(scrollbarThumb, other.scrollbarThumb, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      glassHighlight: Color.lerp(glassHighlight, other.glassHighlight, t)!,
    );
  }
}

/// Точка доступа к палитре текущей темы из виджетов:
/// `AppColors.of(context).textSecondary` вместо старого
/// `AppColors.textSecondary`. Также оставлен статический [red] —
/// акцентный цвет бренда одинаков в обеих темах и используется в местах,
/// где BuildContext неудобен (например, в CustomPainter).
class AppColors {
  AppColors._();

  static const red = Color(0xFFE0294B);

  static AppPalette of(BuildContext context) {
    return Theme.of(context).extension<AppPalette>() ?? AppPalette.dark;
  }
}

class AppTheme {
  static ThemeData _themeFor(AppPalette palette, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      fontFamily: 'Helvetica',
      extensions: [palette],
      colorScheme: brightness == Brightness.dark
          ? ColorScheme.dark(primary: palette.accent, surface: palette.surface)
          : ColorScheme.light(primary: palette.accent, surface: palette.surface),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
      ),
      textTheme: TextTheme(
        bodyMedium: TextStyle(color: palette.textPrimary),
        bodySmall: TextStyle(color: palette.textSecondary),
      ),
      iconTheme: IconThemeData(color: palette.textPrimary),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(palette.scrollbarThumb),
      ),
    );
  }

  static ThemeData get dark => _themeFor(AppPalette.dark, Brightness.dark);
  static ThemeData get light => _themeFor(AppPalette.light, Brightness.light);
}
