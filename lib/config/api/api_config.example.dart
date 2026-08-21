class ApiConfig {

// Keycloak
  // ⚠️ Doit être identique entre le login et le refresh
  static const String clientId = 'your-client-id';

  // ── Environnement ─────────────────────────────────────────
  // Un seul bloc actif à la fois : commenter l'autre.

  // Production
  static const String iamBaseUrl      = 'https://your-iam-server.com';
  static const String _backendBaseUrl = 'https://your-api-server.com';

  // Local (réseau interne)
  // ⚠️ En http : nécessite usesCleartextTraffic dans AndroidManifest.
  // static const String iamBaseUrl      = 'http://192.168.x.x:8080';
  // static const String _backendBaseUrl = 'http://192.168.x.x:8081';

  static const String loginEndpoint = '/realms/your-realm/protocol/openid-connect/token';
  static const String baseUrl = '$_backendBaseUrl/api/v1';



  // ── Endpoints Auth ────────────────────────────────
  static const String registerEndpoint = '/registrations/client';
  static const String verifyOtpEndpoint = '/registrations/otp';
  static const String resetPasswordEndpoint = '/registrations/reset-password';
  static const String forgotPasswordEndpoint = '/registrations/forgot-password';
  static const String resendCodeEndpoint = '/registrations/resend-code';
  static const String setAdresseEndpoint = '/registrations/set-adresse';

  // ── Endpoints User ────────────────────────────────
  static const String userDetailEndpoint    = '/registrations/detail';
  static const String updateProfileEndpoint = '/registrations/update';

  // ── Endpoints Catégories ──────────────────────────
  static const String categoriesEndpoint          = '/categorie-structures';
  static const String structuresEndpoint          = '/structures';
  /// Catégories de produits d'une catégorie d'établissement —
  /// alimente les filtres de l'écran Catégorie
  static String categoriesProduitParStructureUrl(int categorieStructureId) =>
      '/categories-produit/categorie-structure/$categorieStructureId'
      '/categories-produit';
  static const String produitsByStructureEndpoint = '/produits/structure';
  static String produitDetailUrl(int id)   => '$baseUrl/produits/$id';

  // ── Endpoints Favoris ────────────────────────────
  static const String structuresFavorisEndpoint       = '/structures-favoris';
  static const String structuresFavorisToggleEndpoint = '/structures-favoris/toggle';
  static const String produitsFavorisEndpoint          = '/produits-favoris';
  static const String produitsFavorisToggleEndpoint   = '/produits-favoris/toggle';

  // ── Endpoints Livraisons & Courses ────────────────
  // Livraison : estimation puis création
  static const String estimationEndpoint = '/livraisons-courses/estimation/livraison';
  static const String livraisonEndpoint  = '/livraisons-courses/livraisons';
  // Course : estimation (renvoie les tarifs MOTO et VEHICULE) puis création
  static const String courseEstimationEndpoint = '/livraisons-courses/estimation/course';
  static const String courseEndpoint           = '/livraisons-courses/courses';
  // Livraison d'une commande d'établissement : renvoie un tarif par
  // type de véhicule, du dépôt de la structure jusqu'au client
  static const String livraisonCommandeEstimationEndpoint =
      '/livraisons-courses/estimation/livraison-commande';

  // Notation du coursier après une mission terminée
  static const String notationCoursierEndpoint = '/notations-coursiers';

  // ── Endpoints Commandes ───────────────────────────
  // Liste unifiée affichée dans l'écran Commandes : livraisons de
  // colis, courses et commandes d'établissement, tous types confondus.
  static const String missionsClientEndpoint =
      '/livraisons-courses/client/livraisons-courses';
  // Détail enrichi — uniquement pour les LIVRAISON_COMMANDE
  static const String commandeClientDetailEndpoint = '/commandes-clients/detail';
  // Commandes d'établissement seules — utilisé par le suivi
  // post-paiement, qui guette les statuts propres à la commande
  static const String commandesClientEndpoint = '/commandes-clients';

  // ── Endpoints Transaction ─────────────────────────
  static const String transactionEndpoint     = '/transactions';
  static const String payTransactionEndpoint  = '/transactions/payer';

  // ── Endpoints Panier ──────────────────────────────
  static const String cartEndpoint            = '/paniers';
  static const String cartClientEndpoint      = '/paniers/client';
  static const String cartDeleteLineEndpoint  = '/paniers/delete-ligne-panier';
  static const String cartClearEndpoint       = '/paniers/vider-panier';

  // ── Timeouts (en secondes) ────────────────────────
  static const int connectionTimeout = 30;
  static const int receiveTimeout    = 30;

  // ── Headers ───────────────────────────────────────
  static Map<String, String> get headers => {
    'Content-Type' : 'application/json',
    'Accept'       : 'application/json',
  };

  // ── Headers Form (spécifique Keycloak) ───────────────────
  // Keycloak n'accepte pas JSON → on lui envoie du form-urlencoded
  static Map<String, String> get formHeaders => {
    'Content-Type' : 'application/x-www-form-urlencoded',
  };

  // Construit l'URL complète : baseUrl + endpoint
  static String getUrl(String endpoint) => '$baseUrl$endpoint';
  static String getIamUrl(String endpoint) => '$iamBaseUrl$endpoint';

  // Construit l'URL d'accès à une image à partir du nom de fichier
  static String getImageUrl(String fileName) => '$baseUrl/files/$fileName';
}