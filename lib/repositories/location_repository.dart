import 'package:riderzz_app/models/photon_place.dart';
import 'package:riderzz_app/services/photon_service.dart';

class LocationRepository {
  final PhotonService _photonService;

  LocationRepository({PhotonService? photonService})
      : _photonService = photonService ?? PhotonService();

  Future<List<PhotonPlace>> search(String query) async {
    return await _photonService.searchPlaces(query);
  }
}
