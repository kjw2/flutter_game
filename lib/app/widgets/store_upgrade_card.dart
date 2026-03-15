import 'package:flutter/material.dart';

class StoreUpgradeCard extends StatelessWidget {
  const StoreUpgradeCard({
    super.key,
    required this.title,
    required this.description,
    required this.level,
    required this.maxLevel,
    required this.currentBonus,
    required this.perLevelBonus,
    required this.priceLabel,
    required this.affordable,
    required this.maxed,
    required this.selected,
    required this.accentColor,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final int level;
  final int maxLevel;
  final String currentBonus;
  final String perLevelBonus;
  final String priceLabel;
  final bool affordable;
  final bool maxed;
  final bool selected;
  final Color accentColor;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? accentColor : Colors.white12;
    final priceColor = maxed
        ? Colors.white54
        : affordable
        ? const Color(0xFFFFD54F)
        : const Color(0xFFEF9A9A);

    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: selected ? 0.22 : 0.1),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accentColor),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Lv $level/$maxLevel',
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    priceLabel,
                    style: TextStyle(
                      color: priceColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 12),
              Text(
                currentBonus,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                perLevelBonus,
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
