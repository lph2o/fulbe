/// Helpers de parsing partagés par tous les modèles.
///
/// Centralise la conversion snake_case ↔ camelCase et la gestion des nullables
/// pour éviter la duplication dans chaque `fromJson`.
library;

import 'package:flutter/material.dart';

/// Helpers de parsing typés.
abstract class Parsers {
  /// Lit une chaîne depuis un JSON (retourne [fallback] si null ou non-String).
  static String string(Map<String, dynamic> json, String key, {String fallback = ''}) {
    final v = json[key];
    if (v == null) return fallback;
    return v.toString();
  }

  /// Lit une chaîne nullable.
  static String? nullableString(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  /// Lit un entier (accepte int, double, String numérique).
  static int integer(Map<String, dynamic> json, String key, {int fallback = 0}) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  /// Lit un double (accepte int, double, String numérique).
  static double doubleValue(Map<String, dynamic> json, String key, {double fallback = 0.0}) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  /// Lit un booléen.
  static bool boolean(Map<String, dynamic> json, String key, {bool fallback = false}) {
    final v = json[key];
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  /// Lit une [DateTime] depuis String ISO, ou [DateTime] déjà parsée.
  static DateTime dateTime(Map<String, dynamic> json, String key,
      {DateTime? fallback}) {
    final v = json[key];
    if (v == null) return fallback ?? DateTime.now();
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? (fallback ?? DateTime.now());
    }
    return fallback ?? DateTime.now();
  }

  /// Lit une [DateTime] nullable.
  static DateTime? nullableDateTime(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  /// Lit une liste de chaînes.
  static List<String> stringList(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is List) {
      return v.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  /// Lit une couleur depuis un hex `#RRGGBB` ou `0xAARRGGBB` ou `RRGGBB`.
  static Color? colorFromHex(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v == null) return null;
    var hex = v.toString().trim();
    if (hex.isEmpty) return null;
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}

/// Helpers de conversion des noms de colonnes (snake_case ↔ camelCase).
abstract class ColumnNames {
  /// Cherche la valeur de [camelKey] d'abord, puis [snakeKey] en fallback.
  ///
  /// Permet de lire des schémas DB avec l'un ou l'autre format.
  static dynamic pick(Map<String, dynamic> json, String camelKey, String snakeKey) {
    if (json.containsKey(camelKey)) return json[camelKey];
    if (json.containsKey(snakeKey)) return json[snakeKey];
    return null;
  }
}
