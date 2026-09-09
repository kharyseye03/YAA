import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaa/features/auth/providers/auth_notifier.dart';
import 'package:yaa/main.dart';

/// L'application démarre-t-elle ?
///
/// Ce fichier contenait le test d'exemple de `flutter create` — celui
/// d'un compteur qui n'a jamais existé dans YAA. Il échouait depuis le
/// premier jour, et son échec ne voulait rien dire ; pire, il rendait
/// `flutter test` rouge en permanence, ce qui apprend à ignorer le
/// rouge. Une suite dans laquelle on n'a plus confiance ne sert à rien.
///
/// À la place, le test le plus élémentaire qui soit : l'arbre de
/// widgets se construit sans lever. Il ne vérifie aucune
/// fonctionnalité, mais il attrape la panne la plus coûteuse — celle
/// où l'app ne démarre pas du tout, parce qu'un provider manque, qu'un
/// thème est mal formé ou qu'une route est cassée.
void main() {
  testWidgets('l\'application se construit sans lever', (tester) async {
    // Aucun stockage réel sous les tests : SharedPreferences n'a pas de
    // plugin natif ici, il faut lui donner un contenu simulé.
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const YaaApp(),
      ),
    );

    // Une seule frame : le splash lance des appels réseau que le test
    // ne peut pas satisfaire. On vérifie que la construction aboutit,
    // pas que l'app s'anime.
    await tester.pump();

    expect(tester.takeException(), isNull);

    // Le splash laisse tourner son animation et sa temporisation de
    // navigation. Le banc d'essai considère un minuteur encore vivant
    // comme une fuite et fait échouer le test : on remplace l'arbre,
    // puis on laisse le temps s'écouler pour qu'ils s'éteignent.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}
