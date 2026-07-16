class PhotonPlace {
  final String displayName;
  final String name;
  final String? city;
  final String? state;
  final String? country;
  final String? postcode;
  final double latitude;
  final double longitude;

  PhotonPlace({
    required this.displayName,
    required this.name,
    this.city,
    this.state,
    this.country,
    this.postcode,
    required this.latitude,
    required this.longitude,
  });

  factory PhotonPlace.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? {};
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? [];

    final double lng = coordinates.isNotEmpty ? (coordinates[0] as num).toDouble() : 0.0;
    final double lat = coordinates.length > 1 ? (coordinates[1] as num).toDouble() : 0.0;

    final String name = properties['name'] as String? ?? '';
    final String? city = properties['city'] as String?;
    final String? state = properties['state'] as String?;
    final String? country = properties['country'] as String?;
    final String? postcode = properties['postcode'] as String?;

    // Build a nice display name
    final List<String> parts = [];
    if (name.isNotEmpty) parts.add(name);
    if (city != null && city.isNotEmpty && city != name) parts.add(city);
    if (state != null && state.isNotEmpty && state != city) parts.add(state);
    if (country != null && country.isNotEmpty) parts.add(country);
    if (postcode != null && postcode.isNotEmpty) parts.add(postcode);

    final displayName = parts.isEmpty ? 'Unknown Place' : parts.join(', ');

    return PhotonPlace(
      displayName: displayName,
      name: name,
      city: city,
      state: state,
      country: country,
      postcode: postcode,
      latitude: lat,
      longitude: lng,
    );
  }
}
