import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/services/call_service.dart' show CallType;
import '../../core/services/group_call_service.dart';
import '../../core/services/ringtone_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/fc_card.dart';

/// Écran d'appel de groupe entrant avec sonnerie.
///
/// Joue une sonnerie en boucle via [RingtoneService] tant que l'écran
/// est affiché. La sonnerie s'arrête automatiquement quand l'utilisateur
/// rejoint, rejette, ou quitte l'écran.
class GroupIncomingCallScreen extends StatefulWidget {
  final GroupCallData callData;
  final String callerName;
  final String? callerAvatarUrl;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const GroupIncomingCallScreen({
    super.key,
    required this.callData,
    required this.callerName,
    this.callerAvatarUrl,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<GroupIncomingCallScreen> createState() =>
      _GroupIncomingCallScreenState();
}

class _GroupIncomingCallScreenState extends State<GroupIncomingCallScreen> {
  final _ringtone = RingtoneService();

  @override
  void initState() {
    super.initState();
    _ringtone.startRinging();
  }

  @override
  void dispose() {
    _ringtone.stopRinging();
    super.dispose();
  }

  void _accept() {
    _ringtone.stopRinging();
    widget.onAccept();
  }

  void _reject() {
    _ringtone.stopRinging();
    widget.onReject();
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = widget.callData.callType == CallType.video;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            FcAvatar(
              imageUrl: widget.callerAvatarUrl,
              initials: widget.callerName.isNotEmpty
                  ? widget.callerName.substring(0, 1)
                  : '?',
              size: 120,
              showBorder: true,
            ),
            const SizedBox(height: AppSpacing.stackLg),
            Text(
              widget.callerName,
              style: AppTextStyles.headlineMd.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.stackSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isVideo ? PhosphorIcons.videoCamera : PhosphorIcons.phone,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isVideo
                      ? 'Appel vidéo de groupe entrant…'
                      : 'Appel vocal de groupe entrant…',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.marginMobile,
                vertical: AppSpacing.stackLg,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallActionButton(
                    icon: PhosphorIcons.phoneDisconnect,
                    label: 'Rejeter',
                    color: AppColors.error,
                    onTap: _reject,
                  ),
                  _CallActionButton(
                    icon: isVideo
                        ? PhosphorIcons.videoCamera
                        : PhosphorIcons.phone,
                    label: 'Rejoindre',
                    color: AppColors.primary,
                    onTap: _accept,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
