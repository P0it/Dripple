/// Abstract authentication service.
/// Implement with Firebase Auth for production.
abstract class AuthService {
  /// Get current user ID (null if not signed in)
  String? get currentUserId;

  /// Get current display name
  String? get displayName;

  /// Whether user is signed in
  bool get isSignedIn;

  /// Sign in as guest (anonymous auth)
  Future<String> signInAsGuest();

  /// Sign out
  Future<void> signOut();
}

/// Local-only auth for offline play
class LocalAuthService implements AuthService {
  String? _userId;
  String? _name;

  @override
  String? get currentUserId => _userId;

  @override
  String? get displayName => _name;

  @override
  bool get isSignedIn => _userId != null;

  @override
  Future<String> signInAsGuest() async {
    _userId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    _name = 'Player';
    return _userId!;
  }

  @override
  Future<void> signOut() async {
    _userId = null;
    _name = null;
  }
}

/// Firebase Auth implementation stub.
/// To implement:
/// 1. Add firebase_auth to pubspec.yaml
/// 2. Initialize Firebase in main.dart
/// 3. Implement using FirebaseAuth.instance
///
/// ```dart
/// class FirebaseAuthService implements AuthService {
///   final _auth = FirebaseAuth.instance;
///
///   @override
///   String? get currentUserId => _auth.currentUser?.uid;
///
///   @override
///   Future<String> signInAsGuest() async {
///     final cred = await _auth.signInAnonymously();
///     return cred.user!.uid;
///   }
/// }
/// ```
