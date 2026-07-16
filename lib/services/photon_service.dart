import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riderzz_app/models/photon_place.dart';

class PhotonService {
  final Dio _dio;

  PhotonService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://photon.komoot.io/api/',
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  Future<List<PhotonPlace>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final response = await _dio.get(
        '',
        queryParameters: {
          'q': query,
          'limit': 8,
          'lang': 'en',
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('features')) {
          final features = data['features'] as List<dynamic>;
          return features
              .map((item) => PhotonPlace.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('PhotonService Error: $e');
      return [];
    }
  }
}
