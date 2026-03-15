import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../input/gamepad_manager.dart';
import 'survivor_floor_tiles.dart';
import 'survivor_run_config.dart';

part 'survivor_components.dart';
part 'survivor_entities.dart';
part 'survivor_pixel_art.dart';
part 'survivor_upgrades.dart';

class SurvivorGame extends FlameGame with KeyboardEvents {
  static const double enemyMinRadius = 21;
  static const double enemyMaxRadius = 36;
  static const int _maxTreasureChestsPerRun = 5;
  static const double _treasureChestIntervalSeconds = 90;
  static const double _maxSimulationDt = 1 / 30;
  static const Map<SurvivorWeaponType, String> _weaponHitAudioAssets =
      <SurvivorWeaponType, String>{
        SurvivorWeaponType.spear: 'hit_spear.wav',
        SurvivorWeaponType.scythe: 'hit_scythe.wav',
        SurvivorWeaponType.bow: 'hit_bow.wav',
        SurvivorWeaponType.talisman: 'hit_talisman.wav',
        SurvivorWeaponType.scream: 'hit_talisman.wav',
        SurvivorWeaponType.ancestor: 'hit_talisman.wav',
      };

  SurvivorGame({
    required this.characterConfig,
    required this.weaponConfig,
    required this.mapConfig,
    this.startingLevelUpRerolls = 5,
    this.onPauseRequested,
    this.onLevelUpChoicesChanged,
    this.onRunEnded,
  }) : levelUpRerollsRemaining = math.max(0, startingLevelUpRerolls),
       random = math.Random();

  static const double runDurationSeconds = 30 * 60;

  final math.Random random;
  final SurvivorCharacterConfig characterConfig;
  final SurvivorWeaponConfig weaponConfig;
  final SurvivorMapConfig mapConfig;
  final int startingLevelUpRerolls;
  final VoidCallback? onPauseRequested;
  final ValueChanged<List<UpgradeChoice>>? onLevelUpChoicesChanged;
  final VoidCallback? onRunEnded;
  final GamepadManager gamepad = GamepadManager.instance;
  final Map<UpgradeType, int> _upgradeLevels = <UpgradeType, int>{
    for (final type in UpgradeType.values) type: 0,
  };

  late final JoystickComponent joystick;
  late final ExperienceHudComponent experienceHud;
  late final DashCooldownHud dashHud;
  late final TextComponent statsText;
  late final TextComponent timerText;
  late final TextComponent runInfoText;
  late final TextComponent hintText;
  late final MiniMapComponent miniMap;
  late final GameOverOverlay gameOverOverlay;
  late final Player player;
  late final List<Rect> solidObstacleRects;
  late final List<Rect> mireRects;

  final Set<LogicalKeyboardKey> _keysPressed = <LogicalKeyboardKey>{};
  final List<UpgradeChoice> _currentLevelUpChoices = <UpgradeChoice>[];
  final Vector2 _lastMovementDirection = Vector2(0, -1);

  double elapsedTime = 0;
  double spawnTimer = 0;
  double _hurtFeedbackTimer = 0;
  double _enemyHitAudioCooldown = 0;
  double _enemyBurstAudioCooldown = 0;
  double _treasureChestSpawnTimer = _treasureChestIntervalSeconds;
  double _movementDirectionBuffer = 999;
  bool _suppressDashWhileSpaceHeld = false;
  bool gameOver = false;
  bool playerWon = false;
  bool showMinimap = true;
  bool isLevelingUp = false;
  int pendingLevelUps = 0;
  int levelUpRerollsRemaining;
  int runGold = 0;
  int _spawnedTreasureChestCount = 0;
  bool _hurtAudioReady = false;
  bool _enemyBurstAudioReady = false;
  final Map<SurvivorWeaponType, bool> _weaponHitAudioReady =
      <SurvivorWeaponType, bool>{};
  bool _isSessionReady = false;

  static const double _dashDirectionBufferDuration = 0.18;

