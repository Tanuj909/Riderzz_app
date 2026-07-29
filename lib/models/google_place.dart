/// Google Place model representing an autocomplete suggestion and its details.
class GooglePlace {
  final String placeId;
  final String displayName;
  final String name;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;

  GooglePlace({
    required this.placeId,
    required this.displayName,
    required this.name,
    this.formattedAddress,
    this.latitude,
    this.longitude,
  });

  /// Create a GooglePlace from an autocomplete suggestion JSON.
  factory GooglePlace.fromAutocompleteSuggestion(Map<String, dynamic> json) {
    final placePrediction = json['placePrediction'] as Map<String, dynamic>? ?? {};
    final placeId = placePrediction['placeId'] as String? ?? '';
    final textObj = placePrediction['text'] as Map<String, dynamic>? ?? {};
    final fullText = textObj['text'] as String? ?? '';

    // Extract short name (first part before comma)
    final name = fullText.contains(',') ? fullText.split(',').first.trim() : fullText;

    return GooglePlace(
      placeId: placeId,
      displayName: fullText,
      name: name,
    );
  }

  /// Create a GooglePlace with full details from the Place Details API response.
  factory GooglePlace.fromPlaceDetails(Map<String, dynamic> json) {
    final placeId = json['id'] as String? ?? '';
    final formattedAddress = json['formattedAddress'] as String? ?? '';
    final displayNameObj = json['displayName'] as Map<String, dynamic>? ?? {};
    final name = displayNameObj['text'] as String? ?? '';
    final locationObj = json['location'] as Map<String, dynamic>? ?? {};
    final latitude = (locationObj['latitude'] as num?)?.toDouble();
    final longitude = (locationObj['longitude'] as num?)?.toDouble();

    return GooglePlace(
      placeId: placeId,
      displayName: formattedAddress.isNotEmpty ? formattedAddress : name,
      name: name,
      formattedAddress: formattedAddress,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
