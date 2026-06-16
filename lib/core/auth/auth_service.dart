/// Service d'authentification centralisé.
///
/// Wrapper au-dessus de [SupabaseAuthClient] qui :
///   - expose un stream d'état d'auth typé
///   - localise les messages d'erreur en français
///   - offre un signOut idempotent avec cleanup
///   - fournit un accès typé aux métadonnées utilisateur
library;

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../errors/app_exception.dart';
import '../logging/app_logger.dart';
import '../services/notification_service.dart';

/// Service d'auth singleton.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  sb.SupabaseClient get _client => sb.Supabase.instance.client;
  sb.GoTrueClient get _auth => _client.auth;

  /// Stream de l'état d'auth (session actuelle, événements).
  Stream<sb.AuthState> get authStateChanges => _auth.onAuthStateChange;

  /// Session active, ou null si non connecté.
  sb.Session? get currentSession => _auth.currentSession;

  /// Utilisateur courant, ou null.
  sb.User? get currentUser => _auth.currentUser;

  /// Vrai si l'utilisateur est authentifié.
  bool get isAuthenticated => currentSession != null;

  /// Connecte l'utilisateur avec email + mot de passe.
  ///
  /// Lève [AuthException] en cas d'échec (message localisé).
  Future<sb.Session> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _auth.signInWithPassword(email: email, password: password);
      if (res.session == null) {
        throw const AuthException('Connexion impossible. Vérifiez vos identifiants.');
      }
      log.info('User signed in: ${res.user?.id}', tag: 'auth');
      return res.session!;
    } on sb.AuthException catch (e, st) {
      throw AuthException(_localizeAuthError(e.message), cause: e, stackTrace: st);
    } catch (e, st) {
      log.error('signInWithPassword failed', tag: 'auth', error: e, stackTrace: st);
      throw AuthException(
        'Une erreur inattendue est survenue. Veuillez réessayer.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Inscrit l'utilisateur avec métadonnées (nom, ville, pays).
  Future<sb.AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String city,
    required String country,
  }) async {
    try {
      final res = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'city': city,
          'country': country,
        },
      );
      log.info('User signed up: ${res.user?.id}', tag: 'auth');
      return res;
    } on sb.AuthException catch (e, st) {
      throw AuthException(_localizeAuthError(e.message), cause: e, stackTrace: st);
    } catch (e, st) {
      log.error('signUp failed', tag: 'auth', error: e, stackTrace: st);
      throw AuthException(
        'Une erreur inattendue est survenue. Veuillez réessayer.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Vérifie un code OTP (étape de confirmation email).
  Future<sb.Session> verifyOtp({required String email, required String token}) async {
    try {
      final res = await _auth.verifyOTP(
        email: email,
        token: token,
        type: sb.OtpType.signup,
      );
      if (res.session == null) {
        throw const AuthException('Code de confirmation invalide ou expiré.');
      }
      return res.session!;
    } on sb.AuthException catch (e, st) {
      throw AuthException(_localizeAuthError(e.message), cause: e, stackTrace: st);
    } catch (e, st) {
      log.error('verifyOtp failed', tag: 'auth', error: e, stackTrace: st);
      throw AuthException(
        'Code invalide ou expiré. Veuillez réessayer.',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Déconnecte l'utilisateur. Idempotent.
  Future<void> signOut() async {
    try {
      // Supprime le token FCM avant de déconnecter l'utilisateur.
      await NotificationService.instance.removeToken();
      await _auth.signOut();
      log.info('User signed out', tag: 'auth');
    } catch (e, st) {
      log.warn('signOut failed (ignoring)', tag: 'auth', error: e, stackTrace: st);
      // On ne relance pas : le logout est best-effort.
    }
  }

  /// Force le rafraîchissement du token d'accès.
  Future<sb.Session?> refreshSession() async {
    try {
      final res = await _auth.refreshSession();
      return res.session;
    } catch (e, st) {
      log.error('refreshSession failed', tag: 'auth', error: e, stackTrace: st);
      return null;
    }
  }

  /// Helper typé pour lire les métadonnées utilisateur.
  T? getUserMetadata<T>(String key) {
    final meta = currentUser?.userMetadata;
    if (meta == null) return null;
    final raw = meta[key];
    return raw is T ? raw : null;
  }

  // ── Helpers privés ──────────────────────────────────────────────────

  /// Traduit les messages d'erreur bruts de Supabase en français.
  String _localizeAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Identifiants de connexion invalides. Vérifiez votre email et mot de passe.';
    }
    if (lower.contains('email already registered') || lower.contains('user already exists')) {
      return 'Cet email est déjà enregistré. Connectez-vous à la place.';
    }
    if (lower.contains('password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (lower.contains('network') || lower.contains('connection failed')) {
      return 'Erreur réseau. Vérifiez votre connexion internet.';
    }
    if (lower.contains('token') && (lower.contains('expired') || lower.contains('invalid'))) {
      return 'Code de confirmation invalide ou expiré.';
    }
    if (lower.contains('rate limit')) {
      return 'Trop de tentatives. Veuillez patienter quelques minutes.';
    }
    if (lower.contains('error sending confirmation') ||
        lower.contains('failed to send confirmation')) {
      return 'Erreur lors de l\'envoi de l\'email de confirmation. '
          'Vérifiez la configuration SMTP dans votre dashboard Supabase '
          'ou réessayez dans quelques instants.';
    }
    return message;
  }
}

/// Helper top-level pour éviter `AuthService.instance` partout.
final auth = AuthService.instance;
