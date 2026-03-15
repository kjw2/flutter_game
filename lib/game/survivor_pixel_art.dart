part of 'survivor_game.dart';

enum _PlayerPose { front, back, side }

class _PlayerAppearance {
  const _PlayerAppearance({
    required this.palette,
    required this.frontOverlay,
    required this.backOverlay,
    required this.sideOverlay,
  });

  final Map<String, Color> palette;
  final List<String> frontOverlay;
  final List<String> backOverlay;
  final List<String> sideOverlay;
}

class _PlayerPixelArt {
  const _PlayerPixelArt._();

  static const double _pixelSize = 5.1;

  static const Map<String, Color> _farmerPalette = <String, Color>{
    'a': Color(0xFF2B1712),
    'h': Color(0xFFF3C79F),
    'e': Color(0xFFFDFBF4),
    'r': Color(0xFFF0EEE6),
    'c': Color(0xFFD7D0BE),
    'd': Color(0xFFB8AF98),
    'b': Color(0xFF5B4330),
    'm': Color(0xFFF7F1DE),
  };

  static const Map<String, Color> _pojolPalette = <String, Color>{
    'a': Color(0xFF1B1617),
    'h': Color(0xFFF0C39C),
    'e': Color(0xFFF6F7F9),
    'r': Color(0xFFC2454A),
    'c': Color(0xFF355A8B),
    'd': Color(0xFF21354F),
    'b': Color(0xFF23272A),
    'm': Color(0xFFE7D8B7),
  };

  static const Map<String, Color> _admiralPalette = <String, Color>{
    'a': Color(0xFF14171D),
    'h': Color(0xFFF1C59E),
    'e': Color(0xFFF8FAFD),
    'r': Color(0xFFD7A441),
    'c': Color(0xFF405E92),
    'd': Color(0xFF243754),
    'b': Color(0xFF171A1F),
    'm': Color(0xFF8EA4B8),
  };

  static const List<String> _frontIdle = <String>[
    '...aaaa...',
    '..ahhhha..',
    '..aheeha..',
    '...hrrh...',
    '..ccrrcc..',
    '..cdrrdc..',
    '...cddc...',
    '...b..b...',
    '..bb..bb..',
    '..........',
  ];

  static const List<String> _frontStep = <String>[
    '...aaaa...',
    '..ahhhha..',
    '..aheeha..',
    '...hrrh...',
    '..ccrrcc..',
    '..cdrrdc..',
    '..ccddcc..',
    '..b....b..',
    '...b..b...',
    '..b....b..',
  ];

  static const List<String> _backIdle = <String>[
    '...aaaa...',
    '..ahhhha..',
    '..aaaaaa..',
    '...crrc...',
    '..ccrrcc..',
    '..cdrrdc..',
    '...cddc...',
    '...b..b...',
    '..bb..bb..',
    '..........',
  ];

  static const List<String> _backStep = <String>[
    '...aaaa...',
    '..ahhhha..',
    '..aaaaaa..',
    '...crrc...',
    '..ccrrcc..',
    '..cdrrdc..',
    '..ccddcc..',
    '..b....b..',
    '...b..b...',
    '..b....b..',
  ];

  static const List<String> _sideIdle = <String>[
    '....aaa...',
    '...ahhh...',
    '...ahee...',
    '....hrr...',
    '...ccrcm..',
    '...cddcm..',
    '....cdc...',
    '....bb....',
    '...bb.....',
    '..........',
  ];

  static const List<String> _sideStep = <String>[
    '....aaa...',
    '...ahhh...',
    '...ahee...',
    '....hrr...',
    '...ccrcm..',
    '...cddcm..',
    '...ccdc...',
    '...bb.....',
    '....bb....',
    '..........',
  ];

  static const List<String> _farmerFrontOverlay = <String>[
    '....a.....',
    '....a.....',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
  ];

  static const List<String> _farmerBackOverlay = <String>[
    '....a.....',
    '....a.....',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
  ];

  static const List<String> _farmerSideOverlay = <String>[
    '....a.....',
    '...aa.....',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
  ];

  static const List<String> _pojolFrontOverlay = <String>[
    '..aaaaaa..',
    '...aaaa...',
    '....r.....',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
  ];

  static const List<String> _pojolBackOverlay = <String>[
    '..aaaaaa..',
    '...aaaa...',
    '....r.....',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
  ];

  static const List<String> _pojolSideOverlay = <String>[
    '.aaaaaa...',
    '..aaaa....',
    '...r......',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
  ];

  static const List<String> _admiralFrontOverlay = <String>[
    '....r.....',
    '..ammmma..',
    '...aaaa...',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
  ];

