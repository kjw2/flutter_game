import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/survivor_floor_tiles.dart';
import '../../game/survivor_run_config.dart';
import '../../input/gamepad_manager.dart';

class MapEditorDraft {
  const MapEditorDraft({
    this.editingId,
    this.name = '새 커스텀 맵',
    this.widthCells = 24,
    this.heightCells = 18,
    this.floorType = SurvivorMapFloorType.dirt,
    this.backgroundStyle = SurvivorMapBackgroundStyle.grid,
    this.floorColor = const Color(0xFF101517),
    this.gridColor = const Color(0xFF1B2529),
    this.detailColor = const Color(0xFF58B7D5),
    this.obstacleType = SurvivorMapObstacleType.wall,
    this.tool = MapEditorObstacleTool.paint,
    this.placementMode = MapEditorPlacementMode.brush,
    this.brushSize = MapEditorBrushSize.small,
    this.cursorX = 2,
    this.cursorY = 2,
    this.obstacles = const <SurvivorMapObstacle>[],
  });

  factory MapEditorDraft.fromMap(SurvivorMapConfig map) {
    return MapEditorDraft(
      editingId: map.id,
      name: map.name,
      widthCells: map.widthCells,
      heightCells: map.heightCells,
      floorType: map.floorType,
      backgroundStyle: map.backgroundStyle,
      floorColor: map.floorColor,
      gridColor: map.gridColor,
      detailColor: map.detailColor,
      obstacleType: map.obstacles.isEmpty
          ? SurvivorMapObstacleType.wall
          : map.obstacles.last.type,
      placementMode: MapEditorPlacementMode.brush,
      cursorX: 2,
      cursorY: 2,
      obstacles: map.obstacles,
    );
  }

  final String? editingId;
  final String name;
  final int widthCells;
  final int heightCells;
  final SurvivorMapFloorType floorType;
  final SurvivorMapBackgroundStyle backgroundStyle;
  final Color floorColor;
  final Color gridColor;
  final Color detailColor;
  final SurvivorMapObstacleType obstacleType;
  final MapEditorObstacleTool tool;
  final MapEditorPlacementMode placementMode;
  final MapEditorBrushSize brushSize;
  final int cursorX;
  final int cursorY;
  final List<SurvivorMapObstacle> obstacles;
}

class MapEditorView extends StatefulWidget {
  const MapEditorView({
    super.key,
    required this.existingMaps,
    required this.initialDraft,
    required this.onSave,
    required this.onTest,
    required this.onDelete,
    required this.onDraftChanged,
    required this.onBack,
  });

  final List<SurvivorMapConfig> existingMaps;
  final MapEditorDraft initialDraft;
  final Future<void> Function(SurvivorMapConfig map) onSave;
  final Future<void> Function(SurvivorMapConfig map) onTest;
  final Future<void> Function(String id) onDelete;
  final ValueChanged<MapEditorDraft> onDraftChanged;
  final VoidCallback onBack;

  @override
  State<MapEditorView> createState() => MapEditorViewState();
}

class MapEditorViewState extends State<MapEditorView> {
  static const int _historyLimit = 80;

  final TextEditingController _nameController = TextEditingController(
    text: '새 커스텀 맵',
  );
  final FocusNode _editorFocusNode = FocusNode(debugLabel: 'map-editor');
  final math.Random _random = math.Random();
  final Map<_GridCell, SurvivorMapObstacleType> _obstacles =
      <_GridCell, SurvivorMapObstacleType>{};
  final List<_MapEditorHistorySnapshot> _undoStack =
      <_MapEditorHistorySnapshot>[];
  final List<_MapEditorHistorySnapshot> _redoStack =
      <_MapEditorHistorySnapshot>[];

  _GridCell _cursorCell = const _GridCell(2, 2);
  int _widthCells = 24;
  int _heightCells = 18;
  SurvivorMapFloorType _floorType = SurvivorMapFloorType.dirt;
  SurvivorMapBackgroundStyle _backgroundStyle = SurvivorMapBackgroundStyle.grid;
  Color _floorColor = const Color(0xFF101517);
  Color _gridColor = const Color(0xFF1B2529);
  Color _detailColor = const Color(0xFF58B7D5);
  SurvivorMapObstacleType _obstacleType = SurvivorMapObstacleType.wall;
  MapEditorObstacleTool _tool = MapEditorObstacleTool.paint;
  MapEditorPlacementMode _placementMode = MapEditorPlacementMode.brush;
  MapEditorBrushSize _brushSize = MapEditorBrushSize.small;
  String? _editingId;
  bool _saving = false;
  bool _testing = false;
  bool _isRestoringDraft = false;
  _GridCell? _heldGamepadDirection;
  _GridCell? _shapeAnchor;
  Duration _nextGamepadCursorMoveAt = Duration.zero;

  static const Duration _initialGamepadRepeatDelay = Duration(
    milliseconds: 240,
  );
  static const Duration _gamepadRepeatInterval = Duration(milliseconds: 95);

