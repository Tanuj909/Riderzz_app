import 'package:jwt_decoder/jwt_decoder.dart';

class JwtHelper {
  /// Checks whether a given JWT token is expired.
  static bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      // If the token is invalid or cannot be decoded, treat it as expired/invalid
      return true;
    }
  }
}
