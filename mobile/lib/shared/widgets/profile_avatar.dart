import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    Key? key,
    required this.name,
    this.imageDataUrl,
    this.radius = 24,
  }) : super(key: key);

  final String name;
  final String? imageDataUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageBytes = _decodeImageData(imageDataUrl);
    final initials = _initialsForName(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF97CAD8),
      backgroundImage: imageBytes == null ? null : MemoryImage(imageBytes),
      child: imageBytes == null
          ? Text(
              initials,
              style: TextStyle(
                color: const Color(0xFF0A1628),
                fontSize: radius * 0.7,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }

  Uint8List? _decodeImageData(String? dataUrl) {
    if (dataUrl == null || dataUrl.isEmpty) {
      return null;
    }

    try {
      final raw = dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  String _initialsForName(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
