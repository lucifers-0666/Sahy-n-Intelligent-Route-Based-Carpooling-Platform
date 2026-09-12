import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class StepCounter extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String? suffix;

  const StepCounter({
    super.key,
    required this.value,
    this.min = 1,
    this.max = 8,
    required this.onChanged,
    this.suffix = 'Seats',
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = value > min;
    final canIncrement = value < max;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: SahyanColors.chipBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SahyanColors.border, width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            enabled: canDecrement,
            onTap: () {
              if (canDecrement) {
                HapticFeedback.lightImpact();
                onChanged(value - 1);
              }
            },
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                suffix != null ? '$value $suffix' : '$value',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: SahyanColors.textMain,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            enabled: canIncrement,
            onTap: () {
              if (canIncrement) {
                HapticFeedback.lightImpact();
                onChanged(value + 1);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? SahyanColors.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      elevation: enabled ? 1 : 0,
      shadowColor: SahyanColors.textMain.withValues(alpha: 0.06),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 16,
            color: enabled ? SahyanColors.textMain : SahyanColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
