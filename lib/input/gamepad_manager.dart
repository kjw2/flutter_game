import 'dart:io';

import 'package:win32_gamepad/win32_gamepad.dart';

class GamepadManager {
  GamepadManager._();

  static final GamepadManager instance = GamepadManager._();

  Gamepad? _gamepad;
  bool _initialized = false;
  bool _available = false;
  bool _connected = false;

  double moveX = 0;
  double moveY = 0;

  bool _previousA = false;
  bool _previousB = false;
  bool _previousBack = false;
  bool _previousStart = false;
  bool _previousX = false;
  bool _previousY = false;
  bool _previousLeftShoulder = false;
  bool _previousRightShoulder = false;
  bool _previousUp = false;
  bool _previousDown = false;

  bool justPressedA = false;
  bool justPressedB = false;
  bool justPressedBack = false;
  bool justPressedStart = false;
  bool justPressedX = false;
  bool justPressedY = false;
  bool justPressedLeftShoulder = false;
  bool justPressedRightShoulder = false;
  bool justPressedUp = false;
  bool justPressedDown = false;

  bool get isAvailable => _available;
  bool get isConnected => _connected;

  void update() {
    _ensureInitialized();
    justPressedA = false;
    justPressedB = false;
    justPressedBack = false;
    justPressedStart = false;
    justPressedX = false;
    justPressedY = false;
    justPressedLeftShoulder = false;
    justPressedRightShoulder = false;
    justPressedUp = false;
    justPressedDown = false;

    if (!_available || _gamepad == null) {
      moveX = 0;
      moveY = 0;
      _connected = false;
      return;
    }

    try {
      _gamepad!.updateState();
      final state = _gamepad!.state;
      _connected = state.isConnected;

      if (!_connected) {
        moveX = 0;
        moveY = 0;
        _cacheButtons(
          a: false,
          b: false,
          back: false,
          start: false,
          x: false,
          y: false,
          leftShoulder: false,
          rightShoulder: false,
          up: false,
          down: false,
        );
        return;
      }

      final stickX = _normalizeAxis(state.leftThumbstickX, 7849);
      final stickY = _normalizeAxis(state.leftThumbstickY, 7849);
      moveX = stickX;
      moveY = -stickY;

      final dpadUp = state.dpadUp;
      final dpadDown = state.dpadDown;
      final dpadLeft = state.dpadLeft;
      final dpadRight = state.dpadRight;

      if (moveX.abs() < 0.2 && moveY.abs() < 0.2) {
        moveX = (dpadRight ? 1 : 0) - (dpadLeft ? 1 : 0);
        moveY = (dpadDown ? 1 : 0) - (dpadUp ? 1 : 0);
      }

      final buttonA = state.buttonA;
      final buttonB = state.buttonB;
      final buttonBack = state.buttonBack;
      final buttonStart = state.buttonStart;
      final buttonX = state.buttonX;
      final buttonY = state.buttonY;
      final leftShoulder = state.leftShoulder;
      final rightShoulder = state.rightShoulder;
      final navUp = dpadUp || stickY > 0.7;
      final navDown = dpadDown || stickY < -0.7;

      justPressedA = buttonA && !_previousA;
      justPressedB = buttonB && !_previousB;
      justPressedBack = buttonBack && !_previousBack;
      justPressedStart = buttonStart && !_previousStart;
      justPressedX = buttonX && !_previousX;
      justPressedY = buttonY && !_previousY;
      justPressedLeftShoulder = leftShoulder && !_previousLeftShoulder;
      justPressedRightShoulder = rightShoulder && !_previousRightShoulder;
      justPressedUp = navUp && !_previousUp;
      justPressedDown = navDown && !_previousDown;

      _cacheButtons(
        a: buttonA,
        b: buttonB,
        back: buttonBack,
        start: buttonStart,
        x: buttonX,
        y: buttonY,
        leftShoulder: leftShoulder,
        rightShoulder: rightShoulder,
        up: navUp,
        down: navDown,
      );
    } catch (_) {
      moveX = 0;
      moveY = 0;
      _connected = false;
    }
  }

  void _ensureInitialized() {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (!Platform.isWindows) {
      return;
    }

    try {
      _gamepad = Gamepad(0);
      _available = true;
    } catch (_) {
      _available = false;
    }
  }

  void _cacheButtons({
    required bool a,
    required bool b,
    required bool back,
    required bool start,
    required bool x,
    required bool y,
    required bool leftShoulder,
    required bool rightShoulder,
    required bool up,
    required bool down,
  }) {
    _previousA = a;
    _previousB = b;
    _previousBack = back;
    _previousStart = start;
    _previousX = x;
    _previousY = y;
    _previousLeftShoulder = leftShoulder;
    _previousRightShoulder = rightShoulder;
    _previousUp = up;
    _previousDown = down;
  }

  double _normalizeAxis(int value, int deadzone) {
    if (value.abs() <= deadzone) {
      return 0;
    }
    final raw = value < 0
        ? (value + deadzone) / (32768 - deadzone)
        : (value - deadzone) / (32767 - deadzone);
    return raw.clamp(-1.0, 1.0);
  }
}
