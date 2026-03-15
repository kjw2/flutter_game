part of 'survivor_game.dart';

class EquippedWeapon {
  EquippedWeapon({
    required this.config,
    required this.characterBaseDamage,
    required this.characterBaseAttackInterval,
  }) {
    resetToBase();
  }

  final SurvivorWeaponConfig config;
  final double characterBaseDamage;
  final double characterBaseAttackInterval;

  int level = 1;
  double attackTimer = 0;
  double damage = 0;
  double attackInterval = 0;
  double projectileSpeed = 0;
  double projectileLifetime = 0;
  double projectileRadius = 0;
  int projectileCount = 0;
  int projectilePierce = 0;
  int talismanCount = 0;
  int ancestorCount = 0;
  double orbitRadiusBonus = 0;
  double ancestorRangeBonus = 0;

  bool get isTalisman => config.weaponType == SurvivorWeaponType.talisman;
  bool get isScream => config.weaponType == SurvivorWeaponType.scream;
  bool get isAncestor => config.weaponType == SurvivorWeaponType.ancestor;
  bool get canLevelUp => level < 5;
  double get fireRate => 1 / attackInterval;
  double get orbitRadius => Player.baseRadius * 2 + orbitRadiusBonus;
  double get screamRadius => projectileRadius;
  double get ancestorRange => Player.baseRadius * 5 + ancestorRangeBonus;

  void resetToBase() {
    level = 1;
    attackTimer = 0;
    attackInterval =
        (characterBaseAttackInterval * config.attackIntervalMultiplier)
            .clamp(0.18, 9.0)
            .toDouble();
    damage = math.max(1, characterBaseDamage + config.damageBonus).toDouble();
    projectileSpeed = config.projectileSpeed;
    projectileLifetime = config.projectileLifetime;
    projectileRadius = config.projectileRadius;
    projectileCount = config.baseProjectileCount;
    projectilePierce = config.basePierce;
    talismanCount = isTalisman ? 1 : 0;
    ancestorCount = isAncestor ? 1 : 0;
    orbitRadiusBonus = 0;
    ancestorRangeBonus = 0;
  }

  List<WeaponUpgradeStat> upgradePool() {
    if (isTalisman || isScream || isAncestor) {
      return <WeaponUpgradeStat>[
        WeaponUpgradeStat.attackPower,
        WeaponUpgradeStat.fireRate,
        WeaponUpgradeStat.attackRange,
      ];
    }

    return <WeaponUpgradeStat>[
      WeaponUpgradeStat.attackPower,
      WeaponUpgradeStat.fireRate,
      WeaponUpgradeStat.attackRange,
      WeaponUpgradeStat.projectileCount,
      WeaponUpgradeStat.projectilePierce,
    ];
  }

  void applyUpgrade(WeaponUpgradeStat stat) {
    if (!canLevelUp) {
      return;
    }

    level += 1;
    if (isTalisman) {
      talismanCount += 1;
    }
    if (isAncestor && level >= 5) {
      ancestorCount = 2;
    }

    switch (stat) {
      case WeaponUpgradeStat.attackPower:
        damage += (isTalisman || isScream || isAncestor) ? 5 : 6;
        break;
      case WeaponUpgradeStat.fireRate:
        attackInterval = math.max(0.16, attackInterval * 0.9);
        attackTimer = math.min(attackTimer, attackInterval);
        break;
      case WeaponUpgradeStat.attackRange:
        if (isTalisman) {
          orbitRadiusBonus += Player.baseRadius * 0.55;
        } else if (isScream) {
          projectileRadius += Player.baseRadius * 0.6;
        } else if (isAncestor) {
          ancestorRangeBonus += Player.baseRadius * 0.7;
        } else {
          projectileLifetime += 0.18;
          projectileSpeed += 10;
        }
        break;
      case WeaponUpgradeStat.projectileCount:
        projectileCount += 1;
        break;
      case WeaponUpgradeStat.projectilePierce:
        projectilePierce += 1;
        break;
    }
  }

  void applyGlobalRangeUpgradeStep() {
    if (isTalisman) {
      orbitRadiusBonus += Player.baseRadius * 0.42;
      projectileRadius += 1.2;
      return;
    }

    if (isScream) {
      projectileRadius += Player.baseRadius * 0.48;
      return;
    }

    if (isAncestor) {
      ancestorRangeBonus += Player.baseRadius * 0.42;
      return;
    }

    projectileLifetime += 0.14;
  }
}

class Player extends CircleComponent with HasGameReference<SurvivorGame> {
  static const double baseRadius = 27;
  static const int maxWeapons = 3;

  Player({required this.characterConfig, required this.weaponConfig})
    : super(
        radius: baseRadius,
        anchor: Anchor.center,
        position: Vector2.zero(),
      ) {
    _initializeWeapons();
    _applyCharacterBaseStats();
  }

  final SurvivorCharacterConfig characterConfig;
  final SurvivorWeaponConfig weaponConfig;
  final Vector2 moveInput = Vector2.zero();
  final Vector2 _dashDirection = Vector2.zero();
  final List<_DashAfterImage> _dashEchoes = <_DashAfterImage>[];
  final List<EquippedWeapon> _weapons = <EquippedWeapon>[];
  final List<OrbitingTalisman> _orbitingTalismans = <OrbitingTalisman>[];
  final List<AncestorSpirit> _ancestorSpirits = <AncestorSpirit>[];
  ScreamAura? _screamAura;
  double _animationTime = 0;
  double _hurtFlashTime = 0;
  double _dashTimeRemaining = 0;
  double _dashCooldownRemaining = 0;
  double _dashInvulnerabilityRemaining = 0;
  double _dashEchoTimer = 0;
  double _groundTrailTimer = 0;
  double _groundTrailSide = 1;
  int _globalWeaponRangeLevel = 0;

