class CategorieStructure {
  final int id;
  final String name;
  final String? imageFileName;

  const CategorieStructure({
    required this.id,
    required this.name,
    this.imageFileName,
  });

  factory CategorieStructure.fromJson(Map<String, dynamic> json) {
    return CategorieStructure(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      imageFileName: json['image'] as String?,
    );
  }
}