  bool get isSessionReady => _isSessionReady;
  Player? get playerOrNull => _isSessionReady ? player : null;
  int get maxLevelUpRerolls => startingLevelUpRerolls;
  bool get canRerollLevelUpChoices =>
      isLevelingUp &&
      !gameOver &&
      levelUpRerollsRemaining > 0 &&
      _currentLevelUpChoices.isNotEmpty;
  double get enemySpeedPhaseMultiplier {
    final minutes = elapsedTime / 60;
    if (minutes < 10) {
      return 0.75;
    }
    if (minutes < 20) {
      return 1.25;
    }
    return 1.0;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _initializeAudio();

    solidObstacleRects = mapConfig.obstacles
        .where((obstacle) => obstacle.type.isSolid)
        .map((obstacle) => obstacle.toWorldRect(mapConfig))
        .toList(growable: false);
    mireRects = mapConfig.obstacles
        .where((obstacle) => obstacle.type == SurvivorMapObstacleType.mire)
        .map((obstacle) => obstacle.toWorldRect(mapConfig))
        .toList(growable: false);

    camera.viewfinder.anchor = Anchor.center;
    world.add(GridBackground());
    world.add(MapObstacleLayerComponent());

    player = Player(
      characterConfig: characterConfig,
      weaponConfig: weaponConfig,
    );
    world.add(player);
    camera.follow(player);

    joystick = JoystickComponent(
      priority: 100,
      margin: const EdgeInsets.only(left: 32, bottom: 32),
      background: CircleComponent(
        radius: 56,
        paint: Paint()..color = const Color(0x558BC34A),
      ),
      knob: CircleComponent(
        radius: 22,
        paint: Paint()..color = const Color(0xDDF1F8E9),
      ),
    );
    camera.viewport.add(joystick);

    experienceHud = ExperienceHudComponent(
      position: Vector2(20, 18),
      size: Vector2(340, 58),
    );
    camera.viewport.add(experienceHud);

    dashHud = DashCooldownHud(
      position: Vector2(20, 86),
      size: Vector2(340, 34),
    );
    camera.viewport.add(dashHud);

    statsText = TextComponent(
      position: Vector2(20, 130),
      priority: 100,
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    camera.viewport.add(statsText);

    timerText = TextComponent(
      position: Vector2(size.x / 2, 18),
      priority: 100,
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFFFFF3C4),
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
    camera.viewport.add(timerText);

    runInfoText = TextComponent(
      position: Vector2(size.x / 2, 52),
      priority: 100,
      anchor: Anchor.topCenter,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
    camera.viewport.add(runInfoText);

    hintText = TextComponent(
      position: Vector2(20, 156),
      priority: 100,
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
    );
    camera.viewport.add(hintText);

    miniMap = MiniMapComponent(
      size: Vector2(160, 160),
      position: Vector2(size.x - 180, 20),
    );
    camera.viewport.add(miniMap);

    gameOverOverlay = GameOverOverlay();
    camera.viewport.add(gameOverOverlay);

    _spawnInitialTreasureChest();
    _isSessionReady = true;
    _refreshHud();
  }

  @override
  void update(double dt) {
    final simulationDt = dt.clamp(0.0, _maxSimulationDt).toDouble();
    super.update(simulationDt);

    _hurtFeedbackTimer = math.max(0, _hurtFeedbackTimer - simulationDt);
    _enemyHitAudioCooldown = math.max(0, _enemyHitAudioCooldown - simulationDt);
    _enemyBurstAudioCooldown = math.max(
      0,
      _enemyBurstAudioCooldown - simulationDt,
    );
    if (_suppressDashWhileSpaceHeld &&
        !HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.space,
        )) {
      _suppressDashWhileSpaceHeld = false;
    }
    miniMap.position.setValues(size.x - 180, 20);
    timerText.position.setValues(size.x / 2, 18);
    runInfoText.position.setValues(size.x / 2, 52);
    gameOverOverlay.position.setValues(size.x / 2, size.y / 2);

    if (gameOver || isLevelingUp) {
      player.cancelDash();
      player.moveInput.setZero();
      _refreshHud();
      return;
    }

    elapsedTime += simulationDt;
    if (elapsedTime >= runDurationSeconds) {
      elapsedTime = runDurationSeconds;
      onPlayerVictory();
      _refreshHud();
      return;
    }
    spawnTimer -= simulationDt;
    _treasureChestSpawnTimer -= simulationDt;

    final movement = _movementVector();
    player.moveInput.setFrom(movement);
    if (movement.length2 > 0) {
      _lastMovementDirection.setFrom(movement.normalized());
      _movementDirectionBuffer = 0;
    } else {
      _movementDirectionBuffer += simulationDt;
    }
    player.updateCombat(simulationDt, this);
    player.regenerate(simulationDt);

    if (spawnTimer <= 0) {
      _spawnEnemyWave();
      spawnTimer = math.max(
        0.18,
        (0.9 - elapsedTime * 0.012) / mapConfig.spawnRateMultiplier,
      );
    }

    if (_spawnedTreasureChestCount < _maxTreasureChestsPerRun &&
        _treasureChestSpawnTimer <= 0) {
      if (_spawnTreasureChest()) {
        _treasureChestSpawnTimer = _treasureChestIntervalSeconds;
      } else {
        _treasureChestSpawnTimer = 6;
      }
    }

    _resolveCollisions(simulationDt);
    _refreshHud();
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      _keysPressed.add(event.logicalKey);
    } else if (event is KeyUpEvent) {
      _keysPressed.remove(event.logicalKey);
    }

    if (_suppressDashWhileSpaceHeld &&
        event.logicalKey == LogicalKeyboardKey.space) {
      if (event is KeyUpEvent) {
        _suppressDashWhileSpaceHeld = false;
      }
      return KeyEventResult.handled;
    }

    if (!gameOver &&
        !isLevelingUp &&
        !paused &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      player.cancelDash();
      onPauseRequested?.call();
      return KeyEventResult.handled;
    }

    if (!gameOver &&
        !isLevelingUp &&
        !paused &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.space) {
      player.tryDash(_dashInputVector());
      return KeyEventResult.handled;
    }

    if (gameOver &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyR) {
      resetRun();
      onRunEnded?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  void suppressDashWhileSpaceHeld() {
    _suppressDashWhileSpaceHeld = true;
  }

  Vector2 _movementVector() {
    final movement = Vector2.zero();

    if (_keysPressed.contains(LogicalKeyboardKey.keyA) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      movement.x -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyD) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      movement.x += 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyW) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      movement.y -= 1;
    }
    if (_keysPressed.contains(LogicalKeyboardKey.keyS) ||
        _keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      movement.y += 1;
    }

    movement.add(joystick.relativeDelta);
    movement.add(Vector2(gamepad.moveX, gamepad.moveY));
    if (movement.length2 > 1) {
      movement.normalize();
    }
    return movement;
  }

