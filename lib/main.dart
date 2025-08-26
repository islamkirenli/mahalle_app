import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahalle_app/features/events/events_page.dart';
import 'package:mahalle_app/features/market/marketplace_page.dart';
import 'core/theme.dart';
import 'features/home/home_page.dart';
import 'features/post/new_post_page.dart';
import 'features/profile/profile_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); 
  runApp(const ProviderScope(child: MahalleApp()));
}

final _router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const RootScaffold()),
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
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});
  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;
  final _pages = const [
    HomePage(),      // 0: Akış
    EventsPage(),    // 1: Etkinlik
    MarketPage(),    // 2: Pazar
    ProfilePage(),   // 3: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mahalle — Osmanağa')),
      body: _pages[_index],
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly, // eşit aralık
            children: [
              // SOL TARAF
              IconButton(
                tooltip: 'Akış',
                icon: Icon(
                  _index == 0 ? Icons.home : Icons.home_outlined,
                  color: _index == 0 ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: () => setState(() => _index = 0),
              ),
              IconButton(
                tooltip: 'Etkinlik',
                icon: Icon(
                  _index == 1 ? Icons.event : Icons.event_outlined,
                  color: _index == 1 ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: () => setState(() => _index = 1),
              ),

              // ORTAK BOŞLUK (FAB için yer ayır)
              const SizedBox(width: 56), // FAB çapı kadar boşluk (default FAB ~56)

              // SAĞ TARAF
              IconButton(
                tooltip: 'Pazar',
                icon: Icon(
                  _index == 2 ? Icons.storefront : Icons.storefront_outlined,
                  color: _index == 2 ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: () => setState(() => _index = 2),
              ),
              IconButton(
                tooltip: 'Profil',
                icon: Icon(
                  _index == 3 ? Icons.person : Icons.person_outline,
                  color: _index == 3 ? Theme.of(context).colorScheme.primary : null,
                ),
                onPressed: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          shape: const CircleBorder(), // daire
          onPressed: () => context.push('/new'),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}
