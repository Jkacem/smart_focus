import 'package:flutter/material.dart';

// feature-specific widgets
import '../widgets/index.dart';

// shared widgets
import '../../../shared/widgets/index.dart';
// robot painter is available in shared/widgets if needed

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
                // Smart Focus Badge
                const SmartFocusBadge(),
                const Spacer(flex: 2),
                
                // Robot Section
                const RobotSection(),
                const Spacer(flex: 2),
                
                // Text Content
                const HomeTextSection(),
                const Spacer(flex: 1),
                
                // Continue Button
                const ContinueButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarfield() {
    return SizedBox.expand(
      child: CustomPaint(painter: StarfieldPainter()),
    );
  }
}

// Painters are provided by shared widgets (imported above).
