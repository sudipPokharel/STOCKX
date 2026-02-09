import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  // Current logged-in user
  User? get currentUser => firebaseAuth.currentUser;

  // Stream to listen for auth state changes
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // ---------------- EMAIL/PASSWORD AUTH ----------------

  // Sign in with email verification check
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password);

    // Check if email is verified
    if (!(userCredential.user?.emailVerified ?? false)) {
      // Sign out immediately if not verified
      await firebaseAuth.signOut();
      throw FirebaseAuthException(
        code: "email-not-verified",
        message: "Please verify your email before logging in.",
      );
    }

    return userCredential;
  }

  // Create account
  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    UserCredential userCredential = await firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);

    // Send email verification after signup
    await userCredential.user!.sendEmailVerification();

    return userCredential;
  }

  // Check if email is verified
  bool isEmailVerified() {
    return firebaseAuth.currentUser?.emailVerified ?? false;
  }

  // Sign out
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  // Update username (display name)
  Future<void> updateUsername({required String username}) async {
    if (currentUser != null) {
      await currentUser!.updateDisplayName(username);
      await currentUser!.reload();
    }
  }

  // Delete account
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.delete();
    await firebaseAuth.signOut();
  }

  // Reset password from current password
  Future<void> resetPasswordFromCurrentPassword({
    required String email,
    required String newPassword,
    required String currentPassword,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPassword,
    );
    await currentUser!.reauthenticateWithCredential(credential);
    await currentUser!.updatePassword(newPassword);
  }
}
