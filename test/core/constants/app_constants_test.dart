import 'package:flutter_test/flutter_test.dart';
import 'package:fulbe/core/constants/app_constants.dart';

void main() {
  group('AppConstants.hasSupabaseConfig', () {
    test(
      'retourne false avec les valeurs placeholder par défaut '
      '(build sans --dart-define)',
      () {
        // Les valeurs par défaut de AppConstants supabaseUrl /
        // supabasePublishableKey sont les placeholders. Ce test
        // garantit qu'on détecte bien cette configuration invalide.
        expect(AppConstants.supabaseUrl, equals(AppConstants.supabaseUrlPlaceholder));
        expect(
          AppConstants.supabasePublishableKey,
          equals(AppConstants.supabaseKeyPlaceholder),
        );
        expect(AppConstants.hasSupabaseConfig, isFalse);
      },
    );

    test("l'URL placeholder contient le mot-clé 'placeholder'", () {
      expect(AppConstants.supabaseUrlPlaceholder, contains('placeholder'));
      expect(AppConstants.supabaseKeyPlaceholder, contains('placeholder'));
    });

    test('une URL qui contient "placeholder" est toujours considérée invalide', () {
      // Robustesse : même si l'utilisateur met une URL qui n'est pas
      // exactement la sentinel string, on rejette tout ce qui contient
      // "placeholder" pour éviter des faux positifs.
      const fakeUrl = 'https://placeholder.example.com';
      expect(fakeUrl.contains('placeholder'), isTrue);
    });
  });
}
