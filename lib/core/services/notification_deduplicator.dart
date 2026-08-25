/// Helper to prevent showing duplicate notifications from WebSocket and FCM 
/// in the foreground.
class NotificationDeduplicator {
  static final List<String> _recentKeys = [];
  static const int _maxCacheSize = 50;

  /// Checks if a notification with this notificationId (or title/body fallback) was recently shown.
  /// If not, marks it as shown and returns true.
  static bool shouldShow({
    String? notificationId,
    String? title,
    String? body,
  }) {
    String key;
    
    if (notificationId != null && notificationId.isNotEmpty) {
      key = notificationId;
    } else {
      if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
        return true; // Cannot deduplicate empty notifications without ID
      }
      key = '${title ?? ''}|${body ?? ''}';
    }
    
    if (_recentKeys.contains(key)) {
      return false; // Already shown recently
    }
    
    _recentKeys.add(key);
    
    if (_recentKeys.length > _maxCacheSize) {
      _recentKeys.removeAt(0); // Maintain bounded cache size
    }
    
    return true;
  }
}
