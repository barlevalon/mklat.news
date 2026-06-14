import '../data/models/saved_location.dart';

List<SavedLocation> normalizeSavedLocations(List<SavedLocation> locations) {
  if (locations.isEmpty) return [];

  final primaryIndex = locations.indexWhere((location) => location.isPrimary);
  final normalizedPrimaryIndex = primaryIndex == -1 ? 0 : primaryIndex;

  return [
    for (var i = 0; i < locations.length; i++)
      locations[i].isPrimary == (i == normalizedPrimaryIndex)
          ? locations[i]
          : locations[i].copyWith(isPrimary: i == normalizedPrimaryIndex),
  ];
}
