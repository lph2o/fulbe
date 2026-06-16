import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/book.dart';
import '../models/chapter.dart';
import '../models/community_project.dart';
import '../models/event.dart';
import '../models/finances_summary.dart';
import '../models/job.dart';
import '../models/member.dart';
import '../models/organization.dart';
import '../models/conversation.dart' show Conversation, ChatMessage;
import '../models/post.dart' show Post, Announcement, PostComment;
import '../models/service.dart';
import '../models/call_entry.dart';
import '../models/transaction.dart';
import '../models/community.dart';
import '../models/community_post.dart';
import '../repositories/call_history_repository.dart';
import '../repositories/conversations_repository.dart';
import '../repositories/events_repository.dart';
import '../repositories/finances_repository.dart';
import '../repositories/jobs_repository.dart';
import '../repositories/library_repository.dart';
import '../repositories/marketplace_repository.dart';
import '../repositories/members_repository.dart';
import '../repositories/organizations_repository.dart';
import '../repositories/posts_repository.dart';
import '../repositories/communities_repository.dart';
import '../../errors/app_exception.dart';

// ── Repositories ──────────────────────────────────────────────────────────

final eventsRepositoryProvider =
    Provider<EventsRepository>((ref) => const EventsRepository());

final jobsRepositoryProvider =
    Provider<JobsRepository>((ref) => const JobsRepository());

final marketplaceRepositoryProvider =
    Provider<MarketplaceRepository>((ref) => const MarketplaceRepository());

final libraryRepositoryProvider =
    Provider<LibraryRepository>((ref) => const LibraryRepository());

final postsRepositoryProvider =
    Provider<PostsRepository>((ref) => const PostsRepository());

final financesRepositoryProvider =
    Provider<FinancesRepository>((ref) => const FinancesRepository());

final membersRepositoryProvider =
    Provider<MembersRepository>((ref) => const MembersRepository());

final organizationsRepositoryProvider =
    Provider<OrganizationsRepository>((ref) => const OrganizationsRepository());

// ── Data ───────────────────────────────────────────────────────────────────

/// Liste de tous les événements (triés par date croissante), avec le statut
/// RSVP de l'utilisateur courant hydraté depuis `event_rsvps`.
final eventsProvider = FutureProvider<List<Event>>((ref) async {
  final repo = ref.watch(eventsRepositoryProvider);
  // Lance les deux requêtes en parallèle pour réduire la latence au toggle RSVP.
  final results = await Future.wait([
    repo.fetchAll(),
    repo.fetchUserRsvpIds(),
  ]);
  final events = results[0] as List<Event>;
  final rsvpIds = results[1] as Set<String>;
  return events.map((e) => e.copyWith(isRsvped: rsvpIds.contains(e.id))).toList();
});

/// Liste de toutes les offres d'emploi (récentes d'abord).
final jobsProvider = FutureProvider<List<Job>>((ref) async {
  return ref.watch(jobsRepositoryProvider).fetchAll();
});

/// Liste de tous les services marketplace (mieux notés d'abord).
final servicesProvider = FutureProvider<List<MarketService>>((ref) async {
  return ref.watch(marketplaceRepositoryProvider).fetchAll();
});

/// Liste de tous les livres de la bibliothèque.
final booksProvider = FutureProvider<List<Book>>((ref) async {
  return ref.watch(libraryRepositoryProvider).fetchAll();
});

