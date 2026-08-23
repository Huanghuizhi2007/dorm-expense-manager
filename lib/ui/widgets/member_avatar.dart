import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/app_constants.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 36,
    this.seed = '',
  });

  final String name;
  final String? imageUrl;
  final double size;
  final String seed;

  @override
  Widget build(BuildContext context) {
    final color = avatarColorFor(seed.isEmpty ? name : seed);
    ImageProvider? image;
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      try {
        if (url.startsWith('data:')) {
          final commaIndex = url.indexOf(',');
          final encoded = commaIndex >= 0
              ? url.substring(commaIndex + 1)
              : url;
          image = MemoryImage(base64Decode(encoded));
        } else {
          image = NetworkImage(url);
        }
      } catch (_) {
        image = null;
      }
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withOpacity(0.16),
      foregroundImage: image,
      child: Text(
        initials(name),
        style: TextStyle(
          color: color,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
