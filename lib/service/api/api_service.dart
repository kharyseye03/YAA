import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../config/api/api_config.dart';
import '../../model/auth/login_response.dart';
import '../../model/auth/register_response.dart';
import '../../model/cart/cart_model.dart';
import '../../model/favori/produit_favori_model.dart';
import '../../model/favori/structure_favori_model.dart';
import '../../model/order/commande_detail_model.dart';
import '../../model/order/commande_model.dart';
import '../../model/order/livraison_course_model.dart';
import '../../model/transaction/transaction_model.dart';
import '../../model/category/categorie_produit.dart';
import '../../model/category/categorie_structure.dart';
import '../../model/category/structure.dart';
import '../../model/category/produit_detail.dart';
import '../../model/category/structure_detail.dart';
import '../../model/course/estimation_model.dart';
import '../auth/token_storage.dart';
import '../../model/user/user_profile.dart';
import 'api_logger.dart';

class ApiService {
  // ── Singleton ──────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ════════════════════════════════════════════════════
  // AUTHENTIFICATION — Renouvellement automatique du token
  // ════════════════════════════════════════════════════

  /// Renouvellement en cours, partagé par tous les appels : sans ce
  /// verrou, trois écrans qui se rafraîchissent en même temps
  /// déclencheraient trois refresh simultanés — et Keycloak peut
  /// invalider le refresh token après usage.
  Future<String>? _refreshing;

  /// Token valide, renouvelé si besoin. null si la session est morte.
  Future<String?> _validToken() async {
    if (await TokenStorage.instance.hasValidToken()) {
      return TokenStorage.instance.getAccessToken();
    }
    return _renewToken();
  }

  Future<String?> _renewToken() async {
    _refreshing ??= _performRefresh().whenComplete(() => _refreshing = null);
    try {
      return await _refreshing;
    } catch (_) {
      return null;
    }
  }

  Future<String> _performRefresh() async {
    final refresh = await TokenStorage.instance.getRefreshToken();
    if (refresh == null) throw Exception('Aucun refresh token.');
    ApiLogger.trace('Renouvellement du token…');
    final auth = await refreshToken(refreshToken: refresh);
    // Bien enregistrer le NOUVEAU refresh token, pas seulement l'access
    await TokenStorage.instance.saveTokens(auth);
    return auth.accessToken;
  }

  /// Exécute une requête authentifiée, avec renouvellement préventif
  /// et une seule nouvelle tentative si le serveur répond 401.
  Future<http.Response> _authed(
    Future<http.Response> Function(String token) send,
  ) async {
    var token = await _validToken();
    if (token == null) throw _sessionExpired();

    var response = await send(token);
    if (response.statusCode != 401) return response;

    ApiLogger.trace('401 reçu → nouvelle tentative');
    // L'en-tête WWW-Authenticate précise la cause exacte du 401
    // (Jwt expired, iss claim not valid, …) — utile en debug.
    final reason = response.headers['www-authenticate'];
    if (reason != null) ApiLogger.trace('WWW-Authenticate → $reason');

    token = await _renewToken();
    if (token == null) throw _sessionExpired();

    response = await send(token);
    if (response.statusCode == 401) throw _sessionExpired();
    return response;
  }

  Exception _sessionExpired() =>
      Exception('Session expirée. Reconnectez-vous.');

  /// Adaptateur : exécute [request] avec les bons en-têtes, en passant
  /// par [_authed] quand l'endpoint est protégé.
  Future<http.Response> _send({
    required bool auth,
    required Future<http.Response> Function(Map<String, String> headers)
        request,
  }) {
    Future<http.Response> run(Map<String, String> headers) =>
        request(headers).timeout(
          const Duration(seconds: ApiConfig.connectionTimeout),
          onTimeout: () => throw TimeoutException(
              'Le serveur ne répond pas. Vérifiez votre connexion.'),
        );

    if (!auth) return run(ApiConfig.headers);
    return _authed((token) => run({
          ...ApiConfig.headers,
          'Authorization': 'Bearer $token',
        }));
  }

