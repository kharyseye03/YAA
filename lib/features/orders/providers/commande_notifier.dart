import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order/commande_detail_model.dart';
import '../../../model/order/livraison_course_model.dart';
import '../../../service/api/api_service.dart';

class CommandeState {
  final bool                       isLoading;
  final List<LivraisonCourseModel> missions;
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
    this.error,
    this.isLoadingDetail  = false,
    this.detail,
    this.detailError,
  });

  CommandeState copyWith({
    bool?                       isLoading,
    List<LivraisonCourseModel>? missions,
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
      error           : clearError      ? null : (error ?? this.error),
      isLoadingDetail : isLoadingDetail,
      detail          : clearDetail     ? null : (detail ?? this.detail),
      detailError     : clearDetailError
          ? null
          : (detailError ?? this.detailError),
    );
  }

  List<LivraisonCourseModel> get enCours =>
      missions.where((m) =>  m.isEnCours).toList();
  List<LivraisonCourseModel> get terminees =>
      missions.where((m) => !m.isEnCours).toList();
}

class CommandeNotifier extends StateNotifier<CommandeState> {
  CommandeNotifier() : super(const CommandeState());

  // ── Liste ──────────────────────────────────────────────────
  Future<void> loadCommandes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final missions = await ApiService().getMissions();
      // Le plus récent en premier
      missions.sort((a, b) {
        final da = a.createdDate;
        final db = b.createdDate;
        if (da == null || db == null) return b.id.compareTo(a.id);
        return db.compareTo(da);
      });
      state = state.copyWith(isLoading: false, missions: missions);
    } catch (e) {
      debugPrint('❌ loadCommandes: $e');
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
