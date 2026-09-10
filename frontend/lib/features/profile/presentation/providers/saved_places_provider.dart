import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class SavedPlacesNotifier extends StateNotifier<List<SavedPlace>> {
  SavedPlacesNotifier()
    : super([
        const SavedPlace(
          id: 'place-1',
          label: 'Home',
          address: 'Navrangpura, Ahmedabad, Gujarat',
          landmark: 'Near Commerce Six Roads',
        ),
        const SavedPlace(
          id: 'place-2',
          label: 'Work',
          address: 'GIFT City Tower 1, Gandhinagar, Gujarat',
          landmark: 'Tech Zone Block 12',
        ),
      ]);

  void addPlace({
    required String label,
    required String address,
    String? landmark,
  }) {
    final newPlace = SavedPlace(
      id: 'place-${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      address: address,
      landmark: landmark,
    );
    state = [...state, newPlace];
  }

  void removePlace(String id) {
    state = state.where((p) => p.id != id).toList();
  }
}

final savedPlacesProvider =
    StateNotifierProvider<SavedPlacesNotifier, List<SavedPlace>>((ref) {
      return SavedPlacesNotifier();
    });
