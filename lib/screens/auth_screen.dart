import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // Import flutter_svg
import 'package:genesis_f1/digital_assets/auth_bg.dart';
import 'package:genesis_f1/utils/system_ui_helper.dart';
import '../services/auth_manager.dart';
import 'package:genesis_f1/constant/colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  //add top padding
                  const SizedBox(height: 190), // Increased padding from 48 to 64
                  Text(
                    'genesis',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),

                  const SizedBox(height: 64), // Increased padding from 48 to 64
                  // Email TextField
                  //add top padding
                  const SizedBox(height: 95), // Added padding
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8), // Adjusted margin
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => email = val,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      cursorColor: isDark ? AppColors.cursorDark : AppColors.cursorLight,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Added vertical padding
                        hintText: 'Email',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ), // Theme-responsive hint
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // Password TextField
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => password = val,
                      obscureText: true,
                      style: TextStyle(
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      cursorColor: isDark ? AppColors.cursorDark : AppColors.cursorLight,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Added vertical padding
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ), // Theme-responsive hint
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                    // Forgot Password
                    Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      style: TextButton.styleFrom(
                      padding: const EdgeInsets.only(left: 20, right: 8, top: 0, bottom: 0),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                      // TODO: Implement forgot password logic
                      },
                      child: Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400, // Decreased text weight
                      ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 10),
                    // add horizontal separator with increased bottom padding
                    const Padding(
                      padding: EdgeInsets.only(top:10, bottom: 25.0), // 12 top, 40+12=52 bottom
                      child: Divider(
                      color: Color.fromARGB(255, 121, 121, 121),
                      height: 1,
                      thickness: 0.15, // Separator thickness
                      indent: 0,      // No indent, full width
                      endIndent: 0,   // No endIndent, full width
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? AppColors.buttonBackgroundDark : AppColors.buttonBackgroundLight,
                        foregroundColor: isDark ? AppColors.buttonTextDark : AppColors.buttonTextLight,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100), // More rounded
                        ),
                        elevation: 0,
                        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1),
                      ),
                      onPressed: submit,
                      child: Text(
                        isLogin ? 'Login' : 'Register',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Added padding
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Text('Login with'),
                          label: SvgPicture.asset(
                            'assets/logo/google_logo.svg',
                            height: 20.0,
                            colorFilter: ColorFilter.mode(
                              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Implement Google Sign-In
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            backgroundColor: AppColors.secondaryButtonBackground,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: isDark ? AppColors.secondaryButtonBorderDark : AppColors.secondaryButtonBorderLight,
                                width: 1.2,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Text('Login with'),
                          label: SvgPicture.asset(
                            'assets/logo/x_logo.svg',
                            height: 19.0,
                            colorFilter: ColorFilter.mode(
                              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () {
                            // TODO: Implement X Sign-In
                          },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            backgroundColor: AppColors.secondaryButtonBackground,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(100),
                              side: BorderSide(
                                color: isDark ? AppColors.secondaryButtonBorderDark : AppColors.secondaryButtonBorderLight,
                                width: 1.2,
                              ),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(), // Added Spacer to push the following to the bottom
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60.0), // Added padding to lift it from the absolute bottom
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin
                              ? "Don't have an account? "
                              : 'Already have an account? ',
                          style: TextStyle(
                            fontSize: 15,
                            color: Theme.of(context).hintColor, // Subtler color
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => isLogin = !isLogin),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            isLogin ? 'Sign up' : 'Login',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight, // Use primary color for emphasis
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Removed the old TextButton for toggling auth mode
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
