part of 'survivor_game.dart';

class MiniMapComponent extends PositionComponent
    with HasGameReference<SurvivorGame> {
  MiniMapComponent({required Vector2 size, required Vector2 position}) {
    this.size = size;
    this.position = position;
    priority = 100;
    anchor = Anchor.topLeft;
  }

  static const double _worldRadius = 900;

  @override
  void render(Canvas canvas) {
    if (!game.showMinimap) {
      return;
    }

    final frame = Rect.fromLTWH(0, 0, size.x, size.y);
    final center = Offset(size.x / 2, size.y / 2);

    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(18)),
      Paint()..color = const Color(0xBB071015),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(18)),
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawCircle(
      center,
      size.x * 0.38,
      Paint()
        ..color = const Color(0x332B3B40)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (final enemy in game.world.children.whereType<Enemy>()) {
      final delta = enemy.position - game.player.position;
      if (delta.length > _worldRadius) {
        delta.scale(_worldRadius / delta.length);
      }
      final point = _mapOffset(delta, center);
      canvas.drawCircle(point, 2.8, Paint()..color = const Color(0xFFE57373));
    }

    for (final shard in game.world.children.whereType<XpShard>()) {
      final delta = shard.position - game.player.position;
      if (delta.length > _worldRadius) {
        continue;
      }
      final point = _mapOffset(delta, center);
      canvas.drawCircle(point, 2, Paint()..color = const Color(0xFF64B5F6));
    }

    for (final goldPickup in game.world.children.whereType<GoldPickup>()) {
      final delta = goldPickup.position - game.player.position;
      if (delta.length > _worldRadius) {
        continue;
      }
      final point = _mapOffset(delta, center);
      canvas.drawCircle(point, 2.2, Paint()..color = const Color(0xFFFFD54F));
    }

    for (final potion in game.world.children.whereType<HealthPotionPickup>()) {
      final delta = potion.position - game.player.position;
      if (delta.length > _worldRadius) {
        continue;
      }
      final point = _mapOffset(delta, center);
      canvas.drawCircle(point, 2.3, Paint()..color = const Color(0xFFEF6C6C));
    }

    for (final chest in game.world.children.whereType<TreasureChest>()) {
      final delta = chest.position - game.player.position;
      if (delta.length > _worldRadius) {
        continue;
      }
      final point = _mapOffset(delta, center);
      canvas.drawRect(
        Rect.fromCenter(center: point, width: 4.4, height: 4.4),
        Paint()..color = const Color(0xFFD79B43),
      );
    }

    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFFE8F5E9));
  }

  Offset _mapOffset(Vector2 delta, Offset center) {
    final scaleX = (size.x * 0.42) / _worldRadius;
    final scaleY = (size.y * 0.42) / _worldRadius;
    return Offset(center.dx + delta.x * scaleX, center.dy + delta.y * scaleY);
  }
}

class ExperienceHudComponent extends PositionComponent
    with HasGameReference<SurvivorGame> {
  ExperienceHudComponent({required Vector2 position, required Vector2 size})
    : super(
        position: position,
        size: size,
        priority: 100,
        anchor: Anchor.topLeft,
      );

  final TextPaint _labelPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
    ),
  );

  final TextPaint _levelPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w900,
    ),
  );

  final TextPaint _xpPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );

  @override
  void render(Canvas canvas) {
    final frame = Rect.fromLTWH(0, 0, size.x, size.y);
    final levelBox = Rect.fromLTWH(10, 10, 72, size.y - 20);
    final barRect = Rect.fromLTWH(96, 18, size.x - 112, 20);
    final xpRatio = game.player.experienceToNextLevel == 0
        ? 0.0
        : (game.player.experience / game.player.experienceToNextLevel).clamp(
            0.0,
            1.0,
          );

    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(18)),
      Paint()..color = const Color(0xBB0A1216),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(18)),
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(levelBox, const Radius.circular(14)),
      Paint()..color = const Color(0xFF17302D),
    );

    _labelPaint.render(canvas, 'LV', Vector2(33, 15));
    _levelPaint.render(
      canvas,
      '${game.player.level}',
      Vector2(game.player.level >= 10 ? 25 : 31, 28),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(12)),
      Paint()..color = const Color(0xFF122027),
    );

    final fillWidth = math.max(0.0, barRect.width * xpRatio);
    if (fillWidth > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barRect.left, barRect.top, fillWidth, barRect.height),
          const Radius.circular(12),
        ),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF4FC3F7), Color(0xFF8BC34A)],
          ).createShader(barRect),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(12)),
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _xpPaint.render(
      canvas,
      'EXP ${game.player.experience.floor()} / ${game.player.experienceToNextLevel.ceil()}',
      Vector2(104, 42),
    );
  }
}