/// Posts du fil d'actualité (récent → ancien), avec les statuts like,
/// bookmark et repost de l'utilisateur courant hydratés.
final postsProvider = FutureProvider<List<Post>>((ref) async {
  final repo = ref.watch(postsRepositoryProvider);
  final results = await Future.wait([
    repo.fetchPosts(),
    repo.fetchUserLikedPostIds(),
    repo.fetchUserBookmarkedPostIds(),
    repo.fetchUserRepostedPostIds(),
  ]);
  final posts = results[0] as List<Post>;
  final likedIds = results[1] as Set<String>;
  final bookmarkedIds = results[2] as Set<String>;
  final repostedIds = results[3] as Set<String>;

  // Hydrate isLiked + isBookmarked + isReposted + firstLikerName
  final postIds = posts.map((p) => p.id).toList();
  final firstLikerNames = await repo.fetchFirstLikerNames(postIds);

  // Charge les posts originaux pour les reposts (embed visuel)
  final repostOfIds = posts
      .where((p) => p.repostOf != null)
      .map((p) => p.repostOf!)
      .toSet()
      .toList();
  final Map<String, Post> repostOriginals = {};
  for (final originalId in repostOfIds) {
    final original = await repo.fetchRepostOriginal(originalId);
    if (original != null) {
      repostOriginals[originalId] = original;
    }
  }

  return posts
      .map((p) => p.copyWith(
            isLiked: likedIds.contains(p.id),
            isBookmarked: bookmarkedIds.contains(p.id),
            isReposted: repostedIds.contains(p.id),
            firstLikerName: firstLikerNames[p.id],
            repostOriginal: p.repostOf != null
                ? repostOriginals[p.repostOf]
                : null,
          ))
      .toList(growable: false);
});

/// Annonces communautaires (les plus récentes d'abord).
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  return ref.watch(postsRepositoryProvider).fetchAnnouncements();
});

/// Commentaires d'un post, du plus ancien au plus récent,
/// avec le statut like de l'utilisateur courant hydraté depuis `comment_likes`.
final commentsProvider =
    FutureProvider.family<List<PostComment>, String>((ref, postId) async {
  final repo = ref.watch(postsRepositoryProvider);
  final results = await Future.wait([
    repo.fetchComments(postId),
    repo.fetchUserLikedCommentIds(),
  ]);
  final comments = results[0] as List<PostComment>;
  final likedIds = results[1] as Set<String>;
  return comments
      .map((c) => c.copyWith(isLiked: likedIds.contains(c.id)))
      .toList(growable: false);
});

/// Aperçu des 2 commentaires les plus récents d'un post, avec le vrai
/// nombre total (COUNT exact depuis `post_comments`).
final commentsPreviewProvider =
    FutureProvider.autoDispose
        .family<({List<PostComment> comments, int totalCount}), String>(
            (ref, postId) async {
  final repo = ref.watch(postsRepositoryProvider);
  final comments = await repo.fetchCommentsPreview(postId);
  final totalCount = await repo.fetchCommentsCount(postId);
  return (comments: comments, totalCount: totalCount);
});

/// Historique de transactions de l'utilisateur connecté.
final transactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.watch(financesRepositoryProvider)
      .fetchSummary()
      .then((s) => s.transactions);
});

/// Agrégat complet "Mes Finances" (transactions + solde + prochain dû + chart).
final financesSummaryProvider = FutureProvider<FinancesSummary>((ref) async {
  return ref.watch(financesRepositoryProvider).fetchSummary();
});

/// Liste des projets communautaires actifs (collecte de fonds).
final projectsProvider = FutureProvider<List<CommunityProject>>((ref) async {
  return ref.watch(financesRepositoryProvider).fetchProjects();
});

/// Liste de tous les membres (annuaire).
final membersProvider = FutureProvider<List<Member>>((ref) async {
  return ref.watch(membersRepositoryProvider).fetchAll();
});

/// Nombre total de membres sur la plateforme.
///
/// Requête COUNT légère, sans charger les profils complets.
/// Retourne 0 en cas d'erreur (le header affiche un fallback).
final totalMemberCountProvider = FutureProvider<int>((ref) async {
  return ref.watch(membersRepositoryProvider).fetchTotalCount();
});

/// Clusters géographiques pour la World Map.
final memberClustersProvider = FutureProvider<List<MemberCluster>>((ref) async {
  return ref.watch(membersRepositoryProvider).fetchClusters();
});

