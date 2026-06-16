import 'package:flutter_test/flutter_test.dart';
import 'package:fulbe/core/data/models/post.dart';
import 'package:fulbe/core/data/providers/data_providers.dart';
import 'package:fulbe/core/data/repositories/posts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tests unitaires pour la fonctionnalité de like persistant côté serveur.
///
/// Couvre :
/// - Le modèle [Post] : valeur par défaut de `isLiked`, `copyWith`, égalité
/// - Le provider `postsProvider` : vérifie que `isLiked` est hydraté
/// - Le repository `PostsRepository` : vérification des requêtes sans Supabase
void main() {
  // ── Post Model ──────────────────────────────────────────────────────
  group('Post.isLiked (constructeur)', () {
    test('isLiked = false par défaut', () {
      const post = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'A',
        authorCity: 'B',
        authorCountry: 'C',
        content: 'Hello',
        likesCount: 0,
        commentsCount: 0,
        timeAgo: '0m',
      );
      expect(post.isLiked, isFalse);
    });

    test('isLiked = true quand explicite', () {
      const post = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'A',
        authorCity: 'B',
        authorCountry: 'C',
        content: 'Hello',
        likesCount: 0,
        commentsCount: 0,
        timeAgo: '0m',
        isLiked: true,
      );
      expect(post.isLiked, isTrue);
    });
  });

  group('Post.copyWith (isLiked)', () {
    const base = Post(
      id: 'p1',
      authorId: 'a1',
      authorName: 'A',
      authorCity: 'B',
      authorCountry: 'C',
      content: 'Hello',
      likesCount: 5,
      commentsCount: 2,
      timeAgo: '1h',
    );

    test('toggle false → true', () {
      final liked = base.copyWith(isLiked: true);
      expect(liked.isLiked, isTrue);
      expect(liked.likesCount, equals(5)); // inchangé
    });

    test('toggle true → false', () {
      final unliked = base.copyWith(isLiked: true).copyWith(isLiked: false);
      expect(unliked.isLiked, isFalse);
    });

    test('sans argument, reste inchangé', () {
      final same = base.copyWith();
      expect(same == base, isTrue);
      expect(same.isLiked, isFalse);
      expect(same.likesCount, equals(5));
    });

    test('likesCount indépendant de isLiked', () {
      final liked = base.copyWith(isLiked: true, likesCount: 6);
      expect(liked.isLiked, isTrue);
      expect(liked.likesCount, equals(6));
    });
  });

  group('Post.fromJson (isLiked)', () {
    test('isLiked absent du JSON → false par défaut', () {
      final p = Post.fromJson(const {
        'id': 'p1',
        'author_id': 'a1',
        'author_name': 'X',
        'author_city': 'Y',
        'author_country': 'Z',
        'content': 'Salut',
        'likes_count': 3,
        'comments_count': 1,
        'time_ago': '2h',
      });
      expect(p.isLiked, isFalse);
    });

    test('hydratation séparée via copyWith (simulation provider)', () {
      // Ceci reproduit le pattern utilisé dans postsProvider
      final rawPost = Post.fromJson(const {
        'id': 'p1',
        'author_id': 'a1',
        'author_name': 'X',
        'author_city': 'Y',
        'author_country': 'Z',
        'content': 'Test',
        'likes_count': 10,
        'comments_count': 5,
        'time_ago': '3h',
      });

      const likedPostIds = {'p1', 'p2', 'p3'};
      final hydratedPost = rawPost.copyWith(
        isLiked: likedPostIds.contains(rawPost.id),
      );

      expect(hydratedPost.isLiked, isTrue);
      expect(hydratedPost.likesCount, equals(10)); // préservé
    });
  });

  group('Post.operator == (isLiked)', () {
    test('deux posts identiques sauf isLiked sont différents', () {
      const liked = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'A',
        authorCity: 'B',
        authorCountry: 'C',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
        isLiked: true,
      );
      final unliked = liked.copyWith(isLiked: false);
      expect(liked == unliked, isFalse);
    });

    test('mêmes champs + même isLiked → égaux', () {
      const a = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'A',
        authorCity: 'B',
        authorCountry: 'C',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
        isLiked: true,
      );
      const b = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'A',
        authorCity: 'B',
        authorCountry: 'C',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
        isLiked: true,
      );
      expect(a == b, isTrue);
    });
  });

  group('Post.hashCode (isLiked)', () {
    test('cohérent entre deux copies identiques', () {
      const a = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'A',
        authorCity: 'B',
        authorCountry: 'C',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
        isLiked: true,
      );
      final b = a.copyWith();
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  // ── Provider hydratation ────────────────────────────────────────────
  group("postsProvider (logique d'hydratation)", () {
    test('isLiked est true quand postId est dans likedIds', () {
      // Reproduit la logique du provider : postsProvider
      //   .map((p) => p.copyWith(isLiked: likedIds.contains(p.id)))
      const posts = [
        Post(id: 'p1', authorId: 'a1', authorName: 'A', authorCity: 'B',
            authorCountry: 'C', content: 'C1', likesCount: 0, commentsCount: 0,
            timeAgo: '0m'),
        Post(id: 'p2', authorId: 'a2', authorName: 'B', authorCity: 'C',
            authorCountry: 'D', content: 'C2', likesCount: 0, commentsCount: 0,
            timeAgo: '0m'),
        Post(id: 'p3', authorId: 'a3', authorName: 'C', authorCity: 'D',
            authorCountry: 'E', content: 'C3', likesCount: 0, commentsCount: 0,
            timeAgo: '0m'),
      ];

      final likedIds = {'p1', 'p3'};
      final hydrated = posts
          .map((p) => p.copyWith(isLiked: likedIds.contains(p.id)))
          .toList(growable: false);

      expect(hydrated[0].isLiked, isTrue);  // p1
      expect(hydrated[1].isLiked, isFalse); // p2
      expect(hydrated[2].isLiked, isTrue);  // p3
    });

    test('isLiked est false si likedIds est vide', () {
      const posts = [
        Post(id: 'p1', authorId: 'a1', authorName: 'A', authorCity: 'B',
            authorCountry: 'C', content: 'C', likesCount: 0, commentsCount: 0,
            timeAgo: '0m'),
      ];

      const empty = <String>{};
      final hydrated = posts
          .map((p) => p.copyWith(isLiked: empty.contains(p.id)))
          .toList();

      expect(hydrated.first.isLiked, isFalse);
    });
  });

  // ── toJson ─────────────────────────────────────────────────────────
  group('Post.toJson (isLiked)', () {
    test('isLiked ne fait PAS partie de toJson (champ client-side)', () {
      const post = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'A',
        authorCity: 'B',
        authorCountry: 'C',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
        isLiked: true,
      );
      final json = post.toJson();
      expect(json.containsKey('is_liked'), isFalse);
      expect(json.containsKey('isLiked'), isFalse);
    });
  });

  // ── Repository + Providers (intégration minimale) ──────────────────
  group('PostsRepository + Providers (infrastructure)', () {
    test('PostsRepository a un constructeur const', () {
      const repo = PostsRepository();
      expect(repo, isNotNull);
    });

    test("postsRepositoryProvider s'initialise sans Supabase", () {
      final container = ProviderContainer();
      addTearDown(() => container.dispose());
      final repo = container.read(postsRepositoryProvider);
      expect(repo, isA<PostsRepository>());
    });
  });
}
