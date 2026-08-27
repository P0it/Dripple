/// Who is making a request.
///
/// Verification is a seam because the real one needs a Firebase project that
/// does not exist yet, and because every rule of the game can be tested
/// without it. Nothing below this line cares how identity was established —
/// only that it was.
abstract class TokenVerifier {
  /// Return the account id for [idToken], or null if it does not check out.
  Future<String?> verify(String idToken);
}

/// Trusts the token to be the account id. For tests and local runs only.
///
/// Wiring this into a deployment would let anyone play as anyone, so
/// [bin/server.dart] refuses to start with it unless explicitly told to.
class TrustingTokenVerifier implements TokenVerifier {
  const TrustingTokenVerifier();

  @override
  Future<String?> verify(String idToken) async =>
      idToken.trim().isEmpty ? null : idToken.trim();
}
