import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'survivor_run_config.dart';

enum SurvivorMetaUpgradeType {
  maxHealth,
  moveSpeed,
  attackPower,
  fireRate,
  pickupRange,
  levelUpReroll,
}

class SurvivorMetaUpgradeDefinition {
  const SurvivorMetaUpgradeDefinition({
    required this.type,
    required this.name,
    required this.description,
    required this.accentColor,
    required this.icon,
    required this.perLevelLabel,
    required this.totalBonusLabel,
  });

  final SurvivorMetaUpgradeType type;
  final String name;
  final String description;
  final Color accentColor;
  final IconData icon;
  final String Function() perLevelLabel;
  final String Function(int level) totalBonusLabel;

  static const int maxLevel = 10;

  int priceForLevel(int currentLevel) => 200 + currentLevel * 100;
}

const List<SurvivorMetaUpgradeDefinition> survivorMetaUpgrades =
    <SurvivorMetaUpgradeDefinition>[
      SurvivorMetaUpgradeDefinition(
        type: SurvivorMetaUpgradeType.maxHealth,
        name: '체력 단련',
        description: '모든 캐릭터의 시작 최대 HP를 높입니다.',
        accentColor: Color(0xFFE57373),
        icon: Icons.favorite,
        perLevelLabel: _maxHealthPerLevelLabel,
        totalBonusLabel: _maxHealthTotalBonusLabel,
      ),
      SurvivorMetaUpgradeDefinition(
        type: SurvivorMetaUpgradeType.moveSpeed,
        name: '기동 훈련',
        description: '모든 캐릭터의 기본 이동속도를 높입니다.',
        accentColor: Color(0xFF64C79A),
        icon: Icons.directions_run,
        perLevelLabel: _moveSpeedPerLevelLabel,
        totalBonusLabel: _moveSpeedTotalBonusLabel,
      ),
      SurvivorMetaUpgradeDefinition(
        type: SurvivorMetaUpgradeType.attackPower,
        name: '전투 교범',
        description: '모든 캐릭터의 시작 공격력을 높입니다.',
        accentColor: Color(0xFFFFB74D),
        icon: Icons.flash_on,
        perLevelLabel: _attackPowerPerLevelLabel,
        totalBonusLabel: _attackPowerTotalBonusLabel,
      ),
      SurvivorMetaUpgradeDefinition(
        type: SurvivorMetaUpgradeType.fireRate,
        name: '속사 훈련',
        description: '모든 캐릭터의 시작 발사속도를 높입니다.',
        accentColor: Color(0xFF4FC3F7),
        icon: Icons.speed,
        perLevelLabel: _fireRatePerLevelLabel,
        totalBonusLabel: _fireRateTotalBonusLabel,
      ),
      SurvivorMetaUpgradeDefinition(
        type: SurvivorMetaUpgradeType.pickupRange,
        name: '탐색 감각',
        description: '모든 캐릭터의 시작 획득범위를 넓힙니다.',
        accentColor: Color(0xFFBA68C8),
        icon: Icons.scatter_plot_outlined,
        perLevelLabel: _pickupRangePerLevelLabel,
        totalBonusLabel: _pickupRangeTotalBonusLabel,
      ),
      SurvivorMetaUpgradeDefinition(
        type: SurvivorMetaUpgradeType.levelUpReroll,
        name: '재선택 보급',
        description: '모든 런 시작 시 레벨업 카드 다시 선택 횟수를 1회 더 충전합니다.',
        accentColor: Color(0xFF90CAF9),
        icon: Icons.refresh,
        perLevelLabel: _rerollPerLevelLabel,
        totalBonusLabel: _rerollTotalBonusLabel,
      ),
    ];

Map<SurvivorMetaUpgradeType, int> defaultMetaUpgradeLevels() {
  return <SurvivorMetaUpgradeType, int>{
    for (final definition in survivorMetaUpgrades) definition.type: 0,
  };
}

SurvivorMetaUpgradeDefinition metaUpgradeDefinitionFor(
  SurvivorMetaUpgradeType type,
) {
  for (final definition in survivorMetaUpgrades) {
    if (definition.type == type) {
      return definition;
    }
  }
  return survivorMetaUpgrades.first;
}

SurvivorCharacterConfig applyMetaUpgradesToCharacter(
  SurvivorCharacterConfig base,
  Map<SurvivorMetaUpgradeType, int> levels,
) {
  final healthLevel = levels[SurvivorMetaUpgradeType.maxHealth] ?? 0;
  final moveSpeedLevel = levels[SurvivorMetaUpgradeType.moveSpeed] ?? 0;
  final attackPowerLevel = levels[SurvivorMetaUpgradeType.attackPower] ?? 0;
  final fireRateLevel = levels[SurvivorMetaUpgradeType.fireRate] ?? 0;
  final pickupRangeLevel = levels[SurvivorMetaUpgradeType.pickupRange] ?? 0;

  final attackInterval = (base.attackInterval * math.pow(0.96, fireRateLevel))
      .clamp(0.18, 9.0)
      .toDouble();

  return base.copyWith(
    maxHealth: base.maxHealth + healthLevel * 8,
    moveSpeed: base.moveSpeed + moveSpeedLevel * 6,
    projectileDamage: base.projectileDamage + attackPowerLevel * 2,
    attackInterval: attackInterval,
    pickupRadius: base.pickupRadius + pickupRangeLevel * 10,
  );
}

int startingLevelUpRerollsFor(
  Map<SurvivorMetaUpgradeType, int> levels, {
  int baseRerolls = 5,
}) {
  final purchasedRerolls = levels[SurvivorMetaUpgradeType.levelUpReroll] ?? 0;
  return baseRerolls + purchasedRerolls.clamp(0, 10);
}

String _maxHealthPerLevelLabel() => '레벨당 +8 HP';
String _maxHealthTotalBonusLabel(int level) => '총 +${level * 8} HP';
String _moveSpeedPerLevelLabel() => '레벨당 +6 이동속도';
String _moveSpeedTotalBonusLabel(int level) => '총 +${level * 6} 이동속도';
String _attackPowerPerLevelLabel() => '레벨당 +2 공격력';
String _attackPowerTotalBonusLabel(int level) => '총 +${level * 2} 공격력';
String _fireRatePerLevelLabel() => '레벨당 발사속도 4% 증가';
String _fireRateTotalBonusLabel(int level) =>
    '총 ${(level * 4).clamp(0, 40)}% 증가';
String _pickupRangePerLevelLabel() => '레벨당 +10 획득범위';
String _pickupRangeTotalBonusLabel(int level) => '총 +${level * 10} 획득범위';
String _rerollPerLevelLabel() => '레벨당 +1 다시 선택';
String _rerollTotalBonusLabel(int level) => '총 +$level 다시 선택';