  double maxHealth = 100;
  double health = 100;
  double speed = 220;
  int level = 1;
  double experience = 0;
  double experienceToNextLevel = 40;
  double experienceGainMultiplier = 1;
  double defense = 0;
  double healthRegen = 0;
  double pickupRadius = 10;
  double movementMultiplier = 1;
  int kills = 0;
  Vector2 facing = Vector2(0, -1);

  static const double dashCooldownDuration = 5;
  static const double _dashDuration = 0.12;
  static const double _dashInvulnerabilityDuration = 0.2;
  static const double _dashEchoLifetime = 0.22;
  static const double _dashEchoInterval = 0.028;
  static const double _groundTrailInterval = 0.11;

  List<EquippedWeapon> get weapons =>
      List<EquippedWeapon>.unmodifiable(_weapons);
  EquippedWeapon get primaryWeapon => _weapons.first;
  ScreamAura? get screamAura => _screamAura;
  String get equippedWeaponNames =>
      _weapons.map((weapon) => weapon.config.name).join(', ');
  bool get canEquipMoreWeapons => _weapons.length < maxWeapons;
  double get attackInterval => primaryWeapon.attackInterval;
  double get projectileDamage => primaryWeapon.damage;
  double get projectileSpeed => primaryWeapon.projectileSpeed;
  double get projectileLifetime => primaryWeapon.projectileLifetime;
  double get projectileRadius => primaryWeapon.projectileRadius;
  int get projectileCount => primaryWeapon.projectileCount;
  int get projectilePierce => primaryWeapon.projectilePierce;
  double get fireRate => primaryWeapon.fireRate;
  int get globalWeaponRangeLevel => _globalWeaponRangeLevel;
  double get touchDamageRadius => radius * 0.92;

  @override
  void onMount() {
    super.onMount();
    _syncOrbitingTalismans();
    _syncAncestorSpirits();
    _syncScreamAura();
  }

  void _initializeWeapons() {
    _weapons
      ..clear()
      ..add(_createEquippedWeapon(weaponConfig));
  }

  void _applyCharacterBaseStats() {
    maxHealth = characterConfig.maxHealth;
    health = maxHealth;
    speed = characterConfig.moveSpeed;
    pickupRadius = characterConfig.pickupRadius;
  }

  EquippedWeapon _createEquippedWeapon(SurvivorWeaponConfig config) {
    final weapon = EquippedWeapon(
      config: config,
      characterBaseDamage: characterConfig.projectileDamage,
      characterBaseAttackInterval: characterConfig.attackInterval,
    );
    for (var i = 0; i < _globalWeaponRangeLevel; i++) {
      weapon.applyGlobalRangeUpgradeStep();
    }
    return weapon;
  }

  EquippedWeapon? weaponById(String weaponId) {
    for (final weapon in _weapons) {
      if (weapon.config.id == weaponId) {
        return weapon;
      }
    }
    return null;
  }

  bool hasWeapon(String weaponId) => weaponById(weaponId) != null;

  void equipWeapon(SurvivorWeaponConfig config) {
    if (hasWeapon(config.id) || !canEquipMoreWeapons) {
      return;
    }

    _weapons.add(_createEquippedWeapon(config));
    _syncOrbitingTalismans();
    _syncAncestorSpirits();
    _syncScreamAura();
  }

  void applyWeaponUpgrade(SurvivorWeaponConfig config, WeaponUpgradeStat stat) {
    final weapon = weaponById(config.id);
    if (weapon == null) {
      return;
    }
    weapon.applyUpgrade(stat);
    _syncOrbitingTalismans();
    _syncAncestorSpirits();
    _syncScreamAura();
  }

  void reset() {
    for (final talisman in _orbitingTalismans) {
      talisman.removeFromParent();
    }
    _orbitingTalismans.clear();
    for (final ancestor in _ancestorSpirits) {
      ancestor.removeFromParent();
    }
    _ancestorSpirits.clear();
    _screamAura?.removeFromParent();
    _screamAura = null;

    position.setZero();
    _animationTime = 0;
    level = 1;
    experience = 0;
    experienceToNextLevel = 40;
    experienceGainMultiplier = 1;
    _hurtFlashTime = 0;
    _dashTimeRemaining = 0;
    _dashCooldownRemaining = 0;
    _dashInvulnerabilityRemaining = 0;
    _dashEchoTimer = 0;
    _dashDirection.setZero();
    _dashEchoes.clear();
    _groundTrailTimer = 0;
    _groundTrailSide = 1;
    _globalWeaponRangeLevel = 0;
    defense = 0;
    healthRegen = 0;
    movementMultiplier = 1;
    kills = 0;
    facing.setValues(0, -1);
    _applyCharacterBaseStats();
    _initializeWeapons();
    _syncOrbitingTalismans();
    _syncAncestorSpirits();
    _syncScreamAura();
  }

  void applyGlobalWeaponRangeUpgrade() {
    _globalWeaponRangeLevel += 1;
    for (final weapon in _weapons) {
      weapon.applyGlobalRangeUpgradeStep();
    }
    _syncOrbitingTalismans();
    _syncAncestorSpirits();
    _syncScreamAura();
  }

  void _syncOrbitingTalismans() {
    EquippedWeapon? talismanWeapon;
    for (final weapon in _weapons) {
      if (weapon.isTalisman) {
        talismanWeapon = weapon;
        break;
      }
    }

    if (talismanWeapon == null) {
      for (final talisman in _orbitingTalismans) {
        talisman.removeFromParent();
      }
      _orbitingTalismans.clear();
      return;
    }

    final desiredCount = talismanWeapon.talismanCount;
    while (_orbitingTalismans.length > desiredCount) {
      _orbitingTalismans.removeLast().removeFromParent();
    }

    while (_orbitingTalismans.length < desiredCount) {
      final talisman = OrbitingTalisman(
        owner: this,
        weapon: talismanWeapon,
        orbitIndex: _orbitingTalismans.length,
        totalCount: desiredCount,
      );
      _orbitingTalismans.add(talisman);
      if (isMounted) {
        game.world.add(talisman);
      }
    }

    for (var i = 0; i < _orbitingTalismans.length; i++) {
      final talisman = _orbitingTalismans[i];
      talisman.syncWeapon(
        weapon: talismanWeapon,
        orbitIndex: i,
        totalCount: desiredCount,
      );
      if (isMounted && !talisman.isMounted) {
        game.world.add(talisman);
      }
    }
  }

