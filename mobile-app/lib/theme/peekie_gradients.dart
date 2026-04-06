import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class PeekieGradients {
  /// CSS `linear-gradient(43.88deg, rgba(138, 197, 255, 0.97) -22.46%, rgba(210, 236, 255, 0.97) 78.34%)`
  /// Góc CSS: 0° = hướng lên, tăng theo chiều kim đồng hồ.
  static LinearGradient get musicNenHomeCard {
    const angleDeg = 43.88;
    final r = angleDeg * math.pi / 180;
    final dx = math.sin(r);
    final dy = -math.cos(r);
    return LinearGradient(
      begin: Alignment(-dx, -dy),
      end: Alignment(dx, dy),
      colors: const [
        Color.fromRGBO(138, 197, 255, 0.97),
        Color.fromRGBO(210, 236, 255, 0.97),
      ],
      stops: const [0.0, 1.0],
    );
  }
}
