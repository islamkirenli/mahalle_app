import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';


class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      // SIGNED_IN, SIGNED_OUT, TOKEN_REFRESHED vb. durumlarda router’ı yenile
      notifyListeners();
    });
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
