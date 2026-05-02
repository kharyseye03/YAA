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

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        firstName : json['firstName'] as String? ?? '',
        lastName  : json['lastName']  as String? ?? '',
        email     : json['email']     as String? ?? '',
        telephone : json['telephone'] as String? ?? '',
        imageUrl  : json['image']     as String?,
      );

  String get fullName => '$firstName $lastName'.trim();
}
