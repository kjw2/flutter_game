import 'dart:async';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/custom_map_repository.dart';
import '../game/survivor_game.dart';
import '../game/survivor_meta_progression.dart';
import '../game/survivor_profile_repository.dart';
import '../game/survivor_run_config.dart';
import '../input/gamepad_manager.dart';
import 'map_editor/map_editor_view.dart';
import 'widgets/game_over_overlay.dart';
import 'widgets/level_up_overlay.dart';
import 'widgets/lobby_button.dart';
import 'widgets/pause_overlay.dart';
import 'widgets/selection_option_card.dart';
import 'widgets/store_upgrade_card.dart';

class SurvivorShell extends StatefulWidget {
  const SurvivorShell({super.key});

  @override
  State<SurvivorShell> createState() => _SurvivorShellState();
}

class _SurvivorShellState extends State<SurvivorShell>
    with WidgetsBindingObserver {
  static const String _lobbyMusicAsset = 'survivor_lobby_loop.wav';
  static const String _battleMusicAsset = 'survivor_bgm_loop.wav';
  static const Duration _musicFadeStepDuration = Duration(milliseconds: 28);
  static const int _musicFadeSteps = 8;

  final GamepadManager _gamepad = GamepadManager.instance;
  final CustomMapRepository _customMapRepository = CustomMapRepository();
  final SurvivorProfileRepository _profileRepository =
      SurvivorProfileRepository();
  final GlobalKey<MapEditorViewState> _mapEditorViewKey =
      GlobalKey<MapEditorViewState>();
  final ScrollController _weaponSelectScrollController = ScrollController();
  final ScrollController _mapSelectScrollController = ScrollController();
  final Map<String, GlobalKey> _weaponOptionKeys = <String, GlobalKey>{};
  final Map<String, GlobalKey> _mapOptionKeys = <String, GlobalKey>{};

  SurvivorGame? _session;
  Ticker? _inputTicker;

  bool _showGame = false;
  bool _showMapEditor = false;
  bool _showStore = false;
  bool _showCharacterSelect = false;
  bool _showWeaponSelect = false;
  bool _showMapSelect = false;
  bool _showPauseMenu = false;
  bool _showLevelUpMenu = false;
  double _masterVolume = 0.8;
  bool _screenShake = true;
  bool _showMinimap = true;
  int _lobbySelection = 0;
  int _storeSelection = 0;
  int _characterSelection = 0;
  int _weaponSelection = 0;
  int _mapSelection = 0;
  int _pauseSelection = 0;
  int _gameOverSelection = 0;
  int _levelUpSelection = 0;
  List<UpgradeChoice> _levelUpChoices = const <UpgradeChoice>[];
  List<SurvivorMapConfig> _customMaps = const <SurvivorMapConfig>[];
  MapEditorDraft _mapEditorDraft = const MapEditorDraft();
  SurvivorCharacterConfig? _pendingCharacter;
  SurvivorWeaponConfig? _pendingWeapon;
  SurvivorMapConfig? _pendingMap;
  bool _isMapEditorTestSession = false;
  SurvivorProfile _profile = SurvivorProfile.initial();
  Future<void> _profileWriteQueue = Future<void>.value();
  bool _currentRunGoldSettled = false;
  bool _backgroundMusicReady = false;
  String? _activeBackgroundMusicAsset;
  double _currentBackgroundMusicVolume = 0;
  int _musicTransitionSerial = 0;

  bool get _canContinue => _session != null && !_session!.gameOver;
  String get _gameExitLabel => _isMapEditorTestSession ? '에디터로' : '로비로';
  List<SurvivorMapConfig> get _availableMaps => <SurvivorMapConfig>[
    ...survivorMaps,
    ..._customMaps,
  ];
  SurvivorCharacterConfig get _currentCharacterChoice =>
      _pendingCharacter ??
      survivorCharacters[_characterSelection.clamp(
        0,
        survivorCharacters.length - 1,
      )];
  SurvivorWeaponConfig get _currentWeaponChoice =>
      _pendingWeapon ??
      survivorWeapons[_weaponSelection.clamp(0, survivorWeapons.length - 1)];
  SurvivorMapConfig? get _currentMapChoice {
    final maps = _availableMaps;
    if (maps.isEmpty) {
      return null;
    }
    final pending = _pendingMap;
    if (pending != null) {
      for (final map in maps) {
        if (map.id == pending.id) {
          return map;
        }
      }
    }
    return maps[_mapSelection.clamp(0, maps.length - 1)];
  }

  UpgradeChoice? get _currentLevelUpChoice {
    if (_levelUpChoices.isEmpty) {
      return null;
    }
    return _levelUpChoices[_levelUpSelection.clamp(
      0,
      _levelUpChoices.length - 1,
    )];
  }

  SurvivorMetaUpgradeDefinition get _currentStoreUpgrade =>
      survivorMetaUpgrades[_storeSelection.clamp(
        0,
        survivorMetaUpgrades.length - 1,
      )];
  String get _targetBackgroundMusicAsset =>
      _showGame ? _battleMusicAsset : _lobbyMusicAsset;
  double get _targetBackgroundMusicVolume =>
      (_masterVolume * (_showGame ? 0.42 : 0.24)).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
    _inputTicker = Ticker(_handleGamepadTick)..start();
    _loadCustomMaps();
    _loadProfile();
    unawaited(_initializeBackgroundMusic());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);
    _inputTicker?.dispose();
    _weaponSelectScrollController.dispose();
    _mapSelectScrollController.dispose();
    unawaited(_disposeBackgroundMusic());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused) {
      _pauseForAppBackground();
    }
  }

  Future<void> _initializeBackgroundMusic() async {
    FlameAudio.updatePrefix('assets/audio/');
    try {
      await FlameAudio.bgm.initialize();
      _backgroundMusicReady = true;
      await _syncBackgroundMusicPlayback();
    } catch (_) {
      _backgroundMusicReady = false;
    }
  }

  Future<void> _syncBackgroundMusicPlayback() async {
    if (!_backgroundMusicReady) {
      return;
    }

    final player = FlameAudio.bgm.audioPlayer;
    final targetAsset = _targetBackgroundMusicAsset;
    final targetVolume = _targetBackgroundMusicVolume;
    final transitionSerial = ++_musicTransitionSerial;

    try {
      if (_activeBackgroundMusicAsset == targetAsset) {
        switch (player.state) {
          case PlayerState.paused:
            await FlameAudio.bgm.resume();
            break;
          case PlayerState.stopped:
          case PlayerState.completed:
          case PlayerState.disposed:
            await FlameAudio.bgm.play(targetAsset, volume: 0);
            _activeBackgroundMusicAsset = targetAsset;
            _currentBackgroundMusicVolume = 0;
            break;
          case PlayerState.playing:
            FlameAudio.bgm.isPlaying = true;
            break;
        }

        await _fadeBackgroundMusicVolume(
          targetVolume,
          transitionSerial: transitionSerial,
        );
        return;
      }

      if (_activeBackgroundMusicAsset != null &&
          player.state != PlayerState.stopped &&
          player.state != PlayerState.disposed) {
        await _fadeBackgroundMusicVolume(0, transitionSerial: transitionSerial);
        if (transitionSerial != _musicTransitionSerial) {
          return;
        }
      }

      await FlameAudio.bgm.play(targetAsset, volume: 0);
      _activeBackgroundMusicAsset = targetAsset;
      _currentBackgroundMusicVolume = 0;

      await _fadeBackgroundMusicVolume(
        targetVolume,
        transitionSerial: transitionSerial,
      );
    } catch (_) {}
  }

  Future<void> _updateBackgroundMusicVolume() async {
    if (!_backgroundMusicReady) {
      return;
    }

    try {
      await FlameAudio.bgm.audioPlayer.setVolume(_targetBackgroundMusicVolume);
      _currentBackgroundMusicVolume = _targetBackgroundMusicVolume;
    } catch (_) {}
  }

  Future<void> _fadeBackgroundMusicVolume(
    double targetVolume, {
    required int transitionSerial,
  }) async {
    final fromVolume = _currentBackgroundMusicVolume;
    final clampedTarget = targetVolume.clamp(0.0, 1.0).toDouble();
    if ((fromVolume - clampedTarget).abs() < 0.01) {
      await FlameAudio.bgm.audioPlayer.setVolume(clampedTarget);
      _currentBackgroundMusicVolume = clampedTarget;
      return;
    }

    for (var step = 1; step <= _musicFadeSteps; step++) {
      if (transitionSerial != _musicTransitionSerial) {
        return;
      }

      final progress = step / _musicFadeSteps;
      final volume = fromVolume + (clampedTarget - fromVolume) * progress;
      await FlameAudio.bgm.audioPlayer.setVolume(volume);
      _currentBackgroundMusicVolume = volume;
      await Future<void>.delayed(_musicFadeStepDuration);
    }
  }

  Future<void> _disposeBackgroundMusic() async {
    _musicTransitionSerial += 1;
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}

    try {
      await FlameAudio.bgm.dispose();
    } catch (_) {}
    _backgroundMusicReady = false;
    _activeBackgroundMusicAsset = null;
    _currentBackgroundMusicVolume = 0;
  }

  void _openCharacterSelection() {
    final maps = _availableMaps;
    setState(() {
      _showGame = false;
      _showMapEditor = false;
      _showStore = false;
      _showCharacterSelect = true;
      _showWeaponSelect = false;
      _showMapSelect = false;
      _showPauseMenu = false;
      _showLevelUpMenu = false;
      _characterSelection = 0;
      _weaponSelection = 0;
      _mapSelection = 0;
      _gameOverSelection = 0;
      _pendingCharacter = survivorCharacters.first;
      _pendingWeapon = survivorWeapons.first;
      _pendingMap = maps.isEmpty ? null : maps.first;
      _levelUpChoices = const <UpgradeChoice>[];
      _levelUpSelection = 0;
    });
    unawaited(_syncBackgroundMusicPlayback());
  }

  void _chooseCharacter(SurvivorCharacterConfig character) {
    final characterIndex = survivorCharacters.indexWhere(
      (entry) => entry.id == character.id,
    );
    setState(() {
      _pendingCharacter = character;
      if (characterIndex >= 0) {
        _characterSelection = characterIndex;
      }
      _showCharacterSelect = false;
      _showWeaponSelect = true;
      _weaponSelection = 0;
      _pendingWeapon = survivorWeapons.first;
    });
    _scrollCurrentWeaponOptionIntoView();
  }

  void _chooseWeapon(SurvivorWeaponConfig weapon) {
    final maps = _availableMaps;
    final mapIndex = _mapSelection.clamp(0, maps.length - 1);
    final weaponIndex = survivorWeapons.indexWhere(
      (entry) => entry.id == weapon.id,
    );
    setState(() {
      _pendingWeapon = weapon;
      if (weaponIndex >= 0) {
        _weaponSelection = weaponIndex;
      }
      _showWeaponSelect = false;
      _showMapSelect = true;
      _mapSelection = mapIndex;
      _pendingMap = maps[mapIndex];
    });
    _scrollCurrentMapOptionIntoView();
  }

  void _chooseMap(SurvivorMapConfig map) {
    final mapIndex = _availableMaps.indexWhere((entry) => entry.id == map.id);
    _pendingMap = map;
    if (mapIndex >= 0) {
      _mapSelection = mapIndex;
    }
    _startNewGame();
  }

  void _backToCharacterSelection() {
    setState(() {
      _showWeaponSelect = false;
      _showMapSelect = false;
      _showCharacterSelect = true;
      _weaponSelection = 0;
      _mapSelection = 0;
    });
  }

  void _backToWeaponSelection() {
    setState(() {
      _showMapSelect = false;
      _showWeaponSelect = true;
      _mapSelection = 0;
    });
    _scrollCurrentWeaponOptionIntoView();
  }

  void _startNewGame() {
    final character = _pendingCharacter ?? survivorCharacters.first;
    final weapon = _pendingWeapon ?? survivorWeapons.first;
    final maps = _availableMaps;
    final map = _pendingMap ?? maps.first;
    _startSession(character: character, weapon: weapon, map: map);
  }

  void _startSession({
    required SurvivorCharacterConfig character,
    required SurvivorWeaponConfig weapon,
    required SurvivorMapConfig map,
    bool fromMapEditorTest = false,
  }) {
    final adjustedCharacter = applyMetaUpgradesToCharacter(
      character,
      _profile.upgradeLevels,
    );
    final nextSession = SurvivorGame(
      characterConfig: adjustedCharacter,
      weaponConfig: weapon,
      mapConfig: map,
      startingLevelUpRerolls: startingLevelUpRerollsFor(_profile.upgradeLevels),
      onPauseRequested: _openPauseMenu,
      onLevelUpChoicesChanged: _handleLevelUpChoicesChanged,
      onRunEnded: _handleRunEnded,
    );
    nextSession.showMinimap = _showMinimap;
    setState(() {
      _session = nextSession;
      _currentRunGoldSettled = false;
      _pendingCharacter = character;
      _pendingWeapon = weapon;
      _pendingMap = map;
      _showGame = true;
      _showMapEditor = false;
      _showStore = false;
      _showCharacterSelect = false;
      _showWeaponSelect = false;
      _showMapSelect = false;
      _showPauseMenu = false;
      _showLevelUpMenu = false;
      _gameOverSelection = 0;
      _levelUpChoices = const <UpgradeChoice>[];
      _levelUpSelection = 0;
      _isMapEditorTestSession = fromMapEditorTest;
    });
    unawaited(_syncBackgroundMusicPlayback());
  }

  Future<void> _testMapFromEditor(SurvivorMapConfig map) async {
    final character = survivorCharacters[1];
    final weapon = survivorWeapons[2];
    setState(() {
      _pendingCharacter = character;
      _pendingWeapon = weapon;
      _pendingMap = map;
    });
    _startSession(
      character: character,
      weapon: weapon,
      map: map,
      fromMapEditorTest: true,
    );
  }

  void _continueGame() {
    final session = _session;
    if (session == null) {
      return;
    }
    session.showMinimap = _showMinimap;
    if (!_showPauseMenu && !_showLevelUpMenu) {
      session.resumeEngine();
    }
    setState(() {
      _showGame = true;
      _showMapEditor = false;
      _showStore = false;
      _showCharacterSelect = false;
      _showWeaponSelect = false;
      _showMapSelect = false;
      _showPauseMenu = false;
    });
    unawaited(_syncBackgroundMusicPlayback());
  }

  void _returnToLobby() {
    final session = _session;
    session?.pauseEngine();
    setState(() {
      _showGame = false;
      _showMapEditor = false;
      _showStore = false;
      _showCharacterSelect = false;
      _showWeaponSelect = false;
      _showMapSelect = false;
      _showPauseMenu = false;
      _showLevelUpMenu = false;
      _characterSelection = 0;
      _weaponSelection = 0;
      _mapSelection = 0;
      _gameOverSelection = 0;
      _pendingCharacter = null;
      _pendingWeapon = null;
      _pendingMap = null;
      _levelUpChoices = const <UpgradeChoice>[];
      _levelUpSelection = 0;
      _isMapEditorTestSession = false;
    });
    unawaited(_syncBackgroundMusicPlayback());
  }

  Future<void> _loadCustomMaps() async {
    final maps = await _customMapRepository.loadMaps();
    if (!mounted) {
      return;
    }
    setState(() {
      _customMaps = maps;
      if (_mapSelection >= _availableMaps.length) {
        _mapSelection = _availableMaps.isEmpty ? 0 : _availableMaps.length - 1;
      }
    });
  }

  Future<void> _loadProfile() async {
    final profile = await _profileRepository.loadProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = profile;
    });
  }

  void _openStore() {
    final session = _session;
    session?.pauseEngine();
    setState(() {
      _showGame = false;
      _showMapEditor = false;
      _showStore = true;
      _showCharacterSelect = false;
      _showWeaponSelect = false;
      _showMapSelect = false;
      _showPauseMenu = false;
      _showLevelUpMenu = false;
      _storeSelection = 0;
    });
    unawaited(_syncBackgroundMusicPlayback());
  }

  void _changeStoreSelection(int nextIndex) {
    final wrapped = nextIndex % survivorMetaUpgrades.length;
    setState(() {
      _storeSelection = wrapped;
    });
  }

  void _purchaseStoreUpgrade(SurvivorMetaUpgradeType type) {
    final definition = metaUpgradeDefinitionFor(type);
    final currentLevel = _profile.levelFor(type);
    if (currentLevel >= SurvivorMetaUpgradeDefinition.maxLevel) {
      return;
    }

    final price = definition.priceForLevel(currentLevel);
    if (_profile.gold < price) {
      return;
    }

    final nextLevels = Map<SurvivorMetaUpgradeType, int>.from(
      _profile.upgradeLevels,
    );
    nextLevels[type] = currentLevel + 1;
    final nextProfile = _profile.copyWith(
      gold: _profile.gold - price,
      upgradeLevels: nextLevels,
    );

    setState(() {
      _profile = nextProfile;
    });
    _profileWriteQueue = _profileWriteQueue.then((_) {
      return _profileRepository.saveProfile(nextProfile);
    });
  }

  void _purchaseSelectedStoreUpgrade() {
    _purchaseStoreUpgrade(_currentStoreUpgrade.type);
  }

  void _openMapEditor() {
    final session = _session;
    session?.pauseEngine();
    setState(() {
      _showGame = false;
      _showMapEditor = true;
      _showStore = false;
      _showCharacterSelect = false;
      _showWeaponSelect = false;
      _showMapSelect = false;
      _showPauseMenu = false;
      _showLevelUpMenu = false;
    });
    unawaited(_syncBackgroundMusicPlayback());
  }

  void _returnFromGameSurface() {
    if (!_isMapEditorTestSession) {
      _returnToLobby();
      return;
    }

    final session = _session;
    session?.pauseEngine();
    setState(() {
      _showGame = false;
      _showMapEditor = true;
      _showStore = false;
      _showCharacterSelect = false;
      _showWeaponSelect = false;
      _showMapSelect = false;
      _showPauseMenu = false;
      _showLevelUpMenu = false;
      _gameOverSelection = 0;
      _levelUpChoices = const <UpgradeChoice>[];
      _levelUpSelection = 0;
    });
    unawaited(_syncBackgroundMusicPlayback());
  }

  void _handleMapEditorDraftChanged(MapEditorDraft draft) {
    _mapEditorDraft = draft;
  }

  Future<void> _handleMapSaved(SurvivorMapConfig map) async {
    final maps = await _customMapRepository.saveMap(map);
    if (!mounted) {
      return;
    }
    setState(() {
      _customMaps = maps;
      _pendingMap = map;
      _mapSelection = _availableMaps.indexWhere((entry) => entry.id == map.id);
    });
  }

  Future<void> _handleMapDeleted(String id) async {
    final maps = await _customMapRepository.deleteMap(id);
    if (!mounted) {
      return;
    }
    setState(() {
      _customMaps = maps;
      if (_pendingMap?.id == id) {
        _pendingMap = _availableMaps.isEmpty ? null : _availableMaps.first;
      }
      if (_mapSelection >= _availableMaps.length) {
        _mapSelection = _availableMaps.isEmpty ? 0 : _availableMaps.length - 1;
      }
    });
  }

  void _openPauseMenu() {
    final session = _session;
    if (session == null ||
        session.gameOver ||
        !_showGame ||
        _showPauseMenu ||
        _showLevelUpMenu) {
      return;
    }
    session.pauseEngine();
    setState(() {
      _showPauseMenu = true;
      _pauseSelection = 0;
    });
  }

  void _pauseForAppBackground() {
    final session = _session;
    if (session == null ||
        !_showGame ||
        session.gameOver ||
        _showPauseMenu ||
        _showLevelUpMenu) {
      return;
    }

    session.pauseEngine();
    setState(() {
      _showPauseMenu = true;
      _pauseSelection = 0;
    });
  }

  void _resumeFromPause() {
    final session = _session;
    if (session == null) {
      return;
    }
    session.resumeEngine();
    setState(() {
      _showPauseMenu = false;
    });
  }

  void _changePauseSelection(int nextIndex) {
    setState(() {
      _pauseSelection = nextIndex % 3;
    });
  }

  void _changeGameOverSelection(int nextIndex) {
    setState(() {
      _gameOverSelection = nextIndex % 2;
    });
  }

  void _activatePauseSelection() {
    _activatePauseSelectionAt(_pauseSelection);
  }

  void _activatePauseSelectionAt(int selection) {
    switch (selection) {
      case 0:
        _resumeFromPause();
        return;
      case 1:
        _restartFromPause();
        return;
      case 2:
        _returnFromGameSurface();
        return;
    }
  }

  void _activateGameOverSelection() {
    _activateGameOverSelectionAt(_gameOverSelection);
  }

  void _activateGameOverSelectionAt(int selection) {
    switch (selection) {
      case 0:
        _restartFromGameOver();
        return;
      case 1:
        _returnFromGameSurface();
        return;
    }
  }

  void _activateLobbySelectionAt(int selection) {
    switch (selection) {
      case 0:
        _openCharacterSelection();
        return;
      case 1:
        if (_canContinue) {
          _continueGame();
        }
        return;
      case 2:
        _openStore();
        return;
      case 3:
        _openSettings();
        return;
      case 4:
        _quitGame();
        return;
    }
  }

  void _confirmCurrentCharacterSelection() {
    _chooseCharacter(_currentCharacterChoice);
  }

  void _confirmCurrentWeaponSelection() {
    _chooseWeapon(_currentWeaponChoice);
  }

  void _confirmCurrentMapSelection() {
    final map = _currentMapChoice;
    if (map == null) {
      return;
    }
    _chooseMap(map);
  }

  void _confirmCurrentLevelUpSelection() {
    final choice = _currentLevelUpChoice;
    if (choice == null) {
      return;
    }
    _chooseLevelUp(choice);
  }

  void _restartFromPause() {
    final session = _session;
    if (session == null) {
      return;
    }
    session.resetRun();
    setState(() {
      _currentRunGoldSettled = false;
      _showPauseMenu = false;
      _showLevelUpMenu = false;
      _gameOverSelection = 0;
      _levelUpChoices = const <UpgradeChoice>[];
      _levelUpSelection = 0;
      _showGame = true;
    });
    unawaited(_syncBackgroundMusicPlayback());
  }

  void _restartFromGameOver() {
    final session = _session;
    if (session == null) {
      return;
    }
    session.resetRun();
    setState(() {
      _currentRunGoldSettled = false;
      _showPauseMenu = false;
      _showLevelUpMenu = false;
      _gameOverSelection = 0;
      _levelUpChoices = const <UpgradeChoice>[];
      _levelUpSelection = 0;
      _showGame = true;
    });
    unawaited(_syncBackgroundMusicPlayback());
  }

  void _handleRunEnded() {
    if (!mounted) {
      return;
    }

    _settleRunGoldIfNeeded();
    setState(() {
      _showPauseMenu = false;
      _showLevelUpMenu = false;
      _gameOverSelection = 0;
      _levelUpChoices = const <UpgradeChoice>[];
      _levelUpSelection = 0;
    });
  }

  void _settleRunGoldIfNeeded() {
    final session = _session;
    if (session == null || !session.gameOver || _currentRunGoldSettled) {
      return;
    }

    _currentRunGoldSettled = true;
    final earnedGold = session.runGold;
    if (earnedGold <= 0) {
      return;
    }

    final nextProfile = _profile.copyWith(gold: _profile.gold + earnedGold);
    setState(() {
      _profile = nextProfile;
    });
    _profileWriteQueue = _profileWriteQueue.then((_) {
      return _profileRepository.saveProfile(nextProfile);
    });
  }

  void _handleLevelUpChoicesChanged(List<UpgradeChoice> choices) {
    if (!mounted) {
      return;
    }

    setState(() {
      _levelUpChoices = choices;
      _showLevelUpMenu = choices.isNotEmpty;
      _levelUpSelection = 0;
      _showPauseMenu = false;
    });
  }

  void _chooseLevelUp(UpgradeChoice choice) {
    final session = _session;
    if (session == null) {
      return;
    }
    if (HardwareKeyboard.instance.isLogicalKeyPressed(
      LogicalKeyboardKey.space,
    )) {
      session.suppressDashWhileSpaceHeld();
    }
    session.applyUpgrade(choice);
  }

  void _rerollLevelUpChoices() {
    final session = _session;
    if (session == null) {
      return;
    }
    session.rerollLevelUpChoices();
  }

  void _changeLevelUpSelection(int nextIndex) {
    if (_levelUpChoices.isEmpty) {
      return;
    }
    setState(() {
      _levelUpSelection = nextIndex % _levelUpChoices.length;
    });
  }

  void _changeCharacterSelection(int nextIndex) {
    final wrapped = nextIndex % survivorCharacters.length;
    setState(() {
      _characterSelection = wrapped;
      _pendingCharacter = survivorCharacters[wrapped];
    });
  }

  void _changeWeaponSelection(int nextIndex) {
    final wrapped = nextIndex % survivorWeapons.length;
    setState(() {
      _weaponSelection = wrapped;
      _pendingWeapon = survivorWeapons[wrapped];
    });
    _scrollCurrentWeaponOptionIntoView();
  }

  GlobalKey _weaponOptionKeyFor(String weaponId) =>
      _weaponOptionKeys.putIfAbsent(weaponId, GlobalKey.new);

  void _scrollCurrentWeaponOptionIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_showWeaponSelect) {
        return;
      }

      final weapon = _currentWeaponChoice;
      final context = _weaponOptionKeyFor(weapon.id).currentContext;
      if (context == null) {
        return;
      }

      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _changeMapSelection(int nextIndex) {
    final maps = _availableMaps;
    if (maps.isEmpty) {
      return;
    }
    final wrapped = nextIndex % maps.length;
    setState(() {
      _mapSelection = wrapped;
      _pendingMap = maps[wrapped];
    });
    _scrollCurrentMapOptionIntoView();
  }

  GlobalKey _mapOptionKeyFor(String mapId) =>
      _mapOptionKeys.putIfAbsent(mapId, GlobalKey.new);

  void _scrollCurrentMapOptionIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_showMapSelect) {
        return;
      }

      final map = _currentMapChoice;
      if (map == null) {
        return;
      }

      final context = _mapOptionKeyFor(map.id).currentContext;
      if (context == null) {
        return;
      }

      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    });
  }

  String _sessionWeaponSummary(SurvivorGame session) {
    final player = session.playerOrNull;
    return player?.equippedWeaponNames ?? session.weaponConfig.name;
  }

  String _sessionLevelSummary(SurvivorGame session) {
    final player = session.playerOrNull;
    return player == null ? '준비 중' : 'LV ${player.level}';
  }

  List<MapEntry<String, String>> _buildPauseStats(SurvivorGame session) {
    final player = session.playerOrNull;
    if (player == null) {
      return <MapEntry<String, String>>[
        const MapEntry('상태', '세션 초기화 중'),
        MapEntry('캐릭터', session.characterConfig.name),
        MapEntry('시작 무기', session.weaponConfig.name),
        MapEntry('맵', session.mapConfig.name),
        MapEntry('보유 골드', '${_profile.gold}'),
      ];
    }

    return <MapEntry<String, String>>[
      MapEntry('무기', player.equippedWeaponNames),
      MapEntry('HP', '${player.health.ceil()}/${player.maxHealth.ceil()}'),
      MapEntry('레벨', '${player.level}'),
      MapEntry('공격력', player.projectileDamage.toStringAsFixed(0)),
      MapEntry('발사속도', '${player.fireRate.toStringAsFixed(2)}/s'),
      MapEntry('이동속도', player.speed.toStringAsFixed(0)),
      MapEntry('투사체 수', '${player.projectileCount}'),
      MapEntry('관통수', '${player.projectilePierce}'),
      MapEntry('방어력', '${(player.defense * 100).round()}%'),
      MapEntry('HP 재생', '${player.healthRegen.toStringAsFixed(1)}/s'),
      MapEntry(
        '경험치 획득',
        '+${((player.experienceGainMultiplier - 1) * 100).round()}%',
      ),
      MapEntry('획득범위', player.pickupRadius.toStringAsFixed(0)),
      MapEntry('무기범위', 'Lv ${player.globalWeaponRangeLevel}/5'),
      MapEntry('런 골드', '${session.runGold}'),
    ];
  }

  Future<void> _openSettings() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF182025),
              title: const Text('설정'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('마스터 볼륨'),
                    Slider(
                      value: _masterVolume,
                      onChanged: (value) {
                        setDialogState(() => _masterVolume = value);
                        setState(() => _masterVolume = value);
                        unawaited(_updateBackgroundMusicVolume());
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('미니맵 표시'),
                      value: _showMinimap,
                      onChanged: (value) {
                        setDialogState(() => _showMinimap = value);
                        setState(() => _showMinimap = value);
                        _session?.showMinimap = value;
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('스크린 셰이크'),
                      subtitle: const Text('다음 전투 이펙트 확장용 옵션'),
                      value: _screenShake,
                      onChanged: (value) {
                        setDialogState(() => _screenShake = value);
                        setState(() => _screenShake = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _quitGame() async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0);
    }
    await SystemNavigator.pop();
  }

  bool _handleHardwareKeyEvent(KeyEvent event) {
    final isPressEvent = event is KeyDownEvent || event is KeyRepeatEvent;
    final isConfirmEvent = event is KeyDownEvent;
    if (!isPressEvent) {
      return false;
    }

    if (_showMapEditor) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _returnToLobby();
        return true;
      }
      return false;
    }

    if (_showStore) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        _changeStoreSelection(
          (_storeSelection + survivorMetaUpgrades.length - 1) %
              survivorMetaUpgrades.length,
        );
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _changeStoreSelection(
          (_storeSelection + 1) % survivorMetaUpgrades.length,
        );
        return true;
      }

      if (isConfirmEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        _purchaseSelectedStoreUpgrade();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _changeStoreSelection(0);
        _purchaseStoreUpgrade(survivorMetaUpgrades[0].type);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit2 &&
          survivorMetaUpgrades.length >= 2) {
        _changeStoreSelection(1);
        _purchaseStoreUpgrade(survivorMetaUpgrades[1].type);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit3 &&
          survivorMetaUpgrades.length >= 3) {
        _changeStoreSelection(2);
        _purchaseStoreUpgrade(survivorMetaUpgrades[2].type);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit4 &&
          survivorMetaUpgrades.length >= 4) {
        _changeStoreSelection(3);
        _purchaseStoreUpgrade(survivorMetaUpgrades[3].type);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit5 &&
          survivorMetaUpgrades.length >= 5) {
        _changeStoreSelection(4);
        _purchaseStoreUpgrade(survivorMetaUpgrades[4].type);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit6 &&
          survivorMetaUpgrades.length >= 6) {
        _changeStoreSelection(5);
        _purchaseStoreUpgrade(survivorMetaUpgrades[5].type);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _returnToLobby();
        return true;
      }

      return false;
    }

    if (_showCharacterSelect) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        _changeCharacterSelection(
          (_characterSelection + survivorCharacters.length - 1) %
              survivorCharacters.length,
        );
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _changeCharacterSelection(
          (_characterSelection + 1) % survivorCharacters.length,
        );
        return true;
      }

      if (isConfirmEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        _confirmCurrentCharacterSelection();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _chooseCharacter(survivorCharacters[0]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit2 &&
          survivorCharacters.length >= 2) {
        _chooseCharacter(survivorCharacters[1]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit3 &&
          survivorCharacters.length >= 3) {
        _chooseCharacter(survivorCharacters[2]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _returnToLobby();
        return true;
      }

      return false;
    }

    if (_showWeaponSelect) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        _changeWeaponSelection(
          (_weaponSelection + survivorWeapons.length - 1) %
              survivorWeapons.length,
        );
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _changeWeaponSelection((_weaponSelection + 1) % survivorWeapons.length);
        return true;
      }

      if (isConfirmEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        _confirmCurrentWeaponSelection();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _chooseWeapon(survivorWeapons[0]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit2 &&
          survivorWeapons.length >= 2) {
        _chooseWeapon(survivorWeapons[1]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit3 &&
          survivorWeapons.length >= 3) {
        _chooseWeapon(survivorWeapons[2]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit4 &&
          survivorWeapons.length >= 4) {
        _chooseWeapon(survivorWeapons[3]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _backToCharacterSelection();
        return true;
      }

      return false;
    }

    if (_showMapSelect) {
      final maps = _availableMaps;
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        _changeMapSelection((_mapSelection + maps.length - 1) % maps.length);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _changeMapSelection((_mapSelection + 1) % maps.length);
        return true;
      }

      if (isConfirmEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        _confirmCurrentMapSelection();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _chooseMap(maps[0]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit2 && maps.length >= 2) {
        _chooseMap(maps[1]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit3 && maps.length >= 3) {
        _chooseMap(maps[2]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _backToWeaponSelection();
        return true;
      }

      return false;
    }

    if (_showLevelUpMenu && _levelUpChoices.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        _changeLevelUpSelection(
          (_levelUpSelection + _levelUpChoices.length - 1) %
              _levelUpChoices.length,
        );
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _changeLevelUpSelection(
          (_levelUpSelection + 1) % _levelUpChoices.length,
        );
        return true;
      }

      if (isConfirmEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        _confirmCurrentLevelUpSelection();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _chooseLevelUp(_levelUpChoices[0]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit2 &&
          _levelUpChoices.length >= 2) {
        _chooseLevelUp(_levelUpChoices[1]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit3 &&
          _levelUpChoices.length >= 3) {
        _chooseLevelUp(_levelUpChoices[2]);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.keyR) {
        _rerollLevelUpChoices();
        return true;
      }

      return false;
    }

    if (_showPauseMenu) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        _changePauseSelection((_pauseSelection + 2) % 3);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _changePauseSelection((_pauseSelection + 1) % 3);
        return true;
      }

      if (isConfirmEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        _activatePauseSelection();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _resumeFromPause();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _resumeFromPause();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit2) {
        _restartFromPause();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit3) {
        _returnFromGameSurface();
        return true;
      }
    }

    final session = _session;
    if (_showGame && session != null && session.gameOver) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyW ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        _changeGameOverSelection((_gameOverSelection + 1) % 2);
        return true;
      }

      if (isConfirmEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        _activateGameOverSelection();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.keyR ||
          event.logicalKey == LogicalKeyboardKey.digit1) {
        _restartFromGameOver();
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.digit2) {
        _returnFromGameSurface();
        return true;
      }
    }

    if (!_showGame &&
        !_showMapEditor &&
        !_showCharacterSelect &&
        !_showWeaponSelect &&
        !_showMapSelect &&
        !_showPauseMenu &&
        !_showLevelUpMenu) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
          event.logicalKey == LogicalKeyboardKey.keyW) {
        setState(() {
          _lobbySelection = (_lobbySelection + 4) % 5;
        });
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
          event.logicalKey == LogicalKeyboardKey.keyS) {
        setState(() {
          _lobbySelection = (_lobbySelection + 1) % 5;
        });
        return true;
      }

      if (isConfirmEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        _activateLobbySelectionAt(_lobbySelection);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit1) {
        _activateLobbySelectionAt(0);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit2) {
        _activateLobbySelectionAt(1);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit3) {
        _activateLobbySelectionAt(2);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit4) {
        _activateLobbySelectionAt(3);
        return true;
      }

      if (event.logicalKey == LogicalKeyboardKey.digit5) {
        _activateLobbySelectionAt(4);
        return true;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.keyE ||
        event.logicalKey == LogicalKeyboardKey.keyM) {
      _openMapEditor();
      return true;
    }

    return false;
  }

  void _handleGamepadTick(Duration timestamp) {
    if (!mounted) {
      return;
    }

    _gamepad.update();

    if (_showMapEditor) {
      final editorState = _mapEditorViewKey.currentState;
      if (editorState != null) {
        editorState.handleGamepadInput(timestamp, _gamepad);
      } else if (_gamepad.justPressedBack ||
          _gamepad.justPressedB ||
          _gamepad.justPressedStart) {
        _returnToLobby();
      }
      return;
    }

    if (_showStore) {
      var selection = _storeSelection;
      if (_gamepad.justPressedUp) {
        selection =
            (selection + survivorMetaUpgrades.length - 1) %
            survivorMetaUpgrades.length;
      } else if (_gamepad.justPressedDown) {
        selection = (selection + 1) % survivorMetaUpgrades.length;
      }

      if (selection != _storeSelection) {
        _changeStoreSelection(selection);
      }

      if (_gamepad.justPressedB || _gamepad.justPressedBack) {
        _returnToLobby();
        return;
      }

      if (_gamepad.justPressedA) {
        _purchaseStoreUpgrade(survivorMetaUpgrades[selection].type);
        return;
      }
      return;
    }

    if (_showCharacterSelect) {
      var selection = _characterSelection;
      if (_gamepad.justPressedUp) {
        selection =
            (selection + survivorCharacters.length - 1) %
            survivorCharacters.length;
      } else if (_gamepad.justPressedDown) {
        selection = (selection + 1) % survivorCharacters.length;
      }

      if (selection != _characterSelection) {
        _changeCharacterSelection(selection);
      }

      if (_gamepad.justPressedB) {
        _returnToLobby();
        return;
      }

      if (_gamepad.justPressedA) {
        _confirmCurrentCharacterSelection();
        return;
      }
      return;
    }

    if (_showWeaponSelect) {
      var selection = _weaponSelection;
      if (_gamepad.justPressedUp) {
        selection =
            (selection + survivorWeapons.length - 1) % survivorWeapons.length;
      } else if (_gamepad.justPressedDown) {
        selection = (selection + 1) % survivorWeapons.length;
      }

      if (selection != _weaponSelection) {
        _changeWeaponSelection(selection);
      }

      if (_gamepad.justPressedB) {
        _backToCharacterSelection();
        return;
      }

      if (_gamepad.justPressedA) {
        _confirmCurrentWeaponSelection();
        return;
      }
      return;
    }

    if (_showMapSelect) {
      final maps = _availableMaps;
      var selection = _mapSelection;
      if (_gamepad.justPressedUp) {
        selection = (selection + maps.length - 1) % maps.length;
      } else if (_gamepad.justPressedDown) {
        selection = (selection + 1) % maps.length;
      }

      if (selection != _mapSelection) {
        _changeMapSelection(selection);
      }

      if (_gamepad.justPressedB) {
        _backToWeaponSelection();
        return;
      }

      if (_gamepad.justPressedA) {
        _confirmCurrentMapSelection();
        return;
      }
      return;
    }

    if (_showLevelUpMenu) {
      var selection = _levelUpSelection;
      if (_gamepad.justPressedUp) {
        selection =
            (selection + _levelUpChoices.length - 1) % _levelUpChoices.length;
      } else if (_gamepad.justPressedDown) {
        selection = (selection + 1) % _levelUpChoices.length;
      }

      if (selection != _levelUpSelection) {
        setState(() => _levelUpSelection = selection);
      }

      if (_gamepad.justPressedA && _levelUpChoices.isNotEmpty) {
        _confirmCurrentLevelUpSelection();
      }
      if (_gamepad.justPressedX) {
        _rerollLevelUpChoices();
      }
      return;
    }

    if (_showGame && !_showPauseMenu) {
      final session = _session;
      if (session != null && !session.gameOver && _gamepad.justPressedStart) {
        _openPauseMenu();
        return;
      }
      if (session != null && session.gameOver) {
        var selection = _gameOverSelection;
        if (_gamepad.justPressedUp || _gamepad.justPressedDown) {
          selection = (selection + 1) % 2;
        }
        if (selection != _gameOverSelection) {
          setState(() => _gameOverSelection = selection);
        }
        if (_gamepad.justPressedB || _gamepad.justPressedStart) {
          _returnFromGameSurface();
          return;
        }
        if (_gamepad.justPressedA) {
          _activateGameOverSelectionAt(selection);
          return;
        }
      }
      return;
    }

    if (_showPauseMenu) {
      var selection = _pauseSelection;
      if (_gamepad.justPressedUp) {
        selection = (selection + 2) % 3;
      } else if (_gamepad.justPressedDown) {
        selection = (selection + 1) % 3;
      }
      if (selection != _pauseSelection) {
        setState(() => _pauseSelection = selection);
      }

      if (_gamepad.justPressedB || _gamepad.justPressedStart) {
        _resumeFromPause();
        return;
      }

      if (_gamepad.justPressedA) {
        _activatePauseSelectionAt(selection);
        return;
      }
      return;
    }

    var selection = _lobbySelection;
    if (_gamepad.justPressedUp) {
      selection = (selection + 4) % 5;
    } else if (_gamepad.justPressedDown) {
      selection = (selection + 1) % 5;
    }
    if (selection != _lobbySelection) {
      setState(() => _lobbySelection = selection);
    }

    if (_gamepad.justPressedA) {
      _activateLobbySelectionAt(selection);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget child;
    if (_showGame) {
      child = _buildGameView();
    } else if (_showMapEditor) {
      child = _buildMapEditorView();
    } else if (_showStore) {
      child = _buildStoreView();
    } else if (_showCharacterSelect) {
      child = _buildCharacterSelectView();
    } else if (_showWeaponSelect) {
      child = _buildWeaponSelectView();
    } else if (_showMapSelect) {
      child = _buildMapSelectView();
    } else {
      child = _buildLobbyView();
    }

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: child,
      ),
    );
  }

  Widget _buildLobbyView() {
    final session = _session;
    final summary = session == null
        ? '최근 세션 없음'
        : session.gameOver
        ? '최근 세션 종료됨 · ${session.characterConfig.name} · ${_sessionWeaponSummary(session)} · ${session.mapConfig.name} · ${_sessionLevelSummary(session)}'
        : '계속 가능 · ${session.characterConfig.name} · ${_sessionWeaponSummary(session)} · ${session.mapConfig.name} · ${_sessionLevelSummary(session)}';

    return DecoratedBox(
      key: const ValueKey('lobby'),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F171A), Color(0xFF1F2B21), Color(0xFF090C0E)],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SURVIVOR PROTOTYPE',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.6,
                              ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Flame으로 만든 뱀서 스타일 액션 프로토타입. 밀려오는 적을 끊어내고, 경험치를 먹고, 레벨업 카드로 빌드를 조합합니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0x44141B1F),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SESSION STATUS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                summary,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '보유 골드 ${_profile.gold}',
                                style: const TextStyle(
                                  color: Color(0xFFFFD54F),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _gamepad.isConnected
                                    ? 'Xbox 패드 연결됨\n이동: Left Stick / D-pad\n선택: A  뒤로: B  메뉴: Start'
                                    : '조작: WASD / 방향키 / 좌하단 조이스틱\n일시정지: ESC\n상점: 3\n맵 에디터: E',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    flex: 4,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xCC111315),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LobbyButton(
                            label: '1 새게임',
                            onPressed: _openCharacterSelection,
                            selected: _lobbySelection == 0,
                          ),
                          const SizedBox(height: 14),
                          LobbyButton(
                            label: '2 계속하기',
                            onPressed: _canContinue ? _continueGame : null,
                            selected: _lobbySelection == 1,
                          ),
                          const SizedBox(height: 14),
                          LobbyButton(
                            label: '3 상점',
                            onPressed: _openStore,
                            selected: _lobbySelection == 2,
                          ),
                          const SizedBox(height: 14),
                          LobbyButton(
                            label: '4 설정',
                            onPressed: _openSettings,
                            selected: _lobbySelection == 3,
                          ),
                          const SizedBox(height: 14),
                          LobbyButton(
                            label: '5 끝내기',
                            onPressed: _quitGame,
                            destructive: true,
                            selected: _lobbySelection == 4,
                          ),
                          const SizedBox(height: 18),
                          Focus(
                            canRequestFocus: false,
                            descendantsAreFocusable: false,
                            child: OutlinedButton.icon(
                              onPressed: _openMapEditor,
                              icon: const Icon(Icons.grid_on),
                              label: Text(
                                'E 맵 에디터 · 저장된 맵 ${_customMaps.length}개',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCharacterSelectView() {
    final selected = _currentCharacterChoice;
    return _buildSelectionView(
      keyName: 'character-select',
      title: '캐릭터 선택',
      subtitle: '새 런의 시작 스탯과 플레이 성향을 결정합니다.',
      instructions: _gamepad.isConnected
          ? 'D-pad/Left Stick 이동 · A 선택 · B 취소'
          : '방향키/W,S 이동 · Enter/Space 선택 · Esc 뒤로',
      accentColor: selected.accentColor,
      previewName: selected.name,
      previewRole: selected.title,
      previewDescription: selected.description,
      highlights: selected.highlights,
      backLabel: '로비로 돌아가기',
      onBack: _returnToLobby,
      optionCards: [
        for (var i = 0; i < survivorCharacters.length; i++) ...[
          SelectionOptionCard(
            accentColor: survivorCharacters[i].accentColor,
            title: survivorCharacters[i].name,
            subtitle: survivorCharacters[i].title,
            description: survivorCharacters[i].description,
            highlights: survivorCharacters[i].highlights,
            selected: survivorCharacters[i].id == selected.id,
            onTap: () => _chooseCharacter(survivorCharacters[i]),
          ),
          if (i != survivorCharacters.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildStoreView() {
    final selected = _currentStoreUpgrade;
    final currentLevel = _profile.levelFor(selected.type);
    final maxed = currentLevel >= SurvivorMetaUpgradeDefinition.maxLevel;
    final nextPrice = selected.priceForLevel(currentLevel);
    final affordable = _profile.gold >= nextPrice;

    return _buildSelectionView(
      keyName: 'store',
      title: '상점',
      subtitle: '모든 캐릭터에 영구 적용되는 기본 스탯 강화를 구매합니다.',
      instructions: _gamepad.isConnected
          ? 'D-pad/Left Stick 이동 · A 구매 · B 뒤로'
          : '방향키/W,S 이동 · Enter/Space 구매 · Esc 뒤로 · 1~6 빠른 구매',
      accentColor: selected.accentColor,
      previewName: selected.name,
      previewRole: '보유 골드 ${_profile.gold}',
      previewDescription: selected.description,
      highlights: <String>[
        selected.perLevelLabel(),
        selected.totalBonusLabel(currentLevel),
        maxed
            ? '최대 레벨 도달'
            : affordable
            ? '다음 구매 비용 ${nextPrice}G'
            : '골드 부족 · 다음 구매 비용 ${nextPrice}G',
        selected.type == SurvivorMetaUpgradeType.levelUpReroll
            ? '새 게임과 재시작 시 다시 선택 횟수로 충전'
            : '모든 캐릭터 시작 스탯에 즉시 반영',
      ],
      backLabel: '로비로 돌아가기',
      onBack: _returnToLobby,
      optionCards: [
        for (var i = 0; i < survivorMetaUpgrades.length; i++) ...[
          Builder(
            builder: (context) {
              final upgrade = survivorMetaUpgrades[i];
              final level = _profile.levelFor(upgrade.type);
              final isMaxed = level >= SurvivorMetaUpgradeDefinition.maxLevel;
              final price = upgrade.priceForLevel(level);
              return StoreUpgradeCard(
                title: upgrade.name,
                description: upgrade.description,
                level: level,
                maxLevel: SurvivorMetaUpgradeDefinition.maxLevel,
                currentBonus: upgrade.totalBonusLabel(level),
                perLevelBonus: upgrade.perLevelLabel(),
                priceLabel: isMaxed ? 'MAX' : '${price}G',
                affordable: _profile.gold >= price,
                maxed: isMaxed,
                selected: _storeSelection == i,
                accentColor: upgrade.accentColor,
                icon: upgrade.icon,
                onTap: () {
                  _changeStoreSelection(i);
                  _purchaseStoreUpgrade(upgrade.type);
                },
              );
            },
          ),
          if (i != survivorMetaUpgrades.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildWeaponSelectView() {
    final selected = _currentWeaponChoice;
    final character = _pendingCharacter ?? survivorCharacters.first;
    return _buildSelectionView(
      keyName: 'weapon-select',
      title: '무기 선택',
      subtitle: '${character.name}가 들고 나갈 시작 무기를 고릅니다.',
      instructions: _gamepad.isConnected
          ? 'D-pad/Left Stick 이동 · A 선택 · B 이전'
          : '방향키/W,S 이동 · Enter/Space 선택 · Esc 이전',
      accentColor: selected.accentColor,
      previewName: selected.name,
      previewRole: selected.title,
      previewDescription: selected.description,
      highlights: selected.highlights,
      backLabel: '캐릭터 다시 고르기',
      onBack: _backToCharacterSelection,
      optionScrollController: _weaponSelectScrollController,
      optionCards: [
        for (var i = 0; i < survivorWeapons.length; i++) ...[
          SelectionOptionCard(
            key: _weaponOptionKeyFor(survivorWeapons[i].id),
            accentColor: survivorWeapons[i].accentColor,
            title: survivorWeapons[i].name,
            subtitle: survivorWeapons[i].title,
            description: survivorWeapons[i].description,
            highlights: survivorWeapons[i].highlights,
            selected: survivorWeapons[i].id == selected.id,
            onTap: () => _chooseWeapon(survivorWeapons[i]),
          ),
          if (i != survivorWeapons.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildMapSelectView() {
    final maps = _availableMaps;
    final selected =
        _currentMapChoice ?? maps[_mapSelection.clamp(0, maps.length - 1)];
    final character = _pendingCharacter ?? survivorCharacters.first;
    final weapon = _pendingWeapon ?? survivorWeapons.first;
    return _buildSelectionView(
      keyName: 'map-select',
      title: '맵 선택',
      subtitle: '${character.name} · ${weapon.name} 조합으로 출전합니다. 전장의 성격을 고르세요.',
      instructions: _gamepad.isConnected
          ? 'D-pad/Left Stick 이동 · A 선택 · B 이전'
          : '방향키/W,S 이동 · Enter/Space 선택 · Esc 이전',
      accentColor: selected.accentColor,
      previewName: selected.name,
      previewRole: selected.title,
      previewDescription: selected.description,
      highlights: selected.highlights,
      backLabel: '무기 다시 고르기',
      onBack: _backToWeaponSelection,
      optionScrollController: _mapSelectScrollController,
      optionCards: [
        for (var i = 0; i < maps.length; i++) ...[
          SelectionOptionCard(
            key: _mapOptionKeyFor(maps[i].id),
            accentColor: maps[i].accentColor,
            title: maps[i].name,
            subtitle: maps[i].title,
            description: maps[i].description,
            highlights: maps[i].highlights,
            selected: maps[i].id == selected.id,
            onTap: () => _chooseMap(maps[i]),
          ),
          if (i != maps.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildMapEditorView() {
    return MapEditorView(
      key: _mapEditorViewKey,
      existingMaps: _customMaps,
      initialDraft: _mapEditorDraft,
      onSave: _handleMapSaved,
      onTest: _testMapFromEditor,
      onDelete: _handleMapDeleted,
      onDraftChanged: _handleMapEditorDraftChanged,
      onBack: _returnToLobby,
    );
  }

  Widget _buildSelectionView({
    required String keyName,
    required String title,
    required String subtitle,
    required String instructions,
    required Color accentColor,
    required String previewName,
    required String previewRole,
    required String previewDescription,
    required List<String> highlights,
    required String backLabel,
    required VoidCallback onBack,
    required List<Widget> optionCards,
    ScrollController? optionScrollController,
  }) {
    return DecoratedBox(
      key: ValueKey<String>(keyName),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0B1114),
            accentColor.withValues(alpha: 0.12),
            const Color(0xFF090C0E),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                  ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              instructions,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 28),
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: const Color(0xCC111315),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    previewName,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    previewRole,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    previewDescription,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  for (final highlight in highlights) ...[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 5,
                                          ),
                                          child: Icon(
                                            Icons.circle,
                                            size: 8,
                                            color: accentColor,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            highlight,
                                            style: const TextStyle(
                                              color: Colors.white60,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            Focus(
                              canRequestFocus: false,
                              descendantsAreFocusable: false,
                              child: TextButton.icon(
                                onPressed: onBack,
                                icon: const Icon(Icons.arrow_back),
                                label: Text(backLabel),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xCC111315),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Scrollbar(
                        controller: optionScrollController,
                        thumbVisibility: optionScrollController != null,
                        child: SingleChildScrollView(
                          controller: optionScrollController,
                          padding: const EdgeInsets.only(right: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: optionCards,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameView() {
    final session = _session!;
    final player = session.playerOrNull;
    session.showMinimap = _showMinimap;
    if (!_showPauseMenu && !_showLevelUpMenu && !session.gameOver) {
      session.resumeEngine();
    }

    return DecoratedBox(
      key: ValueKey<String>(
        'game-${session.characterConfig.id}-${session.weaponConfig.id}-${session.mapConfig.id}-${_isMapEditorTestSession ? 'editor' : 'run'}',
      ),
      decoration: const BoxDecoration(color: Color(0xFF111315)),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Survivor Prototype',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Focus(
                        canRequestFocus: false,
                        descendantsAreFocusable: false,
                        child: TextButton.icon(
                          onPressed: _returnFromGameSurface,
                          icon: const Icon(Icons.arrow_back),
                          label: Text(_gameExitLabel),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${session.characterConfig.name} · ${player?.equippedWeaponNames ?? session.weaponConfig.name} · ${session.mapConfig.name} · ${_isMapEditorTestSession ? '맵 에디터 테스트' : '30분 생존 런'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white12),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF182025), Color(0xFF0C1013)],
                          ),
                        ),
                        child: GameWidget(
                          key: ObjectKey(session),
                          game: session,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_showLevelUpMenu)
              LevelUpOverlay(
                choices: _levelUpChoices,
                selectedIndex: _levelUpSelection,
                rerollsRemaining: session.levelUpRerollsRemaining,
                maxRerolls: session.maxLevelUpRerolls,
                onSelectionChanged: _changeLevelUpSelection,
                onSelected: _chooseLevelUp,
                onReroll: _rerollLevelUpChoices,
              ),
            if (_showPauseMenu)
              PauseOverlay(
                characterName: session.characterConfig.name,
                stats: _buildPauseStats(session),
                selectedIndex: _pauseSelection,
                onResume: _resumeFromPause,
                onRestart: _restartFromPause,
                onExit: _returnFromGameSurface,
                exitLabel: _gameExitLabel,
              ),
            if (session.gameOver)
              GameOverMenuOverlay(
                playerWon: session.playerWon,
                elapsedLabel: session.formatClock(session.elapsedTime.floor()),
                level: player?.level ?? 1,
                kills: player?.kills ?? 0,
                earnedGold: session.runGold,
                totalGold: _profile.gold,
                selectedIndex: _gameOverSelection,
                onRestart: _restartFromGameOver,
                onExit: _returnFromGameSurface,
                exitLabel: _gameExitLabel,
              ),
          ],
        ),
      ),
    );
  }
}
