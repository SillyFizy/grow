class PlantCategory {
  final String id;
  final String title;
  final String imagePath;
  final String? description;

  const PlantCategory({
    required this.id,
    required this.title,
    required this.imagePath,
    this.description,
  });
}
