import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skyivory/screens/timeline_screen.dart';
import 'package:skyivory/screens/mentions_screen.dart';
import 'package:skyivory/screens/search_screen.dart';
import 'package:skyivory/screens/profile_screen.dart';
import 'package:skyivory/screens/auth/login_screen.dart';
import 'package:skyivory/providers/auth_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = const [
    TimelineScreen(),
    MentionsScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    
    if (session == null) {
      return const LoginScreen();
    }
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
            });
            _playHapticFeedback();
          },
          height: 60,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          indicatorColor: Colors.transparent,
          destinations: [
            NavigationDestination(
              icon: Icon(
                _selectedIndex == 0 ? CupertinoIcons.house_fill : CupertinoIcons.house,
                size: 24,
              ),
              label: 'Timeline',
            ),
            NavigationDestination(
              icon: Icon(
                _selectedIndex == 1 ? CupertinoIcons.at_circle_fill : CupertinoIcons.at_circle,
                size: 24,
              ),
              label: 'Mentions',
            ),
            NavigationDestination(
              icon: Icon(
                _selectedIndex == 2 ? CupertinoIcons.search_circle_fill : CupertinoIcons.search_circle,
                size: 24,
              ),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(
                _selectedIndex == 3 ? CupertinoIcons.person_fill : CupertinoIcons.person,
                size: 24,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
  
  void _playHapticFeedback() {
    // TODO: Implement haptic feedback
  }
}