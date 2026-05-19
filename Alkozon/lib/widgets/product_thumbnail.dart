import 'package:flutter/material.dart';

import '../services/product_image_resolver.dart';

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    required this.productNames,
    this.size = 80,
    this.borderRadius = 12,
    this.accentColor = Colors.green,
    this.fallbackIcon = Icons.shopping_bag_outlined,
  });

  final Iterable<String> productNames;
  final double size;
  final double borderRadius;
  final Color accentColor;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final imagePath = ProductImageResolver.findAssetForNames(productNames);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imagePath != null
            ? Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: size,
                height: size,
                errorBuilder: (_, __, ___) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Icon(
      fallbackIcon,
      color: accentColor,
      size: size * 0.42,
    );
  }
}
