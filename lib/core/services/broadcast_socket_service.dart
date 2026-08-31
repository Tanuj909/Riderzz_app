import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/services/notification_deduplicator.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/features/notification/data/models/notification_model.dart';
import 'package:riderzz_app/services/notification/local_notification_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class BroadcastResponse {
  final BookingModel booking;
    final String? notificationId;
  final int? expiresInSeconds;
  final String? title;
  final String? type;

  BroadcastResponse({
    required this.booking,
    this.expiresInSeconds,
    this.notificationId,
    this.title,
    this.type,
  });

factory BroadcastResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    final bookingJson = json['booking'] is Map<String, dynamic>
        ? json['booking'] as Map<String, dynamic>
        : data is List && data.isNotEmpty && data.first is Map
        ? Map<String, dynamic>.from(data.first as Map)
        : json;

    return BroadcastResponse(
      booking: BookingModel.fromJson(bookingJson),
      expiresInSeconds:
          json['expiresInSeconds'] as int? ??
          bookingJson['expiresInSeconds'] as int?,
      notificationId: json['notificationId']?.toString(),
      title: json['title'] as String?,
      type: json['type'] as String?,
    );
  }
}

class BroadcastSocketService {
  final SecureStorageService _storageService;
  StompClient? _client;
  final _broadcastController = StreamController<BroadcastResponse>.broadcast();
  final _notificationController = StreamController<NotificationModel>.broadcast();

  bool _isConnecting = false;
  bool _isConnected = false;

  // Singleton instance
  static BroadcastSocketService? _instance;

  BroadcastSocketService._internal(this._storageService);

  factory BroadcastSocketService(SecureStorageService storageService) {
    _instance ??= BroadcastSocketService._internal(storageService);
    return _instance!;
  }

