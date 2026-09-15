import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../network/api_config.dart';

/// Payload emitted by the driver and received by passengers.
class DriverLocationPayload {
  final String rideId;
  final double latitude;
  final double longitude;
  final double heading;
  final double speed;
  final DateTime timestamp;

  const DriverLocationPayload({
    required this.rideId,
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.speed,
    required this.timestamp,
  });

  factory DriverLocationPayload.fromMap(Map<dynamic, dynamic> map) {
    return DriverLocationPayload(
      rideId: map['rideId']?.toString() ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
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
        'heading': heading,
        'speed': speed,
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Singleton Socket.IO client for Sahyān real-time telematics.
///
/// Usage:
/// ```dart
/// final client = SocketClient.instance;
/// client.connect();
/// client.joinRideRoom(rideId, userId, 'passenger');
/// client.onDriverLocation(rideId).listen((payload) { ... });
/// ```
class SocketClient {
  SocketClient._internal();
  static final SocketClient instance = SocketClient._internal();

  io.Socket? _socket;

  /// Socket.IO server URL — strips /api/v1 suffix from the REST base URL.
  static String get _socketUrl {
    final base = ApiConfig.defaultBaseUrl;
    return base.replaceFirst(RegExp(r'/api/v1$'), '');
  }

  /// Whether the socket is currently connected.
  bool get isConnected => _socket?.connected ?? false;

  // ── Stream controllers ────────────────────────────────────────────────────
  final Map<String, StreamController<DriverLocationPayload>> _locationControllers =
      {};
  final Map<String, StreamController<String>> _statusControllers = {};

  // ── Connection state ──────────────────────────────────────────────────────
  final _connectionStateController =
      StreamController<SocketConnectionState>.broadcast();

  Stream<SocketConnectionState> get connectionState =>
      _connectionStateController.stream;

  // ── Connect ───────────────────────────────────────────────────────────────

  /// Initialise and connect the socket. Safe to call multiple times.
  void connect() {
    if (_socket != null && _socket!.connected) return;

    _socket?.dispose();
    _socket = null;

    if (kDebugMode) {
      debugPrint('[SocketClient] Connecting to $_socketUrl');
    }

    _socket = io.io(
      _socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(double.infinity)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .build(),
    );

    _socket!.onConnect((_) {
      debugPrint('[SocketClient] Connected (id: ${_socket!.id})');
      _connectionStateController.add(SocketConnectionState.connected);
    });

    _socket!.onDisconnect((_) {
      debugPrint('[SocketClient] Disconnected');
      _connectionStateController.add(SocketConnectionState.disconnected);
    });

    _socket!.onReconnect((_) {
      debugPrint('[SocketClient] Reconnecting…');
      _connectionStateController.add(SocketConnectionState.reconnecting);
    });

    _socket!.onError((err) {
      debugPrint('[SocketClient] Error: $err');
    });

    // Global passenger_location_stream listener — routes to the correct controller
    _socket!.on('passenger_location_stream', (data) {
      try {
        final payload = DriverLocationPayload.fromMap(
            data is Map ? data : <dynamic, dynamic>{});
        final ctrl = _locationControllers[payload.rideId];
        if (ctrl != null && !ctrl.isClosed) {
          ctrl.add(payload);
        }
      } catch (e) {
        debugPrint('[SocketClient] Failed to parse location payload: $e');
      }
    });

    // Trip status changed
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

  /// Join a ride room as `role` ('driver' | 'passenger').
  void joinRideRoom(String rideId, String userId, String role) {
    _ensureConnected();
    _socket!.emit('join_ride_room', {
      'rideId': rideId,
      'userId': userId,
      'role': role,
    });
    debugPrint('[SocketClient] Joined room ride:$rideId as $role');
  }

  /// Leave a ride room (called on trip completion or screen dispose).
  void leaveRideRoom(String rideId) {
    _socket?.emit('leave_ride_room', {'rideId': rideId});
    debugPrint('[SocketClient] Left room ride:$rideId');
  }

  // ── Driver emit ───────────────────────────────────────────────────────────

  /// Emit a GPS location update as the driver.
  void emitDriverLocation(DriverLocationPayload payload) {
    _ensureConnected();
    _socket!.emit('driver_location_update', payload.toMap());
  }

  /// Broadcast a trip status change (driver only).
  void emitTripStatus(String rideId, String status) {
    _socket?.emit('broadcast_trip_status', {'rideId': rideId, 'status': status});
  }

  // ── Passenger streams ─────────────────────────────────────────────────────

  /// Returns a broadcast stream of real-time driver location payloads for
  /// a specific ride. Multiple listeners allowed (map screen + ETA widget).
  Stream<DriverLocationPayload> onDriverLocation(String rideId) {
    if (!_locationControllers.containsKey(rideId) ||
        _locationControllers[rideId]!.isClosed) {
      _locationControllers[rideId] =
          StreamController<DriverLocationPayload>.broadcast();
    }
    return _locationControllers[rideId]!.stream;
  }

  /// Returns a broadcast stream of trip status strings ('boarding', 'active',
  /// 'completed', 'cancelled') for a specific ride.
  Stream<String> onTripStatusChanged(String rideId) {
    if (!_statusControllers.containsKey(rideId) ||
        _statusControllers[rideId]!.isClosed) {
      _statusControllers[rideId] = StreamController<String>.broadcast();
    }
    return _statusControllers[rideId]!.stream;
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    for (final ctrl in _locationControllers.values) {
      if (!ctrl.isClosed) ctrl.close();
    }
    _locationControllers.clear();
    for (final ctrl in _statusControllers.values) {
      if (!ctrl.isClosed) ctrl.close();
    }
    _statusControllers.clear();
    debugPrint('[SocketClient] Disconnected and disposed.');
  }

  void _ensureConnected() {
    if (_socket == null || !_socket!.connected) {
      connect();
    }
  }
}

enum SocketConnectionState { connected, disconnected, reconnecting }
