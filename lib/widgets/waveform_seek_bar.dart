import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "Эквалайзер"-полоса прогресса вместо обычного Slider — столбики разной
/// высоты, часть которых подсвечена акцентным цветом по мере проигрывания.
///
/// Настоящей амплитуды трека у нас нет (для этого пришлось бы декодировать
/// аудиофайл на клиенте), поэтому высоты столбиков генерируются
/// детерминированно по id трека через [Random] с фиксированным seed —
/// один и тот же трек всегда даёт одинаковый узор, а разные треки
/// выглядят по-разному, вместо одинаковой прямой полосы.
class WaveformSeekBar extends StatelessWidget {
  final String trackSeed;
  final Duration position;
  final Duration duration;

  /// null — перетаскивание/тап отключены (например, нет текущего трека).
  final ValueChanged<Duration>? onSeek;

  final int barCount;

  const WaveformSeekBar({
    super.key,
    required this.trackSeed,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.barCount = 46,
  });

  List<double> _barHeights() {
    final random = Random(trackSeed.hashCode);
    return List.generate(barCount, (i) {
      // Синусоида поверх случайности — чтобы узор был похож на волну
      // звука, а не выглядел белым шумом.
      final wave = (sin(i / barCount * pi * 3) + 1) / 2;
      final noise = random.nextDouble();
      return (0.22 + 0.78 * (wave * 0.55 + noise * 0.45)).clamp(0.16, 1.0);
    });
  }

  void _seekToLocalX(double localX, double width) {
    final callback = onSeek;
    if (callback == null || duration <= Duration.zero || width <= 0) return;
    final ratio = (localX / width).clamp(0.0, 1.0);
    callback(duration * ratio);
  }

  @override
  Widget build(BuildContext context) {
    final pal = AppColors.of(context);
    final heights = _barHeights();
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    final interactive = onSeek != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return MouseRegion(
          cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: interactive ? (d) => _seekToLocalX(d.localPosition.dx, width) : null,
            onHorizontalDragUpdate: interactive ? (d) => _seekToLocalX(d.localPosition.dx, width) : null,
            child: SizedBox(
              width: width,
              height: 28,
              child: CustomPaint(
                painter: _WaveformPainter(
                  heights: heights,
                  progress: progress,
                  activeColor: pal.accent,
                  inactiveColor: pal.sliderInactive,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> heights;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  const _WaveformPainter({
    required this.heights,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (heights.isEmpty || size.width <= 0) return;

    const gap = 3.0;
    final barCount = heights.length;
    final barWidth = ((size.width - gap * (barCount - 1)) / barCount).clamp(1.0, double.infinity);
    final activeBars = (progress * barCount).round();

    for (var i = 0; i < barCount; i++) {
      final h = heights[i] * size.height;
      final left = i * (barWidth + gap);
      final rect = Rect.fromLTWH(left, (size.height - h) / 2, barWidth, h);
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = i < activeBars ? activeColor : inactiveColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barWidth / 2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.heights != heights;
  }
}
