import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class CorridorLine extends StatelessWidget {
  final Widget originWidget;
  final Widget destinationWidget;
  final VoidCallback? onFlip;

  const CorridorLine({
    super.key,
    required this.originWidget,
    required this.destinationWidget,
    this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerRight,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left connector line with dots
            SizedBox(
              width: 24,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: SahyanColors.primaryDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: SahyanColors.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 38,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          SahyanColors.primaryDark,
                          SahyanColors.primaryMint,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: SahyanColors.primaryMint,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: SahyanColors.primaryMint.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Origin and Destination inputs
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  originWidget,
                  const SizedBox(height: 12),
                  destinationWidget,
                ],
              ),
            ),
          ],
        ),
        if (onFlip != null)
          Positioned(
            right: 0,
            child: Material(
              color: SahyanColors.chipBackground,
              shape: const CircleBorder(
                side: BorderSide(color: SahyanColors.border, width: 0.8),
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onFlip!();
                },
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.swap_vert_rounded,
                    size: 18,
                    color: SahyanColors.primaryDark,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
