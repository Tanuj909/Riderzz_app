import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riderzz_app/core/network/api_constants.dart';
import 'package:riderzz_app/core/storage/secure_storage_service.dart';
import 'package:riderzz_app/features/user/home/data/models/booking_model.dart';
import 'package:riderzz_app/services/notification/local_notification_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class BroadcastResponse {
  final BookingModel booking;
  final int? expiresInSeconds;

  BroadcastResponse({required this.booking, this.expiresInSeconds});

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
    );
  }
}

class BroadcastSocketService {
  final SecureStorageService _storageService;
  StompClient? _client;
  final _broadcastController = StreamController<BroadcastResponse>.broadcast();

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

    if (token == null || role != 'DRIVER') {
      debugPrint(
        '[BroadcastSocketService] No token or user is not a DRIVER. Aborting socket connection.',
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
            _broadcastController.add(response);
            unawaited(
              LocalNotificationService.showBookingNotification(
                booking: response.booking,
              ),
            );
          } catch (e) {
            debugPrint("JSON Parse Error: $e");
            debugPrint(frame.body);
          }
        }
      },
    );
    debugPrint("Subscribed to /user/queue/broadcasts");
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