class DashCooldownHud extends PositionComponent
    with HasGameReference<SurvivorGame> {
  DashCooldownHud({required Vector2 position, required Vector2 size})
    : super(
        position: position,
        size: size,
        priority: 100,
        anchor: Anchor.topLeft,
      );

  final TextPaint _labelPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.9,
    ),
  );

  final TextPaint _statusPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    ),
  );

  @override
  void render(Canvas canvas) {
    final frame = Rect.fromLTWH(0, 0, size.x, size.y);
    final barRect = Rect.fromLTWH(88, 10, size.x - 168, 14);
    final progress = game.player.dashCooldownProgress.clamp(0.0, 1.0);
    final ready = game.player.isDashReady;
    final invulnerable = game.player.isDashInvulnerable;
    final displayProgress = invulnerable ? 1.0 : progress;
    final pulse = 0.65 + (math.sin(game.elapsedTime * 5.5) + 1) * 0.175;

    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(14)),
      Paint()..color = const Color(0xAA0A1216),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(14)),
      Paint()
        ..color = const Color(0x22FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _labelPaint.render(canvas, 'DASH', Vector2(14, 11));
    _statusPaint.render(canvas, 'SPACE', Vector2(14, 23));

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(10)),
      Paint()..color = const Color(0xFF142024),
    );

    final fillWidth = math.max(0.0, barRect.width * displayProgress);
    if (fillWidth > 0) {
      final color = invulnerable
          ? const Color(0xFF4DD0E1)
          : ready
          ? Color.fromARGB((pulse * 255).round().clamp(0, 255), 105, 240, 174)
          : const Color(0xFFFFB74D);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(barRect.left, barRect.top, fillWidth, barRect.height),
          const Radius.circular(10),
        ),
        Paint()..color = color,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(10)),
      Paint()
        ..color = const Color(0x44FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    _statusPaint.render(
      canvas,
      invulnerable
          ? 'SAFE'
          : ready
          ? 'READY'
          : '${game.player.dashCooldownRemaining.toStringAsFixed(1)}s',
      Vector2(size.x - 64, 17),
    );
  }
}

class DashBurstEffect extends PositionComponent {
  DashBurstEffect({required Vector2 position, required Vector2 direction})
    : _direction = direction.normalized(),
      super(position: position, anchor: Anchor.center, priority: 17);

  static const double _lifetime = 0.16;

  final Vector2 _direction;
  double _timeLeft = _lifetime;

  @override
  void update(double dt) {
    super.update(dt);
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = 1 - (_timeLeft / _lifetime).clamp(0.0, 1.0);
    final alpha = ((1 - progress) * 110).round().clamp(0, 110);
    final length = 24 + progress * 34;
    final width = 10 + progress * 14;

    canvas.save();
    canvas.rotate(math.atan2(_direction.y, _direction.x));

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(-4, 0),
          width: length,
          height: width,
        ),
        const Radius.circular(18),
      ),
      Paint()..color = Color.fromARGB(alpha, 77, 208, 225),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: const Offset(-8, 0),
          width: length * 0.7,
          height: width * 0.45,
        ),
        const Radius.circular(14),
      ),
      Paint()..color = Color.fromARGB((alpha * 0.75).round(), 207, 255, 244),
    );

    canvas.restore();
  }
}

class GroundTrailEffect extends PositionComponent {
  GroundTrailEffect({
    required Vector2 position,
    required this.floorType,
    required Vector2 direction,
    required Color floorColor,
    required Color detailColor,
    required Color accentColor,
    required math.Random random,
  }) : _direction = direction.length2 > 0
           ? direction.normalized()
           : Vector2(0, -1),
       _floorColor = floorColor,
       _detailColor = detailColor,
       _accentColor = accentColor,
       _rotationOffset = (random.nextDouble() - 0.5) * 0.42,
       _seed = random.nextDouble(),
       _lifetime = switch (floorType) {
         SurvivorMapFloorType.sand => 0.34,
         SurvivorMapFloorType.grass => 0.3,
         SurvivorMapFloorType.metal => 0.22,
         _ => 0.26,
       },
       _timeLeft = switch (floorType) {
         SurvivorMapFloorType.sand => 0.34,
         SurvivorMapFloorType.grass => 0.3,
         SurvivorMapFloorType.metal => 0.22,
         _ => 0.26,
       },
       super(position: position, anchor: Anchor.center, priority: 16);

