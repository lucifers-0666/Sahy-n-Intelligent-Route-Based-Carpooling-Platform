import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../network/api_config.dart';
import '../storage/secure_storage_service.dart';

/// Compact telematics payload emitted by driver and received by passengers
class DriverLocationPayload {
  final String rideId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double heading;
  final double speed;
  final DateTime timestamp;

  const DriverLocationPayload({
    required this.rideId,
    required this.latitude,
    required this.longitude,
    this.accuracy = 10.0,
    required this.heading,
    required this.speed,
    required this.timestamp,
  });

  factory DriverLocationPayload.fromMap(Map<dynamic, dynamic> map) {
    return DriverLocationPayload(
      rideId: map['rideId']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? (map['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? (map['lng'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 10.0,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'rideId': rideId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'heading': heading,
        'speed': speed,
        'timestamp': timestamp.toIso8601String(),
      };
}

enum SocketConnectionState { connected, disconnected, reconnecting }

/// Singleton Socket.IO client for Sahyān real-time telematics
class SocketClient {
  SocketClient._internal();
  static final SocketClient instance = SocketClient._internal();

  io.Socket? _socket;
  final SecureStorageService _storage = SecureStorageService();

  /// Socket.IO server URL — strips /api/v1 suffix from the REST base URL
  static String get _socketUrl {
    final base = ApiConfig.defaultBaseUrl;
    return base.replaceFirst(RegExp(r'/api/v1$'), '');
  }

  bool get isConnected => _socket?.connected ?? false;

  // ── Stream controllers ────────────────────────────────────────────────────
  final Map<String, StreamController<DriverLocationPayload>> _locationControllers = {};
  final Map<String, StreamController<String>> _statusControllers = {};
  final _connectionStateController = StreamController<SocketConnectionState>.broadcast();

  Stream<SocketConnectionState> get connectionState => _connectionStateController.stream;

  // ── Bounded Offline Queue ─────────────────────────────────────────────────
  static const int _maxOfflineQueueSize = 10;
  final List<DriverLocationPayload> _offlineQueue = [];

  // ── Connect ───────────────────────────────────────────────────────────────

  /// Initialize and connect the socket with JWT auth handshake
  Future<void> connect({String? authToken}) async {
    if (_socket != null && _socket!.connected) return;

    _socket?.dispose();
    _socket = null;

    final token = authToken ?? await _storage.getToken();

    if (kDebugMode) {
      debugPrint('[SocketClient] Connecting to $_socketUrl');
    }

    final optionBuilder = io.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(double.infinity)
        .setReconnectionDelay(1000)
        .setReconnectionDelayMax(5000);

    if (token != null && token.isNotEmpty) {
      optionBuilder.setAuth({'token': token});
      optionBuilder.setExtraHeaders({'Authorization': 'Bearer $token'});
    }

    _socket = io.io(_socketUrl, optionBuilder.build());

    _socket!.onConnect((_) {
      debugPrint('[SocketClient] Connected (id: ${_socket!.id})');
      _connectionStateController.add(SocketConnectionState.connected);
      _flushOfflineQueue();
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketClient] Disconnected');
      _connectionStateController.add(SocketConnectionState.disconnected);
    });

    _socket!.onReconnect((_) {
      debugPrint('[SocketClient] Reconnecting');
      _connectionStateController.add(SocketConnectionState.reconnecting);
    });

    _socket!.onError((err) {
      debugPrint('[SocketClient] Error: $err');
    });

    _socket!.on('passenger_location_stream', (data) {
      try {
        final payload = DriverLocationPayload.fromMap(
          data is Map ? data : <dynamic, dynamic>{},
        );
        final ctrl = _locationControllers[payload.rideId];
        if (ctrl != null && !ctrl.isClosed) {
          ctrl.add(payload);
        }
      } catch (e) {
        debugPrint('[SocketClient] Failed to parse location payload: $e');
      }
    });

    _socket!.on('trip_status_changed', (data) {
      try {
        final rideId = data['rideId']?.toString() ?? '';
        final status = data['status']?.toString() ?? '';
        final ctrl = _statusControllers[rideId];
        if (ctrl != null && !ctrl.isClosed) {
          ctrl.add(status);
        }
      } catch (e) {
        debugPrint('[SocketClient] Failed to parse status event: $e');
      }
    });

    _socket!.connect();
  }

  // ── Room management ───────────────────────────────────────────────────────

  void joinRideRoom(String rideId, String userId, String role) {
    _ensureConnected();
    _socket?.emit('join_ride_room', {
      'rideId': rideId,
      'userId': userId,
      'role': role,
    });
    debugPrint('[SocketClient] Joined room ride:$rideId as $role');
  }

  void leaveRideRoom(String rideId) {
    _socket?.emit('leave_ride_room', {'rideId': rideId});
    debugPrint('[SocketClient] Left room ride:$rideId');
  }

  // ── Driver Telematics ─────────────────────────────────────────────────────

  void emitDriverLocation(DriverLocationPayload payload) {
    if (isConnected && _socket != null) {
      _socket!.emit('driver_location_update', payload.toMap());
    } else {
      // Queue bounded offline telemetry
      if (_offlineQueue.length >= _maxOfflineQueueSize) {
        _offlineQueue.removeAt(0); // Drop oldest
      }
      _offlineQueue.add(payload);
      _ensureConnected();
    }
  }

  void _flushOfflineQueue() {
    if (_offlineQueue.isEmpty || !isConnected || _socket == null) return;

    final now = DateTime.now();
    // Drop packets older than 60 seconds
    final freshPackets = _offlineQueue.where((p) {
      return now.difference(p.timestamp).inSeconds <= 60;
    }).toList();

    _offlineQueue.clear();

    // Transmit latest fix immediately
    if (freshPackets.isNotEmpty) {
      final latest = freshPackets.last;
      _socket!.emit('driver_location_update', latest.toMap());
    }
  }

  void emitTripStatus(String rideId, String status) {
    _socket?.emit('broadcast_trip_status', {'rideId': rideId, 'status': status});
  }

  // ── Passenger Listeners ───────────────────────────────────────────────────

  Stream<DriverLocationPayload> onDriverLocation(String rideId) {
    if (!_locationControllers.containsKey(rideId) || _locationControllers[rideId]!.isClosed) {
      _locationControllers[rideId] = StreamController<DriverLocationPayload>.broadcast();
    }
    return _locationControllers[rideId]!.stream;
  }

  Stream<String> onTripStatusChanged(String rideId) {
    if (!_statusControllers.containsKey(rideId) || _statusControllers[rideId]!.isClosed) {
      _statusControllers[rideId] = StreamController<String>.broadcast();
    }
    return _statusControllers[rideId]!.stream;
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _offlineQueue.clear();

    for (final ctrl in _locationControllers.values) {
      if (!ctrl.isClosed) ctrl.close();
    }
    _locationControllers.clear();

    for (final ctrl in _statusControllers.values) {
      if (!ctrl.isClosed) ctrl.close();
    }
    _statusControllers.clear();
  }

  void _ensureConnected() {
    if (_socket == null || !_socket!.connected) {
      connect();
    }
  }
}
