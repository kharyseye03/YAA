import 'package:shared_preferences/shared_preferences.dart';

/// Mémorise que l'utilisateur a déjà vu l'onboarding.
///
/// ⚠️ Cette clé ne doit **jamais** être effacée à la déconnexion :
/// quelqu'un qui se déconnecte connaît déjà l'app, le renvoyer sur
/// l'onboarding serait une régression. Seule une désinstallation
/// remet le compteur à zéro, ce qui est le comportement voulu.
class OnboardingStorage {
  OnboardingStorage._();
  static final OnboardingStorage instance = OnboardingStorage._();

  static const _key = 'onboarding_vu';

  Future<bool> dejaVu() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? false;

  Future<void> marquerVu() async =>
      (await SharedPreferences.getInstance()).setBool(_key, true);
}
