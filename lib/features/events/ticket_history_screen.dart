// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/data/models/event.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/helpers/ticket_id.dart' show TicketId;
import '../../shared/widgets/ticket_dialog.dart' show showTicketDialog;

/// Écran « Mes Tickets » — liste tous les événements auxquels l'utilisateur
/// s'est inscrit, avec QR code miniature et bouton pour afficher le ticket
/// complet.
class TicketHistoryScreen extends ConsumerStatefulWidget {
  const TicketHistoryScreen({super.key});

  @override
  ConsumerState<TicketHistoryScreen> createState() =>
      _TicketHistoryScreenState();
}

class _TicketHistoryScreenState extends ConsumerState<TicketHistoryScreen> {
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
          'Mes tickets',
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: asyncEvents.when(
        data: (events) => _TicketList(events: events),
        loading: () => const _LoadingState(),
        error: (e, _) => _ErrorState(
          message: e is AppException
              ? e.message
              : 'Impossible de charger les événements.',
          onRetry: () => ref.invalidate(eventsProvider),
        ),
      ),
    );
  }
}

// ── _TicketList ──────────────────────────────────────────────────────────

class _TicketList extends ConsumerWidget {
  final List<Event> events;
  const _TicketList({required this.events});

  Future<List<String>> _fetchRsvpIds(WidgetRef ref) async {
    final ids = await ref.read(eventsRepositoryProvider).fetchMyRsvpEventIds();
    return ids;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAsync = ref.watch(currentMemberProvider);

    return FutureBuilder<List<String>>(
      future: _fetchRsvpIds(ref),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        if (snap.hasError) {
          return _ErrorState(
            message: 'Impossible de charger vos inscriptions.',
            onRetry: () => ref.invalidate(eventsProvider),
          );
        }

        final rsvpIds = (snap.data ?? []).toSet();
        final rsvpEvents = events.where((e) => rsvpIds.contains(e.id)).toList();

        // Tri : à venir d'abord, puis passés
        final now = DateTime.now();
        rsvpEvents.sort((a, b) {
          final aUpcoming = a.date.isAfter(now);
          final bUpcoming = b.date.isAfter(now);
          if (aUpcoming && !bUpcoming) return -1;
          if (!aUpcoming && bUpcoming) return 1;
          return a.date.compareTo(b.date);
        });

        if (rsvpEvents.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.stackLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    PhosphorIcons.ticket,
                    size: 72,
                    color: AppColors.outlineVariant,
                  ),
                  SizedBox(height: AppSpacing.stackMd),
                  Text(
                    'Aucun ticket',
                    style: AppTextStyles.headlineLgMobile.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Inscrivez-vous à des événements pour retrouver vos tickets ici.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final attendeeName = memberAsync.valueOrNull?.name ?? 'Participant';

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(eventsProvider);
            await ref.read(eventsProvider.future);
          },
          child: ListView.separated(
            physics: AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackMd,
              AppSpacing.marginMobile,
              AppSpacing.bottomNavHeight + AppSpacing.stackLg,
            ),
            itemCount: rsvpEvents.length,
            separatorBuilder: (_, __) =>
                SizedBox(height: AppSpacing.stackMd),
            itemBuilder: (_, i) => _TicketCard(
              event: rsvpEvents[i],
              attendeeName: attendeeName,
            ),
          ),
        );
      },
    );
  }
}

// ── _TicketCard ──────────────────────────────────────────────────────────

class _TicketCard extends StatelessWidget {
  final Event event;
  final String attendeeName;

  const _TicketCard({
    required this.event,
    required this.attendeeName,
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
          PhosphorIcons.ticket,
          color: Colors.white.withValues(alpha: 0.2),
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = event.date.isBefore(now);
    final formattedDate =
        DateFormat('EEE dd MMM yyyy • HH:mm', 'fr_FR').format(event.date);

    final qrData = TicketId.verificationUrl(event.id);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cover image ───────────────────────────────────
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
                      return _buildImageFallback();
                    },
                    errorBuilder: (_, __, ___) => _buildImageFallback(),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 48,
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
                  // Past badge
                  if (isPast)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.radiusFull),
                        ),
                        child: Text(
                          'PASSÉ',
                          style: AppTextStyles.labelSm.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // ── Card body ─────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: event info ────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Past badge (if no cover)
                      Row(
                        children: [
                          if (isPast && event.imageUrl.isEmpty)
                            Container(
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusFull),
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
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      // Date
                      _MetaRow(
                        icon: PhosphorIcons.calendarBlank,
                        text: formattedDate,
                      ),
                      SizedBox(height: 4),
                      // Location
                      _MetaRow(
                        icon: PhosphorIcons.mapPin,
                        text: event.location,
                      ),
                      SizedBox(height: 4),
                      // Attendees + Category
                      Row(
                        children: [
                          Icon(PhosphorIcons.users,
                              size: 12, color: AppColors.onSurfaceVariant),
                          SizedBox(width: 4),
                          Text(
                            '${event.attendeeCount} inscrit${event.attendeeCount > 1 ? 's' : ''}',
                            style: AppTextStyles.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
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
                      SizedBox(height: 12),
                      // View ticket button
                      SizedBox(
                        height: 34,
                        child: OutlinedButton.icon(
                          onPressed: () => showTicketDialog(
                            context,
                            event: event,
                            attendeeName: attendeeName,
                          ),
                          icon: Icon(PhosphorIcons.qrCode, size: 14),
                          label: Text('Voir le ticket'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                                color: AppColors.primary, width: 1),
                            padding: EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            textStyle: AppTextStyles.labelSm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusFull),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 12),

                // ── Right: QR code thumbnail ────────────────
                GestureDetector(
                  onTap: () => showTicketDialog(
                    context,
                    event: event,
                    attendeeName: attendeeName,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                      border: Border.all(
                          color: AppColors.outlineVariant, width: 0.8),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 64,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF012D1D),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── _MetaRow ─────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.onSurfaceVariant),
        SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
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
    );
  }
}

// ── States ───────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        strokeWidth: 2.4,
        color: AppColors.primaryContainer,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.cloudSlash,
                size: 56, color: AppColors.outlineVariant),
            SizedBox(height: AppSpacing.stackMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            SizedBox(height: AppSpacing.stackMd),
            FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: Icon(PhosphorIcons.arrowsClockwise, size: 18),
              label: Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