  final SurvivorMapFloorType floorType;
  final Vector2 _direction;
  final Color _floorColor;
  final Color _detailColor;
  final Color _accentColor;
  final double _rotationOffset;
  final double _seed;
  final double _lifetime;
  double _timeLeft;

  @override
  void update(double dt) {
    super.update(dt);
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = 1 - (_timeLeft / _lifetime).clamp(0.0, 1.0);
    final fade = (1 - progress).clamp(0.0, 1.0);

    canvas.save();
    canvas.rotate(math.atan2(_direction.y, _direction.x) + _rotationOffset);

    switch (floorType) {
      case SurvivorMapFloorType.dirt:
        _renderDustTrail(canvas, progress, fade, scale: 1.0);
        break;
      case SurvivorMapFloorType.grass:
        _renderGrassSweep(canvas, progress, fade);
        break;
      case SurvivorMapFloorType.concrete:
        _renderScuff(canvas, progress, fade, rugged: false);
        break;
      case SurvivorMapFloorType.stone:
        _renderScuff(canvas, progress, fade, rugged: true);
        break;
      case SurvivorMapFloorType.sand:
        _renderDustTrail(canvas, progress, fade, scale: 1.28);
        break;
      case SurvivorMapFloorType.metal:
        _renderMetalSpark(canvas, progress, fade);
        break;
    }

    canvas.restore();
  }

  void _renderDustTrail(
    Canvas canvas,
    double progress,
    double fade, {
    required double scale,
  }) {
    final dust = Color.lerp(_floorColor, _detailColor, 0.55)!;
    final shadow = Color.lerp(_floorColor, Colors.black, 0.18)!;
    final width = (18 + progress * 14) * scale;
    final height = (8 + progress * 8) * scale;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-8 - progress * 7, 0),
        width: width,
        height: height,
      ),
      Paint()..color = dust.withValues(alpha: 0.2 * fade),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-2 - progress * 5, 3),
        width: width * 0.48,
        height: height * 0.44,
      ),
      Paint()..color = shadow.withValues(alpha: 0.16 * fade),
    );

    final speckPaint = Paint()
      ..color = _detailColor.withValues(alpha: 0.3 * fade);
    for (var i = 0; i < 3; i++) {
      final shift = i * 4.0 + _seed * 3;
      canvas.drawCircle(
        Offset(-3 - progress * 6 + shift, -4 + i * 2.8),
        (1.2 + i * 0.3) * scale,
        speckPaint,
      );
    }
  }

  void _renderGrassSweep(Canvas canvas, double progress, double fade) {
    final patch = Color.lerp(_floorColor, _detailColor, 0.28)!;
    final blade = Color.lerp(_accentColor, Colors.white, 0.22)!;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-6 - progress * 4, 1),
        width: 22 + progress * 10,
        height: 8 + progress * 4,
      ),
      Paint()..color = patch.withValues(alpha: 0.14 * fade),
    );

    for (var i = 0; i < 3; i++) {
      final baseX = -8 + i * 6.0;
      final height = 8 + i * 1.8 + progress * 2;
      canvas.drawLine(
        Offset(baseX, 2),
        Offset(baseX + 4 + progress * 3, 2 - height),
        Paint()
          ..color = blade.withValues(alpha: 0.28 * fade)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _renderScuff(
    Canvas canvas,
    double progress,
    double fade, {
    required bool rugged,
  }) {
    final scuff = Color.lerp(_detailColor, Colors.white, rugged ? 0.12 : 0.18)!;
    final grit = Color.lerp(_floorColor, _detailColor, 0.48)!;

    canvas.drawLine(
      Offset(-10 - progress * 8, 0),
      Offset(8 + progress * 2, rugged ? 2 : 0),
      Paint()
        ..color = scuff.withValues(alpha: 0.18 * fade)
        ..strokeWidth = rugged ? 2.2 : 1.6
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 0; i < (rugged ? 3 : 2); i++) {
      canvas.drawCircle(
        Offset(-4 + i * 4.5, -2 + i * 1.8),
        rugged ? 1.6 : 1.2,
        Paint()..color = grit.withValues(alpha: 0.24 * fade),
      );
    }
  }

  void _renderMetalSpark(Canvas canvas, double progress, double fade) {
    final spark = Color.lerp(_accentColor, Colors.white, 0.34)!;
    final streak = Color.lerp(_detailColor, Colors.white, 0.18)!;

    for (var i = 0; i < 3; i++) {
      final spread = i * 0.18 - 0.18;
      final length = 10 + progress * 12 - i * 1.8;
      final angle = spread + _rotationOffset * 0.3;
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle) * length, math.sin(angle) * length),
        Paint()
          ..color = (i == 0 ? spark : streak).withValues(alpha: 0.34 * fade)
          ..strokeWidth = 1.4 - i * 0.2
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      Offset(-1.5, 0),
      2.4 + progress * 1.2,
      Paint()..color = spark.withValues(alpha: 0.22 * fade),
    );
  }
}

