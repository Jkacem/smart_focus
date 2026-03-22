import 'package:flutter/material.dart';

/// The textual description on the welcome screen.
class HomeTextSection extends StatelessWidget {
  const HomeTextSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'MEET ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const Text(
              'KAREN',
              style: TextStyle(
                color: Color.fromARGB(255, 12, 139, 212),
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Votre assistant intelligent',
          style: TextStyle(
            color: Color(0xFFE8D5F2),
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Améliorer votre concentration et bien-être',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFFB8A5D2), fontSize: 14),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