  static const List<String> _admiralBackOverlay = <String>[
    '....r.....',
    '..ammmma..',
    '...aaaa...',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
  ];

  static const List<String> _admiralSideOverlay = <String>[
    '...r......',
    '..ammmm...',
    '...aaaa...',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
    '..........',
  ];

  static const _PlayerAppearance _farmerAppearance = _PlayerAppearance(
    palette: _farmerPalette,
    frontOverlay: _farmerFrontOverlay,
    backOverlay: _farmerBackOverlay,
    sideOverlay: _farmerSideOverlay,
  );

  static const _PlayerAppearance _pojolAppearance = _PlayerAppearance(
    palette: _pojolPalette,
    frontOverlay: _pojolFrontOverlay,
    backOverlay: _pojolBackOverlay,
    sideOverlay: _pojolSideOverlay,
  );

  static const _PlayerAppearance _admiralAppearance = _PlayerAppearance(
    palette: _admiralPalette,
    frontOverlay: _admiralFrontOverlay,
    backOverlay: _admiralBackOverlay,
    sideOverlay: _admiralSideOverlay,
  );

  static void render(
    Canvas canvas, {
    required String characterId,
    required Vector2 facing,
    required bool walkFrame,
    double opacity = 1,
  }) {
    final pose = _poseFor(facing);
    final flipX = pose == _PlayerPose.side && facing.x < 0;
    final appearance = _appearanceFor(characterId);
    final frame = switch (pose) {
      _PlayerPose.front => walkFrame ? _frontStep : _frontIdle,
      _PlayerPose.back => walkFrame ? _backStep : _backIdle,
      _PlayerPose.side => walkFrame ? _sideStep : _sideIdle,
    };
    final overlay = switch (pose) {
      _PlayerPose.front => appearance.frontOverlay,
      _PlayerPose.back => appearance.backOverlay,
      _PlayerPose.side => appearance.sideOverlay,
    };

    _drawShadow(canvas, frame, opacity: opacity);
    _drawFrame(
      canvas,
      frame,
      palette: appearance.palette,
      flipX: flipX,
      bobOffset: walkFrame ? -0.8 : 0,
      opacity: opacity,
    );
    _drawFrame(
      canvas,
      overlay,
      palette: appearance.palette,
      flipX: flipX,
      bobOffset: walkFrame ? -0.8 : 0,
      opacity: opacity,
    );
  }

  static _PlayerPose _poseFor(Vector2 facing) {
    if (facing.y.abs() >= facing.x.abs()) {
      return facing.y < 0 ? _PlayerPose.back : _PlayerPose.front;
    }
    return _PlayerPose.side;
  }

  static void _drawShadow(
    Canvas canvas,
    List<String> frame, {
    double opacity = 1,
  }) {
    final width = frame.first.length * _pixelSize;
    final height = frame.length * _pixelSize;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, height * 0.34),
        width: width * 0.62,
        height: _pixelSize * 2.2,
      ),
      Paint()
        ..color = Color.fromARGB(
          (0x66 * opacity).round().clamp(0, 255),
          0,
          0,
          0,
        ),
    );
  }

  static void _drawFrame(
    Canvas canvas,
    List<String> frame, {
    required Map<String, Color> palette,
    required bool flipX,
    required double bobOffset,
    double opacity = 1,
  }) {
    final paint = Paint();
    final width = frame.first.length * _pixelSize;
    final height = frame.length * _pixelSize;
    final startX = -width / 2;
    final startY = -height / 2 + bobOffset;

    for (var y = 0; y < frame.length; y++) {
      final row = frame[y];
      for (var x = 0; x < row.length; x++) {
        final symbol = row[x];
        final color = palette[symbol];
        if (color == null) {
          continue;
        }

        final drawX = flipX ? row.length - 1 - x : x;
        paint.color = Color.fromARGB(
          (color.a * 255 * opacity).round().clamp(0, 255),
          (color.r * 255).round().clamp(0, 255),
          (color.g * 255).round().clamp(0, 255),
          (color.b * 255).round().clamp(0, 255),
        );
        canvas.drawRect(
          Rect.fromLTWH(
            startX + drawX * _pixelSize,
            startY + y * _pixelSize,
            _pixelSize,
            _pixelSize,
          ),
          paint,
        );
      }
    }
  }

  static _PlayerAppearance _appearanceFor(String characterId) {
    return switch (characterId) {
      'joseon_farmer' => _farmerAppearance,
      'joseon_pojol' => _pojolAppearance,
      'yi_sun_sin' => _admiralAppearance,
      _ => _farmerAppearance,
    };
  }
}

