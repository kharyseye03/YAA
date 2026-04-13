/// Centralized string constants for the YAA application.
/// Facilitates future localization (i18n).
abstract final class AppStrings {
  // ── App ──────────────────────────────────────────────────
  static const String appName = 'YAA';
  static const String appTagline = 'Tout ce dont vous avez besoin, livré.';

  // ── Categories ───────────────────────────────────────────
  static const String restaurants = 'Restaurants';
  static const String pharmacies = 'Pharmacies';
  static const String boutiques = 'Boutiques';
  static const String supermarkets = 'Supermarchés';

  // ── Auth ──────────────────────────────────────────────────
  static const String login = 'Connexion';
  static const String register = 'Inscription';
  static const String email = 'Email';
  static const String password = 'Mot de passe';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String noAccount = 'Pas encore de compte ?';
  static const String alreadyHaveAccount = 'Déjà un compte ?';

  // ── Common ───────────────────────────────────────────────
  static const String search = 'Rechercher';
  static const String seeAll = 'Voir tout';
  static const String addToCart = 'Ajouter au panier';
  static const String orderNow = 'Commander';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String save = 'Enregistrer';
  static const String delete = 'Supprimer';
  static const String retry = 'Réessayer';
  static const String loading = 'Chargement...';
  static const String noResults = 'Aucun résultat';

  // ── Cart ──────────────────────────────────────────────────
  static const String cart = 'Panier';
  static const String emptyCart = 'Votre panier est vide';
  static const String total = 'Total';
  static const String subtotal = 'Sous-total';
  static const String deliveryFee = 'Frais de livraison';
  static const String checkout = 'Passer la commande';

  // ── Orders ───────────────────────────────────────────────
  static const String myOrders = 'Mes commandes';
  static const String orderDetails = 'Détails de la commande';
  static const String trackOrder = 'Suivre la commande';

  // ── Errors ───────────────────────────────────────────────
  static const String genericError = 'Une erreur est survenue. Veuillez réessayer.';
  static const String networkError = 'Vérifiez votre connexion internet.';
  static const String serverError = 'Erreur serveur. Réessayez plus tard.';
}
