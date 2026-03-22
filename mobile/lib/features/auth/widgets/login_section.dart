import 'package:flutter/material.dart';
import 'package:smart_focus/shared/widgets/custom_button.dart';

/// Login section displayed at the bottom of the welcome screen.
/// Contains buttons for login and account creation.
class LoginSection extends StatefulWidget {
  const LoginSection({Key? key}) : super(key: key);

  @override
  State<LoginSection> createState() => _LoginSectionState();
}

class _LoginSectionState extends State<LoginSection> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color.fromARGB(215, 217, 217, 217),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(70),
          topRight: Radius.circular(70),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Mot de passe',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),
            CustomButton(
              text: 'SE CONNECTER',
              width: 288,
              height: 70,
              backgroundColor: const Color(0xFF97cad8),
              borderColor: const Color.fromARGB(88, 0, 0, 0),
              textColor: const Color.fromRGBO(0, 0, 0, 0.56),
              fontSize: 20,
              fontWeight: FontWeight.w600,
              borderRadius: 25,
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  // perform login
                }
              },
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                // handle account creation or navigation
              },
              child: const Text(
                'Créer votre compte',
                style: TextStyle(
                  color: Color.fromRGBO(0, 0, 0, 0.56),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