class DamageNumberEffect extends PositionComponent {
  DamageNumberEffect({
    required Vector2 position,
    required this.label,
    required Color color,
    required math.Random random,
  }) : _color = color,
       _drift = Vector2(
         (random.nextDouble() - 0.5) * 22,
         -(54 + random.nextDouble() * 18),
       ),
       super(position: position, anchor: Anchor.center, priority: 19);

  static const double _lifetime = 0.52;

  final String label;
  final Color _color;
  final Vector2 _drift;
  double _timeLeft = _lifetime;

  @override
  void update(double dt) {
    super.update(dt);
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      removeFromParent();
      return;
    }

    position.add(_drift * dt);
    _drift.x *= 0.92;
    _drift.y *= 0.98;
  }

  @override
  void render(Canvas canvas) {
    final progress = 1 - (_timeLeft / _lifetime).clamp(0.0, 1.0);
    final fade = (1 - progress).clamp(0.0, 1.0);
    final scale = 1 + math.sin(progress * math.pi) * 0.16;

    final shadowPaint = TextPaint(
      style: TextStyle(
        color: Colors.black.withValues(alpha: fade * 0.72),
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    );
    final valuePaint = TextPaint(
      style: TextStyle(
        color: _color.withValues(alpha: fade),
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.3,
      ),
    );

    canvas.save();
    canvas.scale(scale, scale);
    shadowPaint.render(canvas, label, Vector2(1.8, 2.2), anchor: Anchor.center);
    valuePaint.render(canvas, label, Vector2.zero(), anchor: Anchor.center);
    canvas.restore();
  }
}

class RainbowImpactEffect extends PositionComponent {
  RainbowImpactEffect({
    required Vector2 position,
    required Vector2 direction,
    required math.Random random,
    required this.intensity,
  }) : _direction = direction.length2 == 0
           ? Vector2(0, -1)
           : direction.normalized(),
       _rotation = random.nextDouble() * math.pi * 2,
       _paletteOffset = random.nextInt(_palette.length),
       super(position: position, anchor: Anchor.center, priority: 20);

  static const double _lifetime = 0.2;
  static const List<Color> _palette = <Color>[
    Color(0xFFFF5E7A),
    Color(0xFFFFB545),
    Color(0xFFFFF27A),
    Color(0xFF5CF59B),
    Color(0xFF53D8FF),
    Color(0xFF9B7CFF),
  ];

  final Vector2 _direction;
  final double intensity;
  final double _rotation;
  final int _paletteOffset;
  double _timeLeft = _lifetime;

