import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_game/game/survivor_game.dart';
import 'package:flutter_game/game/survivor_run_config.dart';

void main() {
  test(
    'ancestor weapon starts with one spirit and gains a second at level five',
    () {
      final ancestorConfig = survivorWeapons.firstWhere(
        (weapon) => weapon.id == 'ancestor',
      );
      final player = Player(
        characterConfig: survivorCharacters.first,
        weaponConfig: ancestorConfig,
      );

      final weapon = player.weaponById('ancestor');
      expect(weapon, isNotNull);
      expect(weapon!.ancestorCount, 1);
      expect(weapon.level, 1);

      for (var i = 0; i < 4; i++) {
        player.applyWeaponUpgrade(
          ancestorConfig,
          WeaponUpgradeStat.attackPower,
        );
      }

      expect(weapon.level, 5);
      expect(weapon.ancestorCount, 2);
    },
  );

  test('ancestor range upgrades expand spirit activity radius', () {
    final ancestorConfig = survivorWeapons.firstWhere(
      (weapon) => weapon.id == 'ancestor',
    );
    final player = Player(
      characterConfig: survivorCharacters.first,
      weaponConfig: ancestorConfig,
    );

    final weapon = player.weaponById('ancestor');
    expect(weapon, isNotNull);

    final baseRange = weapon!.ancestorRange;
    player.applyWeaponUpgrade(ancestorConfig, WeaponUpgradeStat.attackRange);

    expect(weapon.ancestorRange, greaterThan(baseRange));
  });
}
