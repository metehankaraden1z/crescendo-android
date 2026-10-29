import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../shared/widgets/pressable.dart';
import '../home/presentation/home_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../search/presentation/search_screen.dart';

/// The main app once logged in: Home · Search · Profile tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;
  int _homeVisit = 0; // bumping these keys reloads the tab with fresh data
  int _profileVisit = 0;
  int _searchFocus = 0;

  void _select(int tab) {
    setState(() {
      if (tab == 0 && _tab != 0) _homeVisit++;
      if (tab == 2 && _tab != 2) _profileVisit++;
      _tab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(
            key: ValueKey('home-$_homeVisit'),
            onOpenSearch: () => setState(() {
              _tab = 1;
              _searchFocus++;
            }),
          ),
          SearchScreen(focusRequest: _searchFocus),
          ProfileScreen(key: ValueKey('profile-$_profileVisit')),
        ],
      ),
      bottomNavigationBar: _BottomBar(index: _tab, onSelect: _select),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.search_rounded, label: 'Search'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: CrColors.bg2,
        border: Border(top: BorderSide(color: CrColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final (i, item) in _items.indexed)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: item.label,
                    child: Pressable(
                      onTap: () => onSelect(i),
                      child: ExcludeSemantics(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(item.icon, size: 26, color: i == index ? CrColors.gold2 : CrColors.muted),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: CrText.body(
                                size: 12,
                                weight: FontWeight.w600,
                                color: i == index ? CrColors.gold2 : CrColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
