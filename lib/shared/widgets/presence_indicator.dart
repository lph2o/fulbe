import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Indicateur de présence en ligne.
///
/// Affiche un point coloré (vert = en ligne, gris = hors ligne) suivi
/// du texte de statut ("En ligne", "Vu à l'instant", "Vu il y a X min", etc.).
///
/// Utilisation typique dans l'AppBar d'une conversation :
/// ```dart
/// PresenceIndicator(isOnline: true, presenceText: 'En ligne')
/// ```
class PresenceIndicator extends StatelessWidget {
  final bool isOnline;
  final String presenceText;

  const PresenceIndicator({
    super.key,
    required this.isOnline,
    required this.presenceText,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isOnline ? const Color(0xFF22C55E) : AppColors.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Point de présence
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: isOnline
                ? [
                    BoxShadow(
                      color: dotColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(width: 5),
        // Texte
        Text(
          presenceText,
          style: AppTextStyles.labelSm.copyWith(
            color: isOnline ? const Color(0xFF22C55E) : AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
