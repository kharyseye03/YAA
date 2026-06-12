import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/auth/providers/auth_notifier.dart';
import '../../../model/order/commande_detail_model.dart';
import '../../../model/order/commande_model.dart';
import '../../../service/api/api_service.dart';

const _tokenKey        = 'access_token';
const _refreshTokenKey = 'refresh_token';

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
  CommandeNotifier(this._prefs) : super(const CommandeState());

  final SharedPreferences _prefs;

  // ── Token ──────────────────────────────────────────────────
  static bool _isExpired(String token) {
    try {
      final payload = AuthNotifier.decodeJwtPayload(token);
      if (payload == null) return true;
      final exp = payload['exp'] as int?;
      if (exp == null) return false;
      return DateTime.now().millisecondsSinceEpoch > exp * 1000 - 30000;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _refreshToken() async {
    try {
      final refreshTk = _prefs.getString(_refreshTokenKey);
      if (refreshTk == null) return null;
      final res = await ApiService().refreshToken(refreshToken: refreshTk);
      await _prefs.setString(_tokenKey,        res.accessToken);
      await _prefs.setString(_refreshTokenKey, res.refreshToken);
      return res.accessToken;
    } catch (e) {
      debugPrint('❌ refresh: $e');
      return null;
    }
  }

  Future<String?> _getValidToken() async {
    final token = _prefs.getString(_tokenKey);
    if (token == null) return null;
    if (_isExpired(token)) return await _refreshToken();
    return token;
  }

  // ── Liste ──────────────────────────────────────────────────
  Future<void> loadCommandes() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token     = await _getValidToken();
      final commandes = await ApiService().getCommandes(token: token);
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
      final token  = await _getValidToken();
      final detail = await ApiService().getCommandeDetail(id: id, token: token);
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
      final token  = await _getValidToken();
      final detail = await ApiService().getCommandeDetail(id: id, token: token);
      state = state.copyWith(detail: detail);
    } catch (e) {
      debugPrint('⚠️ refreshDetail (silencieux): $e');
    }
  }
}

final commandeProvider =
    StateNotifierProvider<CommandeNotifier, CommandeState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CommandeNotifier(prefs);
});
