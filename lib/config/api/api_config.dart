class ApiConfig {

  // 🔧 Mode dev → ngrok
  static const String baseUrl = 'https://5d19-41-214-10-114.ngrok-free.app/api/v1';

  // ── Endpoints Auth ────────────────────────────────
  static const String registerEndpoint = '/registrations/client';
  static const String verifyOtpEndpoint = '/registrations/otp';
  static const String resetPasswordEndpoint = '/registrations/reset-password';
  static const String forgotPasswordEndpoint = '/registrations/forgot-password';
  static const String resendCodeEndpoint = '/registrations/resend-code';

  // ── Timeouts (en secondes) ────────────────────────
  static const int connectionTimeout = 30;
  static const int receiveTimeout    = 30;

  // ── Headers ───────────────────────────────────────
  // "get" car les headers peuvent changer selon l'état
  // de l'app (ex: ajouter un token plus tard)
  static Map<String, String> get headers => {
    'Content-Type'               : 'application/json',
    'Accept'                     : 'application/json',
    'ngrok-skip-browser-warning' : 'true',
  };

  // Construit l'URL complète : baseUrl + endpoint
  static String getUrl(String endpoint) => '$baseUrl$endpoint';
}