  void _syncAncestorSpirits() {
    EquippedWeapon? ancestorWeapon;
    for (final weapon in _weapons) {
      if (weapon.isAncestor) {
        ancestorWeapon = weapon;
        break;
      }
    }

    if (ancestorWeapon == null) {
      for (final spirit in _ancestorSpirits) {
        spirit.removeFromParent();
      }
      _ancestorSpirits.clear();
      return;
    }

    final desiredCount = ancestorWeapon.ancestorCount;
    while (_ancestorSpirits.length > desiredCount) {
      _ancestorSpirits.removeLast().removeFromParent();
    }

    while (_ancestorSpirits.length < desiredCount) {
      final spirit = AncestorSpirit(
        owner: this,
        weapon: ancestorWeapon,
        spiritIndex: _ancestorSpirits.length,
        totalCount: desiredCount,
      );
      _ancestorSpirits.add(spirit);
      if (isMounted) {
        game.world.add(spirit);
      }
    }

    for (var i = 0; i < _ancestorSpirits.length; i++) {
      final spirit = _ancestorSpirits[i];
      spirit.syncWeapon(
        weapon: ancestorWeapon,
        spiritIndex: i,
        totalCount: desiredCount,
      );
      if (isMounted && !spirit.isMounted) {
        game.world.add(spirit);
      }
    }
  }

  void _syncScreamAura() {
    EquippedWeapon? screamWeapon;
    for (final weapon in _weapons) {
      if (weapon.isScream) {
        screamWeapon = weapon;
        break;
      }
    }

    if (screamWeapon == null) {
      _screamAura?.removeFromParent();
      _screamAura = null;
      return;
    }

    final aura = _screamAura ?? ScreamAura(owner: this, weapon: screamWeapon);
    aura.syncWeapon(screamWeapon);
    _screamAura = aura;
    if (isMounted && !aura.isMounted) {
      add(aura);
    }
  }

  double get dashCooldownRemaining => _dashCooldownRemaining;
  double get dashCooldownProgress =>
      1 - (_dashCooldownRemaining / dashCooldownDuration);
  bool get isDashReady =>
      _dashCooldownRemaining <= 0 && _dashTimeRemaining <= 0;
  bool get isDashing => _dashTimeRemaining > 0;
  bool get isDashInvulnerable => _dashInvulnerabilityRemaining > 0;
  double get dashDistance => radius * 6;
  double get _dashSpeed => dashDistance / _dashDuration;

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
    _hurtFlashTime = math.max(0, _hurtFlashTime - dt);
    _dashCooldownRemaining = math.max(0, _dashCooldownRemaining - dt);
    _dashInvulnerabilityRemaining = math.max(
      0,
      _dashInvulnerabilityRemaining - dt,
    );

    for (final echo in _dashEchoes) {
      echo.life -= dt;
    }
    _dashEchoes.removeWhere((echo) => echo.life <= 0);

    var remainingDt = dt;
    if (_dashTimeRemaining > 0) {
      _dashEchoTimer -= dt;
      while (_dashEchoTimer <= 0) {
        _dashEchoes.add(
          _DashAfterImage(
            position: position.clone(),
            facing: facing.clone(),
            walkFrame: (_animationTime * 8).floor().isOdd,
            life: _dashEchoLifetime,
          ),
        );
        _dashEchoTimer += _dashEchoInterval;
      }

      final dashDt = math.min(remainingDt, _dashTimeRemaining);
      position += _dashDirection * _dashSpeed * dashDt;
      _dashTimeRemaining -= dashDt;
      remainingDt -= dashDt;
      facing = _dashDirection;
      if (_dashTimeRemaining <= 0) {
        _dashTimeRemaining = 0;
      }
    }

