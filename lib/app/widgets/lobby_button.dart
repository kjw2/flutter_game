import 'package:flutter/material.dart';

class LobbyButton extends StatelessWidget {
  const LobbyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final background = destructive
        ? const Color(0xFF4B1F1F)
        : const Color(0xFF24322A);
    final foreground = destructive
        ? const Color(0xFFFFD7D7)
        : const Color(0xFFF1F8E9);

    return Focus(
      canRequestFocus: false,
      descendantsAreFocusable: false,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: selected
              ? foreground.withValues(alpha: 0.18)
              : background,
          foregroundColor: foreground,
          disabledBackgroundColor: const Color(0xFF1A1D1F),
          disabledForegroundColor: Colors.white30,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          side: BorderSide(
            color: selected ? foreground : Colors.transparent,
            width: 1.2,
          ),
        ),
        onPressed: onPressed,
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    );
  }
}