  Vector2 _dashInputVector() {
    final movement = _movementVector();
    if (movement.length2 > 0) {
      return movement;
    }
    if (player.moveInput.length2 > 0) {
      return player.moveInput.clone();
    }
    if (_movementDirectionBuffer <= _dashDirectionBufferDuration) {
      return _lastMovementDirection.clone();
    }
    return Vector2.zero();
  }

  void _spawnEnemyWave() {
    final enemiesToSpawn = math.max(
      1,
      ((1 + elapsedTime ~/ 25) * mapConfig.waveDensity).round(),
    );
    final currentScreenEnemyCount = _screenEnemyCount();
    final remainingCapacity = _screenEnemyCap() - currentScreenEnemyCount;
    if (remainingCapacity <= 0) {
      return;
    }
    final spawnCount = math.min(enemiesToSpawn, remainingCapacity);

    for (var i = 0; i < spawnCount; i++) {
      final spawn = _screenEdgeSpawnPosition();
      final scale = (1 + elapsedTime * 0.025) * mapConfig.enemyHealthMultiplier;

      world.add(
        Enemy(
          position: spawn,
          radius:
              enemyMinRadius +
              random.nextDouble() * (enemyMaxRadius - enemyMinRadius),
          health: 16 * scale,
          speed:
              (70 + random.nextDouble() * 35 + elapsedTime * 1.2) *
              0.5 *
              mapConfig.enemySpeedMultiplier,
          touchDps: 8 + elapsedTime * 0.35,
          appearanceIndex: random.nextInt(_EnemyPixelArt.variantCount),
        ),
      );
    }
  }

  int _screenEnemyCap() {
    final minutes = elapsedTime / 60;
    if (minutes < 5) {
      return 50;
    }
    if (minutes < 10) {
      return 100;
    }
    if (minutes < 15) {
      return 150;
    }
    return 200;
  }

  int _screenEnemyCount() {
    if (size.x <= 0 || size.y <= 0) {
      return world.children.whereType<Enemy>().length;
    }

    const padding = 96.0;
    final halfW = size.x / 2 + padding;
    final halfH = size.y / 2 + padding;
    final left = player.position.x - halfW;
    final right = player.position.x + halfW;
    final top = player.position.y - halfH;
    final bottom = player.position.y + halfH;

    var count = 0;
    for (final enemy in world.children.whereType<Enemy>()) {
      final x = enemy.position.x;
      final y = enemy.position.y;
      if (x >= left && x <= right && y >= top && y <= bottom) {
        count += 1;
      }
    }
    return count;
  }

  Vector2 _screenEdgeSpawnPosition() {
    final bounds = mapConfig.worldBounds;

    if (size.x <= 0 || size.y <= 0) {
      final angle = random.nextDouble() * math.pi * 2;
      final distance = 520 + random.nextDouble() * 120;
      final fallback =
          player.position +
          Vector2(math.cos(angle) * distance, math.sin(angle) * distance);
      return _clampSpawnToMap(fallback);
    }

    const margin = 72.0;
    final halfW = size.x / 2;
    final halfH = size.y / 2;
    for (var attempt = 0; attempt < 24; attempt++) {
      final side = random.nextInt(4);
      late final Vector2 spawn;

      switch (side) {
        case 0:
          spawn =
              player.position +
              Vector2(
                -halfW - margin,
                random.nextDouble() * (size.y + margin) - (halfH + margin / 2),
              );
          break;
        case 1:
          spawn =
              player.position +
              Vector2(
                halfW + margin,
                random.nextDouble() * (size.y + margin) - (halfH + margin / 2),
              );
          break;
        case 2:
          spawn =
              player.position +
              Vector2(
                random.nextDouble() * (size.x + margin) - (halfW + margin / 2),
                -halfH - margin,
              );
          break;
        default:
          spawn =
              player.position +
              Vector2(
                random.nextDouble() * (size.x + margin) - (halfW + margin / 2),
                halfH + margin,
              );
          break;
      }

      final clamped = _clampSpawnToMap(spawn);
      if (!_isCircleBlocked(clamped, enemyMaxRadius)) {
        return clamped;
      }
    }

    return Vector2(
      bounds.center.dx,
      (player.position.y - halfH - margin).clamp(
        bounds.top + enemyMaxRadius,
        bounds.bottom - enemyMaxRadius,
      ),
    );
  }

  Vector2 _clampSpawnToMap(Vector2 position) {
    final bounds = mapConfig.worldBounds;
    return Vector2(
      position.x
          .clamp(bounds.left + enemyMaxRadius, bounds.right - enemyMaxRadius)
          .toDouble(),
      position.y
          .clamp(bounds.top + enemyMaxRadius, bounds.bottom - enemyMaxRadius)
          .toDouble(),
    );
  }

  void fireProjectile(
    Vector2 origin,
    Vector2 direction,
    EquippedWeapon weapon,
  ) {
    final normalizedDirection = direction.length2 == 0
        ? Vector2(0, -1)
        : direction.normalized();
    final shotCount = math.max(1, weapon.projectileCount);
    final angleCenter = (shotCount - 1) / 2;

    for (var i = 0; i < shotCount; i++) {
      final angleOffset = (i - angleCenter) * (math.pi / 18);
      final shotDirection = _rotateVector(normalizedDirection, angleOffset);
      world.add(
        Projectile(
          position: origin.clone(),
          velocity: shotDirection * weapon.projectileSpeed,
          damage: weapon.damage,
          life: weapon.projectileLifetime,
          remainingPierces: weapon.projectilePierce,
          weaponType: weapon.config.weaponType,
          projectileColor: weapon.config.projectileColor,
          radius: weapon.projectileRadius,
          spinRate: weapon.config.projectileSpinRate,
        ),
      );
    }
  }