    if (_dashTimeRemaining <= 0 && moveInput.length2 > 0 && remainingDt > 0) {
      facing = moveInput.normalized();
      position += facing * speed * movementMultiplier * remainingDt;
      _groundTrailTimer -= remainingDt;
      if (_groundTrailTimer <= 0) {
        _spawnGroundTrail();
        _groundTrailTimer = _groundTrailInterval;
      }
    } else if (!isDashing) {
      _groundTrailTimer = 0;
    }
  }

  @override
  void render(Canvas canvas) {
    for (final echo in _dashEchoes) {
      final opacity = (echo.life / _dashEchoLifetime).clamp(0.0, 1.0);
      final offset = echo.position - position;

      canvas.drawCircle(
        Offset(offset.x, offset.y + radius * 0.2),
        radius + 4,
        Paint()
          ..color = Color.fromARGB(
            (opacity * 46).round().clamp(0, 46),
            92,
            228,
            191,
          ),
      );

      canvas.save();
      canvas.translate(offset.x, offset.y);
      _PlayerPixelArt.render(
        canvas,
        characterId: characterConfig.id,
        facing: echo.facing,
        walkFrame: echo.walkFrame,
        opacity: opacity * 0.42,
      );
      canvas.restore();
    }

    if (isDashing) {
      final alpha = ((_dashTimeRemaining / _dashDuration) * 68).round().clamp(
        0,
        68,
      );
      for (var index = 1; index <= 3; index++) {
        final offset = _dashDirection * -(index * 10.0);
        canvas.drawCircle(
          Offset(offset.x, offset.y),
          radius - index * 2.2,
          Paint()..color = Color.fromARGB(alpha ~/ index, 154, 232, 204),
        );
      }
    }

    if (isDashInvulnerable) {
      final shieldAlpha =
          ((_dashInvulnerabilityRemaining / _dashInvulnerabilityDuration) * 72)
              .round()
              .clamp(0, 72);
      canvas.drawCircle(
        Offset.zero,
        radius + 9,
        Paint()
          ..color = Color.fromARGB(shieldAlpha, 101, 240, 174)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    if (_hurtFlashTime > 0) {
      final flashAlpha = ((_hurtFlashTime / 0.14) * 90).round().clamp(0, 90);
      canvas.drawCircle(
        Offset.zero,
        radius + 7,
        Paint()..color = Color.fromARGB(flashAlpha, 201, 36, 36),
      );
    }

    _PlayerPixelArt.render(
      canvas,
      characterId: characterConfig.id,
      facing: facing,
      walkFrame: moveInput.length2 > 0.02 && (_animationTime * 8).floor().isOdd,
    );
  }

  void notifyHit() {
    _hurtFlashTime = 0.14;
  }

  void _spawnGroundTrail() {
    final lateral = Vector2(-facing.y, facing.x);
    final offset =
        lateral * (_groundTrailSide * radius * 0.28) -
        facing * (radius * 0.34) +
        Vector2(
          (game.random.nextDouble() - 0.5) * radius * 0.14,
          (game.random.nextDouble() - 0.5) * radius * 0.14,
        );
    _groundTrailSide *= -1;
    game.world.add(
      GroundTrailEffect(
        position: position + offset,
        floorType: game.mapConfig.floorType,
        direction: facing.clone(),
        floorColor: game.mapConfig.floorColor,
        detailColor: game.mapConfig.detailColor,
        accentColor: game.mapConfig.accentColor,
        random: game.random,
      ),
    );
  }

  bool tryDash(Vector2 direction) {
    if (!isDashReady) {
      return false;
    }

    final dashVector = direction.length2 > 0
        ? direction.normalized()
        : (moveInput.length2 > 0 ? moveInput.normalized() : Vector2.zero());
    if (dashVector.length2 == 0) {
      return false;
    }

    _dashDirection.setFrom(dashVector);
    _dashTimeRemaining = _dashDuration;
    _dashCooldownRemaining = dashCooldownDuration;
    _dashInvulnerabilityRemaining = _dashInvulnerabilityDuration;
    _dashEchoTimer = 0;
    _dashEchoes
      ..clear()
      ..add(
        _DashAfterImage(
          position: position.clone(),
          facing: dashVector.clone(),
          walkFrame: true,
          life: _dashEchoLifetime,
        ),
      );
    facing = dashVector;
    game.world.add(
      DashBurstEffect(
        position: position.clone(),
        direction: dashVector.clone(),
      ),
    );
    return true;
  }

  void cancelDash() {
    _dashTimeRemaining = 0;
    _dashInvulnerabilityRemaining = 0;
    _dashDirection.setZero();
  }

  void updateCombat(double dt, SurvivorGame game) {
    _syncOrbitingTalismans();
    _syncAncestorSpirits();
    _syncScreamAura();

    for (final weapon in _weapons) {
      if (weapon.isTalisman || weapon.isScream || weapon.isAncestor) {
        continue;
      }

      weapon.attackTimer -= dt;
      if (weapon.attackTimer > 0) {
        continue;
      }

      final target = game.findClosestEnemy(position);
      final direction = target != null
          ? (target.position - position).normalized()
          : facing.normalized();

      game.fireProjectile(
        position + direction * (radius + 10),
        direction,
        weapon,
      );
      weapon.attackTimer = weapon.attackInterval;
    }
  }

  void regenerate(double dt) {
    if (healthRegen <= 0 || health >= maxHealth) {
      return;
    }
    health = math.min(maxHealth, health + healthRegen * dt);
  }
}

class AncestorSpirit extends CircleComponent
    with HasGameReference<SurvivorGame> {
  AncestorSpirit({
    required this.owner,
    required this.weapon,
    required this.spiritIndex,
    required this.totalCount,
  }) : super(
         radius: weapon.projectileRadius + 6,
         anchor: Anchor.center,
         priority: 9,
       );

  final Player owner;
  EquippedWeapon weapon;
  int spiritIndex;
  int totalCount;
  final Map<Enemy, double> _hitCooldowns = <Enemy, double>{};

  double get damage => weapon.damage * 0.5;
  Color get displayColor => weapon.config.projectileColor;
  double get _activityRadius => weapon.ancestorRange;
  double get _moveSpeed => Player.baseRadius * (2.3 + weapon.fireRate * 2.0);

  void syncWeapon({
    required EquippedWeapon weapon,
    required int spiritIndex,
    required int totalCount,
  }) {
    this.weapon = weapon;
    this.spiritIndex = spiritIndex;
    this.totalCount = totalCount;
    radius = weapon.projectileRadius + 6;
  }

  bool tryHit(Enemy enemy) {
    final cooldown = _hitCooldowns[enemy] ?? 0;
    if (cooldown > 0) {
      return false;
    }
    _hitCooldowns[enemy] = math.max(0.08, weapon.attackInterval);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final expired = <Enemy>[];
    _hitCooldowns.forEach((enemy, cooldown) {
      final next = cooldown - dt;
      if (next <= 0 || enemy.isRemoving) {
        expired.add(enemy);
      } else {
        _hitCooldowns[enemy] = next;
      }
    });
    for (final enemy in expired) {
      _hitCooldowns.remove(enemy);
    }

    radius = weapon.projectileRadius + 6;
    final targetEnemy = _findTargetEnemy();
    final targetPoint = targetEnemy?.position ?? _roamingPoint();
    final toTarget = targetPoint - position;

    if (toTarget.length2 > 0) {
      final distance = toTarget.length;
      final step = math.min(distance, _moveSpeed * dt);
      position += toTarget.normalized() * step;
    }

    final fromOwner = position - owner.position;
    if (fromOwner.length > _activityRadius) {
      position.setFrom(
        owner.position + fromOwner.normalized() * _activityRadius,
      );
    }
  }

  Enemy? _findTargetEnemy() {
    Enemy? closest;
    var bestDistance = double.infinity;
    final activityRadiusSquared = _activityRadius * _activityRadius;

    for (final enemy in game.world.children.whereType<Enemy>()) {
      if (enemy.shouldRemove) {
        continue;
      }
      final ownerDistance = owner.position.distanceToSquared(enemy.position);
      if (ownerDistance > activityRadiusSquared) {
        continue;
      }
      final spiritDistance = position.distanceToSquared(enemy.position);
      if (spiritDistance < bestDistance) {
        bestDistance = spiritDistance;
        closest = enemy;
      }
    }
    return closest;
  }

  Vector2 _roamingPoint() {
    final baseAngle = totalCount <= 0
        ? 0.0
        : (spiritIndex / totalCount) * math.pi * 2;
    final angle =
        baseAngle +
        owner._animationTime * (0.55 + weapon.fireRate * 0.14) +
        spiritIndex * 0.6;
    final radiusFactor =
        0.46 + math.sin(owner._animationTime * 1.1 + spiritIndex * 1.7) * 0.16;
    final roamDistance = _activityRadius * radiusFactor.clamp(0.22, 0.68);
    return owner.position +
        Vector2(math.cos(angle) * roamDistance, math.sin(angle) * roamDistance);
  }

  @override
  void render(Canvas canvas) {
    final pulse =
        0.88 +
        math.sin(owner._animationTime * (2.2 + spiritIndex * 0.35)) * 0.1;
    final auraRadius = (radius + 6) * pulse;

    canvas.drawCircle(
      Offset.zero,
      auraRadius,
      Paint()..color = displayColor.withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 1.1,
      Paint()..color = displayColor.withValues(alpha: 0.2),
    );

    final body = Path()
      ..moveTo(0, -radius * 1.15)
      ..quadraticBezierTo(
        radius * 0.7,
        -radius * 0.3,
        radius * 0.62,
        radius * 0.6,
      )
      ..quadraticBezierTo(0, radius * 1.25, -radius * 0.62, radius * 0.6)
      ..quadraticBezierTo(-radius * 0.7, -radius * 0.3, 0, -radius * 1.15)
      ..close();
    canvas.drawPath(
      body,
      Paint()..color = displayColor.withValues(alpha: 0.72),
    );

    canvas.drawCircle(
      Offset(-radius * 0.22, -radius * 0.22),
      radius * 0.12,
      Paint()..color = const Color(0xFF223049),
    );
    canvas.drawCircle(
      Offset(radius * 0.22, -radius * 0.22),
      radius * 0.12,
      Paint()..color = const Color(0xFF223049),
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(0, radius * 0.08),
        width: radius * 0.72,
        height: radius * 0.5,
      ),
      0.1,
      math.pi - 0.2,
      false,
      Paint()
        ..color = const Color(0xFFEDF8FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}

class OrbitingTalisman extends CircleComponent
    with HasGameReference<SurvivorGame> {
  OrbitingTalisman({
    required this.owner,
    required this.weapon,
    required this.orbitIndex,
    required this.totalCount,
  }) : super(
         radius: weapon.projectileRadius + 4,
         anchor: Anchor.center,
         priority: 9,
       );

  final Player owner;
  EquippedWeapon weapon;
  int orbitIndex;
  int totalCount;
  final Map<Enemy, double> _hitCooldowns = <Enemy, double>{};

  void syncWeapon({
    required EquippedWeapon weapon,
    required int orbitIndex,
    required int totalCount,
  }) {
    this.weapon = weapon;
    this.orbitIndex = orbitIndex;
    this.totalCount = totalCount;
    radius = weapon.projectileRadius + 4;
  }

  double get damage => weapon.damage;
  Color get displayColor => weapon.config.projectileColor;

  bool tryHit(Enemy enemy) {
    final cooldown = _hitCooldowns[enemy] ?? 0;
    if (cooldown > 0) {
      return false;
    }
    _hitCooldowns[enemy] = math.max(0.08, weapon.attackInterval * 0.55);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final expired = <Enemy>[];
    _hitCooldowns.forEach((enemy, cooldown) {
      final next = cooldown - dt;
      if (next <= 0 || enemy.isRemoving) {
        expired.add(enemy);
      } else {
        _hitCooldowns[enemy] = next;
      }
    });
    for (final enemy in expired) {
      _hitCooldowns.remove(enemy);
    }

    final angleBase = totalCount <= 0
        ? 0.0
        : (orbitIndex / totalCount) * math.pi * 2;
    final angularSpeed = math.pi * (0.68 + weapon.fireRate * 0.52);
    final baseOrbitDistance = owner.radius + weapon.orbitRadius;
    final minimumOrbitDistance = totalCount <= 1
        ? baseOrbitDistance
        : ((radius * 2 + 10) / (2 * math.sin(math.pi / totalCount)))
              .clamp(baseOrbitDistance, double.infinity)
              .toDouble();
    final orbitDistance = math.max(baseOrbitDistance, minimumOrbitDistance);
    final angle = angleBase + owner._animationTime * angularSpeed;

    position.setFrom(
      owner.position +
          Vector2(
            math.cos(angle) * orbitDistance,
            math.sin(angle) * orbitDistance,
          ),
    );
  }

  @override
  void render(Canvas canvas) {
    final glow = Paint()..color = displayColor.withValues(alpha: 0.24);
    final body = Paint()..color = displayColor;
    final seal = Paint()..color = const Color(0xFF7A2E1A);

    canvas.drawCircle(Offset.zero, radius + 5, glow);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 1.45,
          height: radius * 1.95,
        ),
        Radius.circular(radius * 0.36),
      ),
      body,
    );
    canvas.drawCircle(Offset.zero, radius * 0.32, seal);
    canvas.drawLine(
      Offset(0, -radius * 1.15),
      Offset(0, -radius * 1.68),
      Paint()
        ..color = displayColor.withValues(alpha: 0.82)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }
}

class ScreamAura extends PositionComponent with HasGameReference<SurvivorGame> {
  ScreamAura({required this.owner, required this.weapon})
    : radius = weapon.screamRadius,
      super(position: Vector2.zero(), anchor: Anchor.center, priority: 8);

  final Player owner;
  EquippedWeapon weapon;
  final Map<Enemy, double> _hitCooldowns = <Enemy, double>{};
  double radius;

  void syncWeapon(EquippedWeapon weapon) {
    this.weapon = weapon;
    radius = weapon.screamRadius;
  }

  double get damage => weapon.damage;
  Color get displayColor => weapon.config.projectileColor;

  bool tryHit(Enemy enemy) {
    final cooldown = _hitCooldowns[enemy] ?? 0;
    if (cooldown > 0) {
      return false;
    }
    _hitCooldowns[enemy] = math.max(0.06, weapon.attackInterval);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    radius = weapon.screamRadius;

    final expired = <Enemy>[];
    _hitCooldowns.forEach((enemy, cooldown) {
      final next = cooldown - dt;
      if (next <= 0 || enemy.isRemoving) {
        expired.add(enemy);
      } else {
        _hitCooldowns[enemy] = next;
      }
    });
    for (final enemy in expired) {
      _hitCooldowns.remove(enemy);
    }
  }

  @override
  void render(Canvas canvas) {
    final pulse =
        0.92 +
        math.sin(owner._animationTime * (1.8 + weapon.fireRate * 0.4)) * 0.04;
    final auraRadius = radius * pulse;
    final baseColor = displayColor;

    canvas.drawCircle(
      Offset.zero,
      auraRadius + 14,
      Paint()..color = baseColor.withValues(alpha: 0.06),
    );
    canvas.drawCircle(
      Offset.zero,
      auraRadius,
      Paint()..color = baseColor.withValues(alpha: 0.13),
    );
    canvas.drawCircle(
      Offset.zero,
      auraRadius * 0.72,
      Paint()..color = baseColor.withValues(alpha: 0.08),
    );
    canvas.drawCircle(
      Offset.zero,
      auraRadius,
      Paint()
        ..color = baseColor.withValues(alpha: 0.46)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class _DashAfterImage {
  _DashAfterImage({
    required this.position,
    required this.facing,
    required this.walkFrame,
    required this.life,
  });

  final Vector2 position;
  final Vector2 facing;
  final bool walkFrame;
  double life;
}

class Enemy extends CircleComponent with HasGameReference<SurvivorGame> {
  Enemy({
    required Vector2 position,
    required double radius,
    required this.health,
    required this.speed,
    required this.touchDps,
    required this.appearanceIndex,
  }) : super(position: position, radius: radius, anchor: Anchor.center);

  double health;
  final double speed;
  final double touchDps;
  final int appearanceIndex;
  double movementMultiplier = 1;
  double _animationTime = 0;
  bool shouldRemove = false;
  double get touchDamageRadius => radius * 0.54;

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;

    final toPlayer = game.player.position - position;
    if (toPlayer.length2 > 0) {
      position +=
          toPlayer.normalized() *
          speed *
          game.enemySpeedPhaseMultiplier *
          movementMultiplier *
          dt;
    }
  }

  @override
  void render(Canvas canvas) {
    _EnemyPixelArt.render(
      canvas,
      appearanceIndex: appearanceIndex,
      animationTime: _animationTime,
      radius: radius,
    );
  }

  @override
  void onRemove() {
    if (health <= 0) {
      game.player.kills += 1;
    }
    super.onRemove();
  }
}

class Projectile extends CircleComponent {
  Projectile({
    required Vector2 position,
    required Vector2 velocity,
    required this.damage,
    required this.life,
    required this.remainingPierces,
    required this.weaponType,
    required this.projectileColor,
    required double radius,
    required this.spinRate,
  }) : velocity = velocity.clone(),
       _initialLife = life,
       super(position: position, radius: radius, anchor: Anchor.center);

  Vector2 velocity;
  final double damage;
  int remainingPierces;
  final SurvivorWeaponType weaponType;
  final Color projectileColor;
  final double spinRate;
  bool shouldRemove = false;
  double life;
  final Set<Enemy> hitEnemies = <Enemy>{};
  double _spinAngle = 0;
  final double _initialLife;

  bool get _isReturningScythe =>
      weaponType == SurvivorWeaponType.scythe && life <= _initialLife * 0.48;

  @override
  void update(double dt) {
    super.update(dt);
    if (_isReturningScythe && parent != null) {
      final game = findGame() as SurvivorGame?;
      final player = game?.playerOrNull;
      if (player != null) {
        final toPlayer = player.position - position;
        if (toPlayer.length2 <= math.pow(player.radius + radius + 10, 2)) {
          removeFromParent();
          return;
        }
        if (toPlayer.length2 > 0) {
          final returnSpeed = math.max(velocity.length, 320) * 1.18;
          velocity = toPlayer.normalized() * returnSpeed;
        }
      }
    }
    position += velocity * dt;
    _spinAngle += spinRate * dt;
    life -= dt;
    if (life <= 0) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final direction = velocity.length2 == 0
        ? Vector2(0, -1)
        : velocity.normalized();
    canvas.save();
    canvas.rotate(math.atan2(direction.y, direction.x));

    switch (weaponType) {
      case SurvivorWeaponType.spear:
        _renderSpear(canvas);
        break;
      case SurvivorWeaponType.scythe:
        canvas.rotate(_spinAngle);
        _renderScythe(canvas);
        break;
      case SurvivorWeaponType.bow:
        _renderArrow(canvas);
        break;
      case SurvivorWeaponType.talisman:
        _renderScythe(canvas);
        break;
      case SurvivorWeaponType.scream:
        _renderScreamSigil(canvas);
        break;
      case SurvivorWeaponType.ancestor:
        _renderScreamSigil(canvas);
        break;
    }

    canvas.restore();
  }

  void _renderSpear(Canvas canvas) {
    final shaftPaint = Paint()
      ..color = Color.lerp(projectileColor, Colors.brown, 0.45)!;
    final headPaint = Paint()..color = projectileColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-radius * 0.55, 0),
          width: radius * 3.8,
          height: radius * 0.32,
        ),
        Radius.circular(radius * 0.2),
      ),
      shaftPaint,
    );

    final tip = Path()
      ..moveTo(radius * 2.0, 0)
      ..lineTo(radius * 0.82, -radius * 0.72)
      ..lineTo(radius * 0.82, radius * 0.72)
      ..close();
    canvas.drawPath(tip, headPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-radius * 1.8, 0),
          width: radius * 0.44,
          height: radius * 0.54,
        ),
        Radius.circular(radius * 0.16),
      ),
      Paint()..color = Color.lerp(projectileColor, Colors.white, 0.18)!,
    );
  }

  void _renderScythe(Canvas canvas) {
    final handlePaint = Paint()
      ..color = Color.lerp(projectileColor, Colors.brown, 0.5)!;
    final bladePaint = Paint()..color = projectileColor;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * 1.8,
          height: radius * 0.34,
        ),
        Radius.circular(radius * 0.18),
      ),
      handlePaint,
    );

    final blade = Path()
      ..moveTo(radius * 0.2, -radius * 1.0)
      ..quadraticBezierTo(
        radius * 1.35,
        -radius * 0.8,
        radius * 1.18,
        radius * 0.25,
      )
      ..quadraticBezierTo(
        radius * 0.45,
        -radius * 0.05,
        radius * 0.05,
        -radius * 0.55,
      )
      ..close();
    canvas.drawPath(blade, bladePaint);
  }

  void _renderArrow(Canvas canvas) {
    final shaftPaint = Paint()
      ..color = Color.lerp(projectileColor, Colors.brown, 0.42)!
      ..strokeWidth = math.max(2, radius * 0.36)
      ..strokeCap = StrokeCap.round;
    final headPaint = Paint()..color = projectileColor;

    canvas.drawLine(
      Offset(-radius * 1.2, 0),
      Offset(radius * 1.2, 0),
      shaftPaint,
    );

    final head = Path()
      ..moveTo(radius * 1.4, 0)
      ..lineTo(radius * 0.55, -radius * 0.46)
      ..lineTo(radius * 0.55, radius * 0.46)
      ..close();
    canvas.drawPath(head, headPaint);

    canvas.drawLine(
      Offset(-radius * 1.0, 0),
      Offset(-radius * 1.55, -radius * 0.46),
      headPaint..strokeWidth = 1.6,
    );
    canvas.drawLine(
      Offset(-radius * 1.0, 0),
      Offset(-radius * 1.55, radius * 0.46),
      headPaint..strokeWidth = 1.6,
    );
  }

  void _renderScreamSigil(Canvas canvas) {
    canvas.drawCircle(
      Offset.zero,
      radius * 1.2,
      Paint()..color = projectileColor.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * 0.76,
      Paint()
        ..color = projectileColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }
}