/// Membre correspondant à l'utilisateur Supabase courant.
///
/// Retourne `null` si non authentifié ou si la ligne n'a pas encore été créée
/// (email non confirmé, race condition post-inscription).
final currentMemberProvider = FutureProvider<Member?>((ref) async {
  return ref.watch(membersRepositoryProvider).fetchCurrent();
});

/// Stats de l'utilisateur courant : nombre d'abonnés et d'abonnements.
///
/// Dépend de [currentMemberProvider] pour récupérer l'ID du membre.
/// Retourne (followerCount, followingCount) — les deux à 0 si non connecté
/// ou si la requête échoue (table manquante, erreur réseau, etc.).
final currentMemberStatsProvider =
    FutureProvider<({int followerCount, int followingCount})>((ref) async {
  final member = await ref.watch(currentMemberProvider.future);
  if (member == null) {
    return (followerCount: 0, followingCount: 0);
  }
  final repo = ref.watch(membersRepositoryProvider);
  // On exécute chaque requête indépendamment pour qu'une panne sur l'une
  // (ex. table member_follows pas encore migrée) n'empêche pas l'autre.
  final followerCount = await repo
      .fetchFollowerCount(member.id)
      .catchError((_) => 0);
  final followingCount = await repo
      .fetchFollowingCount(member.id)
      .catchError((_) => 0);
  return (
    followerCount: followerCount,
    followingCount: followingCount,
  );
});

/// Stats d'un membre par ID : nombre d'abonnés et d'abonnements.
///
/// Retourne 0 pour tout compteur dont la requête échoue, plutôt que de
/// faire planter le provider complet.
final memberStatsProvider =
    FutureProvider.family<({int followerCount, int followingCount}), String>(
        (ref, memberId) async {
  final repo = ref.watch(membersRepositoryProvider);
  final followerCount = await repo
      .fetchFollowerCount(memberId)
      .catchError((_) => 0);
  final followingCount = await repo
      .fetchFollowingCount(memberId)
      .catchError((_) => 0);
  return (
    followerCount: followerCount,
    followingCount: followingCount,
  );
});

/// Indique si l'utilisateur courant suit déjà un membre.
final isFollowingProvider =
    FutureProvider.family<bool, String>((ref, memberId) async {
  return ref.watch(membersRepositoryProvider).fetchIsFollowing(memberId);
});

/// Récupère un membre par son ID.
final memberProvider =
    FutureProvider.family<Member?, String>((ref, id) async {
  return ref.watch(membersRepositoryProvider).fetchById(id);
});

/// Posts d'un membre spécifique (profil), triés du plus récent au plus ancien.
final userPostsProvider =
    FutureProvider.family<List<Post>, String>((ref, memberId) async {
  return ref.watch(postsRepositoryProvider).fetchPostsByMember(memberId);
});

/// Services marketplace proposés par un membre spécifique.
///
/// Utilise `provider_id` sur la table `marketplace_services`.
/// Retourne une liste vide si le membre n'a pas de services ou si
/// la requête échoue.
final memberServicesProvider =
    FutureProvider.family<List<MarketService>, String>((ref, memberId) async {
  final services = await ref
      .watch(marketplaceRepositoryProvider)
      .fetchByProviderId(memberId);
  return services;
});

// ── Réseau d'Associations (organizations + chapters) ────────────────────

/// Liste de toutes les associations actives (triées par pays, nom).
final organizationsProvider = FutureProvider<List<Organization>>((ref) async {
  return ref.watch(organizationsRepositoryProvider).fetchOrganizations();
});

/// Liste de toutes les branches actives (avec nom de l'organisation parente
/// hydraté via embed `organization(*)`).
final chaptersProvider = FutureProvider<List<Chapter>>((ref) async {
  return ref.watch(organizationsRepositoryProvider).fetchChapters();
});

/// Chapitre correspondant au couple (pays, ville) — `null` si aucun match.
///
/// Utilisable en prévisualisation avant inscription, ou pour suggérer une
/// branche à un utilisateur qui change de localisation.
final chapterByCityProvider =
    FutureProvider.family<Chapter?, ({String country, String city})>(
        (ref, key) async {
  return ref
      .watch(organizationsRepositoryProvider)
      .fetchChapterByCity(country: key.country, city: key.city);
});

