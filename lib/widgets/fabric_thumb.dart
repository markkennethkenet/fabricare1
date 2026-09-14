import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shows the captured photo if available, otherwise a soft gradient tile
/// with a fabric-appropriate icon — keeps history/profile cards looking
/// real even though this prototype has no backend image storage.
class FabricThumb extends StatelessWidget {
  final File? image;
  final String fabricType;
  final double size;
  final double radius;

  const FabricThumb({
    super.key,
    required this.image,
    required this.fabricType,
    this.size = 56,
    this.radius = 14,
  });

  static const _iconFor = {
    'Cotton': Icons.crop_square_rounded,
    'Silk': Icons.water_drop_outlined,
    'Denim': Icons.checkroom_outlined,
    'Polyester': Icons.layers_outlined,
    'Linen': Icons.texture_outlined,
    'Wool': Icons.ac_unit_outlined,
  };

  static const _colorFor = {
    'Cotton': Color(0xFFE7E0C9),
    'Silk': Color(0xFFE9D7DE),
    'Denim': Color(0xFFD6E0E8),
    'Polyester': Color(0xFFE3DDE9),
    'Linen': Color(0xFFEDE6D6),
    'Wool': Color(0xFFE3DCD2),
  };

  @override
  Widget build(BuildContext context) {
    final radii = BorderRadius.circular(radius);
    if (image != null) {
      return ClipRRect(
        borderRadius: radii,
        child: Image.file(image!, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _colorFor[fabricType] ?? AppColors.surfaceMuted,
        borderRadius: radii,
      ),
      child: Icon(
        _iconFor[fabricType] ?? Icons.checkroom_outlined,
        color: AppColors.ink.withValues(alpha: 0.55),
        size: size * 0.42,
      ),
    );
  }
}
