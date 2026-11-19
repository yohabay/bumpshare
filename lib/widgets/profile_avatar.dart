import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/profile.dart';
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 72,
    this.ringColor,
    this.ringWidth = 2,
    this.backgroundColor,
    this.foregroundColor,
  });
  final Profile profile;
  final double size;
  final Color? ringColor;
  final double ringWidth;
  final Color? backgroundColor;
  final Color? foregroundColor;
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final Uint8List? bytes = _decode(profile.photo);
    final String initial =
        profile.name.trim().isEmpty ? '?' : profile.name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(ringWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: ringColor == null
            ? null
            : Border.all(color: ringColor!, width: ringWidth),
      ),
      child: CircleAvatar(
        backgroundColor: backgroundColor ?? colors.primaryContainer,
        foregroundImage: bytes == null ? null : MemoryImage(bytes),
        child: bytes == null
            ? Text(
                initial,
                style: TextStyle(
                  color: foregroundColor ?? colors.onPrimaryContainer,
                  fontSize: size * 0.42,
                  fontWeight: FontWeight.w700,
                ),
              )
            : null,
      ),
    );
  }
  static Uint8List? _decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }
}