  @override
  void update(double dt) {
    super.update(dt);
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = 1 - (_timeLeft / _lifetime).clamp(0.0, 1.0);
    final fade = (1 - progress).clamp(0.0, 1.0);
    final baseRadius = (12 + progress * 18) * intensity;

    for (var index = 0; index < 3; index++) {
      final color = _palette[(_paletteOffset + index * 2) % _palette.length];
      canvas.drawCircle(
        Offset.zero,
        baseRadius - index * 4.2,
        Paint()
          ..color = color.withValues(alpha: fade * (0.28 - index * 0.06))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6 - index * 0.55,
      );
    }

    for (var index = 0; index < 6; index++) {
      final angle =
          _rotation +
          math.atan2(_direction.y, _direction.x) +
          (index - 2.5) * 0.34;
      final color = _palette[(_paletteOffset + index) % _palette.length];
      final inner = Offset(
        math.cos(angle) * (3 + progress * 6) * intensity,
        math.sin(angle) * (3 + progress * 6) * intensity,
      );
      final outer = Offset(
        math.cos(angle) * (14 + progress * 22) * intensity,
        math.sin(angle) * (14 + progress * 22) * intensity,
      );
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = color.withValues(alpha: fade * 0.54)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }

    canvas.drawCircle(
      Offset.zero,
      (4.4 + progress * 2.6) * intensity,
      Paint()..color = Colors.white.withValues(alpha: fade * 0.22),
    );
  }
}

class GameOverOverlay extends PositionComponent
    with HasGameReference<SurvivorGame> {
  GameOverOverlay() {
    priority = 110;
    size = Vector2(340, 200);
    anchor = Anchor.center;
    isVisible = false;
  }

  bool isVisible = false;

  final TextPaint _titlePaint = TextPaint(
    style: const TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.w800,
    ),
  );

  final TextPaint _bodyPaint = TextPaint(
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    ),
  );

  @override
  void render(Canvas canvas) {
    if (!isVisible) {
      return;
    }

    final panel = Rect.fromLTWH(-size.x / 2, -size.y / 2, size.x, size.y);
    final radius = const Radius.circular(24);

    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, radius),
      Paint()..color = const Color(0xDD101517),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(panel, radius),
      Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final title = game.playerWon ? 'VICTORY' : 'GAME OVER';
    final summary = game.playerWon
        ? 'Survived the full 30:00 run'
        : 'Survived ${game.formatClock(game.elapsedTime.floor())}';
    final restartPrompt = game.playerWon
        ? 'Press R to play again'
        : 'Press R to restart';

    _titlePaint.render(canvas, title, Vector2(game.playerWon ? -62 : -88, -52));

    _bodyPaint.render(canvas, summary, Vector2(-102, -2));
    _bodyPaint.render(
      canvas,
      'Level ${game.player.level}   Kills ${game.player.kills}',
      Vector2(-88, 28),
    );
    _bodyPaint.render(canvas, restartPrompt, Vector2(-70, 74));
  }
}

