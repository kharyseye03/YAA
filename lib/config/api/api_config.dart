class ApiConfig {

  // ── Keycloak (IAM) ────────────────────────────────────────
  // URL différente car c'est un service complètement séparé
  static const String iamBaseUrl = 'http://ec2-98-94-81-133.compute-1.amazonaws.com:8080';
  static const String loginEndpoint = '/realms/yaa-delivery/protocol/openid-connect/token';

  // 🔧 Backend AWS EC2
  static const String _backendBaseUrl = 'http://ec2-98-94-81-133.compute-1.amazonaws.com:8081';
  static const String baseUrl         = '$_backendBaseUrl/api/v1';




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
  static const String categoriesEndpoint          = '/categorie-structures';
  static const String structuresEndpoint          = '/structures';
  static const String categorieProduitEndpoint    = '/categories-produit/search';
  static const String produitsByStructureEndpoint = '/produits/structure';
  static String structureDetailUrl(int id) => '$baseUrl/structures/$id';
  static String produitDetailUrl(int id)   => '$baseUrl/produits/$id';

  // ── Endpoints Panier ──────────────────────────────
  static const String cartEndpoint       = '/paniers';
  static const String cartClientEndpoint = '/paniers/client';

  // ── Timeouts (en secondes) ────────────────────────
  static const int connectionTimeout = 30;
  static const int receiveTimeout    = 30;

  // ── Headers ───────────────────────────────────────
  // "get" car les headers peuvent changer selon l'état
  // de l'app (ex: ajouter un token plus tard)
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
  // ex: getImageUrl('abc.PNG') → 'https://ngrok.../api/v1/files/abc.PNG'
  static String getImageUrl(String fileName) => '$baseUrl/files/$fileName';
}