  Stream<BroadcastResponse> get broadcasts => _broadcastController.stream;
  Stream<NotificationModel> get notifications => _notificationController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      debugPrint(
        '[BroadcastSocketService] Already connected or connecting. Skipping connect.',
      );
      return;
    }

    _isConnecting = true;
    final token = await _storageService.getToken();
    final role = await _storageService.getRole();

    if (token == null || (role != 'DRIVER' && role != 'CUSTOMER')) {
      debugPrint(
        '[BroadcastSocketService] No token or unauthorized role. Aborting socket connection.',
      );
      _isConnecting = false;
      return;
    }

    final base = ApiConstants.baseUrl;
    final restUri = Uri.parse(base);
    final sockJsEndpointUrl = Uri(
      scheme: restUri.scheme,
      host: restUri.host,
      port: restUri.hasPort ? restUri.port : null,
      path: '/ws/broadcast',
      queryParameters: {'token': token},
    ).toString();
    final wsUrl = Uri.parse(
      sockJsEndpointUrl,
    ).replace(scheme: restUri.scheme == 'https' ? 'wss' : 'ws').toString();

    debugPrint("========== WEBSOCKET ==========");
    debugPrint("REST Base URL: $base");
    debugPrint("Final WebSocket URL: $wsUrl");
    debugPrint("JWT Present: ${token.isNotEmpty}");
    debugPrint("SockJS URL: $sockJsEndpointUrl");

    _client = StompClient(
      config: StompConfig.sockJS(
        url: sockJsEndpointUrl,
        onConnect: (StompFrame frame) {
          debugPrint("WebSocket Connected");
          debugPrint("========== STOMP CONNECT ==========");
          debugPrint("Command: ${frame.command}");
          debugPrint("Headers: ${frame.headers}");
          debugPrint("Body: ${frame.body}");
          _onConnect(frame);
        },
        onDisconnect: (StompFrame frame) {
          debugPrint("========== STOMP DISCONNECT ==========");
          debugPrint("Command: ${frame.command}");
          debugPrint("Headers: ${frame.headers}");
          debugPrint("Body: ${frame.body}");
          _onDisconnect(frame);
        },
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
        onWebSocketError: (dynamic err) {
          debugPrint("========== WEBSOCKET ERROR ==========");
          debugPrint("Error: $err");
          debugPrint("Reconnecting in 5 seconds...");
          _isConnected = false;
          _isConnecting = false;
        },
        onStompError: (StompFrame frame) {
          debugPrint("========== STOMP ERROR ==========");
          debugPrint("Command: ${frame.command}");
          debugPrint("Headers: ${frame.headers}");
          debugPrint("Body: ${frame.body}");
          _isConnected = false;
          _isConnecting = false;
        },
        onUnhandledFrame: (StompFrame frame) {
          debugPrint("========== UNHANDLED FRAME ==========");
          debugPrint("Command: ${frame.command}");
          debugPrint("Headers: ${frame.headers}");
          debugPrint("Body: ${frame.body}");
        },
        onUnhandledReceipt: (StompFrame frame) {
          debugPrint("========== UNHANDLED RECEIPT ==========");
          debugPrint("Command: ${frame.command}");
          debugPrint("Headers: ${frame.headers}");
          debugPrint("Body: ${frame.body}");
        },
        onUnhandledMessage: (StompFrame frame) {
          debugPrint("========== UNHANDLED MESSAGE ==========");
          debugPrint("Command: ${frame.command}");
          debugPrint("Headers: ${frame.headers}");
          debugPrint("Body: ${frame.body}");
        },
        onDebugMessage: (String msg) {
          debugPrint("========== STOMP DEBUG ==========");
          debugPrint("Message: $msg");
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client?.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _isConnecting = false;

    const destination = '/user/queue/broadcasts';

    _client?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        debugPrint("========== BROADCAST RECEIVED ==========");
        debugPrint("Destination: ${frame.headers}");
        debugPrint("Payload: ${frame.body}");
        if (frame.body != null) {
          try {
            debugPrint("Parsing BroadcastResponse...");
            final jsonMap = json.decode(frame.body!) as Map<String, dynamic>;
            final response = BroadcastResponse.fromJson(jsonMap);
            debugPrint("Booking ID: ${response.booking.id}");
debugPrint(
  "🔵 WS notificationId: ${response.notificationId}",
);

            debugPrint("Booking ID: ${response.booking.id}");
            _broadcastController.add(response);
            
            if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
              final id = response.notificationId;
              debugPrint('[DEDUP] WS Broadcast notificationId: $id');
              
              final shouldShow = NotificationDeduplicator.shouldShow(
                notificationId: id,
                title: 'New Booking',
                body: 'Booking ID: ${response.booking.id}',
              );

              if (shouldShow) {
                debugPrint('[DEDUP] Showing notificationId: $id');
                _storageService.getRole().then((role) {
                  if (role == 'DRIVER' && response.type == 'BOOKING_BROADCAST') {
                    unawaited(
                      LocalNotificationService.showBookingNotification(
                        booking: response.booking,
                        notificationId: id,
                      ),
                    );
                  } else {
                    debugPrint('[WS] Skipped booking alert for role: $role, type: ${response.type}');
                  }
                });
              } else {
                debugPrint('[DEDUP] Suppressed duplicate notificationId: $id');
              }
            } else {
              debugPrint('[WS] Ignored broadcast notification display (App is not in foreground)');
            }
          } catch (e) {
            debugPrint("JSON Parse Error: $e");
            debugPrint(frame.body);
          }
        }
      },
    );
    
    debugPrint("Subscribed to /user/queue/broadcasts");

    _client?.subscribe(
      destination: '/user/queue/notifications',
      callback: (StompFrame frame) {
        debugPrint("========== NOTIFICATION RECEIVED ==========");
        debugPrint("Destination: ${frame.headers}");
        debugPrint("Payload: ${frame.body}");
        if (frame.body != null) {
          try {
            final jsonMap = json.decode(frame.body!) as Map<String, dynamic>;
            final notification = NotificationModel.fromJson(jsonMap);
            debugPrint("Notification ID: ${notification.id}");
            _notificationController.add(notification);
            
            if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
              final id = notification.notificationId;
              debugPrint('[DEDUP] WS General notificationId: $id');

              final shouldShow = NotificationDeduplicator.shouldShow(
                notificationId: id,
                title: notification.title,
                body: notification.message,
              );
              
              if (shouldShow) {
                debugPrint('[DEDUP] Showing notificationId: $id');
                
                int localId = notification.id;
                if (id != null && id.isNotEmpty) {
                  localId = LocalNotificationService.generateLocalId(id);
                  debugPrint('[LOCAL_ID] notificationId: $id');
                  debugPrint('[LOCAL_ID] localNotificationId: $localId');
                }
                
                unawaited(
                  LocalNotificationService.showGenericNotification(
                    id: localId,
                    title: notification.title,
                    body: notification.message,
                    payload: notification.actionUrl,
                  ),
                );
              } else {
                debugPrint('[DEDUP] Suppressed duplicate notificationId: $id');
              }
            } else {
              debugPrint('[WS] Ignored notification display (App is not in foreground)');
            }
          } catch (e) {
            debugPrint("Notification Parse Error: $e");
            debugPrint(frame.body);
          }
        }
      },
    );
    debugPrint("Subscribed to /user/queue/notifications");
  }

  void _onDisconnect(StompFrame frame) {
    _isConnected = false;
    _isConnecting = false;
  }

  void disconnect() {
    debugPrint("Disconnect requested.");
    _client?.deactivate();
    _client = null;
    _isConnected = false;
    _isConnecting = false;
  }
}
