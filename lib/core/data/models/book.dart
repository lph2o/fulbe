/// Modèle de livre (bibliothèque culturelle).
///
/// Source de vérité : table Supabase `books`.
library;

import 'package:flutter/material.dart';

import '../parsers.dart';

/// Livre ou document de la bibliothèque culturelle.
@immutable
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.emoji,
    required this.color,
    required this.categoryIndex,
  });

  final String id;
  final String title;
  final String author;
  final String emoji;
  final Color color;
  final int categoryIndex;

  factory Book.fromJson(Map<String, dynamic> json) {
    final color = Parsers.colorFromHex(json, 'color_hex');

    return Book(
      id: Parsers.string(json, 'id'),
      title: Parsers.string(json, 'title'),
      author: Parsers.string(json, 'author'),
      emoji: Parsers.string(json, 'emoji'),
      color: color ?? const Color(0xFF1B4332),
      categoryIndex: Parsers.integer(json, 'category_index',
          fallback: Parsers.integer(json, 'categoryIndex')),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'emoji': emoji,
        'color_hex': '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
        'category_index': categoryIndex,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Book &&
          other.id == id &&
          other.title == title &&
          other.author == author &&
          other.emoji == emoji &&
          other.color == color &&
          other.categoryIndex == categoryIndex;

  @override
  int get hashCode => Object.hash(id, title, author, emoji, color, categoryIndex);
}
