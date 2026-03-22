import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/shared/widgets/custom_button.dart';

/// A rounded "Continue" button used on the welcome screen.
/// Navigates to the login screen on tap.
class LoginButtons extends StatelessWidget {
  const LoginButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: CustomButton(
            text: 'Se connecter',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            backgroundColor: const Color(0xFF97CAD8),
            borderColor: const Color(0xFF97CAD8),
            textColor: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            borderRadius: 30,
            leadingWidget: const Text(
              '→',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            onPressed: () {
              context.go('/login');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomButton(
            text: 'Créer un',
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            backgroundColor: Colors.transparent,
            borderColor: const Color(0xFF97CAD8),
            textColor: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            borderRadius: 30,
            leadingWidget: const Text(
              '→',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            onPressed: () {
              context.go('/register');
            },
          ),
        ),
      ],
    );
  }
}
