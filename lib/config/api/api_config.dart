class ApiConfig {

  // ── Keycloak (IAM) ────────────────────────────────────────
  static const String iamBaseUrl = 'https://57e6-41-83-137-24.ngrok-free.app';
  static const String loginEndpoint = '/realms/yaa-delivery/protocol/openid-connect/token';
  // 🔧 Mode dev → ngrok
  static const String _ngrokBaseUrl = 'https://331c-41-83-137-24.ngrok-free.app';
  static const String baseUrl       = '$_ngrokBaseUrl/api/v1';


  // ── Endpoints Auth ────────────────────────────────
  static const String registerEndpoint = '/registrations/client';
  static const String verifyOtpEndpoint = '/registrations/otp';
  static const String resetPasswordEndpoint = '/registrations/reset-password';
  static const String forgotPasswordEndpoint = '/registrations/forgot-password';
  static const String resendCodeEndpoint = '/registrations/resend-code';

  // ── Endpoints User ────────────────────────────────
  static const String userDetailEndpoint    = '/registrations/detail';
  static const String updateProfileEndpoint = '/registrations/update';

  // ── Endpoints Catégories ──────────────────────────
  static const String categoriesEndpoint = '/categorie-structures';
  static const String structuresEndpoint = '/structures';
  static String structureDetailUrl(int id) => '$baseUrl/structures/$id';
  static String produitDetailUrl(int id) => '$baseUrl/produits/$id';
  static const String categorieProduitEndpoint = '/categories-produit/search';

  // ── Timeouts (en secondes) ────────────────────────
  static const int connectionTimeout = 30;
  static const int receiveTimeout    = 30;

  // ── Headers ───────────────────────────────────────
  static Map<String, String> get headers => {
    'Content-Type'               : 'application/json',
    'Accept'                     : 'application/json',
    'ngrok-skip-browser-warning' : 'true',
  };

  // ── Headers Form (spécifique Keycloak) ───────────────────
  // Keycloak n'accepte pas JSON → on lui envoie du form-urlencoded
  static Map<String, String> get formHeaders => {
    'Content-Type'               : 'application/x-www-form-urlencoded',
    'ngrok-skip-browser-warning' : 'true',
  };

  // Construit l'URL complète : baseUrl + endpoint
  static String getUrl(String endpoint) => '$baseUrl$endpoint';
  static String getIamUrl(String endpoint) => '$iamBaseUrl$endpoint';
  static String getImageUrl(String fileName) => '$baseUrl/files/$fileName';
}