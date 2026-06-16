import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/data/models/event.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Carte de prévisualisation d'événement affichée dans le feed.
///
/// Affiche bannière, titre, date, lieu, nombre de participants et
/// un bouton RSVP 1-clic directement depuis le feed.
class EventPreviewCard extends ConsumerWidget {
  final String eventId;

  const EventPreviewCard({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(eventsProvider);
    final event = asyncEvents.valueOrNull
        ?.where((e) => e.id == eventId)
        .firstOrNull;

    if (event == null) {
      return const SizedBox.shrink();
    }

    final formattedDate =
        DateFormat('EEEE dd MMMM yyyy • HH:mm', 'fr_FR').format(event.date);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.eventDetail,
          arguments: event.id,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner
              if (event.imageUrl.isNotEmpty)
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        event.imageUrl,
                        fit: BoxFit.cover,
                        cacheWidth: 600,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackSm),

                    // Info rows
                    _infoRow(PhosphorIcons.calendarBlank, formattedDate),
                    const SizedBox(height: 4),
                    _infoRow(PhosphorIcons.mapPin, event.location),
                    const SizedBox(height: 4),
                    _infoRow(
                      PhosphorIcons.users,
                      '${event.attendeeCount} participant${event.attendeeCount > 1 ? 's' : ''}',
                    ),
                    const SizedBox(height: AppSpacing.stackSm),

                    // Footer: category badge + RSVP button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryFixed,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Text(
                            event.category,
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _QuickRsvpButton(event: event),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bouton RSVP rapide intégré à la carte événement dans le feed.
///
/// Permet de s'inscrire/se désinscrire sans quitter le feed.
class _QuickRsvpButton extends ConsumerStatefulWidget {
  final Event event;
  const _QuickRsvpButton({required this.event});

  @override
  ConsumerState<_QuickRsvpButton> createState() => _QuickRsvpButtonState();
}

class _QuickRsvpButtonState extends ConsumerState<_QuickRsvpButton> {
  bool _isToggling = false;

  Future<void> _toggle() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);

    try {
      await ref
          .read(eventsRepositoryProvider)
          .toggleRsvp(widget.event.id, !widget.event.isRsvped);
      ref.invalidate(eventsProvider);
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRsvped = widget.event.isRsvped;

    return GestureDetector(
      onTap: _isToggling ? null : _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isRsvped ? AppColors.primaryFixed : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: _isToggling
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRsvped
                        ? PhosphorIcons.checkCircleFill
                        : PhosphorIcons.plus,
                    size: 14,
                    color: isRsvped
                        ? AppColors.primaryContainer
                        : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isRsvped ? 'Inscrit' : "S'inscrire",
                    style: AppTextStyles.labelSm.copyWith(
                      color: isRsvped
                          ? AppColors.primaryContainer
                          : Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
