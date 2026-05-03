/// Modèle de réponse Keycloak après connexion réussie
/// Keycloak retourne BEAUCOUP de champs — on ne garde que l'essentiel
class LoginResponse {
  final String accessToken;   // Le token à envoyer dans chaque requête protégée
  final String tokenType;     // Toujours "Bearer"
  final int    expiresIn;     // Durée de vie du token en secondes (ex: 300 = 5min)
  final String refreshToken;  // Token pour renouveler l'accès sans se reconnecter

  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.refreshToken,
  });

  /// Keycloak utilise snake_case : "access_token" et non "accessToken"
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken  : json['access_token']  as String,
      tokenType    : json['token_type']    as String,
      expiresIn    : json['expires_in']    as int,
      refreshToken : json['refresh_token'] as String,
    );
  }
}