import 'package:flutter/material.dart';
class BumpShareLogo extends StatelessWidget {
  const BumpShareLogo({super.key, this.size = 96.0, this.showIcon = true});
  final double size;
  final bool showIcon;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon)
          Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Color(0xFF6D28D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nfc, size: 48, color: Colors.white),
          ),
        Text(
          'BumpShare',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
