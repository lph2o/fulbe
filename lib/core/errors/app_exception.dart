/// Hiérarchie d'exceptions applicatives avec messages localisés en français.
///
/// Toutes les couches (repositories, services) doivent lever des [AppException]
/// plutôt que des exceptions brutes, afin que la couche UI puisse afficher
/// des messages compréhensibles pour l'utilisateur final.
library;

import 'package:meta/meta.dart';

/// Exception abstraite de base pour toute l'application.
@immutable
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  /// Message déjà localisé en français, prêt à afficher.
  final String message;

  /// Exception d'origine (pour le logging interne).
  final Object? cause;

  /// Stack trace pour le debug.
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// Erreur réseau (timeout, perte de connexion, DNS, etc.).
class NetworkException extends AppException {
  const NetworkException(super.message, {super.cause, super.stackTrace});
}

/// Erreur d'authentification (login invalide, session expirée, etc.).
class AuthException extends AppException {
  const AuthException(super.message, {super.cause, super.stackTrace});
}

/// Ressource introuvable (404, id inexistant, etc.).
class NotFoundException extends AppException {
  const NotFoundException(super.message, {super.cause, super.stackTrace});
}

/// Données invalides (parsing échoué, validation métier).
class ValidationException extends AppException {
  const ValidationException(super.message, {super.cause, this.fieldErrors});

  /// Erreurs par champ (ex. {"email": "Email invalide"}).
  final Map<String, String>? fieldErrors;
}

/// Erreur serveur (5xx, base de données inaccessible, etc.).
class ServerException extends AppException {
  const ServerException(super.message, {super.cause, super.stackTrace, this.statusCode});

  /// Code HTTP si applicable.
  final int? statusCode;
}

/// Erreur inconnue — devrait être rare.
class UnknownException extends AppException {
  const UnknownException(super.message, {super.cause, super.stackTrace});
}