  // ════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES — Le moteur interne
  // ════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _post(
    String endpoint,
    dynamic body, {
    bool auth = false,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      ApiLogger.requete('POST', url, corps: body);
      final chrono = Stopwatch()..start();

      final response = await _send(
        auth    : auth,
        request : (headers) => http.post(
          url,
          headers : headers,
          body    : json.encode(body),
        ),
      );

      ApiLogger.reponse(
          'POST', url, response.statusCode, response.body, chrono.elapsed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return {};
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      }

      if (response.body.isEmpty) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
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

  Future<Map<String, dynamic>> _put(
    String endpoint,
    dynamic body, {
    bool auth = false,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      ApiLogger.requete('PUT', url, corps: body);
      final chrono = Stopwatch()..start();

      final response = await _send(
        auth    : auth,
        request : (headers) => http.put(
          url,
          headers : headers,
          body    : json.encode(body),
        ),
      );

      ApiLogger.reponse(
          'PUT', url, response.statusCode, response.body, chrono.elapsed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return {};
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      }

      if (response.body.isEmpty) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
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

  Future<void> _delete(
    String endpoint, {
    Map<String, String>? queryParams,
    bool auth = false,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      ApiLogger.requete('DELETE', uri);
      final chrono = Stopwatch()..start();

      final response = await _send(
        auth    : auth,
        request : (headers) => http.delete(uri, headers: headers),
      );

      ApiLogger.reponse(
          'DELETE', uri, response.statusCode, response.body, chrono.elapsed);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return; // succès
      }

      if (response.body.isEmpty) {
        throw Exception('Erreur ${response.statusCode}');
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

  Future<Map<String, dynamic>> _get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool auth = false,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      ApiLogger.requete('GET', uri);
      final chrono = Stopwatch()..start();

      final response = await _send(
        auth    : auth,
        request : (headers) => http.get(uri, headers: headers),
      );

      ApiLogger.reponse(
          'GET', uri, response.statusCode, response.body, chrono.elapsed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Corps vide en succès = réponse valide (ex. panier vide)
        if (response.body.isEmpty) return {};
        return json.decode(response.body) as Map<String, dynamic>;
      }

      if (response.body.isEmpty) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
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

  Future<List<dynamic>> _getList(
    String endpoint, {
    Map<String, String>? queryParams,
    bool auth = false,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }
      ApiLogger.requete('GET', uri);
      final chrono = Stopwatch()..start();

      final response = await _send(
        auth    : auth,
        request : (headers) => http.get(uri, headers: headers),
      );

      ApiLogger.reponse(
          'GET', uri, response.statusCode, response.body, chrono.elapsed);

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

  Future<Map<String, dynamic>> _postForm(
    String url,
    Map<String, String> fields,
  ) async {
    try {
      final uri = Uri.parse(url);

      // Mot de passe et jetons transitent ici : on trace les clés
      // du formulaire, jamais leurs valeurs.
      ApiLogger.requete('POST', uri, corps: fields.keys.join(', '));
      final chrono = Stopwatch()..start();

      final response = await http
          .post(uri, headers: ApiConfig.formHeaders, body: fields)
          .timeout(
            const Duration(seconds: ApiConfig.connectionTimeout),
            onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'),
          );

      ApiLogger.reponse(
          'POST', uri, response.statusCode, response.body, chrono.elapsed);

      final data = json.decode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }

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
  // MÉTHODES PUBLIQUES — Auth
  // ════════════════════════════════════════════════════

  Future<RegisterResponse> register({
    required String firstName,
    required String lastName,
    required String email,
    required String telephone,
  }) async {
    try {
      final body = {
        'firstName' : firstName,
        'lastName'  : lastName,
        'email'     : email,
        'telephone' : telephone,
      };
      final response = await _post(ApiConfig.registerEndpoint, body);
      return RegisterResponse.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('register', e);
      rethrow;
    }
  }

  Future<RegisterResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final body = {'email': email, 'otp': otp};
      final response = await _post(ApiConfig.verifyOtpEndpoint, body);
      return RegisterResponse.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('verifyOtp', e);
      rethrow;
    }
  }

  Future<RegisterResponse> createPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final body = {'email': email, 'newPassword': newPassword};
      final response = await _post(ApiConfig.resetPasswordEndpoint, body);
      return RegisterResponse.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('createPassword', e);
      rethrow;
    }
  }

  Future<RegisterResponse> forgotPassword({required String email}) async {
    try {
      final response = await _post(ApiConfig.forgotPasswordEndpoint, {'email': email});
      return RegisterResponse.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('forgotPassword', e);
      rethrow;
    }
  }

  Future<RegisterResponse> resendCode({required String email}) async {
    try {
      final response = await _post(ApiConfig.resendCodeEndpoint, {'email': email});
      return RegisterResponse.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('resendCode', e);
      rethrow;
    }
  }

  Future<void> setAdresse({
    required String email,
    required String telephone,
    required String adresse,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final body = {
        'email'     : email,
        'telephone' : telephone,
        'adresse'   : adresse,
        'latitude'  : latitude,
        'longitude' : longitude,
      };
      await _put(ApiConfig.setAdresseEndpoint, body);
    } catch (e) {
      ApiLogger.erreur('setAdresse', e);
      rethrow;
    }
  }

  /// Estimation des frais d'une livraison / course (distance,
  /// durée et prix) à partir du trajet et du type de véhicule.
  Future<EstimationModel> getEstimation({
    required String typeService,   // LIVRAISON | COURSE
    required String typeVehicule,  // MOTO | VEHICULE
    required double latitudeDepart,
    required double longitudeDepart,
    required double latitudeArrivee,
    required double longitudeArrivee,
  }) async {
    try {
      final body = {
        'typeService'      : typeService,
        'typeVehicule'     : typeVehicule,
        'latitudeDepart'   : latitudeDepart,
        'longitudeDepart'  : longitudeDepart,
        'latitudeArrivee'  : latitudeArrivee,
        'longitudeArrivee' : longitudeArrivee,
      };
      final response = await _post(
          ApiConfig.estimationEndpoint, body, auth: true);
      return EstimationModel.fromJson(
          response['data'] as Map<String, dynamic>);
    } catch (e) {
      ApiLogger.erreur('getEstimation', e);
      rethrow;
    }
  }

  /// Estimation d'une course : un seul appel renvoie les tarifs
  /// des deux véhicules (MOTO et VEHICULE).
  Future<List<EstimationModel>> getCourseEstimations({
    required double latitudeDepart,
    required double longitudeDepart,
    required double latitudeArrivee,
    required double longitudeArrivee,
  }) async {
    try {
      final body = {
        'latitudeDepart'   : latitudeDepart,
        'longitudeDepart'  : longitudeDepart,
        'latitudeArrivee'  : latitudeArrivee,
        'longitudeArrivee' : longitudeArrivee,
      };
      final response = await _post(
          ApiConfig.courseEstimationEndpoint, body, auth: true);
      final list = response['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => EstimationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ApiLogger.erreur('getCourseEstimations', e);
      rethrow;
    }
  }

  /// Estimation de la livraison d'une commande : un appel renvoie un
  /// tarif par type de véhicule (MOTO, CARGO…). Le départ est le
  /// dépôt de la structure, l'arrivée l'adresse du client.
  Future<List<EstimationModel>> getLivraisonCommandeEstimations({
    required double latitudeDepart,
    required double longitudeDepart,
    required double latitudeArrivee,
    required double longitudeArrivee,
  }) async {
    try {
      final body = {
        'latitudeDepart'   : latitudeDepart,
        'longitudeDepart'  : longitudeDepart,
        'latitudeArrivee'  : latitudeArrivee,
        'longitudeArrivee' : longitudeArrivee,
      };
      final response = await _post(
          ApiConfig.livraisonCommandeEstimationEndpoint, body, auth: true);
      final list = response['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => EstimationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ApiLogger.erreur('getLivraisonCommandeEstimations', e);
      rethrow;
    }
  }

  /// Une structure par son identifiant — sert à récupérer ses
  /// coordonnées, absentes du panier.
  Future<Structure> getStructureById(int id) async {
    try {
      final response = await _get('${ApiConfig.structuresEndpoint}/$id');
      return Structure.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('getStructureById($id)', e);
      rethrow;
    }
  }

  /// Note le coursier d'une mission terminée (1 à 5 étoiles).
  Future<void> noterCoursier({
    required int livraisonCourseId,
    required int note,
  }) async {
    try {
      await _post(
        ApiConfig.notationCoursierEndpoint,
        {'livraisonCourseId': livraisonCourseId, 'note': note},
        auth: true,
      );
    } catch (e) {
      ApiLogger.erreur('noterCoursier', e);
      rethrow;
    }
  }

  /// Crée une course (transport A → B) avec le véhicule choisi.
  /// Retourne la mission créée (statut initial RECHERCHE_COURSIER).
  Future<LivraisonCourseModel> createCourse({
    required String typeVehicule,   // MOTO | VEHICULE
    required double latitudeDepart,
    required double longitudeDepart,
    required double latitudeArrivee,
    required double longitudeArrivee,
    required String adresseDepart,
    required String adresseArrivee,
    String  instructions = '',
  }) async {
    try {
      final body = {
        'typeVehicule'     : typeVehicule,
        'latitudeDepart'   : latitudeDepart,
        'longitudeDepart'  : longitudeDepart,
        'latitudeArrivee'  : latitudeArrivee,
        'longitudeArrivee' : longitudeArrivee,
        'adresseDepart'    : adresseDepart,
        'adresseArrivee'   : adresseArrivee,
        'instructions'     : instructions,
      };
      final response =
          await _post(ApiConfig.courseEndpoint, body, auth: true);
      return LivraisonCourseModel.fromJson(
          response['data'] as Map<String, dynamic>);
    } catch (e) {
      ApiLogger.erreur('createCourse', e);
      rethrow;
    }
  }

  /// Crée une demande de livraison (colis A → B).
  /// Retourne la mission créée (statut initial RECHERCHE_COURSIER).
  Future<LivraisonCourseModel> createLivraison({
    required String typeVehicule,   // MOTO | VEHICULE
    required double latitudeDepart,
    required double longitudeDepart,
    required double latitudeArrivee,
    required double longitudeArrivee,
    required String adresseDepart,
    required String adresseArrivee,
    required String telephoneExpediteur,
    required String telephoneDestinataire,
    String  instructions = '',
  }) async {
    try {
      final body = {
        'typeVehicule'          : typeVehicule,
        'latitudeDepart'        : latitudeDepart,
        'longitudeDepart'       : longitudeDepart,
        'latitudeArrivee'       : latitudeArrivee,
        'longitudeArrivee'      : longitudeArrivee,
        'adresseDepart'         : adresseDepart,
        'adresseArrivee'        : adresseArrivee,
        'instructions'          : instructions,
        'telephoneExpediteur'   : telephoneExpediteur,
        'telephoneDestinataire' : telephoneDestinataire,
      };
      final response = await _post(
          ApiConfig.livraisonEndpoint, body, auth: true);
      return LivraisonCourseModel.fromJson(
          response['data'] as Map<String, dynamic>);
    } catch (e) {
      ApiLogger.erreur('createLivraison', e);
      rethrow;
    }
  }

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      final fields = {
        'grant_type' : 'password',
        'client_id'  : ApiConfig.clientId,
        'username'   : username,
        'password'   : password,
      };
      final response = await _postForm(ApiConfig.getIamUrl(ApiConfig.loginEndpoint), fields);
      return LoginResponse.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('login', e);
      rethrow;
    }
  }

  Future<LoginResponse> refreshToken({required String refreshToken}) async {
    try {
      final fields = {
        'grant_type'    : 'refresh_token',
        'client_id'     : ApiConfig.clientId,
        'refresh_token' : refreshToken,
      };
      final response = await _postForm(ApiConfig.getIamUrl(ApiConfig.loginEndpoint), fields);
      return LoginResponse.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('refreshToken', e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES — User
  // ════════════════════════════════════════════════════

  Future<UserProfile> getUserDetail({
    required String email,
  }) async {
    try {
      final response = await _get(
        ApiConfig.userDetailEndpoint,
        queryParams : {'email': email},
        auth        : true,
      );
      return UserProfile.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

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
            'image', imagePath,
            contentType: MediaType(parts[0], parts[1]),
          ),
        );
      }

      ApiLogger.requete('PUT multipart', uri);
      final chrono = Stopwatch()..start();

      final streamed = await request.send().timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'),
      );
      final response = await http.Response.fromStream(streamed);

      ApiLogger.reponse('PUT multipart', uri, response.statusCode,
          response.body, chrono.elapsed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isNotEmpty) {
          try {
            final data = json.decode(response.body) as Map<String, dynamic>;
            final fileName = data['imageFileName'] as String?
                ?? data['image']    as String?
                ?? data['imageUrl'] as String?;
            if (fileName != null && fileName.isNotEmpty) {
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
  // MÉTHODES PUBLIQUES — Catégories & Structures
  // ════════════════════════════════════════════════════

  Future<List<CategorieStructure>> getCategories() async {
    try {
      final response = await _get(ApiConfig.categoriesEndpoint);
      final data = response['data'] as List<dynamic>;
      return data
          .map((e) => CategorieStructure.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ApiLogger.erreur('getCategories', e);
      rethrow;
    }
  }

  Future<List<Structure>> getStructuresByCategory(int categorieId) async {
    return getStructures(categorieId: categorieId);
  }

  /// Recherche de structures — tous les filtres sont optionnels et
  /// combinables : géolocalisation (lat/lng/rayon en mètres),
  /// catégorie, nom, spécialité.
  Future<List<Structure>> getStructures({
    int? categorieId,
    double? latitude,
    double? longitude,
    double? rayon,
    String? nom,
    String? specialite,
  }) async {
    try {
      final queryParams = <String, String>{
        if (categorieId != null) 'categorieId' : categorieId.toString(),
        if (latitude    != null) 'latitude'    : latitude.toString(),
        if (longitude   != null) 'longitude'   : longitude.toString(),
        if (rayon       != null) 'rayon'       : rayon.toString(),
        if (nom         != null) 'nom'         : nom,
        if (specialite  != null) 'specialite'  : specialite,
      };
      final list = await _getList(
        ApiConfig.structuresEndpoint,
        queryParams: queryParams.isEmpty ? null : queryParams,
      );
      return list
          .map((e) => Structure.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ApiLogger.erreur('getStructures', e);
      rethrow;
    }
  }

  /// Filtres de l'écran Catégorie : les catégories de produits
  /// proposées au sein d'une catégorie d'établissement.
  /// La réponse est enveloppée dans `data`.
  Future<List<CategorieProduit>> getFiltresCategorie(
      int categorieStructureId) async {
    try {
      final response = await _get(
        ApiConfig.categoriesProduitParStructureUrl(categorieStructureId),
      );
      final list = response['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => CategorieProduit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ApiLogger.erreur('getFiltresCategorie', e);
      rethrow;
    }
  }

  /// Produits d'une structure.
  ///
  /// Tous les critères sont optionnels et cumulables — ils servent
  /// aussi bien à remplir les sections de la fiche établissement
  /// (`categorieProduitId`) qu'à la recherche dans son catalogue.
  Future<List<Produit>> getProduitsByStructure(
    int structureId, {
    int? categorieProduitId,
    String? nom,
    String? marque,
    String? unite,
    bool? disponible,
    bool? enPromotion,
    bool? necessiteOrdonnance,
    num? prixMin,
    num? prixMax,
  }) async {
    try {
      final params = <String, String>{
        'idStructure': structureId.toString(),
      };
      // Un critère nul — ou une chaîne vide — ne doit pas partir dans
      // l'URL : le backend le prendrait pour un filtre à part entière
      void ajouter(String cle, Object? valeur) {
        if (valeur == null) return;
        if (valeur is String && valeur.trim().isEmpty) return;
        params[cle] = valeur is String ? valeur.trim() : valeur.toString();
      }

      ajouter('categorieProduitId', categorieProduitId);
      ajouter('nom', nom);
      ajouter('marque', marque);
      ajouter('unite', unite);
      ajouter('disponible', disponible);
      ajouter('enPromotion', enPromotion);
      ajouter('necessiteOrdonnance', necessiteOrdonnance);
      ajouter('prixMin', prixMin);
      ajouter('prixMax', prixMax);

      final list = await _getList(
        ApiConfig.produitsByStructureEndpoint,
        queryParams: params,
      );

      // Cas observé sur la structure 17 : /structures/{id} expose des
      // produits que /produits/structure n'a jamais renvoyés. Les
      // produits concernés ont tous stock = 0 alors que
      // disponible = true — l'écran se retrouve vide sans erreur.
      if (list.isEmpty && params.length == 1) {
        ApiLogger.vide(
          'getProduitsByStructure(structure $structureId)',
          'catalogue vide sans aucun filtre. Vérifier /structures/'
          '$structureId : si des produits y figurent, le backend les '
          'écarte ici (piste : stock = 0).',
        );
      }

      return list.map((e) => Produit.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      ApiLogger.erreur('getProduitsByStructure(structure $structureId)', e);
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
  // MÉTHODES PUBLIQUES — Panier
  // ════════════════════════════════════════════════════

  Future<void> addToCart({
    required int produitId,
    required int quantite,
  }) async {
    try {
      final body = [
        {'produitId': produitId, 'quantite': quantite},
      ];
      await _post(ApiConfig.cartEndpoint, body, auth: true);
      // On n'essaie pas de parser la réponse — le CartNotifier
      // recharge le panier complet via getCart() juste après.
    } catch (e) {
      ApiLogger.erreur('addToCart', e);
      rethrow;
    }
  }

  /// Retourne null si aucun panier actif (réponse vide)
  Future<CartModel?> getCart() async {
    try {
      final response = await _get(ApiConfig.cartClientEndpoint, auth: true);
      if (response.isEmpty) return null; // pas de panier actif
      return CartModel.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('getCart', e);
      rethrow;
    }
  }

  /// Supprime une ligne du panier
  Future<void> deleteCartLine({required int idLigne}) async {
    try {
      await _delete(
        ApiConfig.cartDeleteLineEndpoint,
        queryParams: {'idLigne': idLigne.toString()},
        auth: true,
      );
    } catch (e) {
      ApiLogger.erreur('deleteCartLine', e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES — Favoris structures
  // ════════════════════════════════════════════════════

  Future<List<StructureFavoriModel>> getStructuresFavoris() async {
    try {
      final list = await _getList(
        ApiConfig.structuresFavorisEndpoint,
        auth: true,
      );
      return list
          .map((e) => StructureFavoriModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ApiLogger.erreur('getStructuresFavoris', e);
      rethrow;
    }
  }

  Future<void> toggleStructureFavori({
    required int structureId,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(ApiConfig.structuresFavorisToggleEndpoint));
      uri = uri.replace(queryParameters: {'structureId': structureId.toString()});

      ApiLogger.requete('GET', uri);
      final chrono = Stopwatch()..start();

      final response = await _send(
        auth    : true,
        request : (headers) => http.get(uri, headers: headers),
      );

      ApiLogger.reponse(
          'GET', uri, response.statusCode, response.body, chrono.elapsed);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      }

      final data = response.body.isNotEmpty
          ? json.decode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      throw Exception(data['message'] as String? ?? 'Erreur ${response.statusCode}');
    } on SocketException {
      throw Exception('Pas de connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ProduitFavoriModel>> getProduitsFavoris() async {
    try {
      final list = await _getList(
        ApiConfig.produitsFavorisEndpoint,
        auth: true,
      );
      return list
          .map((e) => ProduitFavoriModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ApiLogger.erreur('getProduitsFavoris', e);
      rethrow;
    }
  }

  Future<void> toggleProduitFavori({
    required int produitId,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(ApiConfig.produitsFavorisToggleEndpoint));
      uri = uri.replace(queryParameters: {'produitId': produitId.toString()});

      ApiLogger.requete('GET', uri);
      final chrono = Stopwatch()..start();

      final response = await _send(
        auth    : true,
        request : (headers) => http.get(uri, headers: headers),
      );

      ApiLogger.reponse(
          'GET', uri, response.statusCode, response.body, chrono.elapsed);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      }

      final data = response.body.isNotEmpty
          ? json.decode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      throw Exception(data['message'] as String? ?? 'Erreur ${response.statusCode}');
    } on SocketException {
      throw Exception('Pas de connexion internet.');
    } on TimeoutException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES — Commandes client
  // ════════════════════════════════════════════════════

  Future<CommandeDetailModel> getCommandeDetail({
    required int id,
  }) async {
    try {
      final response = await _get(
        ApiConfig.commandeClientDetailEndpoint,
        queryParams: {'id': id.toString()},
        auth: true,
      );
      return CommandeDetailModel.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('getCommandeDetail', e);
      rethrow;
    }
  }

  Future<List<CommandeModel>> getCommandes() async {
    try {
      final list = await _getList(
        ApiConfig.commandesClientEndpoint,
        auth: true,
      );
      return list
          .map((e) => CommandeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ApiLogger.erreur('getCommandes', e);
      rethrow;
    }
  }

  /// Liste unifiée des livraisons, courses et commandes livrées.
  /// La réponse est enveloppée dans `data`.
  Future<List<LivraisonCourseModel>> getMissions() async {
    try {
      final response = await _get(
        ApiConfig.missionsClientEndpoint,
        auth: true,
      );
      final list = response['data'] as List<dynamic>? ?? [];
      return list
          .map((e) =>
              LivraisonCourseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ApiLogger.erreur('getMissions', e);
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES — Transactions
  // ════════════════════════════════════════════════════

  /// Crée une transaction (commande) — retourne les infos pour le paiement.
  ///
  /// `modeLivraison` est toujours INDIVIDUEL : le regroupement des
  /// livraisons n'est plus proposé au client. Ce qu'il choisit, c'est
  /// son mode de réception (livraison à domicile ou retrait sur place).
  ///
  /// Les adresses restent envoyées à l'identique dans les deux cas :
  /// le backend connaît déjà l'adresse du client et celle de la structure.
  Future<TransactionModel> createTransaction({
    required int    panierId,
    required String modeReceptionCommande, // LIVRAISON | RETRAIT_CLIENT
    required String adresseLivraison,
    required String telephoneClient,
    required double latitude,
    required double longitude,
    String          description = '',
    String?         typeVehicule,   // MOTO | CARGO… — livraison seulement
    double?         fraisLivraison, // tarif retenu par le client
  }) async {
    try {
      final body = {
        'panierId'              : panierId,
        'description'           : description,
        'modeLivraison'         : 'INDIVIDUEL',
        'modeReceptionCommande' : modeReceptionCommande,
        'adresseLivraison'      : adresseLivraison,
        'telephoneClient'       : telephoneClient,
        'latitude'              : latitude,
        'longitude'             : longitude,
        // Absents en retrait : aucun véhicule n'est mobilisé, aucun
        // frais de livraison n'est dû
        if (typeVehicule != null)   'typeVehicule'  : typeVehicule,
        if (fraisLivraison != null) 'fraisLivraison': fraisLivraison,
      };
      final response = await _post(
          ApiConfig.transactionEndpoint, body, auth: true);
      return TransactionModel.fromJson(response);
    } catch (e) {
      ApiLogger.erreur('createTransaction', e);
      rethrow;
    }
  }

  /// Procède au paiement d'une transaction existante
  Future<void> payTransaction({
    required int    id,
    required String reference,
    required String modePaiement,
  }) async {
    try {
      final body = {
        'id'          : id,
        'reference'   : reference,
        'modePaiement': modePaiement,
      };
      await _post(ApiConfig.payTransactionEndpoint, body, auth: true);
    } catch (e) {
      ApiLogger.erreur('payTransaction', e);
      rethrow;
    }
  }

  /// Vide entièrement le panier
  Future<void> clearEntireCart({required int idPanier}) async {
    try {
      await _delete(
        ApiConfig.cartClearEndpoint,
        queryParams: {'idPanier': idPanier.toString()},
        auth: true,
      );
    } catch (e) {
      ApiLogger.erreur('clearEntireCart', e);
      rethrow;
    }
  }

}
