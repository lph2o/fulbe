import 'package:flutter_test/flutter_test.dart';
import 'package:fulbe/core/data/result.dart';
import 'package:fulbe/core/errors/app_exception.dart';

void main() {
  group('Result.when', () {
    test('dispatch vers success', () {
      const r = Result<int>.success(42);
      final out = r.when(
        success: (v) => 'ok=$v',
        failure: (_) => 'ko',
      );
      expect(out, equals('ok=42'));
    });

    test('dispatch vers failure', () {
      const r = Result<int>.failure(NetworkException('oops'));
      final out = r.when(
        success: (v) => 'ok=$v',
        failure: (e) => 'ko=${e.message}',
      );
      expect(out, equals('ko=oops'));
    });
  });

  group('Result.map', () {
    test('transforme la valeur en cas de succès', () {
      const r = Result<int>.success(2);
      final mapped = r.map((v) => v * 10);
      expect(mapped.valueOrNull, equals(20));
    });

    test('propage l\'exception en cas d\'échec', () {
      const r = Result<int>.failure(NetworkException('net'));
      final mapped = r.map((v) => v * 10);
      expect(mapped.exceptionOrNull, isA<NetworkException>());
    });
  });

  group('Result helpers', () {
    test('valueOrNull / exceptionOrNull', () {
      const s = Result<String>.success('x');
      expect(s.valueOrNull, equals('x'));
      expect(s.exceptionOrNull, isNull);

      const f = Result<String>.failure(NotFoundException('nope'));
      expect(f.valueOrNull, isNull);
      expect(f.exceptionOrNull, isA<NotFoundException>());
    });
  });

  group('AppException.toString', () {
    test('format runtimeType: message', () {
      const e = AuthException('bad creds');
      expect(e.toString(), equals('AuthException: bad creds'));
    });
  });
}
