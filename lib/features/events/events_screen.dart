import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/data/models/event.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/fc_card.dart';
import '../../shared/widgets/fc_chip.dart';
import '../../core/navigation/app_router.dart';
import '../../shared/widgets/fc_search_bar.dart';
import '../../shared/widgets/ticket_dialog.dart' show showTicketDialog;

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  int _selectedCategoryIndex = 0;
  String _query = '';
  bool _isToggling = false;

  static const _categories = [
    'Tous',
    'Conférence',
    'Festival',
    'Webinaire',
    'Réunion',
  ];

  List<Event> _filter(List<Event> list) {
    var filtered = list;

    if (_selectedCategoryIndex > 0) {
      final selectedCategory = _categories[_selectedCategoryIndex];
      filtered = filtered.where((e) => e.category == selectedCategory).toList();
    }

    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q) ||
              e.location.toLowerCase().contains(q))
          .toList();
    }

    return filtered;
  }

  Future<void> _toggleRsvp(Event event) async {
    if (_isToggling) return;
    setState(() => _isToggling = true);

    try {
      final repo = ref.read(eventsRepositoryProvider);
      await repo.toggleRsvp(event.id, !event.isRsvped);

      // Invalide le provider pour recharger avec les données à jour
      ref.invalidate(eventsProvider);
      await ref.read(eventsProvider.future);

      if (!event.isRsvped && mounted) {
        final member = ref.read(currentMemberProvider).valueOrNull;
        final attendeeName = member?.name ?? 'Participant';
        showTicketDialog(context, event: event, attendeeName: attendeeName);
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isToggling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(showBack: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.of(context)
              .pushNamed(AppRoutes.createEvent);
          if (created == true && mounted) {
            ref.invalidate(eventsProvider);
          }
        },
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(PhosphorIcons.plus, size: 24),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackMd,
              AppSpacing.marginMobile,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Événements',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Participez aux rassemblements de la communauté.',
                        style: AppTextStyles.bodyMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.myEvents),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIcons.calendarCheck, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Mes événements',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.stackMd),
                FcSearchBar(
                  placeholder: 'Rechercher un événement...',
                  onChanged: (q) => setState(() => _query = q),
                ),
                const SizedBox(height: AppSpacing.stackMd),
              ],
            ),
          ),
          // ── Categories ─────────────────────────────────────────
          FcChipRow(
            labels: _categories,
            onSelectionChanged: (i) =>
                setState(() => _selectedCategoryIndex = i),
          ),
          const SizedBox(height: AppSpacing.stackMd),
          // ── Event list (Riverpod) ──────────────────────────────
          Expanded(
            child: asyncEvents.when(
              data: (events) {
                final filtered = _filter(events);
                if (filtered.isEmpty) {
                  return const _EmptyEventsState();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(eventsProvider);
                    await ref.read(eventsProvider.future);
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.marginMobile,
                      0,
                      AppSpacing.marginMobile,
                      AppSpacing.bottomNavHeight + AppSpacing.stackLg,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.stackLg),
                    itemBuilder: (context, i) {
                      final event = filtered[i];
                      return _EventCard(
                        event: event,
                        onRsvpTap: () => _toggleRsvp(event),
                      );
                    },
                  ),
                );
              },
              loading: () => const _EventsLoadingState(),
              error: (e, _) => _EventsErrorState(
                message: e is AppException
                    ? e.message
                    : 'Impossible de charger les événements.',
                onRetry: () => ref.invalidate(eventsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ── Reusable widget classes (unchanged from original) ──────────────────────

class _EventsLoadingState extends StatelessWidget {
  const _EventsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2.4),
            SizedBox(height: AppSpacing.stackMd),
            Text(
              'Chargement des événements...',
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _EventsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(PhosphorIcons.cloudSlash,
                size: 56, color: AppColors.outlineVariant),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.stackMd),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(PhosphorIcons.arrowsClockwise, size: 18),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onRsvpTap;

  const _EventCard({
    required this.event,
    required this.onRsvpTap,
  });

  static Widget _buildImageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF012D1D), Color(0xFF003F63)],
        ),
      ),
      child: Center(
        child: Icon(
          PhosphorIcons.calendar,
          color: Colors.white.withValues(alpha: 0.3),
          size: 40,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE dd MMMM yyyy • HH:mm', 'fr_FR').format(event.date);

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.eventDetail,
        arguments: event.id,
      ),
      child: FcCard(
        padding: EdgeInsets.zero,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image (cover with gradient fallback)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
            child: AspectRatio(
              aspectRatio: 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Image or gradient placeholder
                  event.imageUrl.isNotEmpty
                      ? Image.network(
                          event.imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 800,
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildImageFallback(),
                                Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            );
                          },
                          errorBuilder: (_, __, ___) => _buildImageFallback(),
                        )
                      : _buildImageFallback(),
                  // Gradient overlay for readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.45),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        event.category.toUpperCase(),
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSecondaryContainer,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.stackMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: AppTextStyles.headlineLgMobile.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.unit),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: AppSpacing.stackMd),
                // Date & Time row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(PhosphorIcons.calendarBlank,
                        size: 14, color: AppColors.primaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        formattedDate,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Location row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(PhosphorIcons.mapPin,
                        size: 15, color: AppColors.primaryContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: AppTextStyles.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Footer (Attendees and Button)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(PhosphorIcons.users,
                            size: 16, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${event.attendeeCount} inscrits',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: onRsvpTap,
                      icon: Icon(
                        event.isRsvped ? PhosphorIcons.checkCircleFill : PhosphorIcons.plus,
                        size: 14,
                      ),
                      label: Text(event.isRsvped ? 'Inscrit' : "S'inscrire"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: event.isRsvped
                            ? AppColors.primaryFixed
                            : AppColors.primaryContainer,
                        foregroundColor: event.isRsvped
                            ? AppColors.primaryContainer
                            : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        textStyle: AppTextStyles.labelSm.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              PhosphorIcons.calendar,
              size: 64,
              color: AppColors.outlineVariant,
            ),
            const SizedBox(height: AppSpacing.stackMd),
            Text(
              'Aucun événement trouvé',
              style: AppTextStyles.headlineLgMobile.copyWith(
                color: AppColors.onSurface,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Essayez de modifier vos filtres ou vos termes de recherche.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


