
import 'package:flutter_test/flutter_test.dart';
import 'package:fulbe/core/data/parsers.dart';

void main() {
  group('Parsers.string', () {
    test('renvoie la valeur quand présente', () {
      expect(
        Parsers.string({'name': 'Aaliyah'}, 'name'),
        equals('Aaliyah'),
      );
    });

    test('coerce les non-Strings via toString()', () {
      expect(Parsers.string({'x': 42}, 'x'), equals('42'));
    });

    test('renvoie le fallback si null', () {
      expect(Parsers.string({}, 'missing', fallback: 'defaut'),
          equals('defaut'));
    });
  });

  group('Parsers.nullableString', () {
    test('renvoie null quand absent', () {
      expect(Parsers.nullableString({}, 'x'), isNull);
    });

    test('renvoie null quand chaîne vide', () {
      expect(Parsers.nullableString({'x': ''}, 'x'), isNull);
    });

    test('renvoie la chaîne quand non vide', () {
      expect(Parsers.nullableString({'x': 'hello'}, 'x'), equals('hello'));
    });
  });

  group('Parsers.integer', () {
    test('accepte int natif', () {
      expect(Parsers.integer({'n': 5}, 'n'), equals(5));
    });

    test('convertit double en int', () {
      expect(Parsers.integer({'n': 5.7}, 'n'), equals(5));
    });

    test('parse une chaîne numérique', () {
      expect(Parsers.integer({'n': '42'}, 'n'), equals(42));
    });

    test('renvoie le fallback pour entrée invalide', () {
      expect(Parsers.integer({'n': 'abc'}, 'n', fallback: 99), equals(99));
    });
  });

  group('Parsers.doubleValue', () {
    test('accepte double natif', () {
      expect(Parsers.doubleValue({'d': 4.9}, 'd'), equals(4.9));
    });

    test('convertit int en double', () {
      expect(Parsers.doubleValue({'d': 5}, 'd'), equals(5.0));
    });

    test('parse une chaîne', () {
      expect(Parsers.doubleValue({'d': '3.14'}, 'd'), equals(3.14));
    });
  });

  group('Parsers.boolean', () {
    test('bool natif', () {
      expect(Parsers.boolean({'b': true}, 'b'), isTrue);
      expect(Parsers.boolean({'b': false}, 'b'), isFalse);
    });

    test('alias "1" / "0"', () {
      expect(Parsers.boolean({'b': '1'}, 'b'), isTrue);
      expect(Parsers.boolean({'b': '0'}, 'b'), isFalse);
    });

    test('num != 0 → true', () {
      expect(Parsers.boolean({'b': 7}, 'b'), isTrue);
      expect(Parsers.boolean({'b': 0}, 'b'), isFalse);
    });
  });

  group('Parsers.dateTime', () {
    test('parse ISO string', () {
      final result = Parsers.dateTime({'d': '2026-06-15T10:00:00Z'}, 'd');
      expect(result.year, equals(2026));
      expect(result.month, equals(6));
    });

    test('renvoie fallback (ou now) si null', () {
      final fallback = DateTime(2020, 1, 1);
      expect(Parsers.dateTime({}, 'd', fallback: fallback), equals(fallback));
    });
  });

  group('Parsers.stringList', () {
    test('extrait une liste de strings', () {
      expect(
        Parsers.stringList({'s': ['a', 'b', 'c']}, 's'),
        equals(['a', 'b', 'c']),
      );
    });

    test('coerce les éléments non-string', () {
      expect(Parsers.stringList({'s': [1, 2]}, 's'), equals(['1', '2']));
    });

    test('renvoie liste vide si clé absente', () {
      expect(Parsers.stringList({}, 's'), isEmpty);
    });
  });

  group('Parsers.colorFromHex', () {
    test('parse #RRGGBB', () {
      final c = Parsers.colorFromHex({'k': '#FF0000'}, 'k');
      expect(c, isNotNull);
      expect((c!.r * 255).round(), equals(255));
      expect((c.g * 255).round(), equals(0));
      expect((c.b * 255).round(), equals(0));
    });

    test('parse RRGGBB sans #', () {
      final c = Parsers.colorFromHex({'k': '00FF00'}, 'k');
      expect(c, isNotNull);
      expect((c!.g * 255).round(), equals(255));
    });

    test('parse AARRGGBB', () {
      final c = Parsers.colorFromHex({'k': 'FF0000FF'}, 'k');
      expect(c, isNotNull);
      expect((c!.b * 255).round(), equals(255));
    });

    test('renvoie null pour entrée invalide', () {
      expect(Parsers.colorFromHex({'k': 'not-a-color'}, 'k'), isNull);
      expect(Parsers.colorFromHex({}, 'k'), isNull);
    });
  });
}
