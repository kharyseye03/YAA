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
import '../../model/transaction/transaction_model.dart';
import '../../model/category/categorie_produit.dart';
import '../../model/category/categorie_structure.dart';
import '../../model/category/structure.dart';
import '../../model/category/produit_detail.dart';
import '../../model/category/structure_detail.dart';
import '../../model/course/estimation_model.dart';
import '../../model/user/user_profile.dart';

class ApiService {
  // ── Singleton ──────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES — Le moteur interne
  // ════════════════════════════════════════════════════

  Future<Map<String, dynamic>> _post(
    String endpoint,
    dynamic body, {
    String? token,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      print('🌐 POST → $url');
      print('📦 Body → $body');

      final headers = {
        ...ApiConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        url,
        headers : headers,
        body    : json.encode(body),
      ).timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () {
          throw TimeoutException('Le serveur ne répond pas. Vérifiez votre connexion.');
        },
      );

      print('📡 Status → ${response.statusCode}');
      print('📬 Réponse → ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return {};
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
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
    String? token,
  }) async {
    try {
      final url = Uri.parse(ApiConfig.getUrl(endpoint));

      print('🌐 PUT → $url');
      print('📦 Body → $body');

      final headers = {
        ...ApiConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        url,
        headers : headers,
        body    : json.encode(body),
      ).timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () {
          throw TimeoutException('Le serveur ne répond pas. Vérifiez votre connexion.');
        },
      );

      print('📡 Status → ${response.statusCode}');
      print('📬 Réponse → ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) return {};
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
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
    String? token,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(endpoint));
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      print('🌐 DELETE → $uri');

      final headers = {
        ...ApiConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'),
      );

      print('📡 DELETE Status → ${response.statusCode}');
      print('📬 DELETE Réponse → ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return; // succès
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
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

  Future<Map<String, dynamic>> _postForm(
    String url,
    Map<String, String> fields,
  ) async {
    try {
      final uri = Uri.parse(url);

      print('🌐 POST FORM → $uri');
      print('📦 Fields → $fields');

      final response = await http
          .post(uri, headers: ApiConfig.formHeaders, body: fields)
          .timeout(
            const Duration(seconds: ApiConfig.connectionTimeout),
            onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'),
          );

      print('📡 Status → ${response.statusCode}');
      print('📬 Réponse → ${response.body}');

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
      print('❌ Erreur register: $e');
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
      print('❌ Erreur verifyOtp: $e');
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
      print('❌ Erreur createPassword: $e');
      rethrow;
    }
  }

  Future<RegisterResponse> forgotPassword({required String email}) async {
    try {
      final response = await _post(ApiConfig.forgotPasswordEndpoint, {'email': email});
      return RegisterResponse.fromJson(response);
    } catch (e) {
      print('❌ Erreur forgotPassword: $e');
      rethrow;
    }
  }

  Future<RegisterResponse> resendCode({required String email}) async {
    try {
      final response = await _post(ApiConfig.resendCodeEndpoint, {'email': email});
      return RegisterResponse.fromJson(response);
    } catch (e) {
      print('❌ Erreur resendCode: $e');
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
      print('❌ Erreur setAdresse: $e');
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
    String? token,
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
          ApiConfig.estimationEndpoint, body, token: token);
      return EstimationModel.fromJson(
          response['data'] as Map<String, dynamic>);
    } catch (e) {
      print('❌ Erreur getEstimation: $e');
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
        'client_id'  : 'yaa',
        'username'   : username,
        'password'   : password,
      };
      final response = await _postForm(ApiConfig.getIamUrl(ApiConfig.loginEndpoint), fields);
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
      final response = await _postForm(ApiConfig.getIamUrl(ApiConfig.loginEndpoint), fields);
      return LoginResponse.fromJson(response);
    } catch (e) {
      print('❌ Erreur refreshToken: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES — User
  // ════════════════════════════════════════════════════

  Future<UserProfile> getUserDetail({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _get(
        ApiConfig.userDetailEndpoint,
        queryParams: {'email': email},
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
      print('❌ Erreur getCategories: $e');
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
      print('❌ Erreur getStructures: $e');
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

      if (response.body.isEmpty) throw Exception('Réponse vide du serveur.');
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
      final list = await _getList('${ApiConfig.categorieProduitEndpoint}/$structureId');
      return list
          .map((e) => CategorieProduit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erreur getCategorieProduits: $e');
      rethrow;
    }
  }

  Future<List<Produit>> getProduitsByStructure(
    int structureId, {
    int? categorieProduitId,
  }) async {
    try {
      final params = <String, String>{
        'idStructure': structureId.toString(),
      };
      if (categorieProduitId != null) {
        params['categorieProduitId'] = categorieProduitId.toString();
      }
      final list = await _getList(
        ApiConfig.produitsByStructureEndpoint,
        queryParams: params,
      );
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
  // MÉTHODES PUBLIQUES — Panier
  // ════════════════════════════════════════════════════

  Future<void> addToCart({
    required int produitId,
    required int quantite,
    String? token,
  }) async {
    try {
      final body = [
        {'produitId': produitId, 'quantite': quantite},
      ];
      await _post(ApiConfig.cartEndpoint, body, token: token);
      // On n'essaie pas de parser la réponse — le CartNotifier
      // recharge le panier complet via getCart() juste après.
    } catch (e) {
      print('❌ Erreur addToCart: $e');
      rethrow;
    }
  }

  /// Retourne null si aucun panier actif (réponse vide)
  Future<CartModel?> getCart({String? token}) async {
    try {
      final response = await _get(ApiConfig.cartClientEndpoint, token: token);
      if (response.isEmpty) return null; // pas de panier actif
      return CartModel.fromJson(response);
    } catch (e) {
      print('❌ Erreur getCart: $e');
      rethrow;
    }
  }

  /// Supprime une ligne du panier
  Future<void> deleteCartLine({required int idLigne, String? token}) async {
    try {
      await _delete(
        ApiConfig.cartDeleteLineEndpoint,
        queryParams: {'idLigne': idLigne.toString()},
        token: token,
      );
    } catch (e) {
      print('❌ Erreur deleteCartLine: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES — Favoris structures
  // ════════════════════════════════════════════════════

  Future<List<StructureFavoriModel>> getStructuresFavoris({String? token}) async {
    try {
      final list = await _getList(
        ApiConfig.structuresFavorisEndpoint,
        token: token,
      );
      return list
          .map((e) => StructureFavoriModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erreur getStructuresFavoris: $e');
      rethrow;
    }
  }

  Future<void> toggleStructureFavori({
    required int structureId,
    String?      token,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(ApiConfig.structuresFavorisToggleEndpoint));
      uri = uri.replace(queryParameters: {'structureId': structureId.toString()});

      print('🌐 GET (toggle favori) → $uri');

      final headers = {
        ...ApiConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'),
      );

      print('📡 Status → ${response.statusCode}');
      print('📬 Réponse → ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
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

  Future<List<ProduitFavoriModel>> getProduitsFavoris({String? token}) async {
    try {
      final list = await _getList(
        ApiConfig.produitsFavorisEndpoint,
        token: token,
      );
      return list
          .map((e) => ProduitFavoriModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erreur getProduitsFavoris: $e');
      rethrow;
    }
  }

  Future<void> toggleProduitFavori({
    required int produitId,
    String?      token,
  }) async {
    try {
      var uri = Uri.parse(ApiConfig.getUrl(ApiConfig.produitsFavorisToggleEndpoint));
      uri = uri.replace(queryParameters: {'produitId': produitId.toString()});

      print('🌐 GET (toggle produit favori) → $uri');

      final headers = {
        ...ApiConfig.headers,
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: ApiConfig.connectionTimeout),
        onTimeout: () => throw TimeoutException('Le serveur ne répond pas.'),
      );

      print('📡 Status produit favori → ${response.statusCode}');
      print('📬 Réponse produit favori → ${response.body}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        return;
      }

      if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
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
    String?      token,
  }) async {
    try {
      final response = await _get(
        ApiConfig.commandeClientDetailEndpoint,
        queryParams: {'id': id.toString()},
        token: token,
      );
      return CommandeDetailModel.fromJson(response);
    } catch (e) {
      print('❌ Erreur getCommandeDetail: $e');
      rethrow;
    }
  }

  Future<List<CommandeModel>> getCommandes({String? token}) async {
    try {
      final list = await _getList(
        ApiConfig.commandesClientEndpoint,
        token: token,
      );
      return list
          .map((e) => CommandeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Erreur getCommandes: $e');
      rethrow;
    }
  }

  // ════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES — Transactions
  // ════════════════════════════════════════════════════

  /// Crée une transaction (commande) — retourne les infos pour le paiement
  Future<TransactionModel> createTransaction({
    required int    panierId,
    required String modeLivraison,
    required String adresseLivraison,
    required String telephoneClient,
    required double latitude,
    required double longitude,
    String          description = '',
    String?         token,
  }) async {
    try {
      final body = {
        'panierId'         : panierId,
        'description'      : description,
        'modeLivraison'    : modeLivraison,
        'adresseLivraison' : adresseLivraison,
        'telephoneClient'  : telephoneClient,
        'latitude'         : latitude,
        'longitude'        : longitude,
      };
      final response = await _post(
          ApiConfig.transactionEndpoint, body, token: token);
      return TransactionModel.fromJson(response);
    } catch (e) {
      print('❌ Erreur createTransaction: $e');
      rethrow;
    }
  }

  /// Procède au paiement d'une transaction existante
  Future<void> payTransaction({
    required int    id,
    required String reference,
    required String modePaiement,
    String?         token,
  }) async {
    try {
      final body = {
        'id'          : id,
        'reference'   : reference,
        'modePaiement': modePaiement,
      };
      await _post(ApiConfig.payTransactionEndpoint, body, token: token);
    } catch (e) {
      print('❌ Erreur payTransaction: $e');
      rethrow;
    }
  }

  /// Vide entièrement le panier
  Future<void> clearEntireCart({required int idPanier, String? token}) async {
    try {
      await _delete(
        ApiConfig.cartClearEndpoint,
        queryParams: {'idPanier': idPanier.toString()},
        token: token,
      );
    } catch (e) {
      print('❌ Erreur clearEntireCart: $e');
      rethrow;
    }
  }

}