class _EnemyPixelVariant {
  const _EnemyPixelVariant({
    required this.idle,
    required this.step,
    required this.palette,
  });

  final List<String> idle;
  final List<String> step;
  final Map<String, Color> palette;
}

class _EnemyPixelArt {
  const _EnemyPixelArt._();

  static const int variantCount = 10;
  static const double _minRadius = SurvivorGame.enemyMinRadius;
  static const double _maxRadius = SurvivorGame.enemyMaxRadius;

  static const Map<String, Color> _sharedPalette = <String, Color>{
    'e': Color(0xFFF4F7FB),
  };

  static const _EnemyPixelVariant _imp = _EnemyPixelVariant(
    idle: <String>[
      '..x.x...',
      '.xpppx..',
      'xpssssp.',
      'xpeseep.',
      '.pssssp.',
      '.pfffp..',
      '..f.f...',
      '.f...f..',
    ],
    step: <String>[
      '..x.x...',
      '.xpppx..',
      'xpssssp.',
      'xpeseep.',
      '.pssssp.',
      '.pfffp..',
      '.f...f..',
      '..f.f...',
    ],
    palette: <String, Color>{
      'x': Color(0xFF341416),
      'p': Color(0xFF7E1F26),
      's': Color(0xFFD44A58),
      'f': Color(0xFF4A242A),
    },
  );

