import 'package:flutter/material.dart';

import 'survivor_run_config.dart';

class SurvivorFloorTileRenderer {
  const SurvivorFloorTileRenderer._();

  static void paint({
    required Canvas canvas,
    required Rect mapRect,
    required SurvivorMapFloorType floorType,
    required Color floorColor,
    required Color gridColor,
    required Color detailColor,
    required double cellSize,
    Rect? visibleRect,
  }) {
    canvas.drawRect(mapRect, Paint()..color = floorColor);

    final clipRect = visibleRect == null
        ? mapRect
        : mapRect.intersect(visibleRect);
    if (clipRect.isEmpty) {
      return;
    }

    final startX = ((clipRect.left - mapRect.left) / cellSize).floor();
    final endX = ((clipRect.right - mapRect.left) / cellSize).ceil();
    final startY = ((clipRect.top - mapRect.top) / cellSize).floor();
    final endY = ((clipRect.bottom - mapRect.top) / cellSize).ceil();

    for (var y = startY; y < endY; y++) {
      for (var x = startX; x < endX; x++) {
        final tileRect = Rect.fromLTWH(
          mapRect.left + x * cellSize,
          mapRect.top + y * cellSize,
          cellSize,
          cellSize,
        );
        _paintTile(
          canvas: canvas,
          tileRect: tileRect,
          x: x,
          y: y,
          floorType: floorType,
          floorColor: floorColor,
          gridColor: gridColor,
          detailColor: detailColor,
        );
      }
    }
  }

  static void _paintTile({
    required Canvas canvas,
    required Rect tileRect,
    required int x,
    required int y,
    required SurvivorMapFloorType floorType,
    required Color floorColor,
    required Color gridColor,
    required Color detailColor,
  }) {
    final baseVariation = _noise(x, y, 1);
    final baseColor = Color.lerp(
      floorColor,
      detailColor,
      0.04 + baseVariation * 0.08,
    )!;

    canvas.drawRect(tileRect, Paint()..color = baseColor);

    switch (floorType) {
      case SurvivorMapFloorType.dirt:
        _paintDirtTile(
          canvas,
          tileRect,
          x,
          y,
          floorColor,
          gridColor,
          detailColor,
        );
        break;
      case SurvivorMapFloorType.grass:
        _paintGrassTile(
          canvas,
          tileRect,
          x,
          y,
          floorColor,
          gridColor,
          detailColor,
        );
        break;
      case SurvivorMapFloorType.concrete:
        _paintConcreteTile(
          canvas,
          tileRect,
          x,
          y,
          floorColor,
          gridColor,
          detailColor,
        );
        break;
      case SurvivorMapFloorType.stone:
        _paintStoneTile(
          canvas,
          tileRect,
          x,
          y,
          floorColor,
          gridColor,
          detailColor,
        );
        break;
      case SurvivorMapFloorType.sand:
        _paintSandTile(
          canvas,
          tileRect,
          x,
          y,
          floorColor,
          gridColor,
          detailColor,
        );
        break;
      case SurvivorMapFloorType.metal:
        _paintMetalTile(
          canvas,
          tileRect,
          x,
          y,
          floorColor,
          gridColor,
          detailColor,
        );
        break;
    }
  }

  static void _paintDirtTile(
    Canvas canvas,
    Rect tileRect,
    int x,
    int y,
    Color floorColor,
    Color gridColor,
    Color detailColor,
  ) {
    final darkSoil = Color.lerp(floorColor, gridColor, 0.45)!;
    final warmDust = Color.lerp(floorColor, detailColor, 0.28)!;
    final pebbleColor = Color.lerp(gridColor, detailColor, 0.22)!;

    canvas.drawRRect(
      RRect.fromRectAndRadius(tileRect.deflate(1.5), const Radius.circular(5)),
      Paint()..color = warmDust.withValues(alpha: 0.26),
    );

    for (var i = 0; i < 3; i++) {
      final n1 = _noise(x, y, 10 + i * 7);
      final n2 = _noise(x, y, 11 + i * 7);
      final center = Offset(
        tileRect.left + tileRect.width * (0.18 + n1 * 0.64),
        tileRect.top + tileRect.height * (0.18 + n2 * 0.64),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: tileRect.width * (0.14 + _noise(x, y, 12 + i * 7) * 0.16),
          height: tileRect.height * (0.08 + _noise(x, y, 13 + i * 7) * 0.12),
        ),
        Paint()..color = darkSoil.withValues(alpha: 0.26 + i * 0.04),
      );
    }

