/// Modèle de réponse pour l'inscription
/// API retourne : { "status": 201, "message": "OTP envoyé avec succès" }
class RegisterResponse {
  final int status;
  final String message;

  const RegisterResponse({
    required this.status,
    required this.message,
  });

  /// "fromJson" = fabrique un objet Dart depuis une Map JSON
  /// On caste explicitement (as int, as String) pour éviter
  /// les erreurs silencieuses si l'API change de format
  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      status  : json['status']  as int,
      message : json['message'] as String,
    );
  }
}