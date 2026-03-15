import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'survivor_meta_progression.dart';

class SurvivorProfile {
  const SurvivorProfile({required this.gold, required this.upgradeLevels});

  SurvivorProfile.initial()
    : gold = 0,
      upgradeLevels = defaultMetaUpgradeLevels();

  final int gold;
  final Map<SurvivorMetaUpgradeType, int> upgradeLevels;

  int levelFor(SurvivorMetaUpgradeType type) => upgradeLevels[type] ?? 0;

  SurvivorProfile copyWith({
    int? gold,
    Map<SurvivorMetaUpgradeType, int>? upgradeLevels,
  }) {
    return SurvivorProfile(
      gold: gold ?? this.gold,
      upgradeLevels:
          upgradeLevels ??
          Map<SurvivorMetaUpgradeType, int>.from(this.upgradeLevels),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'gold': gold,
      'upgrades': <String, int>{
        for (final entry in upgradeLevels.entries) entry.key.name: entry.value,
      },
    };
  }

  factory SurvivorProfile.fromJson(Map<String, dynamic> json) {
    final levels = defaultMetaUpgradeLevels();
    final rawUpgrades = json['upgrades'];
    if (rawUpgrades is Map<String, dynamic>) {
      for (final definition in survivorMetaUpgrades) {
        final level = (rawUpgrades[definition.type.name] as num?)?.toInt();
        if (level != null) {
          levels[definition.type] = level.clamp(
            0,
            SurvivorMetaUpgradeDefinition.maxLevel,
          );
        }
      }
    }

    return SurvivorProfile(
      gold: (json['gold'] as num?)?.toInt() ?? 0,
      upgradeLevels: levels,
    );
  }
}

class SurvivorProfileRepository {
  Future<SurvivorProfile> loadProfile() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return SurvivorProfile.initial();
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return SurvivorProfile.initial();
      }

      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) {
        return SurvivorProfile.initial();
      }

      return SurvivorProfile.fromJson(data);
    } catch (_) {
      return SurvivorProfile.initial();
    }
  }

  Future<void> saveProfile(SurvivorProfile profile) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(profile.toJson()));
  }

  Future<void> deleteProfile() async {
    final file = await _file;
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> get _file async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}profile.json');
  }
}
