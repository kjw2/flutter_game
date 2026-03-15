import 'package:flutter/material.dart';

enum SurvivorMapBackgroundStyle { grid, stripes, rings }

extension SurvivorMapBackgroundStyleX on SurvivorMapBackgroundStyle {
  String get id => switch (this) {
    SurvivorMapBackgroundStyle.grid => 'grid',
    SurvivorMapBackgroundStyle.stripes => 'stripes',
    SurvivorMapBackgroundStyle.rings => 'rings',
  };

  String get label => switch (this) {
    SurvivorMapBackgroundStyle.grid => '그리드',
    SurvivorMapBackgroundStyle.stripes => '스트라이프',
    SurvivorMapBackgroundStyle.rings => '링',
  };

  static SurvivorMapBackgroundStyle fromId(String? id) {
    return SurvivorMapBackgroundStyle.values.firstWhere(
      (style) => style.id == id,
      orElse: () => SurvivorMapBackgroundStyle.grid,
    );
  }
}

enum SurvivorMapFloorType { dirt, grass, concrete, stone, sand, metal }

extension SurvivorMapFloorTypeX on SurvivorMapFloorType {
  String get id => switch (this) {
    SurvivorMapFloorType.dirt => 'dirt',
    SurvivorMapFloorType.grass => 'grass',
    SurvivorMapFloorType.concrete => 'concrete',
    SurvivorMapFloorType.stone => 'stone',
    SurvivorMapFloorType.sand => 'sand',
    SurvivorMapFloorType.metal => 'metal',
  };

  String get label => switch (this) {
    SurvivorMapFloorType.dirt => '흙바닥',
    SurvivorMapFloorType.grass => '풀바닥',
    SurvivorMapFloorType.concrete => '콘크리트',
    SurvivorMapFloorType.stone => '돌바닥',
    SurvivorMapFloorType.sand => '모래바닥',
    SurvivorMapFloorType.metal => '금속바닥',
  };

  static SurvivorMapFloorType fromId(
    String? id, {
    SurvivorMapBackgroundStyle? legacyStyle,
  }) {
    return SurvivorMapFloorType.values.firstWhere(
      (type) => type.id == id,
      orElse: () {
        return switch (legacyStyle) {
          SurvivorMapBackgroundStyle.stripes => SurvivorMapFloorType.grass,
          SurvivorMapBackgroundStyle.rings => SurvivorMapFloorType.concrete,
          _ => SurvivorMapFloorType.stone,
        };
      },
    );
  }
}

enum SurvivorMapObstacleType { wall, pillar, mire }

extension SurvivorMapObstacleTypeX on SurvivorMapObstacleType {
  String get id => switch (this) {
    SurvivorMapObstacleType.wall => 'wall',
    SurvivorMapObstacleType.pillar => 'pillar',
    SurvivorMapObstacleType.mire => 'mire',
  };

  String get label => switch (this) {
    SurvivorMapObstacleType.wall => '벽',
    SurvivorMapObstacleType.pillar => '기둥',
    SurvivorMapObstacleType.mire => '수렁',
  };

  bool get isSolid => switch (this) {
    SurvivorMapObstacleType.wall => true,
    SurvivorMapObstacleType.pillar => true,
    SurvivorMapObstacleType.mire => false,
  };

  static SurvivorMapObstacleType fromId(String? id) {
    return SurvivorMapObstacleType.values.firstWhere(
      (type) => type.id == id,
      orElse: () => SurvivorMapObstacleType.wall,
    );
  }
}

class SurvivorCharacterConfig {
  const SurvivorCharacterConfig({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.maxHealth,
    required this.moveSpeed,
    required this.projectileDamage,
    required this.attackInterval,
    required this.pickupRadius,
    required this.highlights,
  });

  final String id;
  final String name;
  final String title;
  final String description;
  final Color accentColor;
  final double maxHealth;
  final double moveSpeed;
  final double projectileDamage;
  final double attackInterval;
  final double pickupRadius;
  final List<String> highlights;

