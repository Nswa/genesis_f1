import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // Import App Check

import 'firebase_options.dart';
import 'screens/journal_screen.dart';
import 'screens/auth_screen.dart';
import 'theme.dart'; // 👈 import your modular theme setup

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseInitialized = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    debugPrint("Firebase Core initialized successfully.");

    // Activate App Check
    debugPrint("Attempting to activate Firebase App Check...");
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
    debugPrint("FirebaseAppCheck.instance.activate() call attempted.");

    // Attempt to get token immediately to confirm
    debugPrint(
      "Attempting token retrieval immediately after App Check activate()...",
    );
    String? tokenInitial = await FirebaseAppCheck.instance.getToken(true);
    debugPrint("Initial App Check token: $tokenInitial");
    if (tokenInitial == null) {
      debugPrint(
        "CRITICAL: Initial App Check token is NULL. Debug provider might not be working or token not registered in console.",
      );
    }

    // Add a small delay to allow native initializations to settle
    await Future.delayed(const Duration(milliseconds: 500));
    debugPrint("Continuing after small delay.");
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app' && firebaseInitialized) {
      debugPrint(
        "Firebase app already initialized (duplicate-app). App Check should use existing activated state.",
      );
      // Still try to get a token to verify
      try {
        String? token = await FirebaseAppCheck.instance.getToken(true);
        debugPrint("App Check token (on duplicate-app path): $token");
        if (token == null) {
          debugPrint(
            "CRITICAL: App Check token is NULL (on duplicate-app path).",
          );
        }
      } catch (eInner) {
        debugPrint("EXCEPTION getting token (on duplicate-app path): $eInner");
      }
    } else {
      debugPrint(
        "Firebase Core or App Check initialization error: ${e.message} (Code: ${e.code})",
      );
      // For other FirebaseExceptions during init, rethrow if not handled.
      // if (e.code != 'duplicate-app') rethrow; // This was original, but above handles duplicate specifically.
    }
  } catch (e, stackTrace) {
    debugPrint(
      "Generic/Unexpected error during Firebase/App Check initialization: $e",
    );
    debugPrint("Generic init Stack trace: $stackTrace");
  }

  runApp(const JournalApp());

  // Optional: Keep the delayed token check for further debugging if needed
  Future.delayed(const Duration(seconds: 5), () async {
    try {
      debugPrint("Attempting token retrieval (5 seconds AFTER runApp)...");
      String? tokenAfterRunApp = await FirebaseAppCheck.instance.getToken(true);
      debugPrint("App Check token (5 seconds AFTER runApp): $tokenAfterRunApp");
      if (tokenAfterRunApp == null) {
        debugPrint(
          "CRITICAL: App Check token is NULL (5 seconds AFTER runApp).",
        );
      }
    } catch (e) {
      debugPrint("EXCEPTION getting token (5 seconds AFTER runApp): $e");
    }
  });
}

class JournalApp extends StatelessWidget {
  const JournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Journal',
      themeMode: ThemeMode.system, // 👈 respond to system theme
      theme: lightTheme,
      darkTheme: darkTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.hasData ? const JournalScreen() : const AuthScreen();
        },
      ),
    );
  }
}
