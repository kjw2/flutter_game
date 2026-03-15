part of 'survivor_game.dart';

enum UpgradeChoiceCategory { playerStat, unlockWeapon, weaponUpgrade }

enum UpgradeType {
  moveSpeed,
  defense,
  hpRegen,
  pickupRange,
  weaponRange,
  experienceGain,
}

enum WeaponUpgradeStat {
  attackPower,
  fireRate,
  attackRange,
  projectileCount,
  projectilePierce,
}

class UpgradeChoice {
  const UpgradeChoice({
    required this.category,
    required this.title,
    required this.description,
    required this.color,
    required this.level,
    required this.maxLevel,
    required this.levelLabel,
    required this.icon,
    this.type,
    this.weaponConfig,
    this.weaponUpgradeStat,
  });

  factory UpgradeChoice.moveSpeed(int level) {
    return UpgradeChoice(
      category: UpgradeChoiceCategory.playerStat,
      type: UpgradeType.moveSpeed,
      title: '이동속도 증가',
      description: '이동속도 +24',
      color: const Color(0xFF64C79A),
      level: level,
      maxLevel: 5,
      levelLabel: 'Lv $level/5',
      icon: Icons.directions_run,
    );
  }

  factory UpgradeChoice.defense(int level) {
    return UpgradeChoice(
      category: UpgradeChoiceCategory.playerStat,
      type: UpgradeType.defense,
      title: '방어력 증가',
      description: '받는 피해 12% 감소',
      color: const Color(0xFFC0A15A),
      level: level,
      maxLevel: 5,
      levelLabel: 'Lv $level/5',
      icon: Icons.shield_outlined,
    );
  }

  factory UpgradeChoice.hpRegen(int level) {
    return UpgradeChoice(
      category: UpgradeChoiceCategory.playerStat,
      type: UpgradeType.hpRegen,
      title: 'HP 자동 회복',
      description: '초당 체력 2.2 회복',
      color: const Color(0xFF8FD46A),
      level: level,
      maxLevel: 5,
      levelLabel: 'Lv $level/5',
      icon: Icons.favorite_border,
    );
  }

  factory UpgradeChoice.pickupRange(int level) {
    return UpgradeChoice(
      category: UpgradeChoiceCategory.playerStat,
      type: UpgradeType.pickupRange,
      title: '획득범위 증가',
      description: '경험치 및 아이템 획득 범위 증가',
      color: const Color(0xFF58B7D5),
      level: level,
      maxLevel: 5,
      levelLabel: 'Lv $level/5',
      icon: Icons.scatter_plot_outlined,
    );
  }

  factory UpgradeChoice.weaponRange(int level) {
    return UpgradeChoice(
      category: UpgradeChoiceCategory.playerStat,
      type: UpgradeType.weaponRange,
      title: '무기 범위 확대',
      description: '모든 무기의 사거리와 광역 범위 증가',
      color: const Color(0xFFB88CFF),
      level: level,
      maxLevel: 5,
      levelLabel: 'Lv $level/5',
      icon: Icons.blur_circular,
    );
  }

  factory UpgradeChoice.experienceGain(int level) {
    return UpgradeChoice(
      category: UpgradeChoiceCategory.playerStat,
      type: UpgradeType.experienceGain,
      title: '경험치 획득량 증가',
      description: '획득 경험치 20% 증가',
      color: const Color(0xFFFFD36A),
      level: level,
      maxLevel: 5,
      levelLabel: 'Lv $level/5',
      icon: Icons.auto_graph,
    );
  }

  factory UpgradeChoice.unlockWeapon(SurvivorWeaponConfig weapon) {
    return UpgradeChoice(
      category: UpgradeChoiceCategory.unlockWeapon,
      weaponConfig: weapon,
      title: '${weapon.name} 장착',
      description: '${weapon.description} 최대 3개 무기까지 장착 가능합니다.',
      color: weapon.accentColor,
      level: 1,
      maxLevel: 1,
      levelLabel: 'NEW',
      icon: Icons.add_circle_outline,
    );
  }

  factory UpgradeChoice.weaponUpgrade(
    EquippedWeapon weapon,
    WeaponUpgradeStat stat,
  ) {
    final nextLevel = weapon.level + 1;
    final isAreaWeapon =
        weapon.isTalisman || weapon.isScream || weapon.isAncestor;
    final talismanPrefix = weapon.isTalisman ? '부적 +1, ' : '';
    final ancestorFinalPrefix = weapon.isAncestor && nextLevel >= 5
        ? '최종 단계: 조상님 +1, '
        : '';
    final title = '${weapon.config.name} 강화';

    final (description, icon) = switch (stat) {
      WeaponUpgradeStat.attackPower => (
        '${weapon.isAncestor ? ancestorFinalPrefix : talismanPrefix}공격력 +${isAreaWeapon ? 5 : 6}',
        Icons.flash_on,
      ),
      WeaponUpgradeStat.fireRate => (
        weapon.isTalisman
            ? '$talismanPrefix회전 속도 증가'
            : weapon.isScream
            ? '피해 주기 단축'
            : weapon.isAncestor
            ? '$ancestorFinalPrefix추적 속도 및 공격 주기 향상'
            : '발사 주기 10% 단축',
        Icons.speed,
      ),
      WeaponUpgradeStat.attackRange => (
        weapon.isTalisman
            ? '$talismanPrefix회전 거리 증가'
            : weapon.isScream
            ? '절규 범위 증가'
            : weapon.isAncestor
            ? '$ancestorFinalPrefix조상님 활동 범위 증가'
            : '사거리 증가',
        Icons.open_with,
      ),
      WeaponUpgradeStat.projectileCount => ('투사체 +1', Icons.filter_1),
      WeaponUpgradeStat.projectilePierce => ('관통수 +1', Icons.swap_vert),
    };

    return UpgradeChoice(
      category: UpgradeChoiceCategory.weaponUpgrade,
      weaponConfig: weapon.config,
      weaponUpgradeStat: stat,
      title: title,
      description: description,
      color: weapon.config.accentColor,
      level: nextLevel,
      maxLevel: 5,
      levelLabel: 'Lv $nextLevel/5',
      icon: icon,
    );
  }

  final UpgradeChoiceCategory category;
  final UpgradeType? type;
  final SurvivorWeaponConfig? weaponConfig;
  final WeaponUpgradeStat? weaponUpgradeStat;
  final String title;
  final String description;
  final Color color;
  final int level;
  final int maxLevel;
  final String levelLabel;
  final IconData icon;
}
