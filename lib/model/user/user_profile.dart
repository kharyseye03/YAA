import '../../config/api/api_config.dart';

class UserProfile {
  final String firstName;
  final String lastName;
  final String email;
  final String telephone;
  final String? imageUrl;
  final String? address;   // adresse de livraison par défaut
  final double? latitude;
  final double? longitude;

  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.telephone,
    this.imageUrl,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final fileName = json['imageFileName'] as String?
        ?? json['image']    as String?
        ?? json['imageUrl'] as String?;

    String? imageUrl;
    if (fileName != null && fileName.isNotEmpty) {
      imageUrl = fileName.startsWith('http')
          ? fileName
          : ApiConfig.getImageUrl(fileName);
    }

    return UserProfile(
      firstName : json['firstName'] as String? ?? '',
      lastName  : json['lastName']  as String? ?? '',
      email     : json['email']     as String? ?? '',
      telephone : json['telephone'] as String? ?? '',
      imageUrl  : imageUrl,
      address   : json['address'] as String?,
      latitude  : (json['latitude']  as num?)?.toDouble(),
      longitude : (json['longitude'] as num?)?.toDouble(),
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}
