import 'package:share_plus/share_plus.dart';

/// Helper de partage de profil via la feuille de partage native.
///
/// Génère un message attractif avec un lien profond vers le profil.
/// Le lien `fulbe://profile/{memberId}` est prévu pour être intercepté
/// par le deep linking de l'app (à configurer via app_links).
class ProfileShare {
  const ProfileShare._();

  /// Partage un profil via la feuille de partage native.
  ///
  /// [memberName] est le nom complet du membre.
  /// [memberId] est l'UUID du membre pour le lien profond.
  static Future<void> share({
    required String memberName,
    required String memberId,
  }) async {
    const appName = 'Fulɓe Connect';
    final deepLink = 'https://fulbe.app/profile/$memberId';
    final text = 'Découvre le profil de $memberName sur $appName 👥\n\n$deepLink';

    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// Lien profond pour un profil (sans le message marketing).
  static String deepLink(String memberId) =>
      'https://fulbe.app/profile/$memberId';
}