class XpShard extends CircleComponent with HasGameReference<SurvivorGame> {
  XpShard({required Vector2 position, required this.value})
    : super(
        position: position,
        radius: 7,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFF64B5F6),
      );

  final double value;
  double _magnetSpeed = 0;
  double _animationTime = 0;
  bool isMagnetized = false;

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;

    final toPlayer = game.player.position - position;
    final distance = toPlayer.length;
    final magnetDistance =
        game.player.radius + radius + 54 + game.player.pickupRadius;

    if (!isMagnetized && distance <= magnetDistance) {
      isMagnetized = true;
    }

    if (!isMagnetized || distance == 0) {
      return;
    }

    _magnetSpeed = math.min(760, _magnetSpeed + dt * 1250);
    final distanceRatio = (1 - (distance / magnetDistance)).clamp(0.0, 1.0);
    final pullSpeed = _magnetSpeed + distanceRatio * 240;
    position += toPlayer.normalized() * pullSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final glowRadius = radius + (isMagnetized ? 3.5 : 1.5);
    final diamondPulse = 1 + math.sin(_animationTime * 8) * 0.08;
    final paint = Paint();

    canvas.drawCircle(
      Offset.zero,
      glowRadius,
      Paint()..color = const Color(0x3364B5F6),
    );

    final diamond = Path()
      ..moveTo(0, -radius * diamondPulse)
      ..lineTo(radius * 0.82 * diamondPulse, 0)
      ..lineTo(0, radius * diamondPulse)
      ..lineTo(-radius * 0.82 * diamondPulse, 0)
      ..close();

    paint.color = isMagnetized
        ? const Color(0xFF9CD8FF)
        : const Color(0xFF64B5F6);
    canvas.drawPath(diamond, paint);

    canvas.drawPath(
      Path()
        ..moveTo(0, -radius * 0.72 * diamondPulse)
        ..lineTo(radius * 0.3, -radius * 0.02)
        ..lineTo(0, radius * 0.2)
        ..lineTo(-radius * 0.3, -radius * 0.02)
        ..close(),
      Paint()..color = const Color(0xFFDDF3FF),
    );
  }
}

