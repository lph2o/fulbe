import 'dart:async';

import 'package:app_links/app_links.dart';

/// Résultat parsé d'un lien profond.
sealed class DeepLink {
  const DeepLink();
}

/// Profil d'un membre : `/profile/{memberId}`
final class ProfileDeepLink extends DeepLink {
  final String memberId;
  const ProfileDeepLink(this.memberId);
}

/// Lien non reconnu par l'app.
final class UnknownDeepLink extends DeepLink {
  final String url;
  const UnknownDeepLink(this.url);
}

/// Service d'écoute des liens profonds (custom scheme + universal links).
///
/// Utilise [AppLinks] pour intercepter :
/// - `fulbe://profile/{memberId}`
/// - `https://fulbe.app/profile/{memberId}`
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();

  /// Stream de liens entrants (froid au démarrage + chaud ensuite).
  Stream<DeepLink> get links async* {
    // 1. Lien qui a lancé l'app (getInitialLink)
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      yield _parse(initialUri);
    }

    // 2. Liens reçus pendant que l'app tourne (uriLinkStream)
    await for (final uri in _appLinks.uriLinkStream) {
      yield _parse(uri);
    }
  }

  /// Parse un URI en [DeepLink].
  DeepLink _parse(Uri uri) {
    final host = uri.host;
    final path = uri.path;

    // fulbe://profile/xxx  ou  https://fulbe.app/profile/xxx
    if (host == 'profile' || path.startsWith('/profile/')) {
      final memberId = uri.pathSegments.last;
      if (memberId.isNotEmpty && memberId != 'profile') {
        return ProfileDeepLink(memberId);
      }
    }

    return UnknownDeepLink(uri.toString());
  }
}
