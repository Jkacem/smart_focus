import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_focus/core/router/app_routes.dart';
import 'package:smart_focus/shared/widgets/index.dart';
import '../providers/auth_provider.dart';

/// Register form — connects to FastAPI /auth/register via AuthNotifier.
class SignFormScreen extends ConsumerStatefulWidget {
  const SignFormScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignFormScreen> createState() => _SignFormScreenState();
}

class _SignFormScreenState extends ConsumerState<SignFormScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;

  // The role selected via dropdown (student / teacher / professional)
  String _selectedRole = 'student';

  static const _roles = [
    {'value': 'student', 'label': 'Étudiant'},
    {'value': 'teacher', 'label': 'Enseignant'},
    {'value': 'professional', 'label': 'Professionnel'},
  ];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final fullName = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    final didRegister = await ref.read(authProvider.notifier).register(
          fullName,
          email,
          password,
          _selectedRole,
        );

    if (!mounted) return;
    if (didRegister) {
      context.go(AppRoutes.dashboard);
    } else {
      final state = ref.read(authProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.errorMessage ?? 'Erreur lors de l\'inscription'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient base
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

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Image.asset(
                              'assets/images/smartFocus.png',
                              width: 120,
                              height: 120,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Bienvenue !',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'SF Pro Black',
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Full name ──
                          _label('Nom complet'),
                          _inputField(
                            controller: _usernameController,
                            hintText: 'Jean Dupont',
                          ),
                          const SizedBox(height: 16),

                          // ── Email ──
                          _label('Adresse Email'),
                          _inputField(
                            controller: _emailController,
                            hintText: 'example@example.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),

                          // ── Password ──
                          _label('Mot de passe'),
                          _passwordField(),
                          const SizedBox(height: 16),

                          // ── Role dropdown ──
                          _label('Rôle'),
                          _roleDropdown(),
                          const SizedBox(height: 32),

                          // ── Register button ──
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF97CAD8),
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.black87,
                                      ),
                                    )
                                  : const Text(
                                      "S'inscrire",
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Black',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Already have an account? ──
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                context.go(AppRoutes.login);
                              },
                              child: RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Déjà membre ?  ',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Se connecter',
                                      style: TextStyle(
                                        fontFamily: 'SF Pro Black',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: Color(0xFF97CAD8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'SF Pro',
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF97CAD8),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    String hintText = '',
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'SF Pro',
          fontSize: 16,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          hintText: hintText,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(
          fontFamily: 'SF Pro',
          fontSize: 16,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          hintText: '••••••••',
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 15,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
              size: 20,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedRole,
            dropdownColor: const Color(0xFF1a3a4a),
            isExpanded: true,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
            style: const TextStyle(
              fontFamily: 'SF Pro',
              fontSize: 16,
              color: Colors.white,
            ),
            items: _roles
                .map(
                  (r) => DropdownMenuItem<String>(
                    value: r['value'],
                    child: Text(r['label']!),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedRole = val);
            },
          ),
        ),
      ),
    );
  }
}

Widget _buildStarfield() {
  return SizedBox.expand(
    child: CustomPaint(painter: StarfieldPainter()),
  );
}
