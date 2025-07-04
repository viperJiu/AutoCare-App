import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register with email, password, and username
  Future<String?> registerUser({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Save additional user info like username
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'username': username,
          'uid': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return null;
      } else {
        return "Registration failed. Please try again.";
      }
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An error occurred. Please try again.";
    }
  }

  // Login
  Future<String?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Login error. Please try again.";
    }
  }

  // Logout
  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  // Current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
