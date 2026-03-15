import 'package:flutter/material.dart';

class SelectionOptionCard extends StatelessWidget {
  const SelectionOptionCard({
    super.key,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.highlights,
    required this.selected,
    required this.onTap,
  });

  final Color accentColor;
  final String title;
  final String subtitle;
  final String description;
  final List<String> highlights;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: selected ? 0.24 : 0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? accentColor : Colors.white10,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, height: 1.45),
              ),
              const SizedBox(height: 16),
              for (final highlight in highlights) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle, size: 8, color: accentColor),
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
      ),
    );
  }
}
