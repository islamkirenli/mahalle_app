import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepo {
  AuthRepo(this._client);
  final SupabaseClient _client;

  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: 'io.supabase.flutter://login-callback',
    );
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.flutter://login-callback',
    );
  }

  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'io.supabase.flutter://login-callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}

final authRepo = AuthRepo(Supabase.instance.client);
