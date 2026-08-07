import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order/commande_detail_model.dart';
import '../../../model/order/commande_model.dart';
import '../../../service/api/api_service.dart';


class CommandeState {
  final bool                  isLoading;
  final List<CommandeModel>   commandes;
  final String?               error;
  // ── Détail ────────────────────────────────────────
  final bool                  isLoadingDetail;
  final CommandeDetailModel?  detail;
  final String?               detailError;

  const CommandeState({
    this.isLoading        = false,
    this.commandes        = const [],
    this.error,
    this.isLoadingDetail  = false,
    this.detail,
    this.detailError,
  });

  CommandeState copyWith({
    bool?                 isLoading,
    List<CommandeModel>?  commandes,
    String?               error,
    bool                  clearError        = false,
    bool                  isLoadingDetail   = false,
    CommandeDetailModel?  detail,
    bool                  clearDetail       = false,
    String?               detailError,
    bool                  clearDetailError  = false,
  }) {
    return CommandeState(
      isLoading       : isLoading       ?? this.isLoading,
      commandes       : commandes       ?? this.commandes,
      error           : clearError      ? null : (error ?? this.error),
      isLoadingDetail : isLoadingDetail,
      detail          : clearDetail     ? null : (detail ?? this.detail),
      detailError     : clearDetailError
          ? null
          : (detailError ?? this.detailError),
    );
  }

  List<CommandeModel> get enCours   => commandes.where((c) =>  c.isEnCours).toList();
  List<CommandeModel> get terminees => commandes.where((c) => !c.isEnCours).toList();
}

class CommandeNotifier extends StateNotifier<CommandeState> {
  CommandeNotifier() : super(const CommandeState());



  // ── Liste ──────────────────────────────────────────────────
  Future<void> loadCommandes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final commandes = await ApiService().getCommandes();
      state = state.copyWith(isLoading: false, commandes: commandes);
    } catch (e) {
      debugPrint('❌ loadCommandes: $e');
      state = state.copyWith(
        isLoading : false,
        error     : e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ── Détail ─────────────────────────────────────────────────
  Future<void> loadDetail(int id) async {
    state = state.copyWith(
      isLoadingDetail  : true,
      clearDetail      : true,
      clearDetailError : true,
    );
    try {
      final detail = await ApiService().getCommandeDetail(id: id);
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
  Future<void> refreshDetail(int id) async {
    try {
      final detail = await ApiService().getCommandeDetail(id: id);
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
