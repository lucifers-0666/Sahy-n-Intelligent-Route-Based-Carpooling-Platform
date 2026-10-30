import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/utils/profile_image_helper.dart';

/// Modal dialog providing interactive crop, rotate, zoom, and size adjustments
/// for custom profile photos before uploading.
class AvatarCropDialog extends StatefulWidget {
  final Uint8List imageBytes;
  final String userName;

  const AvatarCropDialog({
    super.key,
    required this.imageBytes,
    required this.userName,
  });

  static Future<String?> show(
    BuildContext context, {
    required Uint8List imageBytes,
    required String userName,
  }) {
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AvatarCropDialog(
        imageBytes: imageBytes,
        userName: userName,
      ),
    );
  }

  @override
  State<AvatarCropDialog> createState() => _AvatarCropDialogState();
}

class _AvatarCropDialogState extends State<AvatarCropDialog> {
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;
  int _rotationDegrees = 0;
  int _targetSize = 300; // 300x300 or 600x600
  bool _isCircleFrame = true;
  bool _isProcessing = false;

  void _rotateClockwise() {
    setState(() {
      _rotationDegrees = (_rotationDegrees + 90) % 360;
    });
  }

  void _resetAdjustments() {
    setState(() {
      _scale = 1.0;
      _panOffset = Offset.zero;
      _rotationDegrees = 0;
    });
  }

  Future<void> _handleConfirmCrop() async {
    setState(() => _isProcessing = true);

    try {
      final settings = CropSettings(
        targetSize: _targetSize,
        scale: _scale,
        panOffset: _panOffset,
        rotationDegrees: _rotationDegrees,
        isCircleFrame: _isCircleFrame,
      );

      final croppedDataUri = await processAndCropImageBytes(
        rawBytes: widget.imageBytes,
        settings: settings,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (croppedDataUri != null && croppedDataUri.isNotEmpty) {
        Navigator.of(context).pop(croppedDataUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to process image. Please try another photo.'),
            backgroundColor: AppColors.mutedRust,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image processing error: $e'),
          backgroundColor: AppColors.mutedRust,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double cropBoxSize = 250.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.25),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: AppColors.white,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AppColors.textSecondary,
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crop & Adjust Profile Photo',
                      style: AppTypography.screenTitle.copyWith(fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _isProcessing ? null : _handleConfirmCrop,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryForest,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      _isProcessing ? 'Processing...' : 'Set Photo',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryForest,
                    ),
                  ),
                ],
              ),
            ),

            // Crop Viewport with Gesture Listener
            Container(
              color: const Color(0xFF111816),
              height: 280,
              width: double.infinity,
              alignment: Alignment.center,
              child: GestureDetector(
                onScaleUpdate: (details) {
                  if (_isProcessing) return;
                  setState(() {
                    if (details.scale != 1.0) {
                      _scale = (_scale * details.scale).clamp(1.0, 3.5);
                    }
                    if (details.focalPointDelta != Offset.zero) {
                      final dx = _panOffset.dx + (details.focalPointDelta.dx / (cropBoxSize * 0.5));
                      final dy = _panOffset.dy + (details.focalPointDelta.dy / (cropBoxSize * 0.5));
                      _panOffset = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
                    }
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Transformed image
                    SizedBox(
                      width: cropBoxSize,
                      height: cropBoxSize,
                      child: ClipRect(
                        child: Transform.rotate(
                          angle: (_rotationDegrees * math.pi) / 180,
                          child: Transform.translate(
                            offset: Offset(
                              _panOffset.dx * (cropBoxSize * 0.25),
                              _panOffset.dy * (cropBoxSize * 0.25),
                            ),
                            child: Transform.scale(
                              scale: _scale,
                              child: Image.memory(
                                widget.imageBytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Mask Overlay
                    IgnorePointer(
                      child: CustomPaint(
                        size: const Size(cropBoxSize, cropBoxSize),
                        painter: _CropOverlayPainter(
                          isCircle: _isCircleFrame,
                          borderColor: AppColors.primaryForest,
                        ),
                      ),
                    ),

                    // Drag prompt hint
                    Positioned(
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(0, 0, 0, 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app_outlined, size: 12, color: Colors.white70),
                            SizedBox(width: 4),
                            Text(
                              'Drag to reposition • Pinch to zoom',
                              style: TextStyle(color: Colors.white70, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Controls Area
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Zoom Slider Row
                  Row(
                    children: [
                      const Icon(Icons.zoom_out_rounded, size: 18, color: AppColors.textSecondary),
                      Expanded(
                        child: Slider(
                          value: _scale,
                          min: 1.0,
                          max: 3.0,
                          divisions: 20,
                          activeColor: AppColors.primaryForest,
                          inactiveColor: AppColors.border,
                          onChanged: _isProcessing
                              ? null
                              : (val) {
                                  setState(() => _scale = val);
                                },
                        ),
                      ),
                      const Icon(Icons.zoom_in_rounded, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '${_scale.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.deepEmerald,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Resolution & Aspect Framing Options
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Output Size Selection
                      Row(
                        children: [
                          _buildOptionChip(
                            label: '300px',
                            isSelected: _targetSize == 300,
                            tooltip: 'Standard (300x300) - Lightweight',
                            onTap: () => setState(() => _targetSize = 300),
                          ),
                          const SizedBox(width: 6),
                          _buildOptionChip(
                            label: '600px',
                            isSelected: _targetSize == 600,
                            tooltip: 'High Res (600x600) - Crisp detail',
                            onTap: () => setState(() => _targetSize = 600),
                          ),
                        ],
                      ),

                      // Frame Shape Toggle
                      Row(
                        children: [
                          _buildIconOption(
                            icon: Icons.circle_outlined,
                            isSelected: _isCircleFrame,
                            tooltip: 'Circular profile frame',
                            onTap: () => setState(() => _isCircleFrame = true),
                          ),
                          const SizedBox(width: 6),
                          _buildIconOption(
                            icon: Icons.crop_square_rounded,
                            isSelected: !_isCircleFrame,
                            tooltip: 'Square frame',
                            onTap: () => setState(() => _isCircleFrame = false),
                          ),
                        ],
                      ),

                      // Actions: Rotate & Reset
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.rotate_right_rounded, size: 20),
                            tooltip: 'Rotate 90 degrees',
                            color: AppColors.primaryForest,
                            onPressed: _isProcessing ? null : _rotateClockwise,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                            tooltip: 'Reset adjustments',
                            color: AppColors.textSecondary,
                            onPressed: _isProcessing ? null : _resetAdjustments,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionChip({
    required String label,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.softMint : AppColors.warmBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryForest : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? AppColors.primaryForest : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconOption({
    required IconData icon,
    required bool isSelected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.softMint : AppColors.warmBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primaryForest : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: isSelected ? AppColors.primaryForest : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Custom painter for semi-transparent crop mask and target outline.
class _CropOverlayPainter extends CustomPainter {
  final bool isCircle;
  final Color borderColor;

  _CropOverlayPainter({
    required this.isCircle,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBorder = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Offset.zero & size;

    if (isCircle) {
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2,
        paintBorder,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        paintBorder,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) {
    return oldDelegate.isCircle != isCircle || oldDelegate.borderColor != borderColor;
  }
}
