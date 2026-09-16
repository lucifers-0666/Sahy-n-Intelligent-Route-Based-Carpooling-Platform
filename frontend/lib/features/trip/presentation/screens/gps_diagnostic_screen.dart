import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/location/data/providers/geolocator_provider.dart';
import '../../../../core/location/domain/gps_provider.dart';
import '../../../../core/location/domain/location_accuracy_policy.dart';
import '../../../../core/location/domain/models/location_point.dart';
import '../../../../core/location/services/gps_diagnostic_service.dart';
import '../../../../core/location/services/location_preprocessor.dart';

class GpsDiagnosticScreen extends StatefulWidget {
  final GpsProvider? customProvider;

  const GpsDiagnosticScreen({super.key, this.customProvider});

  @override
  State<GpsDiagnosticScreen> createState() => _GpsDiagnosticScreenState();
}

class _GpsDiagnosticScreenState extends State<GpsDiagnosticScreen> {
  late GpsProvider _provider;
  late GpsDiagnosticService _diagnosticService;
  late LocationPreprocessor _preprocessor;

  GpsDiagnosticResult? _diagnosticResult;
  LocationPoint? _latestRawPoint;
  LocationPoint? _latestSmoothedPoint;
  StreamSubscription<LocationPoint>? _streamSub;
  bool _isRunningAudit = false;

  @override
  void initState() {
    super.initState();
    _provider = widget.customProvider ?? GeolocatorProvider();
    _diagnosticService = GpsDiagnosticService(_provider);
    _preprocessor = LocationPreprocessor();

    _runAudit();
    _startStream();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  Future<void> _runAudit() async {
    setState(() => _isRunningAudit = true);
    final result = await _diagnosticService.runDiagnostics();
    if (!mounted) return;
    setState(() {
      _diagnosticResult = result;
      _isRunningAudit = false;
    });
  }

  void _startStream() {
    _streamSub?.cancel();
    _streamSub = _provider.positionStream.listen((point) {
      if (!mounted) return;
      final smoothed = _preprocessor.process(point);
      setState(() {
        _latestRawPoint = point;
        _latestSmoothedPoint = smoothed;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _diagnosticResult;

    return Scaffold(
      backgroundColor: SahyanColors.canvas,
      appBar: AppBar(
        title: const Text(
          'GPS Diagnostic Console',
          style: TextStyle(
            color: SahyanColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: SahyanColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: SahyanColors.textMain),
        actions: [
          IconButton(
            icon: _isRunningAudit
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isRunningAudit ? null : _runAudit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Diagnostic Status Banner ──────────────────────────────────
            _buildStatusBanner(result),
            const SizedBox(height: 16),

            // ── Hardware & Permission Status ─────────────────────────────
            _buildSectionHeader('Provider & Permissions'),
            const SizedBox(height: 8),
            _buildCard([
              _buildRow('Location Services', result?.locationServicesEnabled == true ? 'Enabled' : 'Disabled'),
              _buildRow('Permission State', result?.permissionStatus.name.toUpperCase() ?? 'CHECKING'),
              _buildRow('Provider Type', _provider.runtimeType.toString()),
            ]),
            const SizedBox(height: 16),

            // ── Live Raw Telemetry ────────────────────────────────────────
            _buildSectionHeader('Live Raw Coordinate Stream'),
            const SizedBox(height: 8),
            _buildCard([
              _buildRow('Latitude', _latestRawPoint?.latitude.toStringAsFixed(6) ?? result?.lastPosition?.latitude.toStringAsFixed(6) ?? 'Awaiting Fix'),
              _buildRow('Longitude', _latestRawPoint?.longitude.toStringAsFixed(6) ?? result?.lastPosition?.longitude.toStringAsFixed(6) ?? 'Awaiting Fix'),
              _buildRow('Accuracy', _latestRawPoint != null ? '${_latestRawPoint!.accuracy.toStringAsFixed(1)} m' : (result?.lastPosition != null ? '${result!.lastPosition!.accuracy.toStringAsFixed(1)} m' : '--')),
              _buildRow('Accuracy Tier', _latestRawPoint != null ? LocationAccuracyPolicy.getTierLabel(LocationAccuracyPolicy.classify(_latestRawPoint!.accuracy)) : (result?.lastPosition != null ? LocationAccuracyPolicy.getTierLabel(LocationAccuracyPolicy.classify(result!.lastPosition!.accuracy)) : '--')),
              _buildRow('Speed', _latestRawPoint != null ? '${_latestRawPoint!.speed.toStringAsFixed(1)} km/h' : (result?.lastPosition != null ? '${result!.lastPosition!.speed.toStringAsFixed(1)} km/h' : '--')),
              _buildRow('Heading', _latestRawPoint != null ? '${_latestRawPoint!.heading.toStringAsFixed(1)} deg' : (result?.lastPosition != null ? '${result!.lastPosition!.heading.toStringAsFixed(1)} deg' : '--')),
              _buildRow('Timestamp', _latestRawPoint?.timestamp.toIso8601String() ?? result?.lastPosition?.timestamp.toIso8601String() ?? '--'),
            ]),
            const SizedBox(height: 16),

            // ── Preprocessed & Smoothed Telemetry ─────────────────────────
            _buildSectionHeader('Normalized Preprocessor Output'),
            const SizedBox(height: 8),
            _buildCard([
              _buildRow('Smoothed Lat', _latestSmoothedPoint?.latitude.toStringAsFixed(6) ?? '--'),
              _buildRow('Smoothed Lng', _latestSmoothedPoint?.longitude.toStringAsFixed(6) ?? '--'),
              _buildRow('Smoothed Heading', _latestSmoothedPoint != null ? '${_latestSmoothedPoint!.heading.toStringAsFixed(1)} deg' : '--'),
              _buildRow('Outlier Status', _latestSmoothedPoint != null ? 'Passed Sanity Check' : 'Rejected / Awaiting'),
            ]),
            const SizedBox(height: 24),

            // ── System Actions ────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SahyanColors.primaryDark,
                      side: const BorderSide(color: SahyanColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    label: const Text('Open App Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => Geolocator.openAppSettings(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SahyanColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text('Location Settings', style: TextStyle(fontWeight: FontWeight.w600)),
                    onPressed: () => Geolocator.openLocationSettings(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(GpsDiagnosticResult? result) {
    final isHealthy = result?.isHealthy ?? false;
    final bgColor = isHealthy
        ? SahyanColors.primaryMint.withValues(alpha: 0.12)
        : const Color(0xFFFEE2E2);
    final borderColor = isHealthy
        ? SahyanColors.primaryMint
        : const Color(0xFFEF4444);
    final textColor = isHealthy
        ? SahyanColors.primaryDark
        : const Color(0xFF991B1B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            color: textColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'GPS Subsystem Healthy' : 'GPS Diagnostics Warning',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result?.statusSummary ?? 'Initializing diagnostic sweep...',
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: SahyanColors.textMuted,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: SahyanColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SahyanColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: List.generate(rows.length, (index) {
          return Column(
            children: [
              rows[index],
              if (index < rows.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16, color: SahyanColors.border),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: SahyanColors.textMuted,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: SahyanColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}
