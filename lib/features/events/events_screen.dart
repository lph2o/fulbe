import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/data/mock_events.dart';
import '../../shared/widgets/fc_card.dart';
import '../../shared/widgets/fc_chip.dart';
import '../../shared/widgets/fc_search_bar.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _selectedCategoryIndex = 0;
  String _query = '';
  late List<Event> _events;

  static const _categories = [
    'Tous',
    'Conférence',
    'Festival',
    'Webinaire',
    'Réunion',
  ];

  @override
  void initState() {
    super.initState();
    _events = List.from(MockEvents.all);
  }

  List<Event> get _filteredEvents {
    var list = _events;

    // Filter by category
    if (_selectedCategoryIndex > 0) {
      final selectedCategory = _categories[_selectedCategoryIndex];
      list = list.where((e) => e.category == selectedCategory).toList();
    }

    // Filter by search query
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.description.toLowerCase().contains(q) ||
              e.location.toLowerCase().contains(q))
          .toList();
    }

    return list;
  }

  void _toggleRsvp(int index, Event event) {
    setState(() {
      final isNowRsvped = !event.isRsvped;
      _events[index] = event.copyWith(
        isRsvped: isNowRsvped,
        attendeeCount: event.attendeeCount + (isNowRsvped ? 1 : -1),
      );

      if (isNowRsvped) {
        _showTicketDialog(context, _events[index]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        elevation: 0.5,
        centerTitle: true,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.marginMobile),
          child: CircleAvatar(
            backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150&h=150&fit=crop&q=80'),
            radius: 20,
          ),
        ),
        title: Text(
          'Fulɓe Connect',
          style: AppTextStyles.headlineLgMobile.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: AppColors.onSurfaceVariant),
            onPressed: () {},
            padding: const EdgeInsets.only(right: AppSpacing.marginMobile),
          ),
        ],
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
                Text(
                  'Participez aux rassemblements de la communauté.',
                  style: AppTextStyles.bodyMd
                      .copyWith(color: AppColors.onSurfaceVariant),
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
          // ── Event list ─────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyEventsState()
                : ListView.separated(
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
                      // Find real index in original list
                      final originalIndex =
                          _events.indexWhere((e) => e.id == event.id);
                      return _EventCard(
                        event: event,
                        onRsvpTap: () => _toggleRsvp(originalIndex, event),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showTicketDialog(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.stackMd),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusXl),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ticket Réservé ! 🎉',
                      style: AppTextStyles.labelMd.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
              // Ticket details
              Padding(
                padding: const EdgeInsets.all(AppSpacing.stackLg),
                child: Column(
                  children: [
                    Text(
                      event.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineLgMobile.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackMd),
                    // Ticket info cards
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          _TicketRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Date & Heure',
                            value: DateFormat('dd MMMM yyyy • HH:mm', 'fr_FR')
                                .format(event.date),
                          ),
                          const Divider(height: 16),
                          _TicketRow(
                            icon: Icons.location_on_outlined,
                            label: 'Lieu',
                            value: event.location,
                          ),
                          const Divider(height: 16),
                          const _TicketRow(
                            icon: Icons.person_outline,
                            label: 'Participant',
                            value: 'Amadou Diallo',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    // Custom QR code painter
                    Container(
                      width: 140,
                      height: 140,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                          ),
                        ],
                        border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                      ),
                      child: CustomPaint(
                        painter: _QrCodePainter(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TICKET-ID: FC-${event.id.toUpperCase()}-${DateTime.now().millisecond}',
                      style: AppTextStyles.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 1,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.stackLg),
                    // Actions
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ajouté à votre agenda de téléphone !'),
                              backgroundColor: AppColors.primaryContainer,
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Ajouter au calendrier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          textStyle: AppTextStyles.labelMd
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
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
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onRsvpTap;

  const _EventCard({
    required this.event,
    required this.onRsvpTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('EEEE dd MMMM yyyy • HH:mm', 'fr_FR').format(event.date);

    return FcCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusLg),
            ),
            child: AspectRatio(
              aspectRatio: 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceContainerHigh,
                      child: const Icon(Icons.event,
                          color: AppColors.outline, size: 48),
                    ),
                  ),
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
                    const Icon(Icons.calendar_today_outlined,
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
                    const Icon(Icons.location_on_outlined,
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
                        const Icon(Icons.people_outline,
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
                        event.isRsvped ? Icons.done : Icons.add,
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
    );
  }
}

class _TicketRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TicketRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primaryContainer),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.labelSm.copyWith(
                  color: AppColors.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
              Icons.calendar_month_outlined,
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

class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryContainer
      ..style = PaintingStyle.fill;

    // Draw some random square shapes to look like a QR code
    final double block = size.width / 8;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        // Create finder patterns in corners (top-left, top-right, bottom-left)
        bool isFinder =
            (r < 3 && c < 3) || (r < 3 && c >= 5) || (r >= 5 && c < 3);
        if (isFinder) {
          // Outer square
          if (r == 0 ||
              r == 2 ||
              c == 0 ||
              c == 2 ||
              (r == 0 && c >= 5) ||
              (r == 2 && c >= 5) ||
              (c == 5 && r < 3) ||
              (c == 7 && r < 3) ||
              (r == 5 && c < 3) ||
              (r == 7 && c < 3) ||
              (c == 0 && r >= 5) ||
              (c == 2 && r >= 5)) {
            canvas.drawRect(
                Rect.fromLTWH(c * block, r * block, block, block), paint);
          } else if ((r == 1 && c == 1) ||
              (r == 1 && c == 6) ||
              (r == 6 && c == 1)) {
            // Inner center dot
            canvas.drawRect(
                Rect.fromLTWH(c * block, r * block, block, block), paint);
          }
        } else {
          // Pseudo-random noise
          if ((r + c) % 3 == 0 || (r * c) % 5 == 1) {
            canvas.drawRect(
                Rect.fromLTWH(c * block, r * block, block, block), paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
