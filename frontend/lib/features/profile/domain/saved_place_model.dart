/// Domain model for passenger and driver saved commute locations.
class SavedPlace {
  final String id;
  final String label; // 'Home', 'Work', 'College', 'Custom'
  final String address;
  final String? landmark;

  const SavedPlace({
    required this.id,
    required this.label,
    required this.address,
    this.landmark,
  });
}
