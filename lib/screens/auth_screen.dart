import 'package:flutter/material.dart';
import 'package:genesis_f1/digital_assets/auth_bg.dart';
import 'package:genesis_f1/utils/system_ui_helper.dart';
import '../services/auth_manager.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  String email = '';
  String password = '';

  void submit() async {
    try {
      if (isLogin) {
        await authManager.signIn(email, password);
      } else {
        await authManager.signUp(email, password);
      }
    } catch (e) {
      debugPrint('Auth error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    updateSystemUiOverlay(context);
    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'genesis',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),

                  const SizedBox(height: 48),
                  TextField(
                    onChanged: (val) => email = val,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    onChanged: (val) => password = val,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB39DDB), // Softer purple shade
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100), // More rounded
                        ),
                        elevation: 0,
                      ),
                      onPressed: submit,
                      child: Text(
                        isLogin ? 'Login' : 'Register',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin
                          ? "Don't have an account? Sign up"
                          : 'Already have an account? Login',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
