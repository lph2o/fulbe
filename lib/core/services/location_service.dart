import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';

/// Service de géolocalisation native : permission + GPS + reverse-geocoding.
///
/// ── Configuration native requise ─────────────────────────────────────────
///
/// **iOS** — `ios/Runner/Info.plist` :
/// ```xml
/// <key>NSLocationWhenInUseUsageDescription</key>
/// <string>Pour détecter automatiquement votre pays et votre ville.</string>
/// ```
///
/// **Android** — `android/app/src/main/AndroidManifest.xml` (avant `<application>`) :
/// ```xml
/// <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
/// <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
/// ```
///
/// **Web** (`web/index.html`) : la géolocalisation requiert HTTPS en production.
/// En dev `localhost` est considéré comme secure par Chrome.
///
/// **iOS App Store** : Apple rejette les apps qui demandent la permission GPS
/// sans justification. Texte ci-dessus validé pour l'usage "détection auto de
/// la localisation à l'inscription".
/// ────────────────────────────────────────────────────────────────────────

/// Service de géolocalisation native : permission + GPS + reverse-geocoding.
///
/// Renvoie un couple (country, city) à partir de la position actuelle de
/// l'utilisateur. Gère tous les cas d'erreur (permission refusée, service
/// désactivé, pas de réseau, etc.) en levant des [AppException] localisées.
class LocationService {
  const LocationService();

  /// Demande la position actuelle et la résout en (pays, ville).
  ///
  /// Renvoie `null` si l'utilisateur n'a pas encore choisi (annule le flow
  /// sans erreur), et lève une [AppException] ciblée en cas d'échec.
  /// Exécute une opération Geolocator en convertissant les exceptions
  /// plateforme (web/desktop) en [AppException] localisées.
  static Future<T> _safeGeolocatorCall<T>(
    Future<T> Function() call,
  ) async {
    try {
      return await call();
    } catch (e) {
      // PlatformException (web où une API n'est pas implémentée,
      // ou timeout inattendu) → message générique mais compréhensible.
      throw ServerException(
        'Impossible d\'accéder à la géolocalisation sur cette plateforme. '
        'Veuillez sélectionner votre pays manuellement.',
        cause: e,
      );
    }
  }

  Future<({String country, String city})?> resolveCurrent() async {
    // ── 0. Plateforme supportée ? (web/desktop = contournement)
    //      Geolocator supporte le web, mais `isLocationServiceEnabled` et
    //      `timeLimit` ne sont pas disponibles sur web → on saute l'étape 1.
    const isMobile = !kIsWeb;

    // ── 1. Service de localisation activé ? (mobile uniquement) ──────────
    if (isMobile) {
      final serviceEnabled = await _safeGeolocatorCall(
        Geolocator.isLocationServiceEnabled,
      );
      if (!serviceEnabled) {
        throw const NetworkException(
          'Les services de localisation sont désactivés. '
          'Activez le GPS dans les paramètres de votre appareil.',
        );
      }
    }

    // ── 2. Permission ───────────────────────────────────────────────────
    var permission = await _safeGeolocatorCall(Geolocator.checkPermission);
    if (permission == LocationPermission.denied) {
      permission = await _safeGeolocatorCall(Geolocator.requestPermission);
    }
    if (permission == LocationPermission.denied) {
      throw const AuthException(
        'La permission de localisation a été refusée.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const AuthException(
        'La permission de localisation est bloquée de façon permanente. '
        'Activez-la dans les paramètres de l\'app.',
      );
    }

    // ── 3. Position GPS ─────────────────────────────────────────────────
    // Sur web, on omet `timeLimit` car il n'est pas supporté par le
    // navigateur et lèverait une PlatformException.
    final position = await _safeGeolocatorCall(() =>
        Geolocator.getCurrentPosition(            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: isMobile ? Duration(seconds: 10) : null,
            ),
        ));

    // ── 4. Reverse-geocoding (avec timeout court pour éviter d'attendre) ─
    final List<geo.Placemark> placemarks;
    try {
      placemarks = await geo
          .placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          )
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => <geo.Placemark>[],
          );
    } catch (e) {
      throw ServerException(
        'Impossible de déterminer votre adresse. '
        'Réessayez ou sélectionnez manuellement.',
        cause: e,
      );
    }

    if (placemarks.isEmpty) {
      throw const ServerException(
        'Position trouvée mais ville introuvable. '
        'Réessayez ou sélectionnez manuellement.',
      );
    }

    final place = placemarks.first;
    final country = place.country ?? '';
    final city = place.locality ??
        place.subAdministrativeArea ??
        place.administrativeArea ??
        '';

    if (country.isEmpty) {
      throw const ServerException(
        'Position trouvée mais pays introuvable. '
        'Réessayez ou sélectionnez manuellement.',
      );
    }

    return (country: country, city: city);
  }
}