    for (var i = 0; i < 2; i++) {
      final n1 = _noise(x, y, 31 + i * 3);
      final n2 = _noise(x, y, 32 + i * 3);
      final center = Offset(
        tileRect.left + tileRect.width * (0.22 + n1 * 0.56),
        tileRect.top + tileRect.height * (0.22 + n2 * 0.56),
      );
      canvas.drawCircle(
        center,
        tileRect.shortestSide * (0.04 + _noise(x, y, 33 + i * 3) * 0.035),
        Paint()..color = pebbleColor.withValues(alpha: 0.34),
      );
    }
  }

  static void _paintGrassTile(
    Canvas canvas,
    Rect tileRect,
    int x,
    int y,
    Color floorColor,
    Color gridColor,
    Color detailColor,
  ) {
    final turf = Color.lerp(floorColor, detailColor, 0.16)!;
    final deepGrass = Color.lerp(gridColor, detailColor, 0.38)!;
    final highlight = Color.lerp(detailColor, Colors.white, 0.24)!;

    canvas.drawRect(tileRect, Paint()..color = turf.withValues(alpha: 0.32));

    for (var i = 0; i < 4; i++) {
      final n = _noise(x, y, 50 + i * 5);
      final baseX = tileRect.left + tileRect.width * (0.14 + n * 0.72);
      final baseY =
          tileRect.top +
          tileRect.height * (0.56 + _noise(x, y, 51 + i * 5) * 0.24);
      final height = tileRect.height * (0.12 + _noise(x, y, 52 + i * 5) * 0.16);
      final lean = (_noise(x, y, 53 + i * 5) - 0.5) * tileRect.width * 0.16;
      canvas.drawLine(
        Offset(baseX, baseY),
        Offset(baseX + lean, baseY - height),
        Paint()
          ..color = (i.isEven ? deepGrass : highlight).withValues(alpha: 0.42)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }

    if ((x + y).isEven) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            tileRect.left + tileRect.width * 0.5,
            tileRect.top + tileRect.height * 0.54,
          ),
          width: tileRect.width * 0.58,
          height: tileRect.height * 0.26,
        ),
        Paint()..color = deepGrass.withValues(alpha: 0.12),
      );
    }
  }

  static void _paintConcreteTile(
    Canvas canvas,
    Rect tileRect,
    int x,
    int y,
    Color floorColor,
    Color gridColor,
    Color detailColor,
  ) {
    final slab = Color.lerp(
      floorColor,
      Colors.white,
      0.06 + _noise(x, y, 80) * 0.07,
    )!;
    final seam = Color.lerp(gridColor, Colors.black, 0.12)!;
    final stain = Color.lerp(detailColor, gridColor, 0.55)!;

    canvas.drawRect(tileRect.deflate(0.6), Paint()..color = slab);
    canvas.drawRect(
      Rect.fromLTWH(tileRect.left, tileRect.top, tileRect.width, 2),
      Paint()..color = seam.withValues(alpha: 0.24),
    );
    canvas.drawRect(
      Rect.fromLTWH(tileRect.left, tileRect.top, 2, tileRect.height),
      Paint()..color = seam.withValues(alpha: 0.18),
    );

    final crackStart = Offset(
      tileRect.left + tileRect.width * (0.18 + _noise(x, y, 81) * 0.16),
      tileRect.top + tileRect.height * (0.18 + _noise(x, y, 82) * 0.18),
    );
    final crackMid = Offset(
      tileRect.left + tileRect.width * (0.45 + _noise(x, y, 83) * 0.12),
      tileRect.top + tileRect.height * (0.36 + _noise(x, y, 84) * 0.16),
    );
    final crackEnd = Offset(
      tileRect.left + tileRect.width * (0.62 + _noise(x, y, 85) * 0.22),
      tileRect.top + tileRect.height * (0.62 + _noise(x, y, 86) * 0.18),
    );
    final crack = Path()
      ..moveTo(crackStart.dx, crackStart.dy)
      ..lineTo(crackMid.dx, crackMid.dy)
      ..lineTo(crackEnd.dx, crackEnd.dy);
    canvas.drawPath(
      crack,
      Paint()
        ..color = seam.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawCircle(
      Offset(
        tileRect.left + tileRect.width * (0.26 + _noise(x, y, 87) * 0.48),
        tileRect.top + tileRect.height * (0.3 + _noise(x, y, 88) * 0.42),
      ),
      tileRect.shortestSide * (0.04 + _noise(x, y, 89) * 0.04),
      Paint()..color = stain.withValues(alpha: 0.18),
    );
  }

  static void _paintStoneTile(
    Canvas canvas,
    Rect tileRect,
    int x,
    int y,
    Color floorColor,
    Color gridColor,
    Color detailColor,
  ) {
    final stoneBase = Color.lerp(
      floorColor,
      Colors.white,
      0.08 + _noise(x, y, 100) * 0.06,
    )!;
    final mortar = Color.lerp(gridColor, Colors.black, 0.14)!;
    final edge = Color.lerp(detailColor, Colors.white, 0.18)!;
    final innerRect = tileRect.deflate(tileRect.width * 0.08);

    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(6)),
      Paint()..color = stoneBase,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(6)),
      Paint()
        ..color = mortar.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final chipRect = Rect.fromLTWH(
      innerRect.left + innerRect.width * (0.12 + _noise(x, y, 101) * 0.46),
      innerRect.top + innerRect.height * (0.16 + _noise(x, y, 102) * 0.38),
      innerRect.width * (0.16 + _noise(x, y, 103) * 0.14),
      innerRect.height * (0.08 + _noise(x, y, 104) * 0.1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(chipRect, const Radius.circular(4)),
      Paint()..color = edge.withValues(alpha: 0.16),
    );
  }

  static void _paintSandTile(
    Canvas canvas,
    Rect tileRect,
    int x,
    int y,
    Color floorColor,
    Color gridColor,
    Color detailColor,
  ) {
    final dune = Color.lerp(
      floorColor,
      Colors.white,
      0.06 + _noise(x, y, 120) * 0.08,
    )!;
    final shadow = Color.lerp(gridColor, Colors.black, 0.08)!;
    final sparkle = Color.lerp(detailColor, Colors.white, 0.22)!;

    canvas.drawRRect(
      RRect.fromRectAndRadius(tileRect.deflate(1.2), const Radius.circular(7)),
      Paint()..color = dune.withValues(alpha: 0.28),
    );

    for (var i = 0; i < 2; i++) {
      final center = Offset(
        tileRect.left +
            tileRect.width * (0.28 + _noise(x, y, 121 + i * 6) * 0.4),
        tileRect.top +
            tileRect.height * (0.34 + _noise(x, y, 122 + i * 6) * 0.32),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center,
          width: tileRect.width * (0.34 + _noise(x, y, 123 + i * 6) * 0.2),
          height: tileRect.height * (0.1 + _noise(x, y, 124 + i * 6) * 0.08),
        ),
        Paint()..color = shadow.withValues(alpha: 0.14 + i * 0.04),
      );
    }

    for (var i = 0; i < 3; i++) {
      final grainCenter = Offset(
        tileRect.left +
            tileRect.width * (0.14 + _noise(x, y, 131 + i * 5) * 0.72),
        tileRect.top +
            tileRect.height * (0.16 + _noise(x, y, 132 + i * 5) * 0.68),
      );
      canvas.drawCircle(
        grainCenter,
        tileRect.shortestSide * (0.025 + _noise(x, y, 133 + i * 5) * 0.018),
        Paint()..color = sparkle.withValues(alpha: 0.28),
      );
    }
  }

  static void _paintMetalTile(
    Canvas canvas,
    Rect tileRect,
    int x,
    int y,
    Color floorColor,
    Color gridColor,
    Color detailColor,
  ) {
    final plate = Color.lerp(
      floorColor,
      Colors.white,
      0.08 + _noise(x, y, 150) * 0.1,
    )!;
    final seam = Color.lerp(gridColor, Colors.black, 0.18)!;
    final highlight = Color.lerp(detailColor, Colors.white, 0.28)!;
    final panelRect = tileRect.deflate(1.4);

    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(6)),
      Paint()..color = plate,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(6)),
      Paint()
        ..color = seam.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        panelRect.left + 2,
        panelRect.top + 2,
        panelRect.width - 4,
        2,
      ),
      Paint()..color = highlight.withValues(alpha: 0.26),
    );

    if ((x + y).isEven) {
      canvas.drawRect(
        Rect.fromLTWH(
          panelRect.left + panelRect.width * 0.52,
          panelRect.top + 5,
          1.4,
          panelRect.height - 10,
        ),
        Paint()..color = seam.withValues(alpha: 0.22),
      );
    }

    for (final bolt in <Offset>[
      Offset(panelRect.left + 7, panelRect.top + 7),
      Offset(panelRect.right - 7, panelRect.top + 7),
      Offset(panelRect.left + 7, panelRect.bottom - 7),
      Offset(panelRect.right - 7, panelRect.bottom - 7),
    ]) {
      canvas.drawCircle(
        bolt,
        1.8 + _noise(x, y, bolt.dx.round() + bolt.dy.round()) * 0.4,
        Paint()..color = seam.withValues(alpha: 0.38),
      );
    }

    if (_noise(x, y, 161) > 0.45) {
      canvas.drawLine(
        Offset(
          panelRect.left + panelRect.width * (0.22 + _noise(x, y, 162) * 0.16),
          panelRect.top + panelRect.height * (0.28 + _noise(x, y, 163) * 0.12),
        ),
        Offset(
          panelRect.left + panelRect.width * (0.62 + _noise(x, y, 164) * 0.18),
          panelRect.top + panelRect.height * (0.58 + _noise(x, y, 165) * 0.12),
        ),
        Paint()
          ..color = highlight.withValues(alpha: 0.2)
          ..strokeWidth = 1.1
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  static double _noise(int x, int y, int seed) {
    var value = x * 73856093 ^ y * 19349663 ^ seed * 83492791;
    value = (value ^ (value >> 13)) * 1274126177;
    final normalized = (value & 0x7fffffff) / 0x7fffffff;
    return normalized.clamp(0.0, 1.0);
  }
}