  bool get _canUndo => _undoStack.isNotEmpty;
  bool get _canRedo => _redoStack.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_publishDraft);
    _restoreDraft(widget.initialDraft);
  }

  @override
  void dispose() {
    _nameController.removeListener(_publishDraft);
    _nameController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _restoreDraft(MapEditorDraft draft) {
    _isRestoringDraft = true;
    _clearHistory();
    _editingId = draft.editingId;
    _nameController.text = draft.name;
    _widthCells = draft.widthCells;
    _heightCells = draft.heightCells;
    _floorType = draft.floorType;
    _backgroundStyle = draft.backgroundStyle;
    _floorColor = draft.floorColor;
    _gridColor = draft.gridColor;
    _detailColor = draft.detailColor;
    _obstacleType = draft.obstacleType;
    _tool = draft.tool;
    _placementMode = draft.placementMode;
    _brushSize = draft.brushSize;
    _cursorCell = _clampCell(_GridCell(draft.cursorX, draft.cursorY));
    _shapeAnchor = null;
    _obstacles
      ..clear()
      ..addEntries(
        draft.obstacles.map(
          (obstacle) => MapEntry(
            _GridCell(obstacle.gridX, obstacle.gridY),
            obstacle.type,
          ),
        ),
      );
    _isRestoringDraft = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _publishDraft();
      }
    });
  }

  MapEditorDraft _currentDraft() {
    final obstacleEntries = _sortedObstacleEntries();
    return MapEditorDraft(
      editingId: _editingId,
      name: _nameController.text,
      widthCells: _widthCells,
      heightCells: _heightCells,
      floorType: _floorType,
      backgroundStyle: _backgroundStyle,
      floorColor: _floorColor,
      gridColor: _gridColor,
      detailColor: _detailColor,
      obstacleType: _obstacleType,
      tool: _tool,
      placementMode: _placementMode,
      brushSize: _brushSize,
      cursorX: _cursorCell.x,
      cursorY: _cursorCell.y,
      obstacles: obstacleEntries
          .map(
            (entry) => SurvivorMapObstacle(
              gridX: entry.key.x,
              gridY: entry.key.y,
              type: entry.value,
            ),
          )
          .toList(growable: false),
    );
  }

  List<MapEntry<_GridCell, SurvivorMapObstacleType>> _sortedObstacleEntries() {
    final entries = _obstacles.entries.toList(growable: false);
    entries.sort(
      (a, b) => a.key.y != b.key.y
          ? a.key.y.compareTo(b.key.y)
          : a.key.x.compareTo(b.key.x),
    );
    return entries;
  }

  void _publishDraft() {
    if (_isRestoringDraft) {
      return;
    }
    widget.onDraftChanged(_currentDraft());
  }

  _MapEditorHistorySnapshot _createHistorySnapshot() {
    return _MapEditorHistorySnapshot(
      widthCells: _widthCells,
      heightCells: _heightCells,
      floorType: _floorType,
      backgroundStyle: _backgroundStyle,
      floorColor: _floorColor,
      gridColor: _gridColor,
      detailColor: _detailColor,
      cursorCell: _cursorCell,
      obstacles: Map<_GridCell, SurvivorMapObstacleType>.from(_obstacles),
    );
  }

  void _clearHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void _pushUndoSnapshot() {
    _undoStack.add(_createHistorySnapshot());
    if (_undoStack.length > _historyLimit) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  void _restoreHistorySnapshot(
    _MapEditorHistorySnapshot snapshot, {
    required List<_MapEditorHistorySnapshot> pushTo,
  }) {
    pushTo.add(_createHistorySnapshot());
    if (pushTo.length > _historyLimit) {
      pushTo.removeAt(0);
    }

    setState(() {
      _widthCells = snapshot.widthCells;
      _heightCells = snapshot.heightCells;
      _floorType = snapshot.floorType;
      _backgroundStyle = snapshot.backgroundStyle;
      _floorColor = snapshot.floorColor;
      _gridColor = snapshot.gridColor;
      _detailColor = snapshot.detailColor;
      _cursorCell = _clampCell(snapshot.cursorCell);
      _shapeAnchor = null;
      _obstacles
        ..clear()
        ..addAll(snapshot.obstacles);
    });
    _focusEditor();
    _publishDraft();
  }

  void _undo() {
    if (_undoStack.isEmpty) {
      return;
    }
    final snapshot = _undoStack.removeLast();
    _restoreHistorySnapshot(snapshot, pushTo: _redoStack);
  }

  void _redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    final snapshot = _redoStack.removeLast();
    _restoreHistorySnapshot(snapshot, pushTo: _undoStack);
  }

  bool get _isTypingInTextField {
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext == null) {
      return false;
    }
    return focusedContext.widget is EditableText;
  }

  _GridCell _clampCell(_GridCell cell) {
    return _GridCell(
      cell.x.clamp(0, _widthCells - 1).toInt(),
      cell.y.clamp(0, _heightCells - 1).toInt(),
    );
  }

  void _focusEditor() {
    if (_editorFocusNode.canRequestFocus) {
      _editorFocusNode.requestFocus();
    }
  }

  void _setObstacleType(SurvivorMapObstacleType type) {
    if (_obstacleType == type) {
      return;
    }
    setState(() => _obstacleType = type);
    _publishDraft();
  }

  void _setFloorType(SurvivorMapFloorType type) {
    if (_floorType == type) {
      return;
    }
    _pushUndoSnapshot();
    setState(() => _floorType = type);
    _publishDraft();
  }

  void _setPlacementMode(MapEditorPlacementMode mode) {
    if (_placementMode == mode) {
      return;
    }
    setState(() {
      _placementMode = mode;
      _shapeAnchor = null;
    });
    _publishDraft();
  }

  void _setTool(MapEditorObstacleTool tool) {
    if (_tool == tool) {
      return;
    }
    setState(() {
      _tool = tool;
      _shapeAnchor = null;
    });
    _publishDraft();
  }

  void _setBrushSize(MapEditorBrushSize brushSize) {
    if (_brushSize == brushSize) {
      return;
    }
    setState(() => _brushSize = brushSize);
    _publishDraft();
  }

  void _cycleObstacleType(int delta) {
    final values = SurvivorMapObstacleType.values;
    final nextIndex =
        (_obstacleType.index + delta + values.length) % values.length;
    _setObstacleType(values[nextIndex]);
  }

  void _cyclePlacementMode(int delta) {
    final values = MapEditorPlacementMode.values;
    final nextIndex =
        (_placementMode.index + delta + values.length) % values.length;
    _setPlacementMode(values[nextIndex]);
  }

  void _toggleTool() {
    _setTool(
      _tool == MapEditorObstacleTool.paint
          ? MapEditorObstacleTool.erase
          : MapEditorObstacleTool.paint,
    );
  }

  void _clearObstacles() {
    if (_obstacles.isEmpty) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      _obstacles.clear();
      _shapeAnchor = null;
    });
    _publishDraft();
  }

  void _cancelShapeAnchor() {
    if (_shapeAnchor == null) {
      return;
    }
    setState(() => _shapeAnchor = null);
    _publishDraft();
  }

  void _handleBackShortcut() {
    if (_isTypingInTextField) {
      FocusManager.instance.primaryFocus?.unfocus();
      _focusEditor();
      return;
    }
    if (_shapeAnchor != null) {
      _cancelShapeAnchor();
      return;
    }
    widget.onBack();
  }

  void _runEditorShortcut(
    VoidCallback action, {
    bool allowWhileTyping = false,
  }) {
    if (!allowWhileTyping && _isTypingInTextField) {
      return;
    }
    action();
  }

  void _runEditorAsyncShortcut(
    Future<void> Function() action, {
    bool allowWhileTyping = false,
  }) {
    if (!allowWhileTyping && _isTypingInTextField) {
      return;
    }
    unawaited(action());
  }

  void _moveCursorBy(int dx, int dy) {
    final nextCell = _clampCell(
      _GridCell(_cursorCell.x + dx, _cursorCell.y + dy),
    );
    if (nextCell == _cursorCell) {
      return;
    }
    setState(() => _cursorCell = nextCell);
    _publishDraft();
  }

  void _applyToolAtCursor() {
    _applyPlacementAt(_cursorCell);
  }

  _GridCell? _directionFromGamepad(GamepadManager gamepad) {
    const threshold = 0.55;
    final horizontal = gamepad.moveX;
    final vertical = gamepad.moveY;
    if (horizontal.abs() < threshold && vertical.abs() < threshold) {
      return null;
    }

    if (horizontal.abs() >= vertical.abs()) {
      return _GridCell(horizontal >= 0 ? 1 : -1, 0);
    }
    return _GridCell(0, vertical >= 0 ? 1 : -1);
  }

  void handleGamepadInput(Duration now, GamepadManager gamepad) {
    if (!mounted) {
      return;
    }

    if (gamepad.justPressedBack) {
      if (_shapeAnchor != null) {
        _cancelShapeAnchor();
        return;
      }
      if (_canUndo) {
        _undo();
        return;
      }
      widget.onBack();
      return;
    }

    if (gamepad.justPressedB || gamepad.justPressedStart) {
      if (_shapeAnchor != null) {
        _cancelShapeAnchor();
        return;
      }
      widget.onBack();
      return;
    }

    if (gamepad.justPressedX) {
      _toggleTool();
    }
    if (gamepad.justPressedY) {
      _cyclePlacementMode(1);
    }
    if (gamepad.justPressedLeftShoulder) {
      _cycleObstacleType(-1);
    }
    if (gamepad.justPressedRightShoulder) {
      _cycleObstacleType(1);
    }
    if (gamepad.justPressedA) {
      _applyToolAtCursor();
    }

    final direction = _directionFromGamepad(gamepad);
    if (direction == null) {
      _heldGamepadDirection = null;
      _nextGamepadCursorMoveAt = Duration.zero;
      return;
    }

    if (_heldGamepadDirection != direction) {
      _heldGamepadDirection = direction;
      _nextGamepadCursorMoveAt = now + _initialGamepadRepeatDelay;
      _moveCursorBy(direction.x, direction.y);
      return;
    }

    if (now >= _nextGamepadCursorMoveAt) {
      _nextGamepadCursorMoveAt = now + _gamepadRepeatInterval;
      _moveCursorBy(direction.x, direction.y);
    }
  }

  bool _isEditableCell(_GridCell cell) {
    return cell.x >= 0 &&
        cell.y >= 0 &&
        cell.x < _widthCells &&
        cell.y < _heightCells &&
        !_isProtectedCell(cell.x, cell.y);
  }

  Set<_GridCell> _sanitizeCells(Iterable<_GridCell> cells) {
    return cells.where(_isEditableCell).toSet();
  }

  Set<_GridCell> _lineCells(_GridCell start, _GridCell end) {
    final cells = <_GridCell>{};
    var x0 = start.x;
    var y0 = start.y;
    final x1 = end.x;
    final y1 = end.y;
    final dx = (x1 - x0).abs();
    final dy = (y1 - y0).abs();
    final sx = x0 < x1 ? 1 : -1;
    final sy = y0 < y1 ? 1 : -1;
    var error = dx - dy;

    while (true) {
      cells.add(_GridCell(x0, y0));
      if (x0 == x1 && y0 == y1) {
        break;
      }
      final doubledError = error * 2;
      if (doubledError > -dy) {
        error -= dy;
        x0 += sx;
      }
      if (doubledError < dx) {
        error += dx;
        y0 += sy;
      }
    }

    return cells;
  }

  Set<_GridCell> _rectangleCells(_GridCell start, _GridCell end) {
    final cells = <_GridCell>{};
    final left = math.min(start.x, end.x);
    final right = math.max(start.x, end.x);
    final top = math.min(start.y, end.y);
    final bottom = math.max(start.y, end.y);

    for (var y = top; y <= bottom; y++) {
      for (var x = left; x <= right; x++) {
        cells.add(_GridCell(x, y));
      }
    }
    return cells;
  }

  Set<_GridCell> _brushExpandedCells(Iterable<_GridCell> seed) {
    final cells = <_GridCell>{};
    for (final cell in seed) {
      cells.addAll(_brushCells(cell.x, cell.y));
    }
    return cells;
  }

  Set<_GridCell> _cellsForPlacement(_GridCell start, _GridCell end) {
    switch (_placementMode) {
      case MapEditorPlacementMode.brush:
        return _sanitizeCells(_brushCells(end.x, end.y));
      case MapEditorPlacementMode.line:
        return _sanitizeCells(_brushExpandedCells(_lineCells(start, end)));
      case MapEditorPlacementMode.rectangle:
        return _sanitizeCells(_rectangleCells(start, end));
    }
  }

  Set<_GridCell> _currentPreviewCells() {
    if (_placementMode == MapEditorPlacementMode.brush) {
      return _cellsForPlacement(_cursorCell, _cursorCell);
    }
    final anchor = _shapeAnchor;
    if (anchor == null) {
      return <_GridCell>{_cursorCell};
    }
    return _cellsForPlacement(anchor, _cursorCell);
  }

  void _applyToolToCells(
    Iterable<_GridCell> cells, {
    required _GridCell cursor,
    bool clearAnchor = false,
  }) {
    final editableCells = _sanitizeCells(cells);
    final hasContentChange = editableCells.any((cell) {
      return switch (_tool) {
        MapEditorObstacleTool.paint => _obstacles[cell] != _obstacleType,
        MapEditorObstacleTool.erase => _obstacles.containsKey(cell),
      };
    });

    if (hasContentChange) {
      _pushUndoSnapshot();
    }

    setState(() {
      _cursorCell = _clampCell(cursor);
      if (clearAnchor) {
        _shapeAnchor = null;
      }
      for (final cell in editableCells) {
        switch (_tool) {
          case MapEditorObstacleTool.paint:
            _obstacles[cell] = _obstacleType;
            break;
          case MapEditorObstacleTool.erase:
            _obstacles.remove(cell);
            break;
        }
      }
    });
    _focusEditor();
    _publishDraft();
  }

  void _applyPlacementAt(_GridCell cell) {
    final clampedCell = _clampCell(cell);
    if (_placementMode == MapEditorPlacementMode.brush) {
      _applyToolToCells(
        _cellsForPlacement(clampedCell, clampedCell),
        cursor: clampedCell,
      );
      return;
    }

    final anchor = _shapeAnchor;
    if (anchor == null) {
      setState(() {
        _cursorCell = clampedCell;
        _shapeAnchor = clampedCell;
      });
      _focusEditor();
      _publishDraft();
      return;
    }

    _applyToolToCells(
      _cellsForPlacement(anchor, clampedCell),
      cursor: clampedCell,
      clearAnchor: true,
    );
  }

  void _beginShapeDrag(_GridCell cell) {
    if (_placementMode == MapEditorPlacementMode.brush) {
      _applyPlacementAt(cell);
      return;
    }
    final clampedCell = _clampCell(cell);
    setState(() {
      _cursorCell = clampedCell;
      _shapeAnchor = clampedCell;
    });
    _focusEditor();
    _publishDraft();
  }

  void _updateShapeDrag(_GridCell cell) {
    if (_placementMode == MapEditorPlacementMode.brush) {
      _applyPlacementAt(cell);
      return;
    }
    final clampedCell = _clampCell(cell);
    if (clampedCell == _cursorCell) {
      return;
    }
    setState(() => _cursorCell = clampedCell);
    _publishDraft();
  }

  void _finishShapeDrag() {
    if (_placementMode == MapEditorPlacementMode.brush ||
        _shapeAnchor == null) {
      return;
    }
    _applyPlacementAt(_cursorCell);
  }

  void _applyPreset(_EditorBackgroundPreset preset) {
    final matchesCurrent =
        _floorType == preset.floorType &&
        _backgroundStyle == preset.style &&
        _floorColor == preset.floorColor &&
        _gridColor == preset.gridColor &&
        _detailColor == preset.detailColor;
    if (matchesCurrent) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      _floorType = preset.floorType;
      _backgroundStyle = preset.style;
      _floorColor = preset.floorColor;
      _gridColor = preset.gridColor;
      _detailColor = preset.detailColor;
    });
    _publishDraft();
  }

  void _randomizeBackground() {
    _applyPreset(
      _backgroundPresets[_random.nextInt(_backgroundPresets.length)],
    );
  }

  void _setSize({int? widthCells, int? heightCells}) {
    final nextWidth = widthCells ?? _widthCells;
    final nextHeight = heightCells ?? _heightCells;
    if (nextWidth == _widthCells && nextHeight == _heightCells) {
      return;
    }
    _pushUndoSnapshot();
    setState(() {
      _widthCells = nextWidth;
      _heightCells = nextHeight;
      _cursorCell = _clampCell(_cursorCell);
      _shapeAnchor = _shapeAnchor == null ? null : _clampCell(_shapeAnchor!);
      _obstacles.removeWhere(
        (cell, _) =>
            cell.x >= _widthCells ||
            cell.y >= _heightCells ||
            _isProtectedCell(cell.x, cell.y),
      );
    });
    _publishDraft();
  }

  bool _isProtectedCell(int x, int y) {
    final dx = (x + 0.5) - (_widthCells / 2);
    final dy = (y + 0.5) - (_heightCells / 2);
    return dx.abs() <= 1 && dy.abs() <= 1;
  }

  void _applyToolAt(int x, int y) {
    _applyPlacementAt(_GridCell(x, y));
  }

  Iterable<_GridCell> _brushCells(int x, int y) sync* {
    final radius = _brushSize.radius;
    for (var dy = -radius; dy <= radius; dy++) {
      for (var dx = -radius; dx <= radius; dx++) {
        yield _GridCell(x + dx, y + dy);
      }
    }
  }

  SurvivorMapConfig _buildDraft() {
    final id = _editingId ?? 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final name = _nameController.text.trim().isEmpty
        ? '커스텀 맵'
        : _nameController.text.trim();
    final obstacleEntries = _sortedObstacleEntries();

    return SurvivorMapConfig.custom(
      id: id,
      name: name,
      widthCells: _widthCells,
      heightCells: _heightCells,
      floorType: _floorType,
      floorColor: _floorColor,
      gridColor: _gridColor,
      detailColor: _detailColor,
      backgroundStyle: _backgroundStyle,
      obstacles: obstacleEntries
          .map(
            (entry) => SurvivorMapObstacle(
              gridX: entry.key.x,
              gridY: entry.key.y,
              type: entry.value,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<SurvivorMapConfig?> _saveDraft({bool showFeedback = true}) async {
    if (_saving) {
      return null;
    }

    final draft = _buildDraft();
    setState(() => _saving = true);
    await widget.onSave(draft);
    if (!mounted) {
      return null;
    }

    setState(() {
      _saving = false;
      _editingId = draft.id;
    });
    _publishDraft();

    if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${draft.name} 저장 완료. 맵 선택 화면에 바로 반영됩니다.')),
      );
    }
    return draft;
  }

  Future<void> _testDraft() async {
    if (_saving || _testing) {
      return;
    }

    setState(() => _testing = true);
    final draft = await _saveDraft(showFeedback: false);
    if (!mounted || draft == null) {
      if (mounted) {
        setState(() => _testing = false);
      }
      return;
    }

    await widget.onTest(draft);
    if (!mounted) {
      return;
    }
    setState(() => _testing = false);
  }

  void _loadExistingMap(SurvivorMapConfig map) {
    setState(() {
      _clearHistory();
      _editingId = map.id;
      _nameController.text = map.name;
      _widthCells = map.widthCells;
      _heightCells = map.heightCells;
      _floorType = map.floorType;
      _backgroundStyle = map.backgroundStyle;
      _floorColor = map.floorColor;
      _gridColor = map.gridColor;
      _detailColor = map.detailColor;
      _obstacleType = map.obstacles.isEmpty
          ? SurvivorMapObstacleType.wall
          : map.obstacles.last.type;
      _placementMode = MapEditorPlacementMode.brush;
      _cursorCell = _clampCell(_cursorCell);
      _shapeAnchor = null;
      _obstacles
        ..clear()
        ..addEntries(
          map.obstacles.map(
            (obstacle) => MapEntry(
              _GridCell(obstacle.gridX, obstacle.gridY),
              obstacle.type,
            ),
          ),
        );
    });
    _publishDraft();
  }

  Future<void> _deleteExistingMap(SurvivorMapConfig map) async {
    await widget.onDelete(map.id);
    if (!mounted) {
      return;
    }

    if (_editingId == map.id) {
      setState(() {
        _clearHistory();
        _editingId = null;
        _nameController.text = '새 커스텀 맵';
        _obstacles.clear();
        _shapeAnchor = null;
        _floorType = SurvivorMapFloorType.dirt;
      });
      _publishDraft();
    }
  }

  @override
  Widget build(BuildContext context) {
    final obstacleCount = _obstacles.length;
    final wallCount = _obstacles.values
        .where((type) => type == SurvivorMapObstacleType.wall)
        .length;
    final pillarCount = _obstacles.values
        .where((type) => type == SurvivorMapObstacleType.pillar)
        .length;
    final mireCount = _obstacles.values
        .where((type) => type == SurvivorMapObstacleType.mire)
        .length;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            _runEditorShortcut(_undo, allowWhileTyping: true),
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () =>
            _runEditorShortcut(_redo, allowWhileTyping: true),
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () =>
            _runEditorShortcut(_redo, allowWhileTyping: true),
        const SingleActivator(LogicalKeyboardKey.escape): _handleBackShortcut,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            _runEditorAsyncShortcut(_saveDraft, allowWhileTyping: true),
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () =>
            _runEditorAsyncShortcut(_testDraft, allowWhileTyping: true),
        const SingleActivator(LogicalKeyboardKey.keyG): () =>
            _runEditorShortcut(_randomizeBackground),
        const SingleActivator(LogicalKeyboardKey.keyP): () =>
            _runEditorShortcut(() => _setTool(MapEditorObstacleTool.paint)),
        const SingleActivator(LogicalKeyboardKey.keyE): () =>
            _runEditorShortcut(() => _setTool(MapEditorObstacleTool.erase)),
        const SingleActivator(LogicalKeyboardKey.keyV): () =>
            _runEditorShortcut(
              () => _setPlacementMode(MapEditorPlacementMode.brush),
            ),
        const SingleActivator(LogicalKeyboardKey.keyL): () =>
            _runEditorShortcut(
              () => _setPlacementMode(MapEditorPlacementMode.line),
            ),
        const SingleActivator(LogicalKeyboardKey.keyR): () =>
            _runEditorShortcut(
              () => _setPlacementMode(MapEditorPlacementMode.rectangle),
            ),
        const SingleActivator(LogicalKeyboardKey.tab): () =>
            _runEditorShortcut(() => _cyclePlacementMode(1)),
        const SingleActivator(LogicalKeyboardKey.keyZ): () =>
            _runEditorShortcut(() => _setBrushSize(MapEditorBrushSize.small)),
        const SingleActivator(LogicalKeyboardKey.keyX): () =>
            _runEditorShortcut(() => _setBrushSize(MapEditorBrushSize.medium)),
        const SingleActivator(LogicalKeyboardKey.keyC): () =>
            _runEditorShortcut(() => _setBrushSize(MapEditorBrushSize.large)),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _runEditorShortcut(() => _moveCursorBy(-1, 0)),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _runEditorShortcut(() => _moveCursorBy(1, 0)),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _runEditorShortcut(() => _moveCursorBy(0, -1)),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _runEditorShortcut(() => _moveCursorBy(0, 1)),
        const SingleActivator(LogicalKeyboardKey.keyA): () =>
            _runEditorShortcut(() => _moveCursorBy(-1, 0)),
        const SingleActivator(LogicalKeyboardKey.keyD): () =>
            _runEditorShortcut(() => _moveCursorBy(1, 0)),
        const SingleActivator(LogicalKeyboardKey.keyW): () =>
            _runEditorShortcut(() => _moveCursorBy(0, -1)),
        const SingleActivator(LogicalKeyboardKey.keyS): () =>
            _runEditorShortcut(() => _moveCursorBy(0, 1)),
        const SingleActivator(LogicalKeyboardKey.space): () =>
            _runEditorShortcut(_applyToolAtCursor),
        const SingleActivator(LogicalKeyboardKey.enter): () =>
            _runEditorShortcut(_applyToolAtCursor),
        const SingleActivator(LogicalKeyboardKey.delete): () =>
            _runEditorShortcut(_clearObstacles),
        const SingleActivator(LogicalKeyboardKey.digit1): () =>
            _runEditorShortcut(
              () => _setObstacleType(SurvivorMapObstacleType.wall),
            ),
        const SingleActivator(LogicalKeyboardKey.digit2): () =>
            _runEditorShortcut(
              () => _setObstacleType(SurvivorMapObstacleType.pillar),
            ),
        const SingleActivator(LogicalKeyboardKey.digit3): () =>
            _runEditorShortcut(
              () => _setObstacleType(SurvivorMapObstacleType.mire),
            ),
        const SingleActivator(LogicalKeyboardKey.numpad1): () =>
            _runEditorShortcut(
              () => _setObstacleType(SurvivorMapObstacleType.wall),
            ),
        const SingleActivator(LogicalKeyboardKey.numpad2): () =>
            _runEditorShortcut(
              () => _setObstacleType(SurvivorMapObstacleType.pillar),
            ),
        const SingleActivator(LogicalKeyboardKey.numpad3): () =>
            _runEditorShortcut(
              () => _setObstacleType(SurvivorMapObstacleType.mire),
            ),
      },
      child: Focus(
        focusNode: _editorFocusNode,
        autofocus: true,
        child: DecoratedBox(
          key: const ValueKey('map-editor'),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0C1114), Color(0xFF162128), Color(0xFF090C0E)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xCC111315),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: widget.onBack,
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    '맵 에디터',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              '맵 크기를 정하고, 배경을 생성하고, 장애물을 그려서 커스텀 전장을 저장합니다.',
                              style: TextStyle(
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: '맵 이름',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _SectionTitle(
                              title: '맵 크기',
                              subtitle:
                                  '$_widthCells x $_heightCells 타일 · $obstacleCount개 장애물',
                            ),
                            const SizedBox(height: 8),
                            Text('가로 $_widthCells'),
                            Slider(
                              min: 16,
                              max: 40,
                              divisions: 24,
                              value: _widthCells.toDouble(),
                              onChanged: (value) =>
                                  _setSize(widthCells: value.round()),
                            ),
                            Text('세로 $_heightCells'),
                            Slider(
                              min: 12,
                              max: 32,
                              divisions: 20,
                              value: _heightCells.toDouble(),
                              onChanged: (value) =>
                                  _setSize(heightCells: value.round()),
                            ),
                            const SizedBox(height: 12),
                            _SectionTitle(
                              title: '바닥 타일',
                              subtitle: '흙, 풀, 콘크리트, 돌, 모래, 금속 바닥 재질을 선택합니다.',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final floorType
                                    in SurvivorMapFloorType.values)
                                  ChoiceChip(
                                    label: Text(floorType.label),
                                    selected: _floorType == floorType,
                                    onSelected: (_) => _setFloorType(floorType),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _SectionTitle(
                              title: '배경 생성',
                              subtitle: '패턴과 색 조합을 골라 전장 분위기를 바꿉니다.',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final preset in _backgroundPresets)
                                  ChoiceChip(
                                    label: Text(preset.label),
                                    selected:
                                        preset.floorType == _floorType &&
                                        preset.style == _backgroundStyle &&
                                        preset.floorColor == _floorColor &&
                                        preset.gridColor == _gridColor &&
                                        preset.detailColor == _detailColor,
                                    onSelected: (_) => _applyPreset(preset),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: _randomizeBackground,
                                  icon: const Icon(Icons.shuffle),
                                  label: const Text('배경 생성'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _SectionTitle(
                              title: '장애물 배치',
                              subtitle:
                                  '배치/삭제 툴과 브러시 크기를 고르고 우측 캔버스에서 클릭 또는 드래그하세요.',
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final mode
                                    in MapEditorPlacementMode.values)
                                  ChoiceChip(
                                    label: Text(mode.label),
                                    selected: _placementMode == mode,
                                    onSelected: (_) => _setPlacementMode(mode),
                                  ),
                                for (final type
                                    in SurvivorMapObstacleType.values)
                                  ChoiceChip(
                                    label: Text(type.label),
                                    selected: _obstacleType == type,
                                    onSelected: (_) => _setObstacleType(type),
                                  ),
                                ChoiceChip(
                                  label: const Text('배치'),
                                  selected:
                                      _tool == MapEditorObstacleTool.paint,
                                  onSelected: (_) =>
                                      _setTool(MapEditorObstacleTool.paint),
                                ),
                                ChoiceChip(
                                  label: const Text('삭제'),
                                  selected:
                                      _tool == MapEditorObstacleTool.erase,
                                  onSelected: (_) =>
                                      _setTool(MapEditorObstacleTool.erase),
                                ),
                                OutlinedButton(
                                  onPressed: _clearObstacles,
                                  child: const Text('장애물 지우기'),
                                ),
                                for (final brush in MapEditorBrushSize.values)
                                  ChoiceChip(
                                    label: Text(brush.label),
                                    selected: _brushSize == brush,
                                    onSelected: (_) => _setBrushSize(brush),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '벽 $wallCount · 기둥 $pillarCount · 수렁 $mireCount',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '커서 ${_cursorCell.x + 1}, ${_cursorCell.y + 1} · ${_tool == MapEditorObstacleTool.paint ? '배치' : '삭제'} 준비',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            if (_shapeAnchor != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '앵커 ${_shapeAnchor!.x + 1}, ${_shapeAnchor!.y + 1} · ${_placementMode.label} 배치 대기',
                                style: const TextStyle(
                                  color: Color(0xFF9BE7FF),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _canUndo ? _undo : null,
                                    icon: const Icon(Icons.undo),
                                    label: Text('실행 취소 (${_undoStack.length})'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _canRedo ? _redo : null,
                                    icon: const Icon(Icons.redo),
                                    label: Text('다시 실행 (${_redoStack.length})'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: _saving || _testing
                                        ? null
                                        : () => _saveDraft(),
                                    icon: const Icon(Icons.save),
                                    label: Text(_saving ? '저장 중...' : '맵 저장'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: _saving || _testing
                                        ? null
                                        : _testDraft,
                                    icon: const Icon(Icons.play_arrow),
                                    label: Text(
                                      _testing ? '테스트 준비 중...' : '저장 후 테스트',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '테스트는 표준형 사수 캐릭터로 바로 시작합니다.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '단축키: Ctrl+Z 실행 취소 · Ctrl+Y 다시 실행 · 방향키/WASD 커서 · Space/Enter 적용 · V 브러시 · L 라인 · R 사각형 · 1/2/3 장애물 · P 배치 · E 삭제 · Z/X/C 브러시 크기 · G 배경 생성 · Ctrl+S 저장 · Ctrl+Enter 테스트 · Delete 전체 지우기 · Esc 앵커 취소/뒤로가기',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              '패드: Left Stick / D-pad 커서 · A 적용 · Back 실행 취소 · X 툴 전환 · Y 배치 모드 전환 · LB/RB 장애물 전환 · B/Start 앵커 취소/뒤로가기',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (widget.existingMaps.isNotEmpty) ...[
                              const _SectionTitle(
                                title: '저장된 커스텀 맵',
                                subtitle: '불러오거나 삭제할 수 있습니다.',
                              ),
                              const SizedBox(height: 10),
                              for (final map in widget.existingMaps) ...[
                                _SavedMapTile(
                                  map: map,
                                  onLoad: () => _loadExistingMap(map),
                                  onDelete: () => _deleteExistingMap(map),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 6,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xCC111315),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '미리보기',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '중앙의 밝은 영역은 플레이어 시작 보호 구역입니다.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _MapEditorCanvas(
                              widthCells: _widthCells,
                              heightCells: _heightCells,
                              floorType: _floorType,
                              backgroundStyle: _backgroundStyle,
                              floorColor: _floorColor,
                              gridColor: _gridColor,
                              detailColor: _detailColor,
                              obstacles: _obstacles,
                              cursorCell: _cursorCell,
                              shapeAnchor: _shapeAnchor,
                              previewCells: _currentPreviewCells(),
                              obstacleType: _obstacleType,
                              tool: _tool,
                              placementMode: _placementMode,
                              isProtectedCell: _isProtectedCell,
                              onCellInteracted: _applyToolAt,
                              onShapeStarted: _beginShapeDrag,
                              onShapeUpdated: _updateShapeDrag,
                              onShapeFinished: _finishShapeDrag,
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
}

class _MapEditorCanvas extends StatefulWidget {
  const _MapEditorCanvas({
    required this.widthCells,
    required this.heightCells,
    required this.floorType,
    required this.backgroundStyle,
    required this.floorColor,
    required this.gridColor,
    required this.detailColor,
    required this.obstacles,
    required this.cursorCell,
    required this.shapeAnchor,
    required this.previewCells,
    required this.obstacleType,
    required this.tool,
    required this.placementMode,
    required this.isProtectedCell,
    required this.onCellInteracted,
    required this.onShapeStarted,
    required this.onShapeUpdated,
    required this.onShapeFinished,
  });

  final int widthCells;
  final int heightCells;
  final SurvivorMapFloorType floorType;
  final SurvivorMapBackgroundStyle backgroundStyle;
  final Color floorColor;
  final Color gridColor;
  final Color detailColor;
  final Map<_GridCell, SurvivorMapObstacleType> obstacles;
  final _GridCell cursorCell;
  final _GridCell? shapeAnchor;
  final Iterable<_GridCell> previewCells;
  final SurvivorMapObstacleType obstacleType;
  final MapEditorObstacleTool tool;
  final MapEditorPlacementMode placementMode;
  final bool Function(int x, int y) isProtectedCell;
  final void Function(int x, int y) onCellInteracted;
  final ValueChanged<_GridCell> onShapeStarted;
  final ValueChanged<_GridCell> onShapeUpdated;
  final VoidCallback onShapeFinished;

  @override
  State<_MapEditorCanvas> createState() => _MapEditorCanvasState();
}

class _MapEditorCanvasState extends State<_MapEditorCanvas> {
  _GridCell? _lastDraggedCell;

  _GridCell _cellFromOffset(Offset offset, Size size) {
    final cellWidth = size.width / widget.widthCells;
    final cellHeight = size.height / widget.heightCells;
    return _GridCell(
      (offset.dx / cellWidth).floor(),
      (offset.dy / cellHeight).floor(),
    );
  }

  void _handleOffset(Offset offset, Size size) {
    final cell = _cellFromOffset(offset, size);
    if (_lastDraggedCell == cell) {
      return;
    }
    _lastDraggedCell = cell;
    if (widget.placementMode == MapEditorPlacementMode.brush) {
      widget.onCellInteracted(cell.x, cell.y);
    } else {
      widget.onShapeUpdated(cell);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ratio = widget.widthCells / widget.heightCells;
        var width = constraints.maxWidth;
        var height = width / ratio;
        if (height > constraints.maxHeight) {
          height = constraints.maxHeight;
          width = height * ratio;
        }
        final size = Size(width, height);

        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final cell = _cellFromOffset(details.localPosition, size);
                _lastDraggedCell = cell;
                widget.onCellInteracted(cell.x, cell.y);
              },
              onPanStart: (details) {
                final cell = _cellFromOffset(details.localPosition, size);
                _lastDraggedCell = cell;
                if (widget.placementMode == MapEditorPlacementMode.brush) {
                  widget.onCellInteracted(cell.x, cell.y);
                } else {
                  widget.onShapeStarted(cell);
                }
              },
              onPanUpdate: (details) =>
                  _handleOffset(details.localPosition, size),
              onPanEnd: (_) {
                if (widget.placementMode != MapEditorPlacementMode.brush) {
                  widget.onShapeFinished();
                }
                _lastDraggedCell = null;
              },
              onPanCancel: () {
                if (widget.placementMode != MapEditorPlacementMode.brush) {
                  widget.onShapeFinished();
                }
                _lastDraggedCell = null;
              },
              child: CustomPaint(
                painter: _MapEditorPainter(
                  widthCells: widget.widthCells,
                  heightCells: widget.heightCells,
                  floorType: widget.floorType,
                  backgroundStyle: widget.backgroundStyle,
                  floorColor: widget.floorColor,
                  gridColor: widget.gridColor,
                  detailColor: widget.detailColor,
                  obstacles: widget.obstacles,
                  cursorCell: widget.cursorCell,
                  shapeAnchor: widget.shapeAnchor,
                  previewCells: widget.previewCells.toSet(),
                  obstacleType: widget.obstacleType,
                  tool: widget.tool,
                  placementMode: widget.placementMode,
                  isProtectedCell: widget.isProtectedCell,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MapEditorPainter extends CustomPainter {
  const _MapEditorPainter({
    required this.widthCells,
    required this.heightCells,
    required this.floorType,
    required this.backgroundStyle,
    required this.floorColor,
    required this.gridColor,
    required this.detailColor,
    required this.obstacles,
    required this.cursorCell,
    required this.shapeAnchor,
    required this.previewCells,
    required this.obstacleType,
    required this.tool,
    required this.placementMode,
    required this.isProtectedCell,
  });

  final int widthCells;
  final int heightCells;
  final SurvivorMapFloorType floorType;
  final SurvivorMapBackgroundStyle backgroundStyle;
  final Color floorColor;
  final Color gridColor;
  final Color detailColor;
  final Map<_GridCell, SurvivorMapObstacleType> obstacles;
  final _GridCell cursorCell;
  final _GridCell? shapeAnchor;
  final Set<_GridCell> previewCells;
  final SurvivorMapObstacleType obstacleType;
  final MapEditorObstacleTool tool;
  final MapEditorPlacementMode placementMode;
  final bool Function(int x, int y) isProtectedCell;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / widthCells;
    final cellHeight = size.height / heightCells;
    final rect = Offset.zero & size;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)));
    SurvivorFloorTileRenderer.paint(
      canvas: canvas,
      mapRect: rect,
      floorType: floorType,
      floorColor: floorColor,
      gridColor: gridColor,
      detailColor: detailColor,
      cellSize: math.min(cellWidth, cellHeight),
    );

    switch (backgroundStyle) {
      case SurvivorMapBackgroundStyle.grid:
        break;
      case SurvivorMapBackgroundStyle.stripes:
        for (var i = -heightCells; i < widthCells * 2; i++) {
          final stripe = Path()
            ..moveTo(i * cellWidth, 0)
            ..lineTo((i + 1) * cellWidth, 0)
            ..lineTo((i - heightCells + 1) * cellWidth, size.height)
            ..lineTo((i - heightCells) * cellWidth, size.height)
            ..close();
          canvas.drawPath(
            stripe,
            Paint()..color = detailColor.withValues(alpha: 0.16),
          );
        }
        break;
      case SurvivorMapBackgroundStyle.rings:
        final center = Offset(size.width / 2, size.height / 2);
        for (var i = 1; i <= 5; i++) {
          canvas.drawCircle(
            center,
            (size.shortestSide * 0.12) * i,
            Paint()
              ..color = detailColor.withValues(alpha: 0.18)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        break;
    }
    canvas.restore();

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var x = 0; x <= widthCells; x++) {
      final dx = x * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 0; y <= heightCells; y++) {
      final dy = y * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    for (var y = 0; y < heightCells; y++) {
      for (var x = 0; x < widthCells; x++) {
        if (!isProtectedCell(x, y)) {
          continue;
        }
        canvas.drawRect(
          Rect.fromLTWH(x * cellWidth, y * cellHeight, cellWidth, cellHeight),
          Paint()..color = const Color(0x4069F0AE),
        );
      }
    }

    final previewColor = switch (tool) {
      MapEditorObstacleTool.paint => switch (obstacleType) {
        SurvivorMapObstacleType.wall => const Color(0x77546E7A),
        SurvivorMapObstacleType.pillar => const Color(0x778D6E63),
        SurvivorMapObstacleType.mire => const Color(0x775FBF7B),
      },
      MapEditorObstacleTool.erase => const Color(0x88D65A4A),
    };
    final previewBorderColor = isProtectedCell(cursorCell.x, cursorCell.y)
        ? const Color(0xFFF9C74F)
        : const Color(0xFFF1F5F9);
    final anchorColor = const Color(0xFF80DEEA);

    for (final cell in previewCells) {
      canvas.drawRect(
        Rect.fromLTWH(
          cell.x * cellWidth + 3,
          cell.y * cellHeight + 3,
          cellWidth - 6,
          cellHeight - 6,
        ),
        Paint()..color = previewColor,
      );
    }

    for (final entry in obstacles.entries) {
      final cell = entry.key;
      final type = entry.value;
      final tileRect = Rect.fromLTWH(
        cell.x * cellWidth + 2,
        cell.y * cellHeight + 2,
        cellWidth - 4,
        cellHeight - 4,
      );

      switch (type) {
        case SurvivorMapObstacleType.wall:
          canvas.drawRRect(
            RRect.fromRectAndRadius(tileRect, const Radius.circular(6)),
            Paint()..color = const Color(0xFF546E7A),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              tileRect.deflate(4),
              const Radius.circular(4),
            ),
            Paint()..color = const Color(0xFF90A4AE),
          );
          break;
        case SurvivorMapObstacleType.pillar:
          canvas.drawRRect(
            RRect.fromRectAndRadius(tileRect, const Radius.circular(8)),
            Paint()..color = const Color(0x22333D44),
          );
          canvas.drawOval(
            tileRect.deflate(math.min(cellWidth, cellHeight) * 0.18),
            Paint()..color = const Color(0xFF8D6E63),
          );
          canvas.drawOval(
            tileRect.deflate(math.min(cellWidth, cellHeight) * 0.28),
            Paint()..color = const Color(0xFFD7CCC8),
          );
          break;
        case SurvivorMapObstacleType.mire:
          canvas.drawRRect(
            RRect.fromRectAndRadius(tileRect, const Radius.circular(10)),
            Paint()..color = const Color(0xAA335C3F),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: tileRect.center,
              width: tileRect.width * 0.78,
              height: tileRect.height * 0.52,
            ),
            Paint()..color = const Color(0xFF71D18A),
          );
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(
                tileRect.center.dx - tileRect.width * 0.12,
                tileRect.center.dy + tileRect.height * 0.05,
              ),
              width: tileRect.width * 0.32,
              height: tileRect.height * 0.18,
            ),
            Paint()..color = Colors.white.withValues(alpha: 0.16),
          );
          break;
      }
    }

    final cursorRect = Rect.fromLTWH(
      cursorCell.x * cellWidth + 2,
      cursorCell.y * cellHeight + 2,
      cellWidth - 4,
      cellHeight - 4,
    );
    if (shapeAnchor != null) {
      final anchorRect = Rect.fromLTWH(
        shapeAnchor!.x * cellWidth + 4,
        shapeAnchor!.y * cellHeight + 4,
        cellWidth - 8,
        cellHeight - 8,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(anchorRect, const Radius.circular(8)),
        Paint()
          ..color = anchorColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(anchorRect.center, 4, Paint()..color = anchorColor);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(cursorRect, const Radius.circular(8)),
      Paint()
        ..color = previewBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
    canvas.drawCircle(
      cursorRect.topLeft + const Offset(8, 8),
      3,
      Paint()..color = previewBorderColor,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MapEditorPainter oldDelegate) {
    return widthCells != oldDelegate.widthCells ||
        heightCells != oldDelegate.heightCells ||
        floorType != oldDelegate.floorType ||
        backgroundStyle != oldDelegate.backgroundStyle ||
        floorColor != oldDelegate.floorColor ||
        gridColor != oldDelegate.gridColor ||
        detailColor != oldDelegate.detailColor ||
        cursorCell != oldDelegate.cursorCell ||
        shapeAnchor != oldDelegate.shapeAnchor ||
        obstacleType != oldDelegate.obstacleType ||
        tool != oldDelegate.tool ||
        placementMode != oldDelegate.placementMode ||
        !setEquals(previewCells, oldDelegate.previewCells) ||
        !mapEquals(obstacles, oldDelegate.obstacles);
  }
}

class _SavedMapTile extends StatelessWidget {
  const _SavedMapTile({
    required this.map,
    required this.onLoad,
    required this.onDelete,
  });

  final SurvivorMapConfig map;
  final VoidCallback onLoad;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            map.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${map.widthCells} x ${map.heightCells} · 장애물 ${map.obstacles.length}개 · ${map.floorType.label} · ${map.backgroundStyle.label}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton.tonal(onPressed: onLoad, child: const Text('불러오기')),
              const SizedBox(width: 10),
              OutlinedButton(onPressed: onDelete, child: const Text('삭제')),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white60)),
      ],
    );
  }
}

enum MapEditorObstacleTool { paint, erase }

enum MapEditorPlacementMode {
  brush('브러시'),
  line('라인'),
  rectangle('사각형');

  const MapEditorPlacementMode(this.label);

  final String label;
}

enum MapEditorBrushSize {
  small(0, '브러시 1x1'),
  medium(1, '브러시 3x3'),
  large(2, '브러시 5x5');

  const MapEditorBrushSize(this.radius, this.label);

  final int radius;
  final String label;
}

class _GridCell {
  const _GridCell(this.x, this.y);

  final int x;
  final int y;

  @override
  bool operator ==(Object other) {
    return other is _GridCell && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

class _MapEditorHistorySnapshot {
  const _MapEditorHistorySnapshot({
    required this.widthCells,
    required this.heightCells,
    required this.floorType,
    required this.backgroundStyle,
    required this.floorColor,
    required this.gridColor,
    required this.detailColor,
    required this.cursorCell,
    required this.obstacles,
  });

  final int widthCells;
  final int heightCells;
  final SurvivorMapFloorType floorType;
  final SurvivorMapBackgroundStyle backgroundStyle;
  final Color floorColor;
  final Color gridColor;
  final Color detailColor;
  final _GridCell cursorCell;
  final Map<_GridCell, SurvivorMapObstacleType> obstacles;
}

class _EditorBackgroundPreset {
  const _EditorBackgroundPreset({
    required this.label,
    required this.floorType,
    required this.style,
    required this.floorColor,
    required this.gridColor,
    required this.detailColor,
  });

  final String label;
  final SurvivorMapFloorType floorType;
  final SurvivorMapBackgroundStyle style;
  final Color floorColor;
  final Color gridColor;
  final Color detailColor;
}

const List<_EditorBackgroundPreset> _backgroundPresets =
    <_EditorBackgroundPreset>[
      _EditorBackgroundPreset(
        label: '잿빛',
        floorType: SurvivorMapFloorType.dirt,
        style: SurvivorMapBackgroundStyle.grid,
        floorColor: Color(0xFF101517),
        gridColor: Color(0xFF1B2529),
        detailColor: Color(0xFF8BC34A),
      ),
      _EditorBackgroundPreset(
        label: '비취',
        floorType: SurvivorMapFloorType.grass,
        style: SurvivorMapBackgroundStyle.stripes,
        floorColor: Color(0xFF0F1716),
        gridColor: Color(0xFF173431),
        detailColor: Color(0xFF58B7D5),
      ),
      _EditorBackgroundPreset(
        label: '황혼',
        floorType: SurvivorMapFloorType.concrete,
        style: SurvivorMapBackgroundStyle.rings,
        floorColor: Color(0xFF171210),
        gridColor: Color(0xFF3A271A),
        detailColor: Color(0xFFE39C45),
      ),
      _EditorBackgroundPreset(
        label: '심연',
        floorType: SurvivorMapFloorType.stone,
        style: SurvivorMapBackgroundStyle.grid,
        floorColor: Color(0xFF0C0F18),
        gridColor: Color(0xFF202A4A),
        detailColor: Color(0xFF7388FF),
      ),
      _EditorBackgroundPreset(
        label: '사구',
        floorType: SurvivorMapFloorType.sand,
        style: SurvivorMapBackgroundStyle.stripes,
        floorColor: Color(0xFF19140D),
        gridColor: Color(0xFF4A3820),
        detailColor: Color(0xFFD7A85A),
      ),
      _EditorBackgroundPreset(
        label: '격납고',
        floorType: SurvivorMapFloorType.metal,
        style: SurvivorMapBackgroundStyle.grid,
        floorColor: Color(0xFF0C1318),
        gridColor: Color(0xFF253640),
        detailColor: Color(0xFF89B7C7),
      ),
    ];
