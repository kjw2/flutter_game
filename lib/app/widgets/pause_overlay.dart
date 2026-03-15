import 'package:flutter/material.dart';

import 'lobby_button.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    super.key,
    required this.characterName,
    required this.stats,
    required this.selectedIndex,
    required this.onResume,
    required this.onRestart,
    required this.onExit,
    required this.exitLabel,
  });

  final String characterName;
  final List<MapEntry<String, String>> stats;
  final int selectedIndex;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onExit;
  final String exitLabel;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: const Color(0xAA050709),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 560,
              maxHeight: MediaQuery.of(context).size.height - 48,
            ),
            child: Container(
              width: 560,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xEE111315),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '일시정지',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ESC 메뉴',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '방향키/W,S 이동 · Enter/Space 선택 · Esc 닫기',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0x44141B1F),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final tileWidth = constraints.maxWidth >= 420
                              ? (constraints.maxWidth - 12) / 2
                              : constraints.maxWidth;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                characterName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '현재 캐릭터 스탯',
                                style: TextStyle(color: Colors.white60),
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final stat in stats)
                                    _PauseStatTile(
                                      label: stat.key,
                                      value: stat.value,
                                      width: tileWidth,
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    LobbyButton(
                      label: '계속',
                      onPressed: onResume,
                      selected: selectedIndex == 0,
                    ),
                    const SizedBox(height: 12),
                    LobbyButton(
                      label: '다시 시작',
                      onPressed: onRestart,
                      selected: selectedIndex == 1,
                    ),
                    const SizedBox(height: 12),
                    LobbyButton(
                      label: exitLabel,
                      onPressed: onExit,
                      destructive: true,
                      selected: selectedIndex == 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseStatTile extends StatelessWidget {
  const _PauseStatTile({
    required this.label,
    required this.value,
    required this.width,
  });

  final String label;
  final String value;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x221D2428),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