  SurvivorCharacterConfig copyWith({
    String? id,
    String? name,
    String? title,
    String? description,
    Color? accentColor,
    double? maxHealth,
    double? moveSpeed,
    double? projectileDamage,
    double? attackInterval,
    double? pickupRadius,
    List<String>? highlights,
  }) {
    return SurvivorCharacterConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      accentColor: accentColor ?? this.accentColor,
      maxHealth: maxHealth ?? this.maxHealth,
      moveSpeed: moveSpeed ?? this.moveSpeed,
      projectileDamage: projectileDamage ?? this.projectileDamage,
      attackInterval: attackInterval ?? this.attackInterval,
      pickupRadius: pickupRadius ?? this.pickupRadius,
      highlights: highlights ?? this.highlights,
    );
  }
}

enum SurvivorWeaponType { spear, scythe, bow, talisman, scream, ancestor }

class SurvivorWeaponConfig {
  const SurvivorWeaponConfig({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.weaponType,
    required this.damageBonus,
    required this.attackIntervalMultiplier,
    required this.projectileSpeed,
    required this.projectileLifetime,
    required this.baseProjectileCount,
    required this.basePierce,
    required this.projectileRadius,
    required this.projectileColor,
    required this.projectileSpinRate,
    required this.highlights,
  });

  final String id;
  final String name;
  final String title;
  final String description;
  final Color accentColor;
  final SurvivorWeaponType weaponType;
  final double damageBonus;
  final double attackIntervalMultiplier;
  final double projectileSpeed;
  final double projectileLifetime;
  final int baseProjectileCount;
  final int basePierce;
  final double projectileRadius;
  final Color projectileColor;
  final double projectileSpinRate;
  final List<String> highlights;
}

class SurvivorMapObstacle {
  const SurvivorMapObstacle({
    required this.gridX,
    required this.gridY,
    this.type = SurvivorMapObstacleType.wall,
  });

  final int gridX;
  final int gridY;
  final SurvivorMapObstacleType type;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'gridX': gridX, 'gridY': gridY, 'type': type.id};
  }

  factory SurvivorMapObstacle.fromJson(Map<String, dynamic> json) {
    return SurvivorMapObstacle(
      gridX: (json['gridX'] as num?)?.toInt() ?? 0,
      gridY: (json['gridY'] as num?)?.toInt() ?? 0,
      type: SurvivorMapObstacleTypeX.fromId(json['type'] as String?),
    );
  }

  Rect toTileRect(SurvivorMapConfig map) {
    final left = -map.worldWidth / 2 + gridX * SurvivorMapConfig.cellSize;
    final top = -map.worldHeight / 2 + gridY * SurvivorMapConfig.cellSize;
    return Rect.fromLTWH(
      left,
      top,
      SurvivorMapConfig.cellSize,
      SurvivorMapConfig.cellSize,
    );
  }

  Rect toWorldRect(SurvivorMapConfig map) {
    final tileRect = toTileRect(map);
    return switch (type) {
      SurvivorMapObstacleType.wall => tileRect.deflate(2),
      SurvivorMapObstacleType.pillar => tileRect.deflate(10),
      SurvivorMapObstacleType.mire => tileRect.deflate(4),
    };
  }
}

class SurvivorMapConfig {
  const SurvivorMapConfig({
    required this.id,
    required this.name,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.floorType,
    required this.floorColor,
    required this.gridColor,
    required this.detailColor,
    required this.backgroundStyle,
    required this.spawnRateMultiplier,
    required this.waveDensity,
    required this.enemyHealthMultiplier,
    required this.enemySpeedMultiplier,
    required this.highlights,
    this.widthCells = 64,
    this.heightCells = 64,
    this.obstacles = const <SurvivorMapObstacle>[],
    this.isCustom = false,
  });

  static const double cellSize = 64;

  final String id;
  final String name;
  final String title;
  final String description;
  final Color accentColor;
  final SurvivorMapFloorType floorType;
  final Color floorColor;
  final Color gridColor;
  final Color detailColor;
  final SurvivorMapBackgroundStyle backgroundStyle;
  final double spawnRateMultiplier;
  final double waveDensity;
  final double enemyHealthMultiplier;
  final double enemySpeedMultiplier;
  final List<String> highlights;
  final int widthCells;
  final int heightCells;
  final List<SurvivorMapObstacle> obstacles;
  final bool isCustom;