  Enemy? findClosestEnemy(Vector2 from) {
    Enemy? closest;
    var bestDistance = double.infinity;

    for (final enemy in world.children.whereType<Enemy>()) {
      final distance = from.distanceToSquared(enemy.position);
      if (distance < bestDistance) {
        bestDistance = distance;
        closest = enemy;
      }
    }
    return closest;
  }

  void addExperience(double value) {
    final adjustedValue = value * player.experienceGainMultiplier;
    player.experience += adjustedValue;
    while (player.experience >= player.experienceToNextLevel) {
      player.experience -= player.experienceToNextLevel;
      player.level += 1;
      player.experienceToNextLevel = (player.experienceToNextLevel * 1.35)
          .roundToDouble();
      pendingLevelUps += 1;
    }

    if (!isLevelingUp && pendingLevelUps > 0) {
      _presentNextLevelUp();
    }
  }

  void addGold(int value) {
    if (value <= 0) {
      return;
    }
    runGold += value;
    _refreshHud();
  }

  void healPlayer(double amount) {
    if (amount <= 0) {
      return;
    }
    player.health = math.min(player.maxHealth, player.health + amount);
    _refreshHud();
  }

  void applyUpgrade(UpgradeChoice choice) {
    switch (choice.category) {
      case UpgradeChoiceCategory.playerStat:
        final type = choice.type;
        if (type == null) {
          break;
        }
        final currentLevel = _upgradeLevels[type] ?? 0;
        if (currentLevel >= 5) {
          break;
        }
        _upgradeLevels[type] = currentLevel + 1;
        switch (type) {
          case UpgradeType.moveSpeed:
            player.speed += 24;
            break;
          case UpgradeType.defense:
            player.defense = math.min(0.6, player.defense + 0.12);
            break;
          case UpgradeType.hpRegen:
            player.healthRegen += 2.2;
            break;
          case UpgradeType.pickupRange:
            player.pickupRadius += 26;
            break;
          case UpgradeType.weaponRange:
            player.applyGlobalWeaponRangeUpgrade();
            break;
          case UpgradeType.experienceGain:
            player.experienceGainMultiplier += 0.2;
            break;
        }
        break;
      case UpgradeChoiceCategory.unlockWeapon:
        final weapon = choice.weaponConfig;
        if (weapon != null) {
          player.equipWeapon(weapon);
        }
        break;
      case UpgradeChoiceCategory.weaponUpgrade:
        final weapon = choice.weaponConfig;
        final stat = choice.weaponUpgradeStat;
        if (weapon != null && stat != null) {
          player.applyWeaponUpgrade(weapon, stat);
        }
        break;
    }

    isLevelingUp = false;
    _currentLevelUpChoices.clear();
    onLevelUpChoicesChanged?.call(const <UpgradeChoice>[]);

    if (pendingLevelUps > 0) {
      _presentNextLevelUp();
      return;
    }

    resumeEngine();
    _refreshHud();
  }

  bool rerollLevelUpChoices() {
    if (!canRerollLevelUpChoices) {
      return false;
    }

    final nextChoices = _rollUpgradeChoices();
    if (nextChoices.isEmpty) {
      return false;
    }

    levelUpRerollsRemaining -= 1;
    player.cancelDash();
    _currentLevelUpChoices
      ..clear()
      ..addAll(nextChoices);

    onLevelUpChoicesChanged?.call(
      List<UpgradeChoice>.unmodifiable(_currentLevelUpChoices),
    );
    _refreshHud();
    return true;
  }

  void _presentNextLevelUp() {
    if (pendingLevelUps <= 0 || gameOver) {
      return;
    }

    final nextChoices = _rollUpgradeChoices();
    if (nextChoices.isEmpty) {
      pendingLevelUps = 0;
      isLevelingUp = false;
      _currentLevelUpChoices.clear();
      onLevelUpChoicesChanged?.call(const <UpgradeChoice>[]);
      resumeEngine();
      _refreshHud();
      return;
    }

    pendingLevelUps -= 1;
    isLevelingUp = true;
    player.cancelDash();
    pauseEngine();

    _currentLevelUpChoices
      ..clear()
      ..addAll(nextChoices);

    onLevelUpChoicesChanged?.call(
      List<UpgradeChoice>.unmodifiable(_currentLevelUpChoices),
    );
    _refreshHud();
  }

  List<UpgradeChoice> _rollUpgradeChoices() {
    final pool = <UpgradeChoice>[];

    for (final type in UpgradeType.values) {
      final nextLevel = (_upgradeLevels[type] ?? 0) + 1;
      if (nextLevel > 5) {
        continue;
      }
      switch (type) {
        case UpgradeType.moveSpeed:
          pool.add(UpgradeChoice.moveSpeed(nextLevel));
          break;
        case UpgradeType.defense:
          pool.add(UpgradeChoice.defense(nextLevel));
          break;
        case UpgradeType.hpRegen:
          pool.add(UpgradeChoice.hpRegen(nextLevel));
          break;
        case UpgradeType.pickupRange:
          pool.add(UpgradeChoice.pickupRange(nextLevel));
          break;
        case UpgradeType.weaponRange:
          pool.add(UpgradeChoice.weaponRange(nextLevel));
          break;
        case UpgradeType.experienceGain:
          pool.add(UpgradeChoice.experienceGain(nextLevel));
          break;
      }
    }

    if (player.canEquipMoreWeapons) {
      for (final weapon in survivorWeapons) {
        if (player.hasWeapon(weapon.id)) {
          continue;
        }
        pool.add(UpgradeChoice.unlockWeapon(weapon));
      }
    }

    for (final weapon in player.weapons) {
      if (!weapon.canLevelUp) {
        continue;
      }
      final stats = weapon.upgradePool()..shuffle(random);
      if (stats.isEmpty) {
        continue;
      }
      pool.add(UpgradeChoice.weaponUpgrade(weapon, stats.first));
    }

    pool.shuffle(random);
    return pool.take(3).toList(growable: false);
  }

