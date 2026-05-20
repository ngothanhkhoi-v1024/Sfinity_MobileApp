import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_names.dart';
import '../../../favorites/presentation/pages/favorites_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../search/presentation/pages/search_page.dart';
import 'home_page.dart';

/// Shell chính: Scaffold + BottomNavigationBar + Drawer + FAB (PDF layout).
class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _currentIndex = 0;

  static const _tabs = ['Trang chủ', 'Tìm kiếm', 'Yêu thích', 'Cá nhân'];

  late final List<Widget> _pages = const [
    HomePage(),
    SearchPage(),
    FavoritesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tabs[_currentIndex])),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Sfinity', style: TextStyle(fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Nội dung'),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.contentList);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Cài đặt'),
              onTap: () {
                Navigator.pop(context);
                context.push(RouteNames.settings);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(child: _pages[_currentIndex]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteNames.contentCreate),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: 'Yêu thích'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
      ),
    );
  }
}
