import 'package:flutter/material.dart';

import 'lobby_button.dart';

class GameOverMenuOverlay extends StatelessWidget {
  const GameOverMenuOverlay({
    super.key,
    required this.playerWon,
    required this.elapsedLabel,
    required this.level,
    required this.kills,
    required this.earnedGold,
    required this.totalGold,
    required this.selectedIndex,
    required this.onRestart,
    required this.onExit,
    required this.exitLabel,
  });

  final bool playerWon;
  final String elapsedLabel;
  final int level;
  final int kills;
  final int earnedGold;
  final int totalGold;
  final int selectedIndex;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final String exitLabel;

  @override
  Widget build(BuildContext context) {
    final title = playerWon ? 'VICTORY' : 'GAME OVER';
    final summary = playerWon ? '30분을 버텨 승리했습니다.' : '생존 시간 $elapsedLabel';

    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xCC050709),
        child: Center(
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xF0111315),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  summary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'LV $level   Kills $kills   Gold +$earnedGold',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 6),
                Text(
                  '총 보유 골드 $totalGold',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 8),
                Text(
                  '방향키/W,S 이동 · Enter/Space 선택 · 1 다시 시작 · 2 $exitLabel',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 20),
                LobbyButton(
                  label: '1 다시 시작',
                  onPressed: onRestart,
                  selected: selectedIndex == 0,
                ),
                const SizedBox(height: 12),
                LobbyButton(
                  label: '2 $exitLabel',
                  onPressed: onExit,
                  destructive: true,
                  selected: selectedIndex == 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
