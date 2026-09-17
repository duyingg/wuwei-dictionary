import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design/app_theme.dart';
import '../core/widgets/skin_widgets.dart';
import '../features/domain/models.dart';
import 'providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider).valueOrNull ??
        const AppSettings();
    final spec = AppSkinRegistry.of(settings.skin, settings.importedSkin);
    final compact = MediaQuery.sizeOf(context).height < 680;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: compact ? 62 : 72,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index,
            initialLocation: index == navigationShell.currentIndex),
        destinations: [
          NavigationDestination(
              icon: SkinIcon('nav.home',
                  fallback: spec.icon('nav.home', Icons.home_outlined)),
              selectedIcon: SkinIcon('nav.home.selected',
                  fallback: spec.icon('nav.home.selected', Icons.home)),
              label: '首页'),
          NavigationDestination(
              icon: SkinIcon('nav.learning',
                  fallback:
                      spec.icon('nav.learning', Icons.menu_book_outlined)),
              selectedIcon: SkinIcon('nav.learning.selected',
                  fallback:
                      spec.icon('nav.learning.selected', Icons.menu_book)),
              label: '学习'),
          NavigationDestination(
              icon: SkinIcon('nav.culture',
                  fallback:
                      spec.icon('nav.culture', Icons.account_balance_outlined)),
              selectedIcon: SkinIcon('nav.culture.selected',
                  fallback:
                      spec.icon('nav.culture.selected', Icons.account_balance)),
              label: '文化'),
          NavigationDestination(
              icon: SkinIcon('nav.profile',
                  fallback: spec.icon('nav.profile', Icons.person_outline)),
              selectedIcon: SkinIcon('nav.profile.selected',
                  fallback: spec.icon('nav.profile.selected', Icons.person)),
              label: '我的'),
        ],
      ),
    );
  }
}
