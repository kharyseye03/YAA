class ApiConfig {

// Keycloak
  // ⚠️ Doit être identique entre le login et le refresh
  static const String clientId = 'your-client-id';

  static const String iamBaseUrl = 'https://your-iam-server.com';
  static const String iamBaseUrltelephone = 'https://your-iam-server.com';
  static const String loginEndpoint = '/realms/your-realm/protocol/openid-connect/token';

  // Backend
  static const String _backendBaseUrl = 'https://your-api-server.com';
  static const String _backendBaseUrltelephone = 'https://your-api-server.com';
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
  static const String categorieProduitEndpoint    = '/categories-produit/search';
  static const String produitsByStructureEndpoint = '/produits/structure';
  static String structureDetailUrl(int id) => '$baseUrl/structures/$id';
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

  // ── Endpoints Commandes ───────────────────────────
  static const String commandesClientEndpoint       = '/commandes-clients';
  static const String commandeClientDetailEndpoint  = '/commandes-clients-livreurs/client/detail';

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