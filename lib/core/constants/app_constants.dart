/// Constantes globales de l'application Fulɓe Connect.
library;

import 'package:flutter/foundation.dart';

/// Constantes applicatives centralisées (URLs, timeouts, pagination, etc.).
abstract class AppConstants {
  // ── Supabase ──────────────────────────────────────────────────────────
  // Lues depuis --dart-define (cf. main.dart). Des valeurs par défaut
  // (placeholder) sont fournies pour permettre le build en l'absence
  // d'environnement configuré.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://placeholder.supabase.co',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'placeholder_key',
  );

  /// Marqueur sentinelle : URL utilisée quand l'app est buildée sans
  /// configuration Supabase (cf. `.env.example`).
  static const String supabaseUrlPlaceholder = 'https://placeholder.supabase.co';

  /// Marqueur sentinelle : clé utilisée quand l'app est buildée sans
  /// configuration Supabase.
  static const String supabaseKeyPlaceholder = 'placeholder_key';

  /// Indique si la configuration Supabase est exploitable.
  ///
  /// Renvoie `false` si l'URL ou la clé sont encore sur leur valeur
  /// placeholder (build sans `--dart-define`). L'app doit alors afficher
  /// un écran d'erreur au lieu de tenter d'appeler le backend.
  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty &&
      supabasePublishableKey.isNotEmpty &&
      supabaseUrl != supabaseUrlPlaceholder &&
      supabasePublishableKey != supabaseKeyPlaceholder &&
      !supabaseUrl.contains('placeholder');

  // ── Locale ────────────────────────────────────────────────────────────
  static const String defaultLocale = 'fr_FR';

  // ── Pagination ────────────────────────────────────────────────────────
  static const int defaultPageSize = 20;
  static const int largePageSize = 50;

  // ── Timeouts (HTTP) ───────────────────────────────────────────────────
  static const Duration networkTimeout = Duration(seconds: 15);
  static const Duration shortTimeout = Duration(seconds: 5);

  // ── UI ────────────────────────────────────────────────────────────────
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 600);

  // ── Avatars par défaut ────────────────────────────────────────────────
  static const String defaultAvatarUrl =
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=150&h=150&fit=crop&q=80';

  // ── Agora ─────────────────────────────────────────────────────────────
  static const String agoraAppId = String.fromEnvironment(
    'AGORA_APP_ID',
    defaultValue: 'placeholder_agora_app_id',
  );

  static const String agoraAppIdPlaceholder = 'placeholder_agora_app_id';

  static bool get hasAgoraConfig =>
      agoraAppId.isNotEmpty &&
      agoraAppId != agoraAppIdPlaceholder &&
      !agoraAppId.contains('placeholder');

  /// Certificat App Agora (optionnel, pour génération de token).
  ///
  /// Si renseigné, l'app génère un token valide pour chaque canal.
  /// Si absent, l'app passe un token vide (nécessite que le App Certificate
  /// soit DÉSACTIVÉ dans la console Agora).
  static const String agoraAppCertificate = String.fromEnvironment(
    'AGORA_APP_CERTIFICATE',
    defaultValue: '',
  );

  /// Indique si un certificat Agora est configuré pour la génération de tokens.
  static bool get hasAgoraCertificateConfig =>
      agoraAppCertificate.isNotEmpty &&
      agoraAppCertificate != 'placeholder_agora_certificate';

  // ── App ───────────────────────────────────────────────────────────────
  static const String appName = 'Fulɓe Connect';

  /// Indique si on tourne dans un contexte de test (désactive les logs verbeux).
  static bool get isTest =>
      kDebugMode && const bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
}
