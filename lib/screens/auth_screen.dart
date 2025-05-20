import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg
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
                  const SizedBox(height: 26), // Added padding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Text('Login with'), // Moved Text to icon
                          label: SvgPicture.asset( // Moved SvgPicture to label
                            'assets/logo/google_logo.svg',
                            height: 20.0, 
                            colorFilter: ColorFilter.mode( 
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Implement Google Sign-In
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.white
                                : Colors.black,
                            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15), // Increased vertical padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Text('Login with'), // Moved Text to icon
                          label: SvgPicture.asset( // Moved SvgPicture to label
                            'assets/logo/x_logo.svg',
                            height:19.0,
                            colorFilter: ColorFilter.mode(
                              Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Implement X Sign-In
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15), // Increased vertical padding
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
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