  Future<void> _initializeAudio() async {
    FlameAudio.audioCache.prefix = 'assets/audio/';
    _hurtAudioReady = await _loadAudioAsset('hurt_moan.wav');
    _enemyBurstAudioReady = await _loadAudioAsset('enemy_burst.wav');
    for (final entry in _weaponHitAudioAssets.entries) {
      _weaponHitAudioReady[entry.key] = await _loadAudioAsset(entry.value);
    }
  }

  Future<bool> _loadAudioAsset(String asset) async {
    try {
      await FlameAudio.audioCache.load(asset);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _playHurtMoan() async {
    if (!_hurtAudioReady) {
      return;
    }

    try {
      await FlameAudio.play('hurt_moan.wav', volume: 0.58);
    } catch (_) {}
  }

  Future<void> _playWeaponHitSound(SurvivorWeaponType weaponType) async {
    final asset = _weaponHitAudioAssets[weaponType];
    final ready = _weaponHitAudioReady[weaponType] ?? false;
    if (asset == null || !ready || _enemyHitAudioCooldown > 0) {
      return;
    }

    _enemyHitAudioCooldown = 0.055;
    try {
      final volume = switch (weaponType) {
        SurvivorWeaponType.spear => 0.34,
        SurvivorWeaponType.scythe => 0.36,
        SurvivorWeaponType.bow => 0.31,
        SurvivorWeaponType.talisman => 0.3,
        SurvivorWeaponType.scream => 0.28,
        SurvivorWeaponType.ancestor => 0.29,
      };
      await FlameAudio.play(asset, volume: volume);
    } catch (_) {}
  }

  Future<void> _playEnemyBurstSound() async {
    if (!_enemyBurstAudioReady || _enemyBurstAudioCooldown > 0) {
      return;
    }

    _enemyBurstAudioCooldown = 0.08;
    try {
      await FlameAudio.play('enemy_burst.wav', volume: 0.38);
    } catch (_) {}
  }

  void _handlePlayerDamaged(double damageTaken, Vector2 impactDirection) {
    if (damageTaken <= 0) {
      return;
    }

    player.notifyHit();

    if (_hurtFeedbackTimer > 0) {
      return;
    }

    _hurtFeedbackTimer = 0.18;
    world.add(
      BloodBurstEffect(
        position: player.position.clone(),
        direction: impactDirection,
        random: random,
        intensity: (0.75 + damageTaken / 14).clamp(0.85, 1.55),
      ),
    );
    unawaited(_playHurtMoan());
  }

  void _showDamageNumber(Enemy enemy, double damage, Color color) {
    final rounded = damage.roundToDouble();
    final label = (damage - rounded).abs() < 0.05
        ? rounded.toStringAsFixed(0)
        : damage.toStringAsFixed(1);
    final displayColor = Color.lerp(color, Colors.white, 0.18)!;

    world.add(
      DamageNumberEffect(
        position:
            enemy.position +
            Vector2(
              (random.nextDouble() - 0.5) * enemy.radius * 0.44,
              -(enemy.radius + 20),
            ),
        label: label,
        color: displayColor,
        random: random,
      ),
    );
  }

  void _showEnemyHitFeedback(
    Enemy enemy,
    Vector2 direction,
    double damage, {
    required bool killed,
    required SurvivorWeaponType weaponType,
  }) {
    final burstDirection = direction.length2 == 0
        ? enemy.position - player.position
        : direction;
    final spawnOffset = burstDirection.length2 == 0
        ? Vector2.zero()
        : burstDirection.normalized() * (enemy.radius * 0.12);

    world.add(
      BloodBurstEffect.rainbow(
        position: enemy.position + spawnOffset,
        direction: burstDirection,
        random: random,
        intensity: (0.72 + damage / 13).clamp(0.82, 1.38),
      ),
    );
    world.add(
      RainbowImpactEffect(
        position: enemy.position + spawnOffset,
        direction: burstDirection,
        random: random,
        intensity: (0.8 + damage / 18).clamp(0.9, 1.3),
      ),
    );

    unawaited(_playWeaponHitSound(weaponType));
    if (killed) {
      unawaited(_playEnemyBurstSound());
    }
  }

  void onPlayerDeath() {
    gameOver = true;
    playerWon = false;
    isLevelingUp = false;
    pendingLevelUps = 0;
    player.cancelDash();
    _currentLevelUpChoices.clear();
    onLevelUpChoicesChanged?.call(const <UpgradeChoice>[]);
    player.moveInput.setZero();
    gameOverOverlay.isVisible = false;
    hintText.text = 'Run over. Press R to restart.';
    onRunEnded?.call();
  }

  void onPlayerVictory() {
    gameOver = true;
    playerWon = true;
    isLevelingUp = false;
    pendingLevelUps = 0;
    player.cancelDash();
    _currentLevelUpChoices.clear();
    onLevelUpChoicesChanged?.call(const <UpgradeChoice>[]);
    player.moveInput.setZero();
    gameOverOverlay.isVisible = false;
    hintText.text = '30:00 cleared. Press R to start a new run.';
    onRunEnded?.call();
  }

  void resetRun() {
    for (final component in world.children.toList()) {
      if (component is Enemy ||
          component is Projectile ||
          component is XpShard ||
          component is GoldPickup ||
          component is HealthPotionPickup ||
          component is TreasureChest) {
        component.removeFromParent();
      }
    }

    elapsedTime = 0;
    spawnTimer = 0;
    _treasureChestSpawnTimer = _treasureChestIntervalSeconds;
    gameOver = false;
    playerWon = false;
    isLevelingUp = false;
    pendingLevelUps = 0;
    levelUpRerollsRemaining = startingLevelUpRerolls;
    _hurtFeedbackTimer = 0;
    _enemyHitAudioCooldown = 0;
    _enemyBurstAudioCooldown = 0;
    _movementDirectionBuffer = 999;
    _lastMovementDirection.setValues(0, -1);
    runGold = 0;
    _spawnedTreasureChestCount = 0;
    _currentLevelUpChoices.clear();
    _keysPressed.clear();
    for (final type in UpgradeType.values) {
      _upgradeLevels[type] = 0;
    }
    onLevelUpChoicesChanged?.call(const <UpgradeChoice>[]);
    player.reset();
    _spawnInitialTreasureChest();
    gameOverOverlay.isVisible = false;
    camera.viewfinder.position = player.position.clone();
    resumeEngine();
    _refreshHud();
  }

  void _resolveCollisions(double dt) {
    final enemies = world.children.whereType<Enemy>().toList(growable: false);
    final projectiles = world.children.whereType<Projectile>().toList(
      growable: false,
    );
    final talismans = world.children.whereType<OrbitingTalisman>().toList(
      growable: false,
    );
    final ancestors = world.children.whereType<AncestorSpirit>().toList(
      growable: false,
    );
    final scream = player.screamAura;
    final shards = world.children.whereType<XpShard>().toList(growable: false);
    final goldPickups = world.children.whereType<GoldPickup>().toList(
      growable: false,
    );
    final potionPickups = world.children.whereType<HealthPotionPickup>().toList(
      growable: false,
    );
    final treasureChests = world.children.whereType<TreasureChest>().toList(
      growable: false,
    );

    _resolveMapCollisions(enemies, projectiles);

    for (final projectile in projectiles) {
      for (final enemy in enemies) {
        if (projectile.shouldRemove ||
            enemy.shouldRemove ||
            projectile.hitEnemies.contains(enemy)) {
          continue;
        }

        final hitDistance = projectile.radius + enemy.radius;
        if (projectile.position.distanceToSquared(enemy.position) <=
            hitDistance * hitDistance) {
          final damage = projectile.damage;
          final nextHealth = enemy.health - damage;
          final killed = nextHealth <= 0;
          _showEnemyHitFeedback(
            enemy,
            projectile.velocity,
            damage,
            killed: killed,
            weaponType: projectile.weaponType,
          );
          _showDamageNumber(enemy, damage, projectile.projectileColor);
          enemy.health = nextHealth;
          projectile.hitEnemies.add(enemy);
          if (projectile.remainingPierces > 0) {
            projectile.remainingPierces -= 1;
          } else {
            projectile.shouldRemove = true;
          }

          if (killed) {
            enemy.shouldRemove = true;
            _spawnEnemyLoot(enemy.position.clone());
          }
        }
      }
    }

    for (final talisman in talismans) {
      for (final enemy in enemies) {
        if (enemy.shouldRemove) {
          continue;
        }

        final hitDistance = talisman.radius + enemy.radius;
        if (talisman.position.distanceToSquared(enemy.position) >
            hitDistance * hitDistance) {
          continue;
        }
        if (!talisman.tryHit(enemy)) {
          continue;
        }

        final knockbackDirection = enemy.position - talisman.position;
        final damage = talisman.damage;
        final nextHealth = enemy.health - damage;
        final killed = nextHealth <= 0;
        _showEnemyHitFeedback(
          enemy,
          knockbackDirection,
          damage,
          killed: killed,
          weaponType: SurvivorWeaponType.talisman,
        );
        _showDamageNumber(enemy, damage, talisman.displayColor);
        enemy.health = nextHealth;
        if (knockbackDirection.length2 > 0) {
          enemy.position += knockbackDirection.normalized() * 18;
        }
        if (killed) {
          enemy.shouldRemove = true;
          _spawnEnemyLoot(enemy.position.clone());
        }
      }
    }

    for (final ancestor in ancestors) {
      for (final enemy in enemies) {
        if (enemy.shouldRemove) {
          continue;
        }

        final hitDistance = ancestor.radius + enemy.radius * 0.85;
        if (ancestor.position.distanceToSquared(enemy.position) >
            hitDistance * hitDistance) {
          continue;
        }
        if (!ancestor.tryHit(enemy)) {
          continue;
        }

        final damage = ancestor.damage;
        final nextHealth = enemy.health - damage;
        final killed = nextHealth <= 0;
        _showEnemyHitFeedback(
          enemy,
          enemy.position - ancestor.position,
          damage,
          killed: killed,
          weaponType: SurvivorWeaponType.ancestor,
        );
        _showDamageNumber(enemy, damage, ancestor.displayColor);
        enemy.health = nextHealth;
        if (killed) {
          enemy.shouldRemove = true;
          _spawnEnemyLoot(enemy.position.clone());
        }
      }
    }

    if (scream != null) {
      final screamCenter = scream.owner.position;
      for (final enemy in enemies) {
        if (enemy.shouldRemove) {
          continue;
        }

        final hitDistance = scream.radius + enemy.radius * 0.7;
        if (screamCenter.distanceToSquared(enemy.position) >
            hitDistance * hitDistance) {
          continue;
        }
        if (!scream.tryHit(enemy)) {
          continue;
        }

        final damage = scream.damage;
        final nextHealth = enemy.health - damage;
        final killed = nextHealth <= 0;
        _showEnemyHitFeedback(
          enemy,
          enemy.position - screamCenter,
          damage,
          killed: killed,
          weaponType: SurvivorWeaponType.scream,
        );
        _showDamageNumber(enemy, damage, scream.displayColor);
        enemy.health = nextHealth;
        if (killed) {
          enemy.shouldRemove = true;
          _spawnEnemyLoot(enemy.position.clone());
        }
      }
    }

    for (final enemy in enemies) {
      if (enemy.shouldRemove) {
        enemy.removeFromParent();
        continue;
      }
    }

    var totalDamageTaken = 0.0;
    final impactDirection = Vector2.zero();

    for (final enemy in enemies) {
      if (enemy.shouldRemove) {
        continue;
      }
      if (player.isDashInvulnerable) {
        continue;
      }
      final reach = enemy.touchDamageRadius + player.touchDamageRadius;
      if (enemy.position.distanceToSquared(player.position) <= reach * reach) {
        final damageTaken = enemy.touchDps * (1 - player.defense) * dt;
        totalDamageTaken += damageTaken;
        impactDirection.add(player.position - enemy.position);
      }
    }

    if (totalDamageTaken > 0) {
      player.health -= totalDamageTaken;
      _handlePlayerDamaged(
        totalDamageTaken,
        impactDirection.length2 == 0 ? Vector2(0, -1) : impactDirection,
      );
      if (player.health <= 0) {
        player.health = 0;
        onPlayerDeath();
      }
    }

    for (final shard in shards) {
      final pickupDistance = shard.radius + player.radius + 14;
      if (shard.position.distanceToSquared(player.position) <=
          pickupDistance * pickupDistance) {
        addExperience(shard.value);
        shard.removeFromParent();
      }
    }

    for (final goldPickup in goldPickups) {
      final pickupDistance = goldPickup.radius + player.radius + 14;
      if (goldPickup.position.distanceToSquared(player.position) <=
          pickupDistance * pickupDistance) {
        addGold(goldPickup.value);
        goldPickup.removeFromParent();
      }
    }

    for (final potionPickup in potionPickups) {
      if (player.health >= player.maxHealth) {
        continue;
      }
      final pickupDistance = potionPickup.radius + player.radius + 14;
      if (potionPickup.position.distanceToSquared(player.position) <=
          pickupDistance * pickupDistance) {
        healPlayer(potionPickup.healAmount);
        potionPickup.removeFromParent();
      }
    }

    for (final chest in treasureChests) {
      final pickupDistance =
          TreasureChest.interactionRadius + player.radius + 6;
      if (chest.position.distanceToSquared(player.position) <=
          pickupDistance * pickupDistance) {
        _openTreasureChest(chest);
        chest.removeFromParent();
      }
    }

    for (final projectile in projectiles) {
      if (projectile.shouldRemove) {
        projectile.removeFromParent();
      }
    }
  }

  void _resolveMapCollisions(
    List<Enemy> enemies,
    List<Projectile> projectiles,
  ) {
    player.movementMultiplier = 1;
    _keepCircleInsideMap(player);
    for (final obstacle in solidObstacleRects) {
      _pushCircleOutOfRect(player, obstacle);
    }
    _applyMireSlowdown(player, mireMultiplier: 0.58);

    for (final enemy in enemies) {
      enemy.movementMultiplier = 1;
      _keepCircleInsideMap(enemy);
      for (final obstacle in solidObstacleRects) {
        _pushCircleOutOfRect(enemy, obstacle);
      }
      _applyMireSlowdown(enemy, mireMultiplier: 0.72);
    }

    for (final projectile in projectiles) {
      if (_isCircleBlocked(projectile.position, projectile.radius)) {
        projectile.shouldRemove = true;
      }
    }
  }

  void _keepCircleInsideMap(CircleComponent actor) {
    final bounds = mapConfig.worldBounds;
    actor.position.x = actor.position.x
        .clamp(bounds.left + actor.radius, bounds.right - actor.radius)
        .toDouble();
    actor.position.y = actor.position.y
        .clamp(bounds.top + actor.radius, bounds.bottom - actor.radius)
        .toDouble();
  }

  bool _isCircleBlocked(Vector2 center, double radius) {
    for (final obstacle in solidObstacleRects) {
      if (_circleIntersectsRect(center, radius, obstacle)) {
        return true;
      }
    }
    return false;
  }

  void _applyMireSlowdown(
    CircleComponent actor, {
    required double mireMultiplier,
  }) {
    for (final mire in mireRects) {
      if (!_circleIntersectsRect(actor.position, actor.radius, mire)) {
        continue;
      }
      if (actor case final Player playerActor) {
        playerActor.movementMultiplier = mireMultiplier;
      } else if (actor case final Enemy enemyActor) {
        enemyActor.movementMultiplier = mireMultiplier;
      }
      return;
    }
  }

  bool _circleIntersectsRect(Vector2 center, double radius, Rect rect) {
    final closestX = center.x.clamp(rect.left, rect.right).toDouble();
    final closestY = center.y.clamp(rect.top, rect.bottom).toDouble();
    final dx = center.x - closestX;
    final dy = center.y - closestY;
    return dx * dx + dy * dy < radius * radius;
  }

  void _pushCircleOutOfRect(CircleComponent actor, Rect rect) {
    if (!_circleIntersectsRect(actor.position, actor.radius, rect)) {
      return;
    }

    final closestX = actor.position.x.clamp(rect.left, rect.right).toDouble();
    final closestY = actor.position.y.clamp(rect.top, rect.bottom).toDouble();
    final dx = actor.position.x - closestX;
    final dy = actor.position.y - closestY;
    final distanceSquared = dx * dx + dy * dy;

    if (distanceSquared > 0.0001) {
      final distance = math.sqrt(distanceSquared);
      final overlap = actor.radius - distance;
      actor.position.add(
        Vector2(dx / distance * overlap, dy / distance * overlap),
      );
      return;
    }

    final pushLeft = (actor.position.x - rect.left).abs();
    final pushRight = (rect.right - actor.position.x).abs();
    final pushTop = (actor.position.y - rect.top).abs();
    final pushBottom = (rect.bottom - actor.position.y).abs();
    final smallest = math.min(
      math.min(pushLeft, pushRight),
      math.min(pushTop, pushBottom),
    );

    if (smallest == pushLeft) {
      actor.position.x = rect.left - actor.radius;
    } else if (smallest == pushRight) {
      actor.position.x = rect.right + actor.radius;
    } else if (smallest == pushTop) {
      actor.position.y = rect.top - actor.radius;
    } else {
      actor.position.y = rect.bottom + actor.radius;
    }
  }

  void _refreshHud() {
    final seconds = elapsedTime.floor();
    final remainingSeconds = math.max(
      0,
      (runDurationSeconds - elapsedTime).ceil(),
    );

    statsText.text = 'HP ${player.health.ceil()}/${player.maxHealth.ceil()}';

    timerText.text = 'SURVIVE ${formatClock(remainingSeconds)} / 30:00';
    runInfoText.text =
        '경과 ${formatClock(seconds)}   처치 ${player.kills}   골드 $runGold';

    if (gameOver) {
      return;
    }

    if (isLevelingUp) {
      hintText.text = 'Level up. Choose one of three cards.';
      return;
    }

    hintText.text = gamepad.isConnected
        ? '30:00까지 버티면 승리. Space 대쉬 중 잠깐 무적, 패드 Start 일시정지.'
        : '30:00까지 버티면 승리. 이동 중 Space 대쉬, 대쉬 중 잠깐 무적.';
  }

  String formatClock(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final remain = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remain.toString().padLeft(2, '0')}';
  }

  Vector2 _rotateVector(Vector2 vector, double radians) {
    final cosValue = math.cos(radians);
    final sinValue = math.sin(radians);
    return Vector2(
      vector.x * cosValue - vector.y * sinValue,
      vector.x * sinValue + vector.y * cosValue,
    );
  }

  void _spawnEnemyLoot(Vector2 position) {
    if (random.nextBool()) {
      world.add(XpShard(position: position, value: 8));
      return;
    }

    world.add(GoldPickup(position: position, value: random.nextInt(5) + 1));
  }

  void _spawnInitialTreasureChest() {
    _spawnedTreasureChestCount = 0;
    _treasureChestSpawnTimer = _treasureChestIntervalSeconds;
    _spawnTreasureChest();
  }

  bool _spawnTreasureChest() {
    if (_spawnedTreasureChestCount >= _maxTreasureChestsPerRun) {
      return false;
    }

    final spawn = _randomTreasureChestPosition();
    if (spawn == null) {
      return false;
    }

    world.add(TreasureChest(position: spawn));
    _spawnedTreasureChestCount += 1;
    return true;
  }

  Vector2? _randomTreasureChestPosition() {
    final bounds = mapConfig.worldBounds;
    const margin = 96.0;
    const minDistanceFromPlayer = 220.0;

    for (var attempt = 0; attempt < 60; attempt++) {
      final spawn = Vector2(
        bounds.left +
            margin +
            random.nextDouble() * (bounds.width - margin * 2),
        bounds.top +
            margin +
            random.nextDouble() * (bounds.height - margin * 2),
      );

      if ((spawn - player.position).length < minDistanceFromPlayer) {
        continue;
      }
      if (_isCircleBlocked(spawn, TreasureChest.interactionRadius)) {
        continue;
      }

      var overlapsExistingChest = false;
      final chestSpacing = TreasureChest.interactionRadius * 3.2;
      final chestSpacingSquared = chestSpacing * chestSpacing;
      for (final chest in world.children.whereType<TreasureChest>()) {
        if (spawn.distanceToSquared(chest.position) < chestSpacingSquared) {
          overlapsExistingChest = true;
          break;
        }
      }
      if (overlapsExistingChest) {
        continue;
      }

      return spawn;
    }

    return null;
  }

  void _openTreasureChest(TreasureChest chest) {
    final rewardPosition = chest.position.clone();
    final shouldDropPotion =
        player.health < player.maxHealth && random.nextBool();

    if (shouldDropPotion) {
      world.add(HealthPotionPickup(position: rewardPosition, healAmount: 30));
      return;
    }

    world.add(
      GoldPickup(position: rewardPosition, value: random.nextInt(5) + 1),
    );
  }
}
