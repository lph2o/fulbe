// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/models/event.dart';
import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/navigation/app_router.dart';
import '../../shared/helpers/contact_helper.dart';
import '../../shared/helpers/ticket_id.dart' show TicketId;
import '../../shared/widgets/fc_button.dart';
import '../../shared/widgets/ticket_dialog.dart' show showTicketDialog;

/// Écran détail d'un événement — inspiré Luma (landing page visuelle)
/// + Partiful (RSVP 1-clic, voir qui vient).
class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isToggling = false;
  bool _isContacting = false;

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(eventsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: asyncEvents.when(
        data: (events) {
          final event = events.where((e) => e.id == widget.eventId).firstOrNull;
          if (event == null) return _notFound();
          return _buildContent(event);
        },
        loading: () => _buildLoading(),
        error: (e, _) => _buildError(e),
      ),
    );
  }

  // ── Content ─────────────────────────────────────────────────────────

  Widget _buildContent(Event event) {
    final formattedDate = DateFormat('EEEE dd MMMM yyyy • HH:mm', 'fr_FR').format(event.date);

    return CustomScrollView(
      slivers: [
        // ── AppBar avec image ────────────────────────────
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: Container(
            margin: EdgeInsets.only(left: 8, top: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(PhosphorIcons.arrowLeft, size: 22),
              color: Colors.white,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          actions: [
            // ── Owner actions ────────────────────────────
            if (_isOwner(event))
              PopupMenuButton<String>(
                icon: Container(
                  margin: EdgeInsets.only(right: 4, top: 8),
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(PhosphorIcons.dotsThreeVertical,
                      size: 18, color: Colors.white),
                ),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (v) => _onOwnerAction(v, event),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.shareNetwork, size: 18, color: AppColors.primary),
                      title: Text('Partager', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.pencilSimple, size: 18, color: AppColors.onSurfaceVariant),
                      title: Text('Modifier', style: TextStyle(fontFamily: 'Inter', fontSize: 13)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(PhosphorIcons.trash, size: 18, color: AppColors.error),
                      title: Text('Supprimer',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.error)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Hero image avec loading + erreur + fade-in
                _HeroImage(imageUrl: event.imageUrl),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Body ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.marginMobile,
              AppSpacing.stackMd,
              AppSpacing.marginMobile,
              AppSpacing.bottomNavHeight + AppSpacing.stackLg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    event.category.toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.stackMd),

                // Title
                Text(
                  event.title,
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.stackMd),

                // Date & Time card
                _infoCard(
                  icon: PhosphorIcons.calendarBlank,
                  color: AppColors.primaryContainer,
                  title: formattedDate,
                  subtitle: 'Date et heure',
                ),
                SizedBox(height: AppSpacing.stackSm),

                // Location card
                _infoCard(
                  icon: PhosphorIcons.mapPin,
                  color: AppColors.tertiary,
                  title: event.location,
                  subtitle: 'Lieu',
                ),
                SizedBox(height: AppSpacing.stackSm),

                // Attendees card
                _infoCard(
                  icon: PhosphorIcons.users,
                  color: AppColors.secondary,
                  title: '${event.attendeeCount} participant${event.attendeeCount > 1 ? 's' : ''}',
                  subtitle: 'Inscrits',
                ),
                SizedBox(height: AppSpacing.stackLg),

                // Description
                Text(
                  'À propos',
                  style: AppTextStyles.labelLg.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                SizedBox(height: AppSpacing.stackSm),
                Text(
                  event.description,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),

                SizedBox(height: AppSpacing.stackLg),

                // Participants preview
                if (event.attendeeCount > 0) ...[
                  Text(
                    'Qui participe ?',
                    style: AppTextStyles.labelLg.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: AppSpacing.stackMd),
                  _AttendeesPreview(eventId: widget.eventId),
                  SizedBox(height: AppSpacing.stackLg),
                ],

                // RSVP Button
                FcPrimaryButton(
                  label: event.isRsvped ? '✅ Inscrit — Se désinscrire' : "S'inscrire à l'événement",
                  icon: event.isRsvped ? PhosphorIcons.checkCircleFill : PhosphorIcons.plus,
                  onTap: () => _toggleRsvp(event),
                ),

                // Contact organizer (only for non-owners)
                if (!_isOwner(event) && event.createdBy != null) ...[
                  const SizedBox(height: AppSpacing.stackSm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isContacting ? null : _contactOrganizer,
                      icon: _isContacting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(PhosphorIcons.chatCircleDots, size: 18),
                      label: const Text('Contacter l\'organisateur'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryContainer,
                        side: const BorderSide(color: AppColors.primaryContainer, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        textStyle: AppTextStyles.labelMd.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Info Card ───────────────────────────────────────────────────────

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurface, fontWeight: FontWeight.w600, fontSize: 15,
                )),
                SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Owner helpers ───────────────────────────────────────────────────

  bool _isOwner(Event event) {
    final member = ref.watch(currentMemberProvider).valueOrNull;
    if (member == null || event.createdBy == null) return false;
    return member.id == event.createdBy;
  }

  void _onOwnerAction(String action, Event event) {
    final url = TicketId.verificationUrl(event.id);

    switch (action) {
      case 'share':
        SharePlus.instance.share(
          ShareParams(text: '${event.title} — $url'),
        );
      case 'edit':
        Navigator.of(context).pushNamed(
          AppRoutes.createEvent,
          arguments: event,
        ).then((result) {
          if (result == true && mounted) {
            ref.invalidate(eventsProvider);
          }
        });
      case 'delete':
        _confirmDelete(event);
    }
  }

  Future<void> _confirmDelete(Event event) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer l\'événement',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer « ${event.title} » ?\n\n'
          'Cette action est irréversible et supprimera également tous les posts associés.',
          style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Supprimer',
                style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(eventsRepositoryProvider).deleteEvent(event.id);
        ref.invalidate(eventsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Événement supprimé.'),
              backgroundColor: AppColors.primaryContainer,
            ),
          );
          Navigator.of(context).pop();
        }
      } on AppException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      } finally {
        // no-op
      }
    }
  }

  Future<void> _contactOrganizer() async {
    final events = ref.read(eventsProvider).valueOrNull;
    final event = events?.firstWhere((e) => e.id == widget.eventId);
    if (event == null || event.createdBy == null) return;

    if (_isContacting) return;
    setState(() => _isContacting = true);
    await ContactHelper.navigateToConversation(context, ref, event.createdBy!);
    if (mounted) setState(() => _isContacting = false);
  }

  Future<void> _toggleRsvp(Event event) async {
    if (_isToggling) return;
    setState(() => _isToggling = true);

    try {
      await ref.read(eventsRepositoryProvider).toggleRsvp(event.id, !event.isRsvped);
      ref.invalidate(eventsProvider);
      await ref.read(eventsProvider.future);

      if (mounted && !event.isRsvped) {
        final member = ref.read(currentMemberProvider).valueOrNull;
        final attendeeName = member?.name ?? 'Participant';
        showTicketDialog(context, event: event, attendeeName: attendeeName);
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _isToggling = false);
    }
  }

  // ── States ─────────────────────────────────────────────────────────

  Widget _notFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.calendarX, size: 64, color: AppColors.outlineVariant),
          SizedBox(height: AppSpacing.stackMd),
          Text('Événement introuvable', style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant)),
          SizedBox(height: AppSpacing.stackMd),
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Retour')),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator(strokeWidth: 2.4));
  }

  Widget _buildError(Object e) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.stackLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.cloudSlash, size: 56, color: AppColors.outlineVariant),
            SizedBox(height: AppSpacing.stackMd),
            Text(
              e is AppException ? e.message : 'Impossible de charger l\'événement.',
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
}