class GridBackground extends Component with HasGameReference<SurvivorGame> {
  @override
  void render(Canvas canvas) {
    final center = game.player.position;
    final halfW = game.size.x / 2 + 200;
    final halfH = game.size.y / 2 + 200;
    final rect = Rect.fromLTRB(
      center.x - halfW,
      center.y - halfH,
      center.x + halfW,
      center.y + halfH,
    );

    final mapRect = game.mapConfig.worldBounds;
    canvas.drawRect(rect, Paint()..color = const Color(0xFF060A0D));
    SurvivorFloorTileRenderer.paint(
      canvas: canvas,
      mapRect: mapRect,
      floorType: game.mapConfig.floorType,
      floorColor: game.mapConfig.floorColor,
      gridColor: game.mapConfig.gridColor,
      detailColor: game.mapConfig.detailColor,
      cellSize: SurvivorMapConfig.cellSize,
      visibleRect: rect,
    );

    switch (game.mapConfig.backgroundStyle) {
      case SurvivorMapBackgroundStyle.grid:
        _drawGridPattern(canvas, mapRect);
        break;
      case SurvivorMapBackgroundStyle.stripes:
        _drawStripePattern(canvas, mapRect);
        break;
      case SurvivorMapBackgroundStyle.rings:
        _drawRingPattern(canvas, mapRect);
        break;
    }

    canvas.drawRect(
      mapRect,
      Paint()
        ..color = game.mapConfig.accentColor.withValues(alpha: 0.34)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawGridPattern(Canvas canvas, Rect mapRect) {
    final linePaint = Paint()
      ..color = game.mapConfig.gridColor
      ..strokeWidth = 1;
    final detailPaint = Paint()
      ..color = game.mapConfig.detailColor.withValues(alpha: 0.16)
      ..strokeWidth = 1;

    final cell = SurvivorMapConfig.cellSize;
    for (var x = mapRect.left; x <= mapRect.right; x += cell) {
      final paint = ((x - mapRect.left) / cell).round().isEven
          ? linePaint
          : detailPaint;
      canvas.drawLine(Offset(x, mapRect.top), Offset(x, mapRect.bottom), paint);
    }
    for (var y = mapRect.top; y <= mapRect.bottom; y += cell) {
      final paint = ((y - mapRect.top) / cell).round().isEven
          ? linePaint
          : detailPaint;
      canvas.drawLine(Offset(mapRect.left, y), Offset(mapRect.right, y), paint);
    }
  }

  void _drawStripePattern(Canvas canvas, Rect mapRect) {
    final stripePaint = Paint()
      ..color = game.mapConfig.detailColor.withValues(alpha: 0.18);
    final spacing = SurvivorMapConfig.cellSize * 1.4;
    for (
      double start = mapRect.left - mapRect.height;
      start < mapRect.right + mapRect.height;
      start += spacing
    ) {
      canvas.drawLine(
        Offset(start, mapRect.top),
        Offset(start + mapRect.height, mapRect.bottom),
        stripePaint..strokeWidth = SurvivorMapConfig.cellSize * 0.36,
      );
    }
  }

  void _drawRingPattern(Canvas canvas, Rect mapRect) {
    final ringPaint = Paint()
      ..color = game.mapConfig.detailColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final gridPaint = Paint()
      ..color = game.mapConfig.gridColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final center = mapRect.center;

    for (var i = 1; i <= 7; i++) {
      canvas.drawCircle(
        center,
        SurvivorMapConfig.cellSize * 1.4 * i,
        i.isEven ? ringPaint : gridPaint,
      );
    }

    canvas.drawLine(
      Offset(center.dx, mapRect.top),
      Offset(center.dx, mapRect.bottom),
      gridPaint,
    );
    canvas.drawLine(
      Offset(mapRect.left, center.dy),
      Offset(mapRect.right, center.dy),
      gridPaint,
    );
  }
}

class MapObstacleLayerComponent extends Component
    with HasGameReference<SurvivorGame> {
  @override
  void render(Canvas canvas) {
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final obstacle in game.mapConfig.obstacles) {
      final tileRect = obstacle.toTileRect(game.mapConfig);
      final bodyRect = obstacle.toWorldRect(game.mapConfig);

      switch (obstacle.type) {
        case SurvivorMapObstacleType.wall:
          canvas.drawRRect(
            RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)),
            Paint()..color = const Color(0xFF46535A),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              bodyRect.deflate(10),
              const Radius.circular(5),
            ),
            Paint()..color = game.mapConfig.accentColor.withValues(alpha: 0.44),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(bodyRect, const Radius.circular(8)),
            borderPaint,
          );
          break;
        case SurvivorMapObstacleType.pillar:
          canvas.drawOval(
            bodyRect.inflate(6),
            Paint()..color = const Color(0x333B2A22),
          );
          canvas.drawOval(bodyRect, Paint()..color = const Color(0xFF846250));
          canvas.drawOval(
            bodyRect.deflate(8),
            Paint()..color = const Color(0xFFD9CCC2),
          );
          canvas.drawOval(bodyRect, borderPaint);
          break;
        case SurvivorMapObstacleType.mire:
          canvas.drawRRect(
            RRect.fromRectAndRadius(tileRect, const Radius.circular(14)),
            Paint()..color = const Color(0x99325540),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: tileRect.center,
              width: tileRect.width * 0.82,
              height: tileRect.height * 0.56,
            ),
            Paint()..color = const Color(0xFF5FBF7B),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(
                tileRect.center.dx - tileRect.width * 0.12,
                tileRect.center.dy + tileRect.height * 0.08,
              ),
              width: tileRect.width * 0.26,
              height: tileRect.height * 0.12,
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.15),
          );
          break;
      }
    }
  }
}

class BloodBurstEffect extends PositionComponent {
  BloodBurstEffect({
    required Vector2 position,
    required Vector2 direction,
    required math.Random random,
    required this.intensity,
    List<Color>? palette,
  }) : _droplets = _createDroplets(
         direction,
         random,
         intensity,
         palette == null || palette.isEmpty ? _defaultPalette : palette,
       ),
       _coreColors = _createCoreColors(
         random,
         palette == null || palette.isEmpty ? _defaultPalette : palette,
       ),
       super(position: position, anchor: Anchor.center, priority: 18);

