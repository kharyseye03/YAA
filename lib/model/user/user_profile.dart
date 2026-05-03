import '../../config/api/api_config.dart';

class UserProfile {
  final String firstName;
  final String lastName;
  final String email;
  final String telephone;
  final String? imageUrl;

  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.telephone,
    this.imageUrl,
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
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}