// ── Hero Image ────────────────────────────────────────────────────────────

/// Affiche l'image de couverture de l'événement avec :
/// - Chargement progressif (shimmer)
/// - Fade-in à la fin du chargement
/// - Fallback gradient en cas d'absence d'URL ou d'erreur réseau
class _HeroImage extends StatefulWidget {
  final String imageUrl;
  const _HeroImage({required this.imageUrl});

  @override
  State<_HeroImage> createState() => _HeroImageState();
}

class _HeroImageState extends State<_HeroImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  bool _isLoaded = false;
  bool _hasError = false;

  static const _gradientColors = [
    Color(0xFF012D1D),
    Color(0xFF003F63),
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onLoadComplete() {
    if (!mounted) return;
    setState(() => _isLoaded = true);
    _fadeCtrl.forward();
  }

  void _onError() {
    if (!mounted) return;
    setState(() => _hasError = true);
  }

  @override
  void didUpdateWidget(covariant _HeroImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _isLoaded = false;
      _hasError = false;
      _fadeCtrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pas d'image du tout → gradient immédiat
    if (widget.imageUrl.isEmpty || _hasError) {
      return _buildGradient();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient en fond (visible pendant le chargement)
        _buildGradient(),

        // Image avec fade-in
        FadeTransition(
          opacity: _fadeAnim,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (_, child, loadingProgress) {
              if (loadingProgress == null) {
                if (!_isLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _onLoadComplete();
                  });
                }
                return child;
              }
              return child;
            },
            errorBuilder: (_, error, __) {
              _onError();
              return const SizedBox.shrink();
            },
            // Évite le cache disque pour les tests dev
            cacheWidth: 800,
          ),
        ),

        // Subtle shimmer during loading
        if (!_isLoaded && !_hasError)
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: 0.15,
              duration: const Duration(milliseconds: 600),
              child: Container(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
      ),
    );
  }
}

// ── Participants Preview ─────────────────────────────────────────────────

class _AttendeesPreview extends ConsumerWidget {
  final String eventId;
  const _AttendeesPreview({required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(eventsRepositoryProvider).fetchAttendees(eventId),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryContainer)),
          );
        }
        if (!snap.hasData || snap.data!.isEmpty) {
          return Text('Aucun participant pour le moment.', style: AppTextStyles.bodyMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ));
        }

        final attendees = snap.data!.take(8).toList();
        final extra = snap.data!.length > 8 ? snap.data!.length - 8 : 0;

        return Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: attendees.map((m) {
                final name = m['full_name'] as String? ?? '';
                final initials = m['initials'] as String? ?? '';
                final avatar = m['avatar_url'] as String?;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primaryFixed,
                      backgroundImage: avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                      child: avatar == null || avatar.isEmpty
                          ? Text(initials, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primaryContainer))
                          : null,
                    ),
                    SizedBox(height: 4),
                    SizedBox(
                      width: 56,
                      child: Text(
                        name.split(' ').first,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurface, fontSize: 10),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            if (extra > 0) ...[
              SizedBox(height: AppSpacing.stackSm),
              Text(
                '+ $extra autre${extra > 1 ? 's' : ''} participant${extra > 1 ? 's' : ''}',
                style: AppTextStyles.labelSm.copyWith(color: AppColors.primaryContainer, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        );
      },
    );
  }
}