/// Chapitre correspondant à l'utilisateur Supabase courant.
///
/// Dépend de [currentMemberProvider] : si le member n'a pas de `chapter_id`
/// (pas de match `country+city`), renvoie `null`.
final currentChapterProvider = FutureProvider<Chapter?>((ref) async {
  return ref.watch(organizationsRepositoryProvider).fetchCurrentChapter();
});

/// Chapitre correspondant à un membre par son ID.
///
/// Utilisé pour les profils publics. Renvoie `null` si le membre n'a pas
/// de chapitre associé.
final memberChapterProvider =
    FutureProvider.family<Chapter?, String>((ref, memberId) async {
  return ref
      .watch(organizationsRepositoryProvider)
      .fetchChapterByMemberId(memberId);
});

// ── Chapter Detail ─────────────────────────────────────────────────────

/// Membres appartenant à un chapitre.
final chapterMembersProvider =
    FutureProvider.family<List<Member>, String>((ref, chapterId) async {
  return ref.watch(membersRepositoryProvider).fetchByChapter(chapterId);
});

/// Posts des membres d'un chapitre.
final chapterPostsProvider =
    FutureProvider.family<List<Post>, String>((ref, chapterId) async {
  return ref.watch(postsRepositoryProvider).fetchPostsByChapter(chapterId);
});

/// Événements créés par les membres d'un chapitre.
final chapterEventsProvider =
    FutureProvider.family<List<Event>, String>((ref, chapterId) async {
  return ref.watch(eventsRepositoryProvider).fetchByChapter(chapterId);
});

// ── Bookmarks ────────────────────────────────────────────────────────────

/// Posts mis en favoris par l'utilisateur courant (pour l'écran dédié).
final bookmarkedPostsProvider = FutureProvider<List<Post>>((ref) async {
  return ref.watch(postsRepositoryProvider).fetchBookmarkedPosts();
});

// ── Followers / Following ──────────────────────────────────────────────

/// Abonnés (followers) d'un membre.
final memberFollowersProvider =
    FutureProvider.family<List<Member>, String>((ref, memberId) async {
  return ref.watch(membersRepositoryProvider).fetchFollowers(memberId);
});

/// Abonnements (following) d'un membre.
final memberFollowingProvider =
    FutureProvider.family<List<Member>, String>((ref, memberId) async {
  return ref.watch(membersRepositoryProvider).fetchFollowing(memberId);
});

// ── Messagerie (conversations) ────────────────────────────────────────────

final callHistoryRepositoryProvider =
    Provider<CallHistoryRepository>((ref) => const CallHistoryRepository());

final communitiesRepositoryProvider =
    Provider<CommunitiesRepository>((ref) => const CommunitiesRepository());

final conversationsRepositoryProvider =
    Provider<ConversationsRepository>((ref) => const ConversationsRepository());

/// Liste des conversations de l'utilisateur connecté (directes + groupes),
/// triées par dernier message.
final conversationsProvider = FutureProvider<List<Conversation>>((ref) async {
  return ref.watch(conversationsRepositoryProvider).fetchAll();
});

/// Historique des appels (1-to-1) du membre courant, trié du plus récent
/// au plus ancien. Retourne une liste vide si non authentifié.
final callHistoryProvider = FutureProvider<List<CallEntry>>((ref) async {
  final member = await ref.watch(currentMemberProvider.future);
  if (member == null) {
    print('[callHistoryProvider] Aucun membre trouvé (non connecté).');
    return [];
  }
  try {
    return await ref
        .watch(callHistoryRepositoryProvider)
        .fetchCallHistory(member.id);
  } catch (e, st) {
    final cause = e is AppException ? e.cause : null;
    print('[callHistoryProvider] Erreur chargement historique: $e');
    if (cause != null) {
      print('[callHistoryProvider] Cause: $cause\nType: ${cause.runtimeType}');
    }
    rethrow;
  }
});

