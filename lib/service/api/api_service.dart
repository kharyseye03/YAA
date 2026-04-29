import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../config/api/api_config.dart';
import '../../model/auth/register_response.dart';

class ApiService {
  // ── Singleton ──────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES — Le moteur interne
  // Ces méthodes ne sont jamais appelées depuis les écrans
  // ════════════════════════════════════════════════════

  /// Méthode POST privée
  /// [endpoint]  : la route  ex: '/registrations/client'
  /// [body]      : la Map qu'on veut envoyer en JSON
  /// Retourne    : une Map<String, dynamic> (le JSON de la réponse)

  Future<Map<String, dynamic>> _post(String endpoint, Map<String, dynamic> body,) async {
    try {
      // 1. On construit l'URL complète
      //    Uri.parse() transforme le String en objet Uri
      //    que le package http sait utiliser
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      // Log utile pour déboguer depuis la console Flutter
      print('🌐 POST → $url');
      print('📦 Body → $body');

      // 2. On envoie la requête
      //    json.encode() transforme la Map Dart en String JSON
      //    ex: {"firstName":"Abdoul","lastName":"Diallo",...}
      final response = await http.post(
        url,
        headers : ApiConfig.headers,
        body    : json.encode(body),
      )
      // 3. Timeout : si le serveur ne répond pas en 30s
      //    on coupe et on lance une TimeoutException
          .timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () {
          throw TimeoutException(
            'Le serveur ne répond pas. Vérifiez votre connexion.',
          );
        },
      );

      print('📡 Status → ${response.statusCode}');
      print('📬 Réponse → ${response.body}');

      // 4. On décode la réponse JSON en Map Dart
      final data = json.decode(response.body) as Map<String, dynamic>;

      // 5. On accepte 200 ET 201
      //    200 = OK classique
      //    201 = Created (ressource créée avec succès)
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }

      // 6. Si le serveur renvoie une erreur (400, 401, 500…)
      //    On essaie d'extraire le message d'erreur du JSON
      //    Si pas de message → on affiche le code HTTP
      final errorMessage = data['message'] as String? ??
          'Erreur ${response.statusCode}';
      throw Exception(errorMessage);

    } on SocketException {
      // Pas de connexion internet du tout
      throw Exception('Pas de connexion internet.');

    } on TimeoutException catch (e) {
      throw Exception(e.message);

    } on FormatException {
      // La réponse reçue n'est pas du JSON valide
      throw Exception('Réponse invalide du serveur.');

    } catch (e) {
      // Toute autre erreur non prévue : on la relance telle quelle
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES — Auth
  // Ces méthodes sont appelées depuis les écrans
  // ════════════════════════════════════════════════════

  /// Inscription d'un nouveau client
  /// Retourne un [RegisterResponse] si succès
  /// Lance une [Exception] avec un message lisible si erreur
  Future<RegisterResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
  }) async {
    try {
      // On construit le body exactement comme l'API l'attend
      final body = {
        'firstName' : firstName,
        'lastName'  : lastName,
        'email'     : email,
        'telephone' : telephone,
      };

      // On délègue l'envoi HTTP à _post — on ne répète pas la logique
      final response = await _post(ApiConfig.registerEndpoint, body);

      // On transforme la Map JSON en objet RegisterResponse typé
      return RegisterResponse.fromJson(response);

    } catch (e) {
      print('❌ Erreur register: $e');
      // On relance pour que l'écran puisse afficher l'erreur
      rethrow;
    }
  }

  Future<RegisterResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final body = {
        'email' : email,
        'otp'   : otp,
      };

      final response = await _post(ApiConfig.verifyOtpEndpoint, body);
      return RegisterResponse.fromJson(response);

    } catch (e) {
      print('❌ Erreur verifyOtp: $e');
      rethrow;
    }
  }

  Future<RegisterResponse> createPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final body = {
        'email'       : email,
        'newPassword' : newPassword,
      };

      final response = await _post(ApiConfig.resetPasswordEndpoint, body);
      return RegisterResponse.fromJson(response);

    } catch (e) {
      print('❌ Erreur createPassword: $e');
      rethrow;
    }
  }

  Future<RegisterResponse> forgotPassword({
    required String email,
  }) async {
    try {
      final body = {'email': email};
      final response = await _post(ApiConfig.forgotPasswordEndpoint, body);
      return RegisterResponse.fromJson(response);
    } catch (e) {
      print('❌ Erreur forgotPassword: $e');
      rethrow;
    }
  }

  Future<RegisterResponse> resendCode({
    required String email,
  }) async {
    try {
      final body = {'email': email};
      final response = await _post(ApiConfig.resendCodeEndpoint, body);
      return RegisterResponse.fromJson(response);
    } catch (e) {
      print('❌ Erreur resendCode: $e');
      rethrow;
    }
  }
}

