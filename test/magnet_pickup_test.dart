import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_game/game/survivor_game.dart';

void main() {
  test('pickup items can be forced into global magnet mode', () {
    final xp = XpShard(position: Vector2.zero(), value: 8);
    final gold = GoldPickup(position: Vector2.zero(), value: 3);
    final potion = HealthPotionPickup(position: Vector2.zero(), healAmount: 30);
    final magnet = MagnetPickup(position: Vector2.zero());

    xp.triggerGlobalMagnet();
    gold.triggerGlobalMagnet();
    potion.triggerGlobalMagnet();
    magnet.triggerGlobalMagnet();

    expect(xp.isMagnetized, isTrue);
    expect(xp.isForceMagnetized, isTrue);
    expect(gold.isMagnetized, isTrue);
    expect(gold.isForceMagnetized, isTrue);
    expect(potion.isMagnetized, isTrue);
    expect(potion.isForceMagnetized, isTrue);
    expect(magnet.isMagnetized, isTrue);
    expect(magnet.isForceMagnetized, isTrue);
  });
}
