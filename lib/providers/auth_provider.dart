import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get userRole => _user?.role;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      await _handleAuthStateChange(firebaseUser);
    });
  }

  Future<void> _handleAuthStateChange(User? firebaseUser) async {
    if (firebaseUser != null) {
      _user = await _getUserData(firebaseUser.uid);
    } else {
      _user = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔵 Starting registration for: $email');
      
      // Step 1: Create user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Auth user created with UID: ${credential.user!.uid}');

      // Step 2: Create user document in Firestore
      final userData = {
        'uid': credential.user!.uid,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('🔵 Attempting to write to Firestore...');
      await _firestore.collection('users').doc(credential.user!.uid).set(userData);
      print('✅ Firestore document created successfully!');

      // Step 3: Load user data
      await _loadUserData(credential.user!.uid);
      
      _isLoading = false;
      notifyListeners();
      
      print('✅ Registration completed successfully!');
      return true;
      
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Authentication error occurred';
      print('❌ Firebase Auth Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
      
    } on FirebaseException catch (e) {
      _errorMessage = e.message ?? 'Firestore error occurred';
      print('❌ Firestore Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return false;
      
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      print('❌ Unexpected Error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🔵 Starting sign in for: $email');
      
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Sign in successful, UID: ${credential.user!.uid}');
      
      final userModel = await _getUserData(credential.user!.uid);

      if (userModel != null) {
        _user = userModel;
        _isLoading = false;
        notifyListeners();
        print('✅ User role loaded: ${userModel.role}');
        return userModel.role;
      } else {
        _errorMessage = 'User data not found in database.';
        print('⚠️ User data not found for UID: ${credential.user!.uid}');
        _isLoading = false;
        notifyListeners();
        await _auth.signOut();
        return null;
      }
      
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Authentication error occurred';
      print('❌ Sign In Error: ${e.code} - ${e.message}');
      _isLoading = false;
      notifyListeners();
      return null;
      
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: $e';
      print('❌ Unexpected Error: $e');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> _loadUserData(String uid) async {
    try {
      print('🔵 Loading user data for UID: $uid');
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _user = UserModel.fromFirestore(data, doc.id);
        print('✅ User data loaded: ${_user!.name} (${_user!.role})');
      } else {
        print('⚠️ No user document found in Firestore for UID: $uid');
        _user = null;
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Error loading user data: $e');
    }
  }

  Future<UserModel?> _getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel.fromFirestore(data, doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      print('🔵 Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Password reset email sent');
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message;
      print('❌ Password Reset Error: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      print('❌ Unexpected Error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      print('🔵 Signing out...');
      await _auth.signOut();
      _user = null;
      notifyListeners();
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Sign Out Error: $e');
    }
  }

  bool hasRole(List<String> allowedRoles) {
    return _user != null && allowedRoles.contains(_user!.role);
  }
}