  double get worldWidth => widthCells * cellSize;
  double get worldHeight => heightCells * cellSize;

  Rect get worldBounds => Rect.fromCenter(
    center: Offset.zero,
    width: worldWidth,
    height: worldHeight,
  );

  factory SurvivorMapConfig.custom({
    required String id,
    required String name,
    required int widthCells,
    required int heightCells,
    required SurvivorMapFloorType floorType,
    required Color floorColor,
    required Color gridColor,
    required Color detailColor,
    required SurvivorMapBackgroundStyle backgroundStyle,
    required List<SurvivorMapObstacle> obstacles,
    String description = '직접 만든 전장입니다.',
  }) {
    return SurvivorMapConfig(
      id: id,
      name: name,
      title: '커스텀 전장',
      description: description,
      accentColor: detailColor,
      floorType: floorType,
      floorColor: floorColor,
      gridColor: gridColor,
      detailColor: detailColor,
      backgroundStyle: backgroundStyle,
      spawnRateMultiplier: 1.0,
      waveDensity: 1.0,
      enemyHealthMultiplier: 1.0,
      enemySpeedMultiplier: 1.0,
      highlights: <String>[
        '$widthCells x $heightCells 타일',
        '장애물 ${obstacles.length}개',
        '바닥 ${floorType.label}',
        '배경 ${backgroundStyle.label}',
      ],
      widthCells: widthCells,
      heightCells: heightCells,
      obstacles: List<SurvivorMapObstacle>.unmodifiable(obstacles),
      isCustom: true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'title': title,
      'description': description,
      'accentColor': _encodeColor(accentColor),
      'floorType': floorType.id,
      'floorColor': _encodeColor(floorColor),
      'gridColor': _encodeColor(gridColor),
      'detailColor': _encodeColor(detailColor),
      'backgroundStyle': backgroundStyle.id,
      'spawnRateMultiplier': spawnRateMultiplier,
      'waveDensity': waveDensity,
      'enemyHealthMultiplier': enemyHealthMultiplier,
      'enemySpeedMultiplier': enemySpeedMultiplier,
      'highlights': highlights,
      'widthCells': widthCells,
      'heightCells': heightCells,
      'obstacles': obstacles.map((obstacle) => obstacle.toJson()).toList(),
      'isCustom': isCustom,
    };
  }

