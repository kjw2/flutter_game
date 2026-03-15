import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_game/game/survivor_game.dart';
import 'package:flutter_game/game/survivor_meta_progression.dart';
import 'package:flutter_game/game/survivor_run_config.dart';

void main() {
  test('meta upgrades apply to initial player and weapon stats', () {
    final levels = defaultMetaUpgradeLevels()
      ..[SurvivorMetaUpgradeType.maxHealth] = 3
      ..[SurvivorMetaUpgradeType.moveSpeed] = 2
      ..[SurvivorMetaUpgradeType.attackPower] = 4
      ..[SurvivorMetaUpgradeType.fireRate] = 5
      ..[SurvivorMetaUpgradeType.pickupRange] = 1;

    final adjustedCharacter = applyMetaUpgradesToCharacter(
      survivorCharacters.first,
      levels,
    );
    final player = Player(
      characterConfig: adjustedCharacter,
      weaponConfig: survivorWeapons.first,
    );

    expect(player.maxHealth, adjustedCharacter.maxHealth);
    expect(player.health, adjustedCharacter.maxHealth);
    expect(player.speed, adjustedCharacter.moveSpeed);
    expect(player.pickupRadius, adjustedCharacter.pickupRadius);
    expect(
      player.primaryWeapon.damage,
      adjustedCharacter.projectileDamage + survivorWeapons.first.damageBonus,
    );
    expect(
      player.primaryWeapon.attackInterval,
      closeTo(
        (adjustedCharacter.attackInterval *
                survivorWeapons.first.attackIntervalMultiplier)
            .clamp(0.18, 9.0)
            .toDouble(),
        0.0001,
      ),
    );
  });

  test('reset keeps upgraded base stats', () {
    final levels = defaultMetaUpgradeLevels()
      ..[SurvivorMetaUpgradeType.maxHealth] = 2
      ..[SurvivorMetaUpgradeType.moveSpeed] = 4
      ..[SurvivorMetaUpgradeType.attackPower] = 1
      ..[SurvivorMetaUpgradeType.fireRate] = 3
      ..[SurvivorMetaUpgradeType.pickupRange] = 5;

    final adjustedCharacter = applyMetaUpgradesToCharacter(
      survivorCharacters[1],
      levels,
    );
    final player = Player(
      characterConfig: adjustedCharacter,
      weaponConfig: survivorWeapons[2],
    );

    player.health = 1;
    player.speed = 10;
    player.pickupRadius = 0;
    player.applyWeaponUpgrade(
      survivorWeapons[2],
      WeaponUpgradeStat.attackPower,
    );

    player.reset();

    expect(player.maxHealth, adjustedCharacter.maxHealth);
    expect(player.health, adjustedCharacter.maxHealth);
    expect(player.speed, adjustedCharacter.moveSpeed);
    expect(player.pickupRadius, adjustedCharacter.pickupRadius);
    expect(
      player.primaryWeapon.damage,
      adjustedCharacter.projectileDamage + survivorWeapons[2].damageBonus,
    );
    expect(
      player.primaryWeapon.attackInterval,
      closeTo(
        (adjustedCharacter.attackInterval *
                survivorWeapons[2].attackIntervalMultiplier)
            .clamp(0.18, 9.0)
            .toDouble(),
        0.0001,
      ),
    );
  });

  test('reroll meta upgrade adds to the base starting reroll count', () {
    final levels = defaultMetaUpgradeLevels()
      ..[SurvivorMetaUpgradeType.levelUpReroll] = 4;

    expect(startingLevelUpRerollsFor(levels), 9);
  });
}
