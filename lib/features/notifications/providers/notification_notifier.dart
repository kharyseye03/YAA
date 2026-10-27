import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/messages_erreur.dart';
import '../../../model/notification/notification_model.dart';
import '../../../service/api/api_service.dart';
import '../../auth/providers/auth_notifier.dart';

class NotificationState {
  const NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.nonLues = 0,
    this.error,
  });

  final bool isLoading;
  final List<NotificationModel> notifications;

  /// Compteur de la pastille. Tenu à jour localement après chaque
  /// lecture, pour que la pastille réagisse au doigt sans attendre un
  /// aller-retour serveur.
  final int nonLues;

  final String? error;

  NotificationState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? nonLues,
    String? error,
    bool clearError = false,
  }) =>
      NotificationState(
        isLoading     : isLoading ?? this.isLoading,
        notifications : notifications ?? this.notifications,
        nonLues       : nonLues ?? this.nonLues,
        error         : clearError ? null : (error ?? this.error),
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(const NotificationState());

  /// Repart de zéro. Appelé à la déconnexion : l'historique appartient
  /// à une personne, pas à l'appareil.
  void vider() => state = const NotificationState();

  Future<void> charger({bool silencieux = false}) async {
    if (!silencieux) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final liste = await ApiService().getNotifications();
      state = state.copyWith(
        isLoading     : false,
        notifications : liste,
        // Recompté sur la liste reçue plutôt que par un second appel :
        // les deux viennent du même serveur, autant éviter l'aller-
        // retour et le risque de les voir diverger.
        nonLues       : liste.where((n) => !n.lue).length,
        clearError    : true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading : false,
        error     : MessagesErreur.depuisException(e),
      );
    }
  }

  /// Compteur seul, pour la pastille de la cloche.
  ///
  /// Beaucoup plus léger que la liste entière : c'est ce qu'on appelle
  /// depuis l'accueil, où l'on n'a pas besoin du contenu.
  Future<void> chargerCompteur() async {
    try {
      final n = await ApiService().getNotificationsNonLues();
      state = state.copyWith(nonLues: n);
    } catch (_) {
      // Une pastille absente ne mérite pas de message d'erreur.
    }
  }

  /// Marque une notification lue, à l'affichage immédiat.
  ///
  /// L'état change avant la réponse du serveur : le gris s'allume
  /// sous le doigt. En cas d'échec on recharge, ce qui remet la
  /// vérité du serveur — plutôt que de bloquer l'écran sur un
  /// aller-retour.
  Future<void> marquerLue(int id) async {
    final avant = state.notifications;
    final index = avant.indexWhere((n) => n.id == id);
    if (index == -1 || avant[index].lue) return;

    final liste = [...avant];
    liste[index] = liste[index].copyWith(lue: true);
    state = state.copyWith(
      notifications : liste,
      nonLues       : (state.nonLues - 1).clamp(0, 9999),
    );

    try {
      await ApiService().marquerNotificationLue(id);
    } catch (_) {
      await charger(silencieux: true);
    }
  }

  Future<void> marquerToutesLues() async {
    final avant = state.notifications;
    state = state.copyWith(
      notifications : avant.map((n) => n.copyWith(lue: true)).toList(),
      nonLues       : 0,
    );
    try {
      await ApiService().marquerToutesNotificationsLues();
    } catch (_) {
      await charger(silencieux: true);
    }
  }

  Future<void> supprimer(int id) async {
    final avant = state.notifications;
    final cible = avant.where((n) => n.id == id).firstOrNull;
    state = state.copyWith(
      notifications : avant.where((n) => n.id != id).toList(),
      nonLues       : cible != null && !cible.lue
          ? (state.nonLues - 1).clamp(0, 9999)
          : state.nonLues,
    );
    try {
      await ApiService().supprimerNotification(id);
    } catch (_) {
      // L'élément réapparaît : mieux vaut le revoir que croire l'avoir
      // supprimé alors qu'il est toujours là.
      await charger(silencieux: true);
    }
  }

  Future<void> supprimerTout() async {
    final avant = state.notifications;
    state = state.copyWith(notifications: const [], nonLues: 0);
    try {
      await ApiService().supprimerToutesNotifications();
    } catch (_) {
      state = state.copyWith(notifications: avant);
      await charger(silencieux: true);
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notifier = NotificationNotifier();

  // L'historique suit le compte, pas l'appareil : sans ce vidage, la
  // personne suivante à se connecter verrait les notifications de la
  // précédente — ses commandes, ses établissements.
  ref.listen(authProvider, (previous, next) {
    if (!next.isAuthenticated) notifier.vider();
  });

  return notifier;
});