class GoldPickup extends CircleComponent with HasGameReference<SurvivorGame> {
  GoldPickup({required Vector2 position, required this.value})
    : super(
        position: position,
        radius: 8,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFFFD54F),
      );

  final int value;
  double _magnetSpeed = 0;
  double _animationTime = 0;
  bool isMagnetized = false;

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;

    final toPlayer = game.player.position - position;
    final distance = toPlayer.length;
    final magnetDistance =
        game.player.radius + radius + 54 + game.player.pickupRadius;

    if (!isMagnetized && distance <= magnetDistance) {
      isMagnetized = true;
    }

    if (!isMagnetized || distance == 0) {
      return;
    }

    _magnetSpeed = math.min(820, _magnetSpeed + dt * 1380);
    final distanceRatio = (1 - (distance / magnetDistance)).clamp(0.0, 1.0);
    final pullSpeed = _magnetSpeed + distanceRatio * 260;
    position += toPlayer.normalized() * pullSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1 + math.sin(_animationTime * 7.5) * 0.06;
    final glowPaint = Paint()
      ..color = isMagnetized
          ? const Color(0x55FFE082)
          : const Color(0x33FFD54F);
    final coinPaint = Paint()
      ..color = isMagnetized
          ? const Color(0xFFFFE082)
          : const Color(0xFFFFD54F);
    final rimPaint = Paint()
      ..color = const Color(0xFFC58B10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    canvas.drawCircle(Offset.zero, radius + 2.5, glowPaint);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2.1 * pulse,
        height: radius * 1.62 * pulse,
      ),
      coinPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2.1 * pulse,
        height: radius * 1.62 * pulse,
      ),
      rimPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(-radius * 0.22, -radius * 0.18),
        width: radius * 0.58,
        height: radius * 0.34,
      ),
      Paint()..color = const Color(0x66FFF8E1),
    );
  }
}

