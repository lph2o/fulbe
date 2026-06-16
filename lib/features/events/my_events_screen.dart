// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

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

/// Écran "Mes Événements" — deux onglets : Créés et Rejoints.
class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft, size: 22),
          color: AppColors.onSurface,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mes événements',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.onSurfaceVariant,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w700),
          unselectedLabelStyle: AppTextStyles.labelSm.copyWith(fontWeight: FontWeight.w500),
          tabs: [
            Tab(text: 'Créés'),
            Tab(text: 'Rejoints'),
          ],
        ),
      ),
      body: asyncEvents.when(
        data: (events) => TabBarView(
          controller: _tabCtrl,
          children: [
            _EventsTab(events: events, mode: _EventsTabMode.created),
            _EventsTab(events: events, mode: _EventsTabMode.joined),
          ],
        ),
        loading: () => Center(
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.stackLg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIcons.cloudSlash, size: 56, color: AppColors.outlineVariant),
                SizedBox(height: AppSpacing.stackMd),
                Text(
                  e is AppException ? e.message : 'Impossible de charger les événements.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                ),
                SizedBox(height: AppSpacing.stackMd),
                FilledButton.tonalIcon(
                  onPressed: () => ref.invalidate(eventsProvider),
                  icon: Icon(PhosphorIcons.arrowsClockwise, size: 18),
                  label: Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _EventsTabMode { created, joined }

/// Un onglet (Créés ou Rejoints) qui filtre les IDs via le repository.
class _EventsTab extends ConsumerWidget {
  final List<Event> events;
  final _EventsTabMode mode;

  const _EventsTab({required this.events, required this.mode});

  Future<List<String>> _fetchIds(WidgetRef ref) async {
    final repo = ref.read(eventsRepositoryProvider);
    return mode == _EventsTabMode.created
        ? repo.fetchMyCreatedEventIds()
        : repo.fetchMyRsvpEventIds();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<String>>(
      future: _fetchIds(ref),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryContainer),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.cloudSlash, size: 48, color: AppColors.outlineVariant),
                  SizedBox(height: AppSpacing.stackMd),
                  Text(
                    'Impossible de charger vos événements.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  SizedBox(height: AppSpacing.stackMd),
                  FilledButton.tonalIcon(
                    onPressed: () => ref.invalidate(eventsProvider),
                    icon: Icon(PhosphorIcons.arrowsClockwise, size: 18),
                    label: Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        }

        final ids = snap.data ?? [];
        final filtered = events.where((e) => ids.contains(e.id)).toList();

        // Tri : à venir d'abord, puis passés
        final now = DateTime.now();
        filtered.sort((a, b) {
          final aUpcoming = a.date.isAfter(now);
          final bUpcoming = b.date.isAfter(now);
          if (aUpcoming && !bUpcoming) return -1;
          if (!aUpcoming && bUpcoming) return 1;
          return a.date.compareTo(b.date);
        });

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    mode == _EventsTabMode.created ? PhosphorIcons.calendarPlus : PhosphorIcons.calendarCheck,
                    size: 64,
                    color: AppColors.outlineVariant,
                  ),
                  SizedBox(height: AppSpacing.stackMd),
                  Text(
                    mode == _EventsTabMode.created
                        ? "Vous n'avez pas encore créé d'événement."
                        : "Vous n'êtes inscrit à aucun événement.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  if (mode == _EventsTabMode.created) ...[
                    SizedBox(height: AppSpacing.stackMd),
                    FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createEvent),
                      icon: Icon(PhosphorIcons.plus, size: 18),
                      label: Text('Créer un événement'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(eventsProvider);
            await ref.read(eventsProvider.future);
          },
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackMd,
              AppSpacing.marginMobile,
              AppSpacing.bottomNavHeight + AppSpacing.stackLg,
            ),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.stackMd),
            itemBuilder: (_, i) => _MyEventCard(event: filtered[i]),
          ),
        );
      },
    );
  }
}

// ── Mini Event Card ────────────────────────────────────────────────────────

class _MyEventCard extends StatelessWidget {
  final Event event;
  const _MyEventCard({required this.event});

  static Widget _buildCompactFallback() {
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
          color: Colors.white.withValues(alpha: 0.2),
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = event.date.isBefore(now);
    final formattedDate = DateFormat('EEEE dd MMMM yyyy • HH:mm', 'fr_FR').format(event.date);

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.eventDetail,
        arguments: event.id,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image strip (only when imageUrl is set)
            if (event.imageUrl.isNotEmpty)
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      cacheWidth: 600,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return _buildCompactFallback();
                      },
                      errorBuilder: (_, __, ___) => _buildCompactFallback(),
                    ),
                    // Gradient overlay
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
            // Card body
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Color badge
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: isPast
                          ? AppColors.surfaceContainerHigh
                          : AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      isPast ? PhosphorIcons.calendarCheck : PhosphorIcons.calendarBlank,
                      size: 22,
                      color: isPast ? AppColors.outline : AppColors.primaryContainer,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isPast)
                              Container(
                                margin: EdgeInsets.only(right: 8),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                                ),
                                child: Text(
                                  'PASSÉ',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                event.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelMd.copyWith(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(PhosphorIcons.calendarBlank, size: 12, color: AppColors.onSurfaceVariant),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                formattedDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSm.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(PhosphorIcons.users, size: 12, color: AppColors.onSurfaceVariant),
                            SizedBox(width: 4),
                            Text(
                              '${event.attendeeCount} inscrit${event.attendeeCount > 1 ? 's' : ''}',
                              style: AppTextStyles.labelSm.copyWith(
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.w400,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryFixed,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(PhosphorIcons.caretRight, size: 18, color: AppColors.outlineVariant),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
