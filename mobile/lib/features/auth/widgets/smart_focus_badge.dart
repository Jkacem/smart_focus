import 'package:flutter/material.dart';

/// A small badge shown at the top of the welcome screen.
class SmartFocusBadge extends StatelessWidget {
  const SmartFocusBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF97CAD8).withOpacity(0.3),
        border: Border.all(color: const Color(0xFF97CAD8).withOpacity(0.6)),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'SMART FOCUS',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
