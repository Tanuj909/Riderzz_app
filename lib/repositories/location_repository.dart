// ========================================================================
// COMMENTED OUT: Photon-based location repository
// ========================================================================
// import 'package:riderzz_app/models/photon_place.dart';
// import 'package:riderzz_app/services/photon_service.dart';
//
// class LocationRepository {
//   final PhotonService _photonService;
//
//   LocationRepository({PhotonService? photonService})
//       : _photonService = photonService ?? PhotonService();
//
//   Future<List<PhotonPlace>> search(String query) async {
//     return await _photonService.searchPlaces(query);
//   }
// }

import 'package:riderzz_app/models/google_place.dart';
import 'package:riderzz_app/services/google_places_service.dart';

class LocationRepository {
  final GooglePlacesService _googlePlacesService;

  LocationRepository({GooglePlacesService? googlePlacesService})
      : _googlePlacesService = googlePlacesService ?? GooglePlacesService();

  Future<List<GooglePlace>> search(String query) async {
    return await _googlePlacesService.searchPlaces(query);
  }

  Future<GooglePlace?> getPlaceDetails(String placeId) async {
    return await _googlePlacesService.getPlaceDetails(placeId);
  }
}
