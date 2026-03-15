import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'survivor_run_config.dart';

class CustomMapRepository {
  Future<List<SurvivorMapConfig>> loadMaps() async {
    try {
      final file = await _file;
      if (!await file.exists()) {
        return const <SurvivorMapConfig>[];
      }

      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const <SurvivorMapConfig>[];
      }

      final data = jsonDecode(raw);
      if (data is! List<dynamic>) {
        return const <SurvivorMapConfig>[];
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(SurvivorMapConfig.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <SurvivorMapConfig>[];
    }
  }

  Future<List<SurvivorMapConfig>> saveMap(SurvivorMapConfig map) async {
    final maps = (await loadMaps()).toList(growable: true);
    final existingIndex = maps.indexWhere((entry) => entry.id == map.id);
    if (existingIndex >= 0) {
      maps[existingIndex] = map;
    } else {
      maps.add(map);
    }
    maps.sort((a, b) => a.name.compareTo(b.name));
    await _writeAll(maps);
    return List<SurvivorMapConfig>.unmodifiable(maps);
  }

  Future<List<SurvivorMapConfig>> deleteMap(String id) async {
    final maps = (await loadMaps())
        .where((map) => map.id != id)
        .toList(growable: false);
    await _writeAll(maps);
    return maps;
  }

  Future<void> _writeAll(List<SurvivorMapConfig> maps) async {
    final file = await _file;
    await file.parent.create(recursive: true);
    final payload = maps.map((map) => map.toJson()).toList(growable: false);
    await file.writeAsString(jsonEncode(payload));
  }

  Future<File> get _file async {
    final directory = await getApplicationSupportDirectory();
    return File('${directory.path}${Platform.pathSeparator}custom_maps.json');
  }
}
