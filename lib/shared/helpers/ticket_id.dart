/// Générateur d'identifiants de ticket déterministes et cohérents
/// entre l'écran d'historique et le dialogue ticket.
///
/// Format : `FC-{eventId}`
///
/// Utilisé pour :
/// - Le QR code (URL `https://fulbe-connect.app/tickets/<ticketId>`)
/// - L'affichage texte de l'ID ticket
abstract class TicketId {
  /// Génère un ticket ID stable pour un événement donné.
  ///
  /// Basé uniquement sur l'ID de l'événement Supabase (UUID) pour garantir
  /// que le même événement produit toujours le même ticket, quel que soit
  /// l'endroit où il est affiché (dialogue, historique, futur scan).
  static String generate(String eventId) => 'FC-$eventId';

  /// Construit l'URL publique de vérification du ticket.
  static String verificationUrl(String eventId) =>
      'https://fulbe-connect.app/tickets/${generate(eventId)}';
}
