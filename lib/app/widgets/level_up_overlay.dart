import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../game/survivor_game.dart';
import 'level_up_card.dart';

class LevelUpOverlay extends StatelessWidget {
  const LevelUpOverlay({
    super.key,
    required this.choices,
    required this.selectedIndex,
    required this.rerollsRemaining,
    required this.maxRerolls,
    required this.onSelectionChanged,
    required this.onSelected,
    required this.onReroll,
  });

  final List<UpgradeChoice> choices;
  final int selectedIndex;
  final int rerollsRemaining;
  final int maxRerolls;
  final ValueChanged<int> onSelectionChanged;
  final ValueChanged<UpgradeChoice> onSelected;
  final VoidCallback onReroll;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent || choices.isEmpty) {
            return KeyEventResult.ignored;
          }

          if (event.logicalKey == LogicalKeyboardKey.arrowUp ||
              event.logicalKey == LogicalKeyboardKey.keyW) {
            onSelectionChanged(
              (selectedIndex + choices.length - 1) % choices.length,
            );
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown ||
              event.logicalKey == LogicalKeyboardKey.keyS) {
            onSelectionChanged((selectedIndex + 1) % choices.length);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space) {
            onSelected(choices[selectedIndex]);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.keyR) {
            onReroll();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit1 &&
              choices.isNotEmpty) {
            onSelected(choices[0]);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit2 &&
              choices.length >= 2) {
            onSelected(choices[1]);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.digit3 &&
              choices.length >= 3) {
            onSelected(choices[2]);
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: ColoredBox(
          color: const Color(0xCC06080A),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xF014181C),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LEVEL UP',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '카드 3장 중 1장을 골라 새 무기를 장착하거나, 기존 무기와 생존 능력을 강화하세요.',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '방향키/W,S 이동 · Enter/Space 선택 · 1,2,3 바로 선택 · R 다시 선택',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: rerollsRemaining > 0 ? onReroll : null,
                            icon: const Icon(Icons.refresh),
                            label: Text('다시 선택 $rerollsRemaining/$maxRerolls'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      for (var i = 0; i < choices.length; i++) ...[
                        LevelUpCard(
                          choice: choices[i],
                          selected: selectedIndex == i,
                          onTap: () => onSelected(choices[i]),
                        ),
                        if (i != choices.length - 1) const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
