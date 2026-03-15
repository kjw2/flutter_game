import 'package:flutter/material.dart';

import '../../game/survivor_game.dart';

class LevelUpCard extends StatelessWidget {
  const LevelUpCard({
    super.key,
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final UpgradeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: choice.color.withValues(alpha: selected ? 0.28 : 0.16),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? choice.color : Colors.white12,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: choice.color.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Icon(choice.icon, color: choice.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choice.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    choice.levelLabel,
                    style: TextStyle(
                      color: choice.color.withValues(alpha: 0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    choice.description,
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
