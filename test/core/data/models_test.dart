import 'package:flutter_test/flutter_test.dart';
import 'package:fulbe/core/data/models/book.dart';
import 'package:fulbe/core/data/models/chapter.dart';
import 'package:fulbe/core/data/models/event.dart';
import 'package:fulbe/core/data/models/job.dart';
import 'package:fulbe/core/data/models/member.dart';
import 'package:fulbe/core/data/models/organization.dart';
import 'package:fulbe/core/data/models/post.dart';
import 'package:fulbe/core/data/models/service.dart';
import 'package:fulbe/core/data/models/transaction.dart';

void main() {
  // ── Event ────────────────────────────────────────────────────────────
  group('Event.fromJson', () {
    test('parse snake_case DB', () {
      final e = Event.fromJson(const {
        'id': 'e1',
        'title': 'Festival',
        'date': '2026-08-05T10:00:00Z',
        'location': 'Podor',
        'category': 'Festival',
        'description': 'desc',
        'image_url': 'https://x/y.jpg',
        'attendee_count': 1250,
      });
      expect(e.id, equals('e1'));
      expect(e.attendeeCount, equals(1250));
      expect(e.imageUrl, equals('https://x/y.jpg'));
      expect(e.date.year, equals(2026));
    });

    test('accepte camelCase en fallback', () {
      final e = Event.fromJson(const {
        'id': 'e2',
        'title': 'Conf',
        'date': '2026-01-01T00:00:00Z',
        'location': 'Paris',
        'category': 'Conf',
        'description': 'd',
        'imageUrl': 'https://x/z.jpg',
        'attendees': 42,
      });
      expect(e.attendeeCount, equals(42));
      expect(e.imageUrl, equals('https://x/z.jpg'));
    });

    test('égalité par valeur (copyWith)', () {
      final base = Event.fromJson(const {
        'id': 'e1',
        'title': 'A',
        'date': '2026-01-01T00:00:00Z',
        'location': 'L',
        'category': 'C',
        'description': 'D',
        'image_url': 'I',
        'attendee_count': 0,
      });
      final copy = base.copyWith(title: 'B');
      expect(copy, isNot(equals(base)));
      expect(copy.title, equals('B'));
      expect(base.title, equals('A'));
    });
  });

  // ── Job ──────────────────────────────────────────────────────────────
  group('Job.fromJson', () {
    test('parse snake_case avec nullables', () {
      final j = Job.fromJson(const {
        'id': 'j1',
        'title': 'Dev',
        'company': 'Acme',
        'company_initials': 'AC',
        'location': 'Dakar',
        'type': 'Full-time',
        'domain': 'Tech',
        'posted_ago': '2j',
        'badge': 'Alumni',
        'badge_type': 'alumni',
      });
      expect(j.companyInitials, equals('AC'));
      expect(j.badge, equals('Alumni'));
    });

    test('tolère les colonnes nullables absentes', () {
      final j = Job.fromJson(const {
        'id': 'j2',
        'title': 'X',
        'company': 'Y',
        'location': 'Z',
        'type': 'Contract',
        'domain': 'Other',
        'posted_ago': '1j',
      });
      expect(j.badge, isNull);
      expect(j.badgeType, isNull);
    });
  });

  // ── Member ───────────────────────────────────────────────────────────
  group('Member.fromJson', () {
    test('parse + isVerified', () {
      final m = Member.fromJson(const {
        'id': 'm1',
        'name': 'Aaliyah',
        'profession': 'UX Designer',
        'city': 'Dakar',
        'country': 'Sénégal',
        'is_verified': true,
        'skills': ['Figma', 'Pulaar'],
      });
      expect(m.isVerified, isTrue);
      expect(m.skills, hasLength(2));
    });

    test('isVerified false par défaut', () {
      final m = Member.fromJson(const {
        'id': 'm1',
        'name': 'X',
        'profession': 'p',
        'city': 'c',
        'country': 'C',
      });
      expect(m.isVerified, isFalse);
    });
  });

  group('MemberCluster.fromJson', () {
    test('parse lat/lng percent', () {
      final c = MemberCluster.fromJson(const {
        'id': 'c1',
        'name': 'Dakar',
        'country': 'Sénégal',
        'count': 142,
        'lat_pct': 0.545,
        'lng_pct': 0.395,
      });
      expect(c.count, equals(142));
      expect(c.latPercent, closeTo(0.545, 1e-6));
    });
  });

  // ── Post + Announcement ─────────────────────────────────────────────
  group('Post.fromJson', () {
    test('parse avec colonnes aplaties', () {
      final p = Post.fromJson(const {
        'id': 'p1',
        'author_id': 'a1',
        'author_name': 'Aaliyah',
        'author_city': 'Dakar',
        'author_country': 'Sénégal',
        'content': 'Hello',
        'likes_count': 12,
        'comments_count': 3,
        'time_ago': '2h',
      });
      expect(p.authorName, equals('Aaliyah'));
      expect(p.likesCount, equals(12));
    });

    test('hydrate via embed author(*)', () {
      final p = Post.fromJson(const {
        'id': 'p1',
        'author_id': 'a1',
        'content': 'Hi',
        'image_url': null,
        'likes_count': 0,
        'comments_count': 0,
        'time_ago': '1h',
        'author': {
          'name': 'Fatou',
          'city': 'Conakry',
          'country': 'Guinée',
          'avatar_url': 'https://x/a.jpg',
        },
      });
      expect(p.authorName, equals('Fatou'));
      expect(p.authorCity, equals('Conakry'));
      expect(p.authorAvatarUrl, equals('https://x/a.jpg'));
    });
  });

  group('Announcement.fromJson', () {
    test('parse snake_case', () {
      final a = Announcement.fromJson(const {
        'id': 'a1',
        'chip_label': 'Événement',
        'chip_icon': 'event',
        'title': 'T',
        'description': 'D',
        'cta_label': 'Voir',
      });
      expect(a.chipLabel, equals('Événement'));
      expect(a.ctaLabel, equals('Voir'));
    });
  });

  // ── Post (isLiked + copyWith) ────────────────────────────────────────
  group('Post.isLiked', () {
    test('isLiked = false par défaut après fromJson', () {
      final p = Post.fromJson(const {
        'id': 'p1',
        'author_id': 'a1',
        'author_name': 'X',
        'author_city': 'Y',
        'author_country': 'Z',
        'content': 'Hello',
        'likes_count': 5,
        'comments_count': 2,
        'time_ago': '1h',
      });
      expect(p.isLiked, isFalse);
    });

    test('copyWith(isLiked: true) active le like', () {
      const base = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'X',
        authorCity: 'Y',
        authorCountry: 'Z',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
      );
      final liked = base.copyWith(isLiked: true);
      expect(liked.isLiked, isTrue);
      // Les autres champs sont inchangés
      expect(liked.likesCount, equals(5));
      expect(liked.content, equals('Hello'));
    });

    test('copyWith(isLiked: false) désactive le like', () {
      const liked = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'X',
        authorCity: 'Y',
        authorCountry: 'Z',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
        isLiked: true,
      );
      final unliked = liked.copyWith(isLiked: false);
      expect(unliked.isLiked, isFalse);
    });

    test('operator == inclut isLiked', () {
      const a = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'X',
        authorCity: 'Y',
        authorCountry: 'Z',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
        isLiked: true,
      );
      const b = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'X',
        authorCity: 'Y',
        authorCountry: 'Z',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
        isLiked: false,
      );
      expect(a == b, isFalse);
      expect(a.copyWith(isLiked: false) == b, isTrue);
    });

    test('hashCode cohérent avec operator ==', () {
      const a = Post(
        id: 'p1',
        authorId: 'a1',
        authorName: 'X',
        authorCity: 'Y',
        authorCountry: 'Z',
        content: 'Hello',
        likesCount: 5,
        commentsCount: 2,
        timeAgo: '1h',
        isLiked: true,
      );
      final b = a.copyWith();
      expect(a.hashCode, equals(b.hashCode));
      expect(a.hashCode, isNot(equals(a.copyWith(isLiked: false).hashCode)));
    });
  });

  // ── MarketService ───────────────────────────────────────────────────
  group('MarketService.fromJson', () {
    test('parse rating double + snake_case', () {
      final s = MarketService.fromJson(const {
        'id': 's1',
        'category': 'Traduction',
        'category_icon': 'translate',
        'title': 'T',
        'description': 'D',
        'rating': 4.9,
        'review_count': 124,
        'price': '35k',
        'price_label': 'À partir de',
        'cta_label': 'Réserver',
        'image_url': 'https://x/i.jpg',
      });
      expect(s.rating, closeTo(4.9, 1e-6));
      expect(s.reviewCount, equals(124));
    });
  });

  // ── Transaction ─────────────────────────────────────────────────────
  group('Transaction.fromJson', () {
    test('amount négatif = débit', () {
      final t = Transaction.fromJson(const {
        'id': 't1',
        'label': 'Don',
        'date': '10 Sept 2024',
        'method': 'Carte',
        'amount': -25.0,
        'icon': 'water_drop',
      });
      expect(t.amount, equals(-25.0));
      expect(t.icon, equals('water_drop'));
    });
  });

  // ── Book ────────────────────────────────────────────────────────────
  group('Book.fromJson', () {
    test('parse color hex', () {
      final b = Book.fromJson(const {
        'id': 'b1',
        'title': 'Tierno Bokar',
        'author': 'Amadou Hampâté Bâ',
        'emoji': '📖',
        'color_hex': '#1B4332',
        'category_index': 1,
      });
      expect(b.title, equals('Tierno Bokar'));
      expect(b.categoryIndex, equals(1));
      // La couleur est parsée : on vérifie qu'elle n'est pas le fallback.
      expect(b.color.toARGB32(), isNot(equals(0)));
    });
  });

  // ── Organization + Chapter ──────────────────────────────────────────
  group('Organization.fromJson', () {
    test('isActive par défaut', () {
      final o = Organization.fromJson(const {
        'id': 'o1',
        'name': 'CFF',
        'country': 'France',
        'created_at': '2026-01-01T00:00:00Z',
      });
      expect(o.isActive, isTrue);
      expect(o.country, equals('France'));
    });
  });

  group('Chapter.fromJson', () {
    test('hydrate via embed organization(*)', () {
      final c = Chapter.fromJson(const {
        'id': 'c1',
        'organization_id': 'o1',
        'name': 'CFF Île-de-France',
        'city': 'Paris',
        'status': 'active',
        'created_at': '2026-01-01T00:00:00Z',
        'organization': {'name': 'CFF', 'country': 'France'},
      });
      expect(c.organizationName, equals('CFF'));
      expect(c.organizationCountry, equals('France'));
    });
  });
}
