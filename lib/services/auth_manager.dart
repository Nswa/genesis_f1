import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthManager {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign in with email and password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Register a new user with email and password
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign out the current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Stream to listen to auth state (logged in or not)
  Stream<User?> get authState => _auth.authStateChanges();

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User canceled
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  /// Sign in with Twitter/X using Firebase OAuthProvider (recommended for Android)
  Future<UserCredential?> signInWithTwitter() async {
    try {
      print('[DEBUG] Starting Twitter sign-in');
      final provider = OAuthProvider('twitter.com');
      // Optionally add custom parameters, e.g. provider.addCustomParameter('lang', 'en');
      final userCredential = await _auth.signInWithProvider(provider);
      print('[DEBUG] Twitter sign-in successful: \\${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('[DEBUG] FirebaseAuthException during Twitter sign-in: \\${e.code} - \\${e.message}');
      rethrow;
    } catch (e, stack) {
      print('[DEBUG] Unexpected error during Twitter sign-in: \\${e.toString()}');
      print(stack);
      rethrow;
    }
  }
}

// Global instance
final authManager = AuthManager();