// ── Communautés / Groupes ────────────────────────────────────────────

/// Liste de toutes les communautés.
final communitiesProvider = FutureProvider<List<Community>>((ref) async {
  final member = await ref.watch(currentMemberProvider.future);
  if (member == null) {
    return ref.watch(communitiesRepositoryProvider).fetchAll();
  }

  final repo = ref.watch(communitiesRepositoryProvider);
  final results = await Future.wait([
    repo.fetchAll(),
    repo.fetchJoinedIds(member.id),
    repo.fetchAdminIds(member.id),
  ]);

  final communities = results[0] as List<Community>;
  final joinedIds = results[1] as Set<String>;
  final adminIds = results[2] as Set<String>;

  return communities
      .map((c) => c.copyWith(
            isMember: joinedIds.contains(c.id),
            isAdmin: adminIds.contains(c.id),
          ))
      .toList(growable: false);
});

/// Détail d'une communauté.
final communityProvider =
    FutureProvider.family<Community?, String>((ref, id) async {
  final repo = ref.watch(communitiesRepositoryProvider);
  final member = await ref.watch(currentMemberProvider.future);

  final community = await repo.fetchById(id);
  if (member == null) return community;

  final results = await Future.wait([
    repo.checkMembership(id, member.id),
    repo.checkAdmin(id, member.id),
  ]);

  return community.copyWith(
    isMember: results[0] as bool,
    isAdmin: results[1] as bool,
  );
});

/// Code d'invitation d'une communauté.
///
/// Retourne `null` si aucun code n'a encore été généré.
/// Nécessite d'être admin/modérateur pour voir le code (RLS côté serveur).
final communityInviteCodeProvider =
    FutureProvider.family<String?, String>((ref, communityId) async {
  return ref.watch(communitiesRepositoryProvider).getInviteCode(communityId);
});

/// Posts d'une communauté.
final communityPostsProvider =
    FutureProvider.family<List<CommunityPost>, String>((ref, communityId) async {
  final member = await ref.watch(currentMemberProvider.future);
  return ref
      .watch(communitiesRepositoryProvider)
      .fetchPosts(communityId, currentMemberId: member?.id);
});

/// Map : community_id → nombre de messages non lus.
///
/// Cross-référence entre [communitiesProvider] (pour récupérer
/// conversation_id de chaque communauté) et [conversationsProvider]
/// (pour le compteur `unread` de chaque conversation).
final communityUnreadCountsProvider = Provider<Map<String, int>>((ref) {
  final communities = ref.watch(communitiesProvider).asData?.value ?? [];
  final conversations = ref.watch(conversationsProvider).asData?.value ?? [];

  // Map : conversation_id → unread
  final unreadByConv = <String, int>{};
  for (final conv in conversations) {
    if (conv.unread > 0) {
      unreadByConv[conv.id] = conv.unread;
    }
  }

  // Map : community_id → unread (via conversation_id)
  final result = <String, int>{};
  for (final community in communities) {
    final convId = community.conversationId;
    if (convId != null && unreadByConv.containsKey(convId)) {
      result[community.id] = unreadByConv[convId]!;
    }
  }

  return result;
});

/// Messages d'une conversation, du plus ancien au plus récent,
/// avec le flag isMine hydraté pour l'utilisateur courant.
final messagesProvider =
    FutureProvider.family<List<ChatMessage>, String>((ref, conversationId) async {
  final repo = ref.watch(conversationsRepositoryProvider);
  final messages = await repo.fetchMessages(conversationId);

  // Récupère le member_id de l'utilisateur courant pour marquer isMine.
  final currentMember = await ref.watch(currentMemberProvider.future);
  if (currentMember == null) return messages;

  return messages
      .map((m) => m.copyWith(isMine: m.senderId == currentMember.id))
      .toList(growable: false);
});
