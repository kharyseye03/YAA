import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise les missions déjà notées, pour ne pas redemander un avis
/// que le client a déjà donné.
///
/// Stockage local faute de mieux : l'API des missions ne renvoie
/// aucun indicateur du type `dejaNote`. Conséquence assumée — une
/// réinstallation, ou une connexion depuis un autre téléphone, fera
/// reproposer la notation. Le jour où le backend expose le champ,
/// cette classe disparaîtra au profit de la donnée serveur.
class NotationStorage {
  NotationStorage._();
  static final NotationStorage instance = NotationStorage._();

  static const _key = 'missions_notees';

  Future<Set<String>> _lire() async =>
      (await SharedPreferences.getInstance()).getStringList(_key)?.toSet() ??
      <String>{};

  Future<bool> dejaNotee(int missionId) async =>
      (await _lire()).contains('$missionId');

  Future<void> marquerNotee(int missionId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await _lire()..add('$missionId');
    await prefs.setStringList(_key, ids.toList());
  }
}
