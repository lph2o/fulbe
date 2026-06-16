import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/data/providers/data_providers.dart';
import '../../core/errors/app_exception.dart';
import '../../core/theme/app_colors.dart';
import '../../features/messages/conversation_detail_screen.dart';

/// Helper partagé pour la mise en contact avec un membre.
///
/// Centralise la logique dupliquée (6 copies) de
/// `findOrCreateDirectConversation` + navigation + SnackBar.
class ContactHelper {
  /// Ouvre une conversation directe avec le membre identifié par [memberId].
  ///
  /// Vérifie que l'utilisateur courant est connecté, crée ou retrouve la
  /// conversation, navigue vers [ConversationDetailScreen], et affiche un
  /// SnackBar de confirmation.
  static Future<void> navigateToConversation(
    BuildContext context,
    WidgetRef ref,
    String memberId,
  ) async {
    try {
      final currentMember = await ref.read(currentMemberProvider.future);
      if (currentMember == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vous devez être connecté.')),
          );
        }
        return;
      }

      final repo = ref.read(conversationsRepositoryProvider);
      final conversation =
          await repo.findOrCreateDirectConversation(memberId);

      if (context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ConversationDetailScreen(
              conversationId: conversation.id,
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation ouverte avec ${conversation.name}'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.primaryContainer,
          ),
        );
      }
    } on AppException catch (e) {
      if (context.mounted) {
        // Inclut la cause réelle (ex: erreur Supabase) pour le debug
        final detail = e.cause != null ? ' (${e.cause})' : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.message}$detail'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise en contact : $e'),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