  factory SurvivorMapConfig.fromJson(Map<String, dynamic> json) {
    final rawObstacles =
        json['obstacles'] as List<dynamic>? ?? const <dynamic>[];
    final backgroundStyle = SurvivorMapBackgroundStyleX.fromId(
      json['backgroundStyle'] as String?,
    );

    return SurvivorMapConfig(
      id: json['id'] as String? ?? 'custom_map',
      name: json['name'] as String? ?? '커스텀 맵',
      title: json['title'] as String? ?? '커스텀 전장',
      description: json['description'] as String? ?? '직접 만든 전장입니다.',
      accentColor: _decodeColor(json['accentColor'], const Color(0xFF58B7D5)),
      floorType: SurvivorMapFloorTypeX.fromId(
        json['floorType'] as String?,
        legacyStyle: backgroundStyle,
      ),
      floorColor: _decodeColor(json['floorColor'], const Color(0xFF101517)),
      gridColor: _decodeColor(json['gridColor'], const Color(0xFF1B2529)),
      detailColor: _decodeColor(json['detailColor'], const Color(0xFF58B7D5)),
      backgroundStyle: backgroundStyle,
      spawnRateMultiplier:
          (json['spawnRateMultiplier'] as num?)?.toDouble() ?? 1.0,
      waveDensity: (json['waveDensity'] as num?)?.toDouble() ?? 1.0,
      enemyHealthMultiplier:
          (json['enemyHealthMultiplier'] as num?)?.toDouble() ?? 1.0,
      enemySpeedMultiplier:
          (json['enemySpeedMultiplier'] as num?)?.toDouble() ?? 1.0,
      highlights: (json['highlights'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => item.toString())
          .toList(growable: false),
      widthCells: (json['widthCells'] as num?)?.toInt() ?? 24,
      heightCells: (json['heightCells'] as num?)?.toInt() ?? 18,
      obstacles: rawObstacles
          .whereType<Map<String, dynamic>>()
          .map(SurvivorMapObstacle.fromJson)
          .toList(growable: false),
      isCustom: json['isCustom'] as bool? ?? true,
    );
  }
}

int _encodeColor(Color color) {
  final a = (color.a * 255).round().clamp(0, 255);
  final r = (color.r * 255).round().clamp(0, 255);
  final g = (color.g * 255).round().clamp(0, 255);
  final b = (color.b * 255).round().clamp(0, 255);
  return (a << 24) | (r << 16) | (g << 8) | b;
}

Color _decodeColor(Object? raw, Color fallback) {
  if (raw is int) {
    return Color(raw);
  }
  if (raw is num) {
    return Color(raw.toInt());
  }
  return fallback;
}

List<SurvivorMapObstacle> _builtInMapObstacles(
  String mapId, {
  int widthCells = 64,
  int heightCells = 64,
}) {
  final builder = _BuiltInObstacleBuilder(
    widthCells: widthCells,
    heightCells: heightCells,
  );

  switch (mapId) {
    case 'ash_fields':
      builder
        ..addHorizontalWall(8, 14, 18)
        ..addHorizontalWall(49, 55, 18)
        ..addHorizontalWall(8, 14, 45)
        ..addHorizontalWall(49, 55, 45)
        ..addVerticalWall(18, 25, 31)
        ..addVerticalWall(45, 33, 39)
        ..addPillar(20, 20)
        ..addPillar(44, 20)
        ..addPillar(20, 44)
        ..addPillar(44, 44)
        ..addPillar(24, 32)
        ..addPillar(40, 32)
        ..addPatch(10, 12, 35, 37, SurvivorMapObstacleType.mire)
        ..addPatch(51, 53, 26, 28, SurvivorMapObstacleType.mire)
        ..addPatch(28, 35, 10, 11, SurvivorMapObstacleType.mire);
      break;
    case 'jade_garden':
      builder
        ..addHorizontalWall(13, 20, 24)
        ..addHorizontalWall(43, 50, 40)
        ..addVerticalWall(24, 13, 20)
        ..addVerticalWall(40, 43, 50)
        ..addPillar(20, 20)
        ..addPillar(32, 16)
        ..addPillar(44, 20)
        ..addPillar(16, 32)
        ..addPillar(48, 32)
        ..addPillar(20, 44)
        ..addPillar(32, 48)
        ..addPillar(44, 44)
        ..addPatch(9, 15, 9, 13, SurvivorMapObstacleType.mire)
        ..addPatch(48, 54, 12, 16, SurvivorMapObstacleType.mire)
        ..addPatch(12, 18, 48, 52, SurvivorMapObstacleType.mire)
        ..addPatch(46, 52, 45, 49, SurvivorMapObstacleType.mire)
        ..addPatch(27, 36, 18, 19, SurvivorMapObstacleType.mire)
        ..addPatch(27, 36, 44, 45, SurvivorMapObstacleType.mire);
      break;
    case 'twilight_foundry':
      builder
        ..addVerticalWall(18, 10, 24)
        ..addVerticalWall(18, 39, 53)
        ..addVerticalWall(45, 10, 24)
        ..addVerticalWall(45, 39, 53)
        ..addHorizontalWall(10, 24, 18)
        ..addHorizontalWall(39, 53, 18)
        ..addHorizontalWall(10, 24, 45)
        ..addHorizontalWall(39, 53, 45)
        ..addPillar(26, 20)
        ..addPillar(32, 20)
        ..addPillar(38, 20)
        ..addPillar(20, 26)
        ..addPillar(44, 26)
        ..addPillar(20, 38)
        ..addPillar(44, 38)
        ..addPillar(26, 44)
        ..addPillar(32, 44)
        ..addPillar(38, 44)
        ..addPatch(28, 35, 11, 12, SurvivorMapObstacleType.mire)
        ..addPatch(28, 35, 51, 52, SurvivorMapObstacleType.mire);
      break;
    case 'sunscorch_dunes':
      builder
        ..addHorizontalWall(11, 16, 15)
        ..addHorizontalWall(47, 52, 50)
        ..addVerticalWall(12, 42, 47)
        ..addVerticalWall(51, 17, 22)
        ..addPillar(18, 18)
        ..addPillar(26, 24)
        ..addPillar(44, 18)
        ..addPillar(38, 26)
        ..addPillar(18, 46)
        ..addPillar(28, 40)
        ..addPillar(45, 45)
        ..addPillar(40, 38)
        ..addPatch(24, 28, 11, 14, SurvivorMapObstacleType.mire)
        ..addPatch(41, 45, 29, 32, SurvivorMapObstacleType.mire)
        ..addPatch(15, 19, 30, 33, SurvivorMapObstacleType.mire)
        ..addPatch(30, 34, 49, 52, SurvivorMapObstacleType.mire);
      break;
    case 'iron_hangar':
      builder
        ..addHorizontalWall(12, 22, 15)
        ..addHorizontalWall(41, 51, 15)
        ..addHorizontalWall(18, 28, 48)
        ..addHorizontalWall(35, 45, 48)
        ..addVerticalWall(15, 22, 29)
        ..addVerticalWall(15, 34, 42)
        ..addVerticalWall(48, 22, 29)
        ..addVerticalWall(48, 34, 42)
        ..addPillar(24, 18)
        ..addPillar(32, 18)
        ..addPillar(40, 18)
        ..addPillar(21, 32)
        ..addPillar(43, 32)
        ..addPillar(24, 46)
        ..addPillar(32, 46)
        ..addPillar(40, 46)
        ..addPatch(28, 35, 11, 12, SurvivorMapObstacleType.mire)
        ..addPatch(28, 35, 51, 52, SurvivorMapObstacleType.mire)
        ..addPatch(10, 12, 28, 35, SurvivorMapObstacleType.mire)
        ..addPatch(51, 53, 28, 35, SurvivorMapObstacleType.mire);
      break;
  }

  return builder.build();
}

class _BuiltInObstacleBuilder {
  _BuiltInObstacleBuilder({
    required this.widthCells,
    required this.heightCells,
  });

