import 'package:flutter/material.dart';

class CoverView extends StatelessWidget {
  const CoverView({
    super.key,
    required this.url,
    this.width = 72,
    this.height = 104,
    this.radius = 12,
  });

  final String? url;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: url == null || url!.trim().isEmpty
          ? _placeholder()
          : Image.network(
              url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            ),
    );
  }

  Widget _placeholder() => Container(
        width: width,
        height: height,
        color: Colors.grey.withOpacity(0.18),
        alignment: Alignment.center,
        child: Icon(
          Icons.menu_book,
          size: 32,
          color: Colors.grey.withOpacity(0.65),
        ),
      );
}
