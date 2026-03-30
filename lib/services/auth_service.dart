import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final userNotifier = ValueNotifier<User?>(null);

  static bool get isLoggedIn => userNotifier.value != null;
  static String? get uid => userNotifier.value?.uid;
  static User? get currentUser => userNotifier.value;

  static void init() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      userNotifier.value = user;
    });
  }

  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // user cancelled

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}