  final int widthCells;
  final int heightCells;
  final List<SurvivorMapObstacle> _obstacles = <SurvivorMapObstacle>[];
  final Set<String> _occupiedCells = <String>{};

  int get _centerX => widthCells ~/ 2;
  int get _centerY => heightCells ~/ 2;

  List<SurvivorMapObstacle> build() =>
      List<SurvivorMapObstacle>.unmodifiable(_obstacles);

  void addHorizontalWall(int startX, int endX, int y) {
    for (var x = startX; x <= endX; x++) {
      add(x, y, SurvivorMapObstacleType.wall);
    }
  }

  void addVerticalWall(int x, int startY, int endY) {
    for (var y = startY; y <= endY; y++) {
      add(x, y, SurvivorMapObstacleType.wall);
    }
  }

  void addPatch(
    int startX,
    int endX,
    int startY,
    int endY,
    SurvivorMapObstacleType type,
  ) {
    for (var x = startX; x <= endX; x++) {
      for (var y = startY; y <= endY; y++) {
        add(x, y, type);
      }
    }
  }

  void addPillar(int x, int y) {
    add(x, y, SurvivorMapObstacleType.pillar);
  }

  void add(int x, int y, SurvivorMapObstacleType type) {
    if (x < 0 || y < 0 || x >= widthCells || y >= heightCells) {
      return;
    }
    if ((x - _centerX).abs() <= 3 && (y - _centerY).abs() <= 3) {
      return;
    }

    final key = '$x:$y';
    if (!_occupiedCells.add(key)) {
      return;
    }

    _obstacles.add(SurvivorMapObstacle(gridX: x, gridY: y, type: type));
  }
}

const List<SurvivorCharacterConfig> survivorCharacters =
    <SurvivorCharacterConfig>[
      SurvivorCharacterConfig(
        id: 'joseon_farmer',
        name: '조선시대 농부',
        title: '들판을 누비는 생존자',
        description: '흰 두루마기와 상투 차림으로 빠르게 전장을 돌며 자원을 모으는 성장형 캐릭터입니다.',
        accentColor: Color(0xFFE8E0C6),
        maxHealth: 92,
        moveSpeed: 248,
        projectileDamage: 16,
        attackInterval: 0.52,
        pickupRadius: 26,
        highlights: <String>['기본 이동속도 248', '기본 획득범위 증가', '초기 체력은 낮음'],
      ),
      SurvivorCharacterConfig(
        id: 'joseon_pojol',
        name: '조선시대 포졸',
        title: '성문 수비형 전투원',
        description: '붉고 푸른 복식의 포졸로, 공격 템포와 생존력이 균형 잡힌 표준형 캐릭터입니다.',
        accentColor: Color(0xFFB23C3C),
        maxHealth: 100,
        moveSpeed: 224,
        projectileDamage: 18,
        attackInterval: 0.48,
        pickupRadius: 12,
        highlights: <String>['기본 공격속도 우수', '균형형 스탯', '어떤 무기와도 무난하게 어울림'],
      ),
      SurvivorCharacterConfig(
        id: 'yi_sun_sin',
        name: '이순신 장군',
        title: '전선을 지휘하는 영웅',
        description: '갑옷과 투구를 두른 장군으로, 높은 체력과 기본 화력으로 전선을 안정적으로 지탱합니다.',
        accentColor: Color(0xFF476AA8),
        maxHealth: 128,
        moveSpeed: 212,
        projectileDamage: 22,
        attackInterval: 0.58,
        pickupRadius: 12,
        highlights: <String>['기본 HP 128', '기본 공격력 22', '묵직한 전선 유지형'],
      ),
    ];

const List<SurvivorWeaponConfig> survivorWeapons = <SurvivorWeaponConfig>[
  SurvivorWeaponConfig(
    id: 'spear',
    name: '강철 창',
    title: '직선 관통형',
    description: '길게 뻗는 창을 묵직하게 던집니다. 발사 템포는 느리지만 기본 관통이 있어 줄세운 적을 뚫기에 좋습니다.',
    accentColor: Color(0xFFD8B56B),
    weaponType: SurvivorWeaponType.spear,
    damageBonus: 6,
    attackIntervalMultiplier: 2.1,
    projectileSpeed: 520,
    projectileLifetime: 0.62,
    baseProjectileCount: 1,
    basePierce: 1,
    projectileRadius: 7,
    projectileColor: Color(0xFFEFD8A1),
    projectileSpinRate: 0,
    highlights: <String>['기본 공격력 +6', '기본 관통수 +1', '길고 묵직한 직선 투척'],
  ),
  SurvivorWeaponConfig(
    id: 'scythe',
    name: '던지는 낫',
    title: '중거리 중량형',
    description:
        '회전하는 낫을 가까운 중거리로 던진 뒤 다시 되돌려 받습니다. 발사 주기는 느리지만 한 번 맞으면 묵직하고 판정도 큽니다.',
    accentColor: Color(0xFFAF7CF2),
    weaponType: SurvivorWeaponType.scythe,
    damageBonus: 7,
    attackIntervalMultiplier: 1.8,
    projectileSpeed: 260,
    projectileLifetime: 0.72,
    baseProjectileCount: 1,
    basePierce: 1,
    projectileRadius: 11,
    projectileColor: Color(0xFFD7C6FF),
    projectileSpinRate: 14,
    highlights: <String>['기본 공격력 +7', '넓은 타격 판정', '던진 뒤 플레이어에게 되돌아옴'],
  ),
  SurvivorWeaponConfig(
    id: 'bow',
    name: '장궁',
    title: '정밀 원거리형',
    description:
        '화살을 곧고 빠르게 쏘는 기본 원거리 무기입니다. 낫보다 멀리 뻗지만 발사속도는 이전보다 차분하게 조정했습니다.',
    accentColor: Color(0xFF76C6A6),
    weaponType: SurvivorWeaponType.bow,
    damageBonus: 0,
    attackIntervalMultiplier: 1.2,
    projectileSpeed: 620,
    projectileLifetime: 0.88,
    baseProjectileCount: 1,
    basePierce: 0,
    projectileRadius: 4,
    projectileColor: Color(0xFFB6F0D2),
    projectileSpinRate: 0,
    highlights: <String>['직선 원거리 공격', '낫보다 빠른 투사체', '관통 없이 단일 화력 운용'],
  ),
  SurvivorWeaponConfig(
    id: 'talisman',
    name: '부적',
    title: '궤도 수호형',
    description: '플레이어 주위를 맴도는 부적이 닿는 적을 공격합니다. 강화할 때마다 부적 수가 늘어납니다.',
    accentColor: Color(0xFFFFD86E),
    weaponType: SurvivorWeaponType.talisman,
    damageBonus: 2,
    attackIntervalMultiplier: 1.25,
    projectileSpeed: 0,
    projectileLifetime: 0,
    baseProjectileCount: 1,
    basePierce: 0,
    projectileRadius: 9,
    projectileColor: Color(0xFFFFF1B3),
    projectileSpinRate: 9,
    highlights: <String>['주위를 도는 근접 궤도 무기', '강화할 때마다 부적 +1', '발사속도가 회전 속도에 반영'],
  ),
  SurvivorWeaponConfig(
    id: 'scream',
    name: '절규',
    title: '근접 파동형',
    description:
        '플레이어를 둘러싼 반투명한 절규 범위가 안으로 들어온 적을 주기적으로 짓누릅니다. 강화할수록 범위와 타격 주기가 좋아집니다.',
    accentColor: Color(0xFF79E5C1),
    weaponType: SurvivorWeaponType.scream,
    damageBonus: 1,
    attackIntervalMultiplier: 1.15,
    projectileSpeed: 0,
    projectileLifetime: 0,
    baseProjectileCount: 1,
    basePierce: 0,
    projectileRadius: 74,
    projectileColor: Color(0xFFAFFFF1),
    projectileSpinRate: 0,
    highlights: <String>[
      '플레이어 중심 광역 오라',
      '발사속도만큼 주기적으로 피해',
      '범위 강화에 따라 오라 반경 증가',
    ],
  ),
  SurvivorWeaponConfig(
    id: 'ancestor',
    name: '조상님',
    title: '추적 수호령형',
    description:
        '캐릭터 주변을 떠도는 조상님이 근처 적을 감지하면 다가가 공격합니다. 마지막 강화까지 가면 조상님이 둘이 됩니다.',
    accentColor: Color(0xFFD7F2FF),
    weaponType: SurvivorWeaponType.ancestor,
    damageBonus: 3,
    attackIntervalMultiplier: 1.05,
    projectileSpeed: 0,
    projectileLifetime: 0,
    baseProjectileCount: 1,
    basePierce: 0,
    projectileRadius: 10,
    projectileColor: Color(0xFFE8FBFF),
    projectileSpinRate: 0,
    highlights: <String>[
      '캐릭터 주변을 떠도는 유령형 무기',
      '적이 범위에 들어오면 추적 후 50% 피해로 반복 타격',
      '5레벨 달성 시 조상님 +1',
    ],
  ),
];

final List<SurvivorMapConfig> survivorMaps = <SurvivorMapConfig>[
  SurvivorMapConfig(
    id: 'ash_fields',
    name: '잿빛 평원',
    title: '균형형 시작 맵',
    description: '시야가 트여 있고 웨이브 압박이 무난한 표준 전장입니다.',
    accentColor: Color(0xFF8BC34A),
    floorType: SurvivorMapFloorType.dirt,
    floorColor: Color(0xFF101517),
    gridColor: Color(0xFF1B2529),
    detailColor: Color(0xFF2B3B2F),
    backgroundStyle: SurvivorMapBackgroundStyle.grid,
    spawnRateMultiplier: 1.0,
    waveDensity: 1.0,
    enemyHealthMultiplier: 1.0,
    enemySpeedMultiplier: 1.0,
    obstacles: _builtInMapObstacles('ash_fields'),
    highlights: <String>[
      '흙바닥 전장',
      '짧은 벽과 기둥이 사방에서 시야를 한 번씩 끊음',
      '작은 웅덩이를 피해 안정적으로 빌드업 가능',
      '처음 시작하기 적합',
    ],
  ),
  SurvivorMapConfig(
    id: 'jade_garden',
    name: '비취 정원',
    title: '물량 압박 맵',
    description: '적 수는 많지만 개체가 상대적으로 약해서 광역 빌드에 잘 맞습니다.',
    accentColor: Color(0xFF58B7D5),
    floorType: SurvivorMapFloorType.grass,
    floorColor: Color(0xFF0F1716),
    gridColor: Color(0xFF173431),
    detailColor: Color(0xFF1F5550),
    backgroundStyle: SurvivorMapBackgroundStyle.stripes,
    spawnRateMultiplier: 1.18,
    waveDensity: 1.25,
    enemyHealthMultiplier: 0.92,
    enemySpeedMultiplier: 0.96,
    obstacles: _builtInMapObstacles('jade_garden'),
    highlights: <String>[
      '풀바닥 전장',
      '큰 웅덩이와 정원 기둥이 외곽 동선을 크게 흔듦',
      '적 개체 수 증가',
      '적 체력은 다소 낮음',
    ],
  ),
  SurvivorMapConfig(
    id: 'twilight_foundry',
    name: '황혼 공방',
    title: '정예 압박 맵',
    description: '적은 조금 덜 나오지만 개체가 튼튼하고 빨라 빌드 완성도를 요구합니다.',
    accentColor: Color(0xFFE39C45),
    floorType: SurvivorMapFloorType.concrete,
    floorColor: Color(0xFF171210),
    gridColor: Color(0xFF3A271A),
    detailColor: Color(0xFF70472A),
    backgroundStyle: SurvivorMapBackgroundStyle.rings,
    spawnRateMultiplier: 0.94,
    waveDensity: 0.9,
    enemyHealthMultiplier: 1.22,
    enemySpeedMultiplier: 1.08,
    obstacles: _builtInMapObstacles('twilight_foundry'),
    highlights: <String>[
      '콘크리트 전장',
      '공방 벽 구획과 기둥열이 통로전을 강하게 만듦',
      '적 체력 증가',
      '적 이동속도 증가',
    ],
  ),
  SurvivorMapConfig(
    id: 'sunscorch_dunes',
    name: '작열 사구',
    title: '기동전 중심 맵',
    description: '모래바람이 이는 개활지로, 적 물량이 빠르게 밀려들지만 개체는 비교적 약합니다.',
    accentColor: Color(0xFFF0C96B),
    floorType: SurvivorMapFloorType.sand,
    floorColor: Color(0xFF19140D),
    gridColor: Color(0xFF4A3820),
    detailColor: Color(0xFFD7A85A),
    backgroundStyle: SurvivorMapBackgroundStyle.stripes,
    spawnRateMultiplier: 1.12,
    waveDensity: 1.18,
    enemyHealthMultiplier: 0.94,
    enemySpeedMultiplier: 1.0,
    obstacles: _builtInMapObstacles('sunscorch_dunes'),
    highlights: <String>[
      '모래바닥 전장',
      '무너진 벽과 유사 웅덩이가 산개해 회전 동선이 중요함',
      '적 개체 수 증가',
      '맵 순환이 중요한 기동전',
    ],
  ),
  SurvivorMapConfig(
    id: 'iron_hangar',
    name: '철빛 격납고',
    title: '정예 밀집 맵',
    description: '금속 판넬로 깔린 격납고형 전장으로, 적 숫자는 적지만 압박 강도가 높은 편입니다.',
    accentColor: Color(0xFF7DD7F0),
    floorType: SurvivorMapFloorType.metal,
    floorColor: Color(0xFF0C1318),
    gridColor: Color(0xFF253640),
    detailColor: Color(0xFF89B7C7),
    backgroundStyle: SurvivorMapBackgroundStyle.grid,
    spawnRateMultiplier: 0.9,
    waveDensity: 0.84,
    enemyHealthMultiplier: 1.18,
    enemySpeedMultiplier: 1.06,
    obstacles: _builtInMapObstacles('iron_hangar'),
    highlights: <String>[
      '금속 바닥 전장',
      '격납고 벽과 기둥, 냉각 웅덩이가 좁은 진입로를 형성',
      '적 개체 수 감소',
      '정예 적 밀도가 높음',
    ],
  ),
];
