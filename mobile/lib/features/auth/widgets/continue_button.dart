import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/core/router/app_routes.dart';
import 'package:smart_focus/shared/widgets/custom_button.dart';

/// A rounded "Continue" button used on the welcome screen.
/// Navigates to the login screen on tap.
class ContinueButton extends StatelessWidget {
  const ContinueButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomButton(
      text: 'Continuer',
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
      backgroundColor: const Color(0xFF97CAD8),
      borderColor: const Color(0xFF97CAD8),
      textColor: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      borderRadius: 30,
      leadingWidget: const Text(
        '→',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
      onPressed: () {
        context.go(AppRoutes.authOptions);
      },
    );
  }
}
