import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/data/models/event.dart';
import '../../shared/helpers/ticket_id.dart' show TicketId;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Affiche un dialogue « Ticket Réservé » après inscription à un événement.
///
/// Inclut :
/// - Résumé de l'événement (date, lieu)
/// - Nom du participant
/// - QR code réel (encodant un identifiant unique du ticket)
/// - Bouton « Ajouter au calendrier » (ajout réel dans l'agenda du téléphone)
void showTicketDialog(
  BuildContext context, {
  required Event event,
  required String attendeeName,
}) {
  final ticketId = TicketId.generate(event.id);
  // QR code encodes a verification URL
  final qrData = TicketId.verificationUrl(event.id);

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
            // ── Dialog Header ──────────────────────────────────
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
                    child: const Icon(PhosphorIcons.x,
                        color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            // ── Ticket details ─────────────────────────────────
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

                  // ── Info cards ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        _TicketRow(
                          icon: PhosphorIcons.calendarBlank,
                          label: 'Date & Heure',
                          value: DateFormat('dd MMMM yyyy • HH:mm', 'fr_FR')
                              .format(event.date),
                        ),
                        const Divider(height: 16),
                        _TicketRow(
                          icon: PhosphorIcons.mapPin,
                          label: 'Lieu',
                          value: event.location,
                        ),
                        const Divider(height: 16),
                        _TicketRow(
                          icon: PhosphorIcons.user,
                          label: 'Participant',
                          value: attendeeName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // ── QR Code (real) ───────────────────────────
                  Container(
                    width: 140,
                    height: 140,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                        ),
                      ],
                      border: Border.all(
                          color: AppColors.outlineVariant, width: 0.8),
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 116,
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
                  const SizedBox(height: 8),
                  Text(
                    ticketId.toUpperCase(),
                    style: AppTextStyles.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.stackLg),

                  // ── Actions ──────────────────────────────────
                  Row(
                    children: [
                      // Partager le ticket
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            SharePlus.instance.share(
                              ShareParams(text: qrData),
                            );
                          },
                          icon: const Icon(PhosphorIcons.shareNetwork, size: 14),
                          label: const Text('Partager'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                                color: AppColors.primary, width: 1),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            textStyle: AppTextStyles.labelMd
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Ajouter au calendrier
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            final calEvent = calendar.Event(
                              title: event.title,
                              description: event.description,
                              location: event.location,
                              startDate: event.date,
                              endDate: event.date.add(const Duration(hours: 2)),
                            );
                            calendar.Add2Calendar.addEvent2Cal(calEvent);
                          },
                          icon: const Icon(PhosphorIcons.calendarBlank, size: 16),
                          label: const Text('Calendrier'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── _TicketRow ──────────────────────────────────────────────────────────

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
