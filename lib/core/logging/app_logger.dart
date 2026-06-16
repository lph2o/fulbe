/// Logger centralisé pour l'application Fulɓe Connect.
///
/// Wrapper autour de [dart:developer log] qui formate les messages de manière
/// cohérente et peut être désactivé en production.
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Niveaux de log supportés.
enum LogLevel { debug, info, warn, error }

/// Logger singleton.
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  /// Active/désactive les logs (true en debug, false en release par défaut).
  bool enabled = kDebugMode;

  void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  void info(String message, {String? tag}) {
    _log(LogLevel.info, message, tag: tag);
  }

  void warn(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warn, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;
    final fullTag = tag != null ? 'Fulbe.$tag' : 'Fulbe';
    developer.log(
      message,
      name: fullTag,
      level: switch (level) {
        LogLevel.debug => 500,
        LogLevel.info => 800,
        LogLevel.warn => 900,
        LogLevel.error => 1000,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Helper top-level pour ne pas avoir à écrire `AppLogger.instance` partout.
final log = AppLogger.instance;
