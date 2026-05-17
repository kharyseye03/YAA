import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api/api_config.dart';
import '../../model/auth/login_response.dart';
import '../../model/auth/register_response.dart';
import '../../model/category/categorie_produit.dart';
import '../../model/category/categorie_structure.dart';
import '../../model/category/structure.dart';
import '../../model/category/produit_detail.dart';
import '../../model/category/structure_detail.dart';
import '../../model/user/user_profile.dart';

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

    // ════════════════════════════════════════════════════
  // MÉTHODE PRIVÉE — GET
  // ════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = {
        ...ApiConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http
          .get(uri, headers: headers)
          .timeout(
            const Duration(seconds: ApiConfig.connectionTimeout),
            onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'),
          );

      print('📡 GET Status → ${response.statusCode}');
      print('📬 GET Réponse → ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Erreur ${response.statusCode} — réponse vide du serveur.');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }

      final errorMessage = data['message'] as String? ?? 'Erreur ${response.statusCode}';
      throw Exception(errorMessage);

    } on SocketException {
      throw Exception('Pas de connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } on FormatException {
      throw Exception('Réponse invalide du serveur.');
    } catch (e) {
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODE PUBLIQUE — User Profile
  // ════════════════════════════════════════════════════

  Future<UserProfile> getUserDetail({
    required String email,
    required String token,
  }) async {
    try {
      // Essai 1 : sans token (endpoint possiblement public)
      final response = await _get(
        ApiConfig.userDetailEndpoint,
        queryParams: {'email': email},
      );
      return UserProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODE PUBLIQUE — Catégories
  // ════════════════════════════════════════════════════

  Future<List<dynamic>> _getList(
    String endpoint, {
    Map<String, String>? queryParams,
    String? token,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      final headers = {
        ...ApiConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout),
              onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'));

      print('📡 GET Status → ${response.statusCode}');
      print('📬 GET Réponse → ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Erreur ${response.statusCode} — réponse vide du serveur.');
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as List<dynamic>;
      }
      throw Exception('Erreur ${response.statusCode}');
    } on SocketException {
      throw Exception('Pas de connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CategorieStructure>> getCategories() async {
    try {
      final response = await _get(ApiConfig.categoriesEndpoint);
      final data = response['data'] as List<dynamic>;
      return data
          .map((e) => CategorieStructure.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erreur getCategories: $e');
      rethrow;
    }
  }

  Future<List<Structure>> getStructuresByCategory(int categorieId) async {
    try {
      final list = await _getList(
        ApiConfig.structuresEndpoint,
        queryParams: {'categorieId': categorieId.toString()},
      );
      return list
          .map((e) => Structure.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erreur getStructuresByCategory: $e');
      rethrow;
    }
  }

  Future<StructureDetail> getStructureDetail(int id) async {
    try {
      final uri = Uri.parse(ApiConfig.structureDetailUrl(id));
      final response = await http
          .get(uri, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout),
              onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'));

      print('📡 GET Status → ${response.statusCode}');
      print('📬 GET Réponse → ${response.body}');

      if (response.body.isEmpty) {
        throw Exception('Réponse vide du serveur.');
      }
      if (response.statusCode == 200 || response.statusCode == 201) {
        return StructureDetail.fromJson(
            json.decode(response.body) as Map<String, dynamic>);
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] as String? ?? 'Erreur ${response.statusCode}');
    } on SocketException {
      throw Exception('Pas de connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } on FormatException {
      throw Exception('Réponse invalide du serveur.');
    } catch (e) {
      print('❌ Erreur getStructureDetail: $e');
      rethrow;
    }
  }

  Future<List<CategorieProduit>> getCategorieProduits(int structureId) async {
    try {
      final list = await _getList(
        '${ApiConfig.categorieProduitEndpoint}/$structureId',
      );
      return list
          .map((e) => CategorieProduit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erreur getCategorieProduits: $e');
      rethrow;
    }
  }

  Future<List<Produit>> getProduitsByStructure() async {
    try {
      final list = await _getList(ApiConfig.produitsByStructureEndpoint);
      return list.map((e) => Produit.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('❌ Erreur getProduitsByStructure: $e');
      rethrow;
    }
  }

  Future<ProduitDetail> getProduitDetail(int id) async {
    try {
      final uri = Uri.parse(ApiConfig.produitDetailUrl(id));
      final response = await http
          .get(uri, headers: ApiConfig.headers)
          .timeout(const Duration(seconds: ApiConfig.connectionTimeout),
              onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'));

      if (response.body.isEmpty) throw Exception('Réponse vide du serveur.');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return ProduitDetail.fromJson(
            json.decode(response.body) as Map<String, dynamic>);
      }
      final data = json.decode(response.body) as Map<String, dynamic>;
      throw Exception(data['message'] as String? ?? 'Erreur ${response.statusCode}');
    } on SocketException {
      throw Exception('Pas de connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } on FormatException {
      throw Exception('Réponse invalide du serveur.');
    } catch (e) {
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODE PUBLIQUE — Update Profile (multipart form-data)
  // ════════════════════════════════════════════════════

  Future<String?> updateProfile({
    required String email,
    required String firstName,
    required String lastName,
    required String telephone,
    String? imagePath,
  }) async {
    try {
      final uri = Uri.parse(ApiConfig.getUrl(ApiConfig.updateProfileEndpoint));
      final request = http.MultipartRequest('PUT', uri)
        ..headers.addAll({
          'ngrok-skip-browser-warning': 'true',
        })
        ..fields['firstName'] = firstName
        ..fields['lastName']  = lastName
        ..fields['email']     = email
        ..fields['telephone'] = telephone;

      if (imagePath != null) {
        final ext = imagePath.split('.').last.toLowerCase();
        final mimeType = switch (ext) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'png'           => 'image/png',
          'gif'           => 'image/gif',
          'webp'          => 'image/webp',
          _               => 'image/jpeg',
        };
        final parts = mimeType.split('/');
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            imagePath,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      print('🌐 PUT multipart → $uri');

      final streamed = await request.send().timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'),
      );
      final response = await http.Response.fromStream(streamed);

      print('📡 Status → ${response.statusCode}');
      print('📬 Réponse → ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          try {
            final data = json.decode(response.body) as Map<String, dynamic>;
            final fileName = data['imageFileName'] as String?
                ?? data['image'] as String?
                ?? data['imageUrl'] as String?;
            if (fileName != null && fileName.isNotEmpty) {
              // Si c'est déjà une URL complète, on la retourne telle quelle
              if (fileName.startsWith('http')) return fileName;
              return ApiConfig.getImageUrl(fileName);
            }
          } catch (_) {}
        }
        return null;
      }

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try { data = json.decode(response.body) as Map<String, dynamic>; } catch (_) {}
      }
      final errorMessage = data['message'] as String? ?? 'Erreur ${response.statusCode}';
      throw Exception('${response.statusCode} $errorMessage');

    } on SocketException {
      throw Exception('Pas de connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

// ════════════════════════════════════════════════════
// MÉTHODE PRIVÉE — Spécifique form-urlencoded (Keycloak)
// Différente de _post car le body et les headers changent
// ════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _postForm(
      String url, // ← on passe l'URL complète directement (pas un endpoint)
      Map<String, String> fields,
      ) async {
    try {
      final uri = Uri.parse(url);

      print('🌐 POST FORM → $uri');
      print('📦 Fields → $fields');

      // Uri.https encode automatiquement les caractères spéciaux
      // ex: "Test@123" devient "Test%40123" dans l'URL
      final response = await http
          .post(
        uri,
        headers : ApiConfig.formHeaders, // ← headers form, pas JSON
        // On encode le body en format clé=valeur&clé=valeur
        body    : fields,  // http.post gère l'encodage automatiquement
        // quand headers est x-www-form-urlencoded
      )
          .timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () => throw TimeoutException(
          'Le serveur ne répond pas.',
        ),
      );

      print('📡 Status → ${response.statusCode}');
      print('📬 Réponse → ${response.body}');

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }

      // Keycloak retourne "error_description" pour les erreurs
      // ex: "Invalid user credentials"
      final errorMessage = data['error_description'] as String?
          ?? data['error'] as String?
          ?? 'Erreur ${response.statusCode}';
      throw Exception(errorMessage);

    } on SocketException {
      throw Exception('Pas de connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } on FormatException {
      throw Exception('Réponse invalide du serveur.');
    } catch (e) {
      rethrow;
    }
  }

// ════════════════════════════════════════════════════
// MÉTHODE PUBLIQUE — Login
// ════════════════════════════════════════════════════

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final fields = {
        'grant_type' : 'password',
        'client_id'  : 'yaa',
        'username'   : username,
        'password'   : password,
      };
      final response = await _postForm(
        ApiConfig.getIamUrl(ApiConfig.loginEndpoint),
        fields,
      );
      return LoginResponse.fromJson(response);
    } catch (e) {
      print('❌ Erreur login: $e');
      rethrow;
    }
  }

  Future<LoginResponse> refreshToken({required String refreshToken}) async {
    try {
      final fields = {
        'grant_type'    : 'refresh_token',
        'client_id'     : 'yaa',
        'refresh_token' : refreshToken,
      };
      final response = await _postForm(
        ApiConfig.getIamUrl(ApiConfig.loginEndpoint),
        fields,
      );
      return LoginResponse.fromJson(response);
    } catch (e) {
      print('❌ Erreur refreshToken: $e');
      rethrow;
    }
  }
}

