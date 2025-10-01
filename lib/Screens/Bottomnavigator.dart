import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

class HomeBottomNavigator extends StatelessWidget {
  final int selectedIndex;
  final List<Widget> pages;
  final ValueChanged<int> onIndexChanged;

  const HomeBottomNavigator({
    Key? key,
    required this.selectedIndex,
    required this.pages,
    required this.onIndexChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: PageTransitionSwitcher(
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: pages[selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            height: 65,
            selectedIndex: selectedIndex,
            onDestinationSelected: onIndexChanged,
            backgroundColor: Colors.transparent,
            indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: selectedIndex == 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: theme.colorScheme.primary,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.workspace_premium_outlined,
                  color: selectedIndex == 1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                selectedIcon: Icon(
                  Icons.workspace_premium_rounded,
                  color: theme.colorScheme.primary,
                ),
                label: 'Skills',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.add_circle_outline,
                  color: selectedIndex == 2
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                selectedIcon: Icon(
                  Icons.add_circle_rounded,
                  color: theme.colorScheme.primary,
                ),
                label: 'Add',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.chat_bubble_outline,
                  color: selectedIndex == 3
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                selectedIcon: Icon(
                  Icons.chat_bubble,
                  color: theme.colorScheme.primary,
                ),
                label: 'Chat',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.inbox_outlined,
                  color: selectedIndex == 4
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                selectedIcon: Icon(
                  Icons.inbox_rounded,
                  color: theme.colorScheme.primary,
                ),
                label: 'Requests',
              ),
            ],
          ),
        ),
      ),
    );
  }
}