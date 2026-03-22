import 'package:flutter/material.dart';

/// The textual description on the welcome screen.
class LoginTextSection extends StatelessWidget {
  const LoginTextSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Smart ',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'SF Pro Black',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const Text(
              'Focus',
              style: TextStyle(
                color: Color(0xFF97CAD8), // Match theme light blue
                fontFamily: 'SF Pro Black',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Votre assistant intelligent',
          style: TextStyle(
            color: Color(0xFFE8D5F2),
            fontFamily: 'SF Pro',
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Transformez votre concentration en super-pouvoir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontFamily: 'SF Pro',
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