  static const _EnemyPixelVariant _beetle = _EnemyPixelVariant(
    idle: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      'xpsesspx',
      '.pssssp.',
      '.ffppff.',
      '.f....f.',
      '........',
    ],
    step: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      'xpsesspx',
      '.pssssp.',
      '.fppppf.',
      'f..ff..f',
      '........',
    ],
    palette: <String, Color>{
      'x': Color(0xFF352116),
      'p': Color(0xFF8C4B22),
      's': Color(0xFFD98B2B),
      'f': Color(0xFF4B301E),
    },
  );

  static const _EnemyPixelVariant _slime = _EnemyPixelVariant(
    idle: <String>[
      '........',
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      'xpseeepx',
      '.pssssp.',
      '..p..p..',
      '.f....f.',
    ],
    step: <String>[
      '........',
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      'xpseeepx',
      '.pssssp.',
      '.p....p.',
      '..f..f..',
    ],
    palette: <String, Color>{
      'x': Color(0xFF16321C),
      'p': Color(0xFF338E47),
      's': Color(0xFF76D45F),
      'f': Color(0xFF2A5A2D),
    },
  );

  static const _EnemyPixelVariant _crab = _EnemyPixelVariant(
    idle: <String>[
      '.x....x.',
      'xppxxppx',
      'pssssssp',
      'psessesp',
      '.pssssp.',
      'f.p..p.f',
      'ff....ff',
      '........',
    ],
    step: <String>[
      'x......x',
      '.ppxxpp.',
      'pssssssp',
      'psessesp',
      '.pssssp.',
      'ffp..pff',
      '.f....f.',
      '........',
    ],
    palette: <String, Color>{
      'x': Color(0xFF18303A),
      'p': Color(0xFF2E8BA5),
      's': Color(0xFF67C7E7),
      'f': Color(0xFF1D5A6B),
    },
  );

  static const _EnemyPixelVariant _bat = _EnemyPixelVariant(
    idle: <String>[
      'x......x',
      '.xppppx.',
      'ppsssspp',
      'xpsesspx',
      '.pssssp.',
      '..f..f..',
      '.f....f.',
      '........',
    ],
    step: <String>[
      'xx....xx',
      '.pppppp.',
      'xpsssspx',
      '.psessp.',
      '..pssp..',
      '.f....f.',
      '..f..f..',
      '........',
    ],
    palette: <String, Color>{
      'x': Color(0xFF32203C),
      'p': Color(0xFF7040A8),
      's': Color(0xFFB278F3),
      'f': Color(0xFF4C2B69),
    },
  );

  static const _EnemyPixelVariant _hound = _EnemyPixelVariant(
    idle: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpssssp.',
      'xpeppesp',
      '.pssssp.',
      '.fp..pf.',
      'ff....ff',
      '........',
    ],
    step: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpssssp.',
      'xpeppesp',
      '.pssssp.',
      'ff....ff',
      '.f.pp.f.',
      '........',
    ],
    palette: <String, Color>{
      'x': Color(0xFF19253C),
      'p': Color(0xFF3D68B4),
      's': Color(0xFF7FB2F6),
      'f': Color(0xFF2B3D6A),
    },
  );

  static const _EnemyPixelVariant _ghost = _EnemyPixelVariant(
    idle: <String>[
      '..xxxx..',
      '.xpsspx.',
      'xpsesspx',
      'xpsssspx',
      '.pssssp.',
      '.pf..fp.',
      '.pffffp.',
      '..f..f..',
    ],
    step: <String>[
      '..xxxx..',
      '.xpsspx.',
      'xpsesspx',
      'xpsssspx',
      '.pssssp.',
      '.pffffp.',
      '..ff.ff.',
      '.f....f.',
    ],
    palette: <String, Color>{
      'x': Color(0xFF3A404A),
      'p': Color(0xFFD7D9DF),
      's': Color(0xFFF5F5F8),
      'f': Color(0xFF9FA7B4),
    },
  );

  static const _EnemyPixelVariant _mushroom = _EnemyPixelVariant(
    idle: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      '.xpeepx.',
      '.xppppx.',
      '..pffp..',
      '.f....f.',
      '........',
    ],
    step: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      '.xpeepx.',
      '.xppppx.',
      '.f.pp.f.',
      '..f..f..',
      '........',
    ],
    palette: <String, Color>{
      'x': Color(0xFF4B2330),
      'p': Color(0xFFD56E95),
      's': Color(0xFFF1A5C0),
      'f': Color(0xFF8A6C58),
    },
  );

  static const _EnemyPixelVariant _skull = _EnemyPixelVariant(
    idle: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      'xpeseep.',
      '.pssssp.',
      '.pf..fp.',
      '..ffff..',
      '.f....f.',
    ],
    step: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      'xpeseep.',
      '.pssssp.',
      '..ffff..',
      '.f....f.',
      '..f..f..',
    ],
    palette: <String, Color>{
      'x': Color(0xFF4A493F),
      'p': Color(0xFFC9C19C),
      's': Color(0xFFE9E1BA),
      'f': Color(0xFF7E7451),
    },
  );

  static const _EnemyPixelVariant _golem = _EnemyPixelVariant(
    idle: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      'xpsesspx',
      'xpsssspx',
      '.pf..fp.',
      '.ff..ff.',
      'f......f',
    ],
    step: <String>[
      '..xxxx..',
      '.xppppx.',
      'xpsssspx',
      'xpsesspx',
      'xpsssspx',
      '.ff..ff.',
      'f..ff..f',
      '........',
    ],
    palette: <String, Color>{
      'x': Color(0xFF3C281A),
      'p': Color(0xFF8A5A2C),
      's': Color(0xFFC58A4A),
      'f': Color(0xFF5B3B25),
    },
  );

  static const List<_EnemyPixelVariant> _variants = <_EnemyPixelVariant>[
    _imp,
    _beetle,
    _slime,
    _crab,
    _bat,
    _hound,
    _ghost,
    _mushroom,
    _skull,
    _golem,
  ];

  static void render(
    Canvas canvas, {
    required int appearanceIndex,
    required double animationTime,
    required double radius,
  }) {
    final variant = _variants[appearanceIndex % _variants.length];
    final walkFrame = (animationTime * 6).floor().isOdd;
    final frame = walkFrame ? variant.step : variant.idle;
    final scaleFactor = math.max(
      0.0,
      math.min(1.0, (radius - _minRadius) / (_maxRadius - _minRadius)),
    );
    final pixelSize = 3.075 + scaleFactor * 1.2;

    _drawShadow(canvas, frame, pixelSize);
    _drawFrame(
      canvas,
      frame,
      pixelSize: pixelSize,
      palette: variant.palette,
      bobOffset: walkFrame ? -0.6 : 0,
    );
  }

  static void _drawShadow(Canvas canvas, List<String> frame, double pixelSize) {
    final width = frame.first.length * pixelSize;
    final height = frame.length * pixelSize;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, height * 0.3),
        width: width * 0.56,
        height: pixelSize * 2.0,
      ),
      Paint()..color = const Color(0x66000000),
    );
  }

  static void _drawFrame(
    Canvas canvas,
    List<String> frame, {
    required double pixelSize,
    required Map<String, Color> palette,
    required double bobOffset,
  }) {
    final paint = Paint();
    final width = frame.first.length * pixelSize;
    final height = frame.length * pixelSize;
    final startX = -width / 2;
    final startY = -height / 2 + bobOffset;

    for (var y = 0; y < frame.length; y++) {
      final row = frame[y];
      for (var x = 0; x < row.length; x++) {
        final symbol = row[x];
        final color = palette[symbol] ?? _sharedPalette[symbol];
        if (color == null) {
          continue;
        }

        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            startX + x * pixelSize,
            startY + y * pixelSize,
            pixelSize,
            pixelSize,
          ),
          paint,
        );
      }
    }
  }
}