class HealthPotionPickup extends CircleComponent
    with HasGameReference<SurvivorGame> {
  HealthPotionPickup({required Vector2 position, required this.healAmount})
    : super(
        position: position,
        radius: 9,
        anchor: Anchor.center,
        paint: Paint()..color = const Color(0xFFEF6C6C),
      );

  final double healAmount;
  double _magnetSpeed = 0;
  double _animationTime = 0;
  bool isMagnetized = false;

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;

    if (game.player.health >= game.player.maxHealth) {
      isMagnetized = false;
      _magnetSpeed = 0;
      return;
    }

    final toPlayer = game.player.position - position;
    final distance = toPlayer.length;
    final magnetDistance =
        game.player.radius + radius + 54 + game.player.pickupRadius;

    if (!isMagnetized && distance <= magnetDistance) {
      isMagnetized = true;
    }

    if (!isMagnetized || distance == 0) {
      return;
    }

    _magnetSpeed = math.min(760, _magnetSpeed + dt * 1260);
    final distanceRatio = (1 - (distance / magnetDistance)).clamp(0.0, 1.0);
    final pullSpeed = _magnetSpeed + distanceRatio * 220;
    position += toPlayer.normalized() * pullSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1 + math.sin(_animationTime * 6.8) * 0.06;
    final glowPaint = Paint()
      ..color = isMagnetized
          ? const Color(0x55FF9A9A)
          : const Color(0x33EF6C6C);
    final bottlePaint = Paint()
      ..color = isMagnetized
          ? const Color(0xFFFFB0B0)
          : const Color(0xFFEF6C6C);
    final glassPaint = Paint()
      ..color = const Color(0xFFEDE7F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(Offset.zero, radius + 2.4, glowPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, radius * 0.1),
          width: radius * 1.35 * pulse,
          height: radius * 1.7 * pulse,
        ),
        Radius.circular(radius * 0.38),
      ),
      bottlePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, radius * 0.1),
          width: radius * 1.35 * pulse,
          height: radius * 1.7 * pulse,
        ),
        Radius.circular(radius * 0.38),
      ),
      glassPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -radius * 0.9),
          width: radius * 0.62,
          height: radius * 0.56,
        ),
        Radius.circular(radius * 0.14),
      ),
      Paint()..color = const Color(0xFFD7CCC8),
    );
    canvas.drawLine(
      Offset(-radius * 0.34, radius * 0.08),
      Offset(radius * 0.34, radius * 0.08),
      Paint()
        ..color = const Color(0xFFFDECEC)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
  }
}

