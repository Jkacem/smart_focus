import 'package:flutter/material.dart';
import 'package:smart_focus/features/auth/widgets/login_buttons.dart';
import 'package:smart_focus/features/auth/widgets/login_text_section.dart';
import 'package:smart_focus/features/auth/widgets/robot_section.dart';
import 'package:smart_focus/shared/widgets/starfield_painter.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0a1628),
                  Color(0xFF1a3a4a),
                  Color(0xFF0d2635),
                ],
              ),
            ),
          ),

          // Starfield Layer
          _buildStarfield(),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Spacer(flex: 1),

                // Robot Section
                const RobotSection(),
                const Spacer(flex: 1),

                // Text Content
                const LoginTextSection(),
                const Spacer(flex: 1),

                // Continue Button
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: LoginButtons(),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarfield() {
    return SizedBox.expand(child: CustomPaint(painter: StarfieldPainter()));
  }
}
