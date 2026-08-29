/// Google Place model representing an autocomplete suggestion and its details.
class GooglePlace {
  final String placeId;
  final String displayName;
  final String name;
  final String? formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? postalCode;
  final String? city;
  final String? state;
  final String? country;
  final String? street;

  GooglePlace({
    required this.placeId,
    required this.displayName,
    required this.name,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.postalCode,
    this.city,
    this.state,
    this.country,
    this.street,
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

    String? postalCode;
    String? city;
    String? state;
    String? country;
    String? street;

    final addressComponents = json['addressComponents'] as List<dynamic>? ?? [];
    for (var component in addressComponents) {
      final types = (component['types'] as List<dynamic>? ?? []).cast<String>();
      final longText = component['longText'] as String? ?? '';
      
      if (types.contains('postal_code')) {
        postalCode = longText;
      } else if (types.contains('locality') || types.contains('administrative_area_level_2')) {
        city ??= longText; // locality preferred, but fallback to admin_area_2 if seen first (or vice versa? actually we just set if null)
      } else if (types.contains('administrative_area_level_1')) {
        state = longText;
      } else if (types.contains('country')) {
        country = longText;
      } else if (types.contains('route') || types.contains('street_address')) {
        street = longText;
      } else if (types.contains('sublocality') && street == null) {
        street = longText; // fallback to sublocality if no route
      }
    }

    return GooglePlace(
      placeId: placeId,
      displayName: formattedAddress.isNotEmpty ? formattedAddress : name,
      name: name,
      formattedAddress: formattedAddress,
      latitude: latitude,
      longitude: longitude,
      postalCode: postalCode,
      city: city,
      state: state,
      country: country,
      street: street,
    );
  }
}