class TreasureChest extends PositionComponent
    with HasGameReference<SurvivorGame> {
  TreasureChest({required Vector2 position})
    : super(position: position, anchor: Anchor.center, priority: 7);

  static const double interactionRadius = 18;

  double _animationTime = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _animationTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final pulse = 1 + math.sin(_animationTime * 5.2) * 0.05;
    final bodyRect = Rect.fromCenter(
      center: const Offset(0, 2),
      width: interactionRadius * 2.15 * pulse,
      height: interactionRadius * 1.5 * pulse,
    );
    final lidRect = Rect.fromCenter(
      center: Offset(0, -interactionRadius * 0.52),
      width: interactionRadius * 2.22 * pulse,
      height: interactionRadius * 0.72 * pulse,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0, interactionRadius * 0.82),
        width: interactionRadius * 2.3,
        height: interactionRadius * 0.86,
      ),
      Paint()..color = const Color(0x22000000),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bodyRect,
        Radius.circular(interactionRadius * 0.28),
      ),
      Paint()..color = const Color(0xFF7A4F2A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        lidRect,
        Radius.circular(interactionRadius * 0.22),
      ),
      Paint()..color = const Color(0xFF986336),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bodyRect,
        Radius.circular(interactionRadius * 0.28),
      ),
      Paint()
        ..color = const Color(0xFFF2C15F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        lidRect,
        Radius.circular(interactionRadius * 0.22),
      ),
      Paint()
        ..color = const Color(0xFFF0D08A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, 3),
          width: interactionRadius * 0.42,
          height: interactionRadius * 0.7,
        ),
        Radius.circular(interactionRadius * 0.12),
      ),
      Paint()..color = const Color(0xFFF7E2A2),
    );
    canvas.drawCircle(
      Offset(interactionRadius * 0.62, -interactionRadius * 0.84),
      interactionRadius * 0.2,
      Paint()..color = const Color(0x55FFD54F),
    );
  }
}
