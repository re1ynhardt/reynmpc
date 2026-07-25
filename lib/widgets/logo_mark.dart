import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Логотип из icon.pdn: незамкнутое кольцо градиентом (сине-фиолетовое)
/// с разрывом снизу и белой музыкальной нотой внутри.
/// Фон и надпись "" из исходника сюда намеренно не перенесены.
class LogoMark extends StatelessWidget {
  final double size;
  final Color noteColor;

  const LogoMark({super.key, required this.size, this.noteColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8395F0).withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: -2,
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: const _RingPainter(),
          child: Center(
            child: Icon(Icons.music_note, color: noteColor, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height)
        .deflate(size.width * 0.08);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [Color(0xFF8395F0), Color(0xFFA3B4E5)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    // Кольцо с разрывом снизу — как в оригинальном логотипе.
    const startAngle = 0.36 * math.pi;
    const sweepAngle = 2 * math.pi - 0.72 * math.pi;
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}
