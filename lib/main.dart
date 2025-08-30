import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalle_app/features/events/events_page.dart';
import 'package:mahalle_app/features/market/marketplace_page.dart';
import 'core/theme.dart';
import 'features/home/home_page.dart';
import 'features/post/new_post_page.dart';
import 'features/profile/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_keys.dart';
import 'features/auth/login_page.dart';
import 'features/auth/auth_notifier.dart';
import 'package:mahalle_app/features/auth/register_page.dart';
import 'package:mahalle_app/features/auth/profile_setup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  runApp(const ProviderScope(child: MahalleApp()));
}

final _authNotifier = AuthNotifier();

final _router = GoRouter(
  initialLocation: '/',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;

    final loc = state.matchedLocation;
    final goingToLoginOrRegister = (loc == '/login' || loc == '/register');

    if (!loggedIn && !goingToLoginOrRegister) return '/login';
    if (loggedIn && goingToLoginOrRegister) return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (_, __) => const RootScaffold()),
    GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
    GoRoute(path: '/setup', builder: (_, __) => const ProfileSetupPage()),
    GoRoute(path: '/new', builder: (_, __) => const NewPostPage()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
  ],
);

class MahalleApp extends StatelessWidget {
  const MahalleApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mahalle',
      theme: buildAppTheme(),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});
  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  /// Navigation bar index (0..4). 2 = Yeni Post (modal/route), seçili olarak tutulmaz.
  int _navIndex = 0;

  /// Gösterilecek sayfalar (Yeni Post bir sayfa sekmesi değil).
  final _pages = const [
    HomePage(), // 0
    EventsPage(), // 1
    MarketPage(), // 2  (bar’da 3. ikon)
    ProfilePage() // 3  (bar’da 5. ikon)
  ];

  /// bar: [0:home, 1:events, 2:new, 3:market, 4:profile]  -> page: [-]
  int _pageIndexForBar(int barIndex) {
    if (barIndex <= 1) return barIndex; // 0,1 => 0,1
    if (barIndex == 2) return -1; // Yeni Post
    if (barIndex == 3) return 2; // Market
    return 3; // 4 => Profile
  }

  @override
  void initState() {
    super.initState();
    _guardProfileCompleteness();
  }

  Future<void> _guardProfileCompleteness() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return; // login değilse dokunma

    final uid = session.user.id;
    final res = await Supabase.instance.client
        .from('profiles')
        .select('display_name, district')
        .eq('id', uid)
        .maybeSingle();

    final complete = (res != null) &&
        (res['display_name'] != null &&
            (res['display_name'] as String).trim().isNotEmpty) &&
        (res['district'] != null &&
            (res['district'] as String).trim().isNotEmpty);

    if (!mounted) return;
    if (!complete) {
      context.go('/setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final currentPageIndex = _pageIndexForBar(_navIndex) == -1
        ? _pageIndexForBar(0)
        : _pageIndexForBar(_navIndex);

    final theme = Theme.of(context);

    Color? iconColorFor(int barIdx) {
      final isActive = _pageIndexForBar(barIdx) == currentPageIndex;
      return isActive ? theme.colorScheme.primary : null;
    }

    IconData iconFor(int barIdx) {
      switch (barIdx) {
        case 0:
          return (_pageIndexForBar(0) == currentPageIndex)
              ? Icons.home_rounded
              : Icons.home_outlined;
        case 1:
          return (_pageIndexForBar(1) == currentPageIndex)
              ? Icons.event_rounded
              : Icons.event_outlined;
        case 2: // Yeni Post (her zaman aynı ikon)
          return Icons.add_circle;
        case 3:
          return (_pageIndexForBar(3) == currentPageIndex)
              ? Icons.storefront_rounded
              : Icons.storefront_outlined;
        case 4:
          return (_pageIndexForBar(4) == currentPageIndex)
              ? Icons.person_rounded
              : Icons.person_outline_rounded;
        default:
          return Icons.circle;
      }
    }

    void onTapBar(int i) {
      HapticFeedback.selectionClick();
      if (i == 2) {
        // Yeni Post: route aç, seçimi değiştirme
        HapticFeedback.mediumImpact();
        context.push('/new');
        return;
      }
      setState(() => _navIndex = i);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mahalle — Osmanağa')),
      resizeToAvoidBottomInset: false,
      body: _pages[currentPageIndex],
      bottomNavigationBar: keyboardOpen
          ? const SizedBox.shrink()
          : SafeArea(
              top: false,
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                    ),
                  ),
                ),
                child: Row(
                  children: List.generate(5, (i) {
                    // 5 buton, eşit genişlik için Expanded
                    return Expanded(
                      child: IconButton(
                        padding:
                            EdgeInsets.zero, // varsayılan 8px padding'i kaldır
                        alignment: Alignment.center, // tam ortaya hizala
                        constraints: const BoxConstraints(
                          // dikeyde 64px'e oturt
                          minWidth: 64,
                          minHeight: 64,
                        ),
                        tooltip: i == 0
                            ? 'Ana Sayfa'
                            : i == 1
                                ? 'Etkinlik'
                                : i == 2
                                    ? 'Yeni Post'
                                    : i == 3
                                        ? 'Pazar'
                                        : 'Profil',
                        onPressed: () => onTapBar(i),
                        icon: Icon(
                          iconFor(i),
                          size: i == 2 ? 60 : 30, // boyutlar aynı kalıyor
                          color: i == 2
                              ? theme.colorScheme.primary
                              : iconColorFor(i),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
    );
  }
}
