import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riderzz_app/models/google_place.dart';

class GooglePlacesService {
  final Dio _dio;
  final String _apiKey;

  GooglePlacesService({Dio? dio, String? apiKey})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            ),
        _apiKey = apiKey ?? (dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '');

  /// Autocomplete search with region restriction to Delhi-NCR.
  Future<List<GooglePlace>> searchPlaces(String query) async {
    if (query.trim().isEmpty || _apiKey.isEmpty) {
      return [];
    }

    try {
      final response = await _dio.post(
        'https://places.googleapis.com/v1/places:autocomplete',
        data: {
          'input': query,
          'locationRestriction': {
            'rectangle': {
              'low': {
                'latitude': 28.20,
                'longitude': 76.80,
              },
              'high': {
                'latitude': 28.95,
                'longitude': 77.70,
              },
            },
          },
          'includedRegionCodes': ['in'],
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask':
                'suggestions.placePrediction.placeId,suggestions.placePrediction.text',
          },
        ),
      );

      debugPrint(
          'GooglePlacesService: Status ${response.statusCode}, suggestions count: ${(response.data is Map && response.data.containsKey('suggestions')) ? (response.data['suggestions'] as List).length : 'N/A'}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('suggestions')) {
          final suggestions = data['suggestions'] as List<dynamic>;
          return suggestions
              .map((item) => GooglePlace.fromAutocompleteSuggestion(
                  item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('GooglePlacesService Autocomplete Error: $e');
      return [];
    }
  }

  /// Fetch full place details (lat/lng, formatted address) by placeId.
  Future<GooglePlace?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty || _apiKey.isEmpty) {
      return null;
    }

    try {
      final response = await _dio.get(
        'https://places.googleapis.com/v1/places/$placeId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _apiKey,
            'X-Goog-FieldMask':
                'id,displayName,formattedAddress,location,addressComponents',
          },
        ),
      );

      debugPrint(
          'GooglePlacesService PlaceDetails: Status ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        return GooglePlace.fromPlaceDetails(
            response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('GooglePlacesService PlaceDetails Error: $e');
      return null;
    }
  }
}
