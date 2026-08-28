import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order/commande_detail_model.dart';
import '../../../model/order/commande_model.dart';
import '../../../model/order/livraison_course_model.dart';
import '../../../service/api/api_service.dart';

/// Une ligne de la page « Mes commandes ».
///
/// La page agrège deux API qui ne partagent aucun modèle :
/// `/livraisons-courses/client/livraisons-courses` (missions) et
/// `/commandes-clients` (commandes d'établissement). D'où cette union,
/// plutôt qu'une conversion de l'une vers l'autre qui obligerait à
/// inventer les champs manquants (trajet, distance, coursier…).
sealed class ElementCommande {
  const ElementCommande();

  /// Date de création, pour trier les deux sources ensemble.
  DateTime? get date;

  bool get isEnCours;
}

class ElementMission extends ElementCommande {
  const ElementMission(this.mission);
  final LivraisonCourseModel mission;

  @override
  DateTime? get date => mission.createdDate;

  @override
  bool get isEnCours => mission.isEnCours;
}

class ElementCommandeStructure extends ElementCommande {
  const ElementCommandeStructure(this.commande);
  final CommandeModel commande;

  @override
  DateTime? get date => commande.createdDate;

  @override
  bool get isEnCours => commande.isEnCours;
}

class CommandeState {
  final bool                       isLoading;
  final List<LivraisonCourseModel> missions;
  final List<CommandeModel>        commandes;
  final String?                    error;
  // ── Détail ────────────────────────────────────────
  // Renseigné uniquement pour les LIVRAISON_COMMANDE : les autres
  // types se suffisent des données de la liste.
  final bool                  isLoadingDetail;
  final CommandeDetailModel?  detail;
  final String?               detailError;

  const CommandeState({
    this.isLoading        = false,
    this.missions         = const [],
    this.commandes        = const [],
    this.error,
    this.isLoadingDetail  = false,
    this.detail,
    this.detailError,
  });

  CommandeState copyWith({
    bool?                       isLoading,
    List<LivraisonCourseModel>? missions,
    List<CommandeModel>?        commandes,
    String?                     error,
    bool                        clearError        = false,
    bool                        isLoadingDetail   = false,
    CommandeDetailModel?        detail,
    bool                        clearDetail       = false,
    String?                     detailError,
    bool                        clearDetailError  = false,
  }) {
    return CommandeState(
      isLoading       : isLoading       ?? this.isLoading,
      missions        : missions        ?? this.missions,
      commandes       : commandes       ?? this.commandes,
      error           : clearError      ? null : (error ?? this.error),
      isLoadingDetail : isLoadingDetail,
      detail          : clearDetail     ? null : (detail ?? this.detail),
      detailError     : clearDetailError
          ? null
          : (detailError ?? this.detailError),
    );
  }

  /// Les deux sources fusionnées, du plus récent au plus ancien.
  ///
  /// Aucun dédoublonnage volontairement : une commande déjà suivie
  /// comme mission apparaît donc deux fois. C'est un choix assumé, la
  /// clé de recoupement serait `mission.commandeStructureId`.
  List<ElementCommande> get elements {
    final tous = <ElementCommande>[
      ...missions.map(ElementMission.new),
      ...commandes.map(ElementCommandeStructure.new),
    ];
    tous.sort((a, b) {
      final da = a.date;
      final db = b.date;
      // Les éléments sans date partent en fin de liste plutôt que de
      // remonter arbitrairement en tête.
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return tous;
  }

  List<ElementCommande> get enCours =>
      elements.where((e) =>  e.isEnCours).toList();
  List<ElementCommande> get terminees =>
      elements.where((e) => !e.isEnCours).toList();

  // ── Les deux onglets de « Mes commandes » ──────────────────
  // Chaque onglet montre sa source telle quelle : aucun recoupement
  // entre les deux API, aucun filtre par type. Une livraison de
  // commande figure donc dans les deux onglets — c'est ce que
  // renvoient les serveurs.
  //
  // Seul tri conservé : les terminées basculent dans l'Historique du
  // profil et ne restent pas dans « Mes commandes ».

  static int _duPlusRecent(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  /// Onglet « Achat » — commandes passées chez un commerçant
  List<CommandeModel> get achatsEnCours =>
      commandes.where((c) => c.isEnCours).toList()
        ..sort((a, b) => _duPlusRecent(a.createdDate, b.createdDate));

  /// Onglet « Course » — colis et trajets, tous types confondus
  List<LivraisonCourseModel> get coursesEnCours =>
      missions.where((m) => m.isEnCours).toList()
        ..sort((a, b) => _duPlusRecent(a.createdDate, b.createdDate));
}

class CommandeNotifier extends StateNotifier<CommandeState> {
  CommandeNotifier() : super(const CommandeState());

  // ── Liste ──────────────────────────────────────────────────
  /// Charge les deux listes.
  ///
  /// [silencieux] pour les rappels périodiques : on ne lève pas
  /// `isLoading`, donc la liste ne se remplace pas par un indicateur
  /// de chargement toutes les vingt secondes. Une mise à jour de
  /// statut doit se remarquer parce que le badge a changé, pas parce
  /// que l'écran a clignoté.
  Future<void> loadCommandes({bool silencieux = false}) async {
    if (!silencieux) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      // Les deux appels sont indépendants : les lancer en parallèle
      // évite de cumuler les deux temps de réponse. Le tri est fait
      // à la lecture, par CommandeState.elements.
      final (missions, commandes) = await (
        ApiService().getMissions(),
        ApiService().getCommandes(),
      ).wait;
      state = state.copyWith(
        isLoading : false,
        missions  : missions,
        commandes : commandes,
      );
    } catch (e) {
      debugPrint('❌ loadCommandes: $e');
      // En silencieux, un échec réseau ne doit pas faire surgir un
      // bandeau rouge sur une liste qui s'affiche correctement : on
      // garde les données précédentes et on retentera au prochain tour.
      if (silencieux) return;
      state = state.copyWith(
        isLoading : false,
        error     : e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Détail ─────────────────────────────────────────────────
  /// Ne charge un détail que pour les commandes d'établissement.
  /// Pour une livraison ou une course, la liste contient déjà tout.
  Future<void> loadDetail(LivraisonCourseModel mission) async {
    if (!mission.hasDetail) {
      state = state.copyWith(clearDetail: true, clearDetailError: true);
      return;
    }
    state = state.copyWith(
      isLoadingDetail  : true,
      clearDetail      : true,
      clearDetailError : true,
    );
    try {
      final detail = await ApiService()
          .getCommandeDetail(id: mission.commandeStructureId!);
      state = state.copyWith(isLoadingDetail: false, detail: detail);
    } catch (e) {
      debugPrint('❌ loadDetail: $e');
      state = state.copyWith(
        isLoadingDetail : false,
        detailError     : e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Rafraîchit le détail en arrière-plan (polling) : pas de spinner,
  /// on garde l'affichage actuel et on remplace les données à l'arrivée.
  /// Les erreurs sont silencieuses (réseau instable → on réessaiera
  /// au prochain tick).
  Future<void> refreshDetail(int commandeId) async {
    try {
      final detail = await ApiService().getCommandeDetail(id: commandeId);
      state = state.copyWith(detail: detail);
    } catch (e) {
      debugPrint('⚠️ refreshDetail (silencieux): $e');
    }
  }
}

final commandeProvider =
    StateNotifierProvider<CommandeNotifier, CommandeState>((ref) {
  return CommandeNotifier();
});