  BloodBurstEffect.rainbow({
    required Vector2 position,
    required Vector2 direction,
    required math.Random random,
    required double intensity,
  }) : this(
         position: position,
         direction: direction,
         random: random,
         intensity: intensity,
         palette: _rainbowPalette,
       );

  static const double _lifetime = 0.34;
  static const List<Color> _defaultPalette = <Color>[
    Color(0xFF700E12),
    Color(0xFF8A0F14),
    Color(0xFFB81C1A),
  ];
  static const List<Color> _rainbowPalette = <Color>[
    Color(0xFFFF476F),
    Color(0xFFFF9F1C),
    Color(0xFFFFE66D),
    Color(0xFF59E37D),
    Color(0xFF3EC8FF),
    Color(0xFF7A6CFF),
  ];

  final List<_BloodDroplet> _droplets;
  final List<Color> _coreColors;
  final double intensity;
  double _timeLeft = _lifetime;

  static List<_BloodDroplet> _createDroplets(
    Vector2 direction,
    math.Random random,
    double intensity,
    List<Color> palette,
  ) {
    final burstDirection = direction.length2 == 0
        ? Vector2(0, -1)
        : direction.normalized();
    final count = 8 + random.nextInt(5);

    return List<_BloodDroplet>.generate(count, (_) {
      final spread = Vector2(
        random.nextDouble() * 2 - 1,
        random.nextDouble() * 2 - 1,
      );
      if (spread.length2 > 1) {
        spread.normalize();
      }

      return _BloodDroplet(
        offset: spread * (2 + random.nextDouble() * 6),
        velocity:
            burstDirection * (40 + random.nextDouble() * 100) +
            spread * (34 + random.nextDouble() * 76),
        radius: (2.1 + random.nextDouble() * 2.8) * intensity,
        color: _tintedPaletteColor(
          palette[random.nextInt(palette.length)],
          random,
        ),
      );
    });
  }

  static List<Color> _createCoreColors(
    math.Random random,
    List<Color> palette,
  ) {
    final primary = palette[random.nextInt(palette.length)];
    final secondary =
        palette[(random.nextInt(palette.length) + 1) % palette.length];
    return <Color>[
      Color.lerp(primary, Colors.black, 0.22) ?? primary,
      Color.lerp(secondary, Colors.white, 0.16) ?? secondary,
    ];
  }

  static Color _tintedPaletteColor(Color base, math.Random random) {
    final mixTarget = random.nextBool() ? Colors.white : Colors.black;
    final mixAmount = 0.08 + random.nextDouble() * 0.16;
    return Color.lerp(base, mixTarget, mixAmount) ?? base;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      removeFromParent();
      return;
    }

    for (final droplet in _droplets) {
      droplet.offset.add(droplet.velocity * dt);
      droplet.velocity.scale(0.86);
    }
  }

  @override
  void render(Canvas canvas) {
    final opacity = (_timeLeft / _lifetime).clamp(0.0, 1.0);

    canvas.drawCircle(
      Offset.zero,
      5.4 * intensity,
      Paint()..color = _coreColors.first.withValues(alpha: opacity * 0.44),
    );
    canvas.drawCircle(
      Offset.zero,
      3.1 * intensity,
      Paint()..color = _coreColors.last.withValues(alpha: opacity * 0.52),
    );

    for (final droplet in _droplets) {
      final dropletColor = droplet.color.withValues(alpha: opacity * 0.92);
      final dropletOffset = Offset(droplet.offset.x, droplet.offset.y);

      if (droplet.velocity.length2 > 0.1) {
        final trail =
            droplet.offset - droplet.velocity.normalized() * droplet.radius;
        canvas.drawLine(
          Offset(trail.x, trail.y),
          dropletOffset,
          Paint()
            ..color = dropletColor
            ..strokeCap = StrokeCap.round
            ..strokeWidth = math.max(1.4, droplet.radius * 0.72),
        );
      }

      canvas.drawCircle(
        dropletOffset,
        droplet.radius * (0.82 + opacity * 0.18),
        Paint()..color = dropletColor,
      );
    }
  }
}

class _BloodDroplet {
  _BloodDroplet({
    required this.offset,
    required this.velocity,
    required this.radius,
    required this.color,
  });

  final Vector2 offset;
  final Vector2 velocity;
  final double radius;
  final Color color;
}
