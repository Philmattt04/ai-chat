import 'package:flutter/material.dart';
import '../models/message.dart';

class PersonaSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const PersonaSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: Persona.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final persona = Persona.all[i];
          final isSelected = persona.id == selected;
          return GestureDetector(
            onTap: () => onSelect(persona.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? isDark
                        ? const Color(0xFF4f46e5).withValues(alpha: 0.2)
                        : const Color(0xFFede9fe)
                    : isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? isDark
                          ? const Color(0xFF4f46e5).withValues(alpha: 0.6)
                          : const Color(0xFF6366f1).withValues(alpha: 0.4)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFe5e7eb),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(persona.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    persona.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? isDark
                              ? const Color(0xFFa5b4fc)
                              : const Color(0xFF4f46e5)
                          : isDark
                              ? const Color(0xFF9ca3af)
                              : const Color(0xFF6b7280),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
