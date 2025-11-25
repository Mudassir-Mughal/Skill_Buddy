import 'package:flutter/material.dart';
import 'package:skill_buddy_fyp/Screens/profile.dart';
import 'package:skill_buddy_fyp/Screens/settings.dart';
import 'Chatlist.dart';
import 'login.dart';
import "Homecontent.dart";
import 'theme.dart';
import 'ViewRequest.dart';
import 'package:animations/animations.dart';
import '../Service/api_service.dart';
import '../config.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final String? currentUserId = ApiService.currentUserId;
  String userRole = "student";
  List<Widget> _pages = [];
  Map<String, dynamic>? userProfileData;
  bool isLoading = true;

  static const List<String> _pageTitles = [
    'Home',
    'Chat',
    'Requests'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndSetupPages();
  }

  Future<void> _fetchUserRoleAndSetupPages() async {
    if (currentUserId == null) return;
    final data = await ApiService.getUserProfile(currentUserId!);
    userRole = (data?['role'] ?? 'student').toString().toLowerCase();
    setState(() {
      userProfileData = data;
      _pages = [
        HomeScreenContent(),
        ChatListPage(currentUserId: currentUserId!, baseUrl: baseUrl),
        ViewRequestsPage(role: userRole),
      ];
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (isLoading || _pages.isEmpty) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.05 * 255).toInt()),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: Text(
                      _pageTitles[_selectedIndex],
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _showProfileCard(context),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                        child: Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PageTransitionSwitcher(
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: _buildBottomNav(theme),
    );
  }

  void _showProfileCard(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = userProfileData?['Fullname'] ?? 'User';
    final email = userProfileData?['email'] ?? '';
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.1 * 255).toInt()),
                blurRadius: 10,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withAlpha((0.8 * 255).toInt()),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person,
                          size: 40,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((0.2 * 255).toInt()),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(email, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white)),
                    ),
                  ],
                ),
              ),
              _buildProfileMenuItem(
                icon: Icons.person_outline,
                title: 'My Profile',
                subtitle: 'View and edit your profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage(userId: currentUserId ?? ''))
                  );
                },
                theme: theme,
              ),
              _buildProfileMenuItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'App preferences and more',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
                theme: theme,
              ),
              const Divider(height: 1),
              _buildProfileMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out from your account',
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout(context);
                },
                theme: theme,
                isDestructive: true,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDestructive
                    ? theme.colorScheme.error.withAlpha((0.1 * 255).toInt())
                    : theme.colorScheme.primary.withAlpha((0.1 * 255).toInt()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDestructive
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDestructive
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      // LOGOUT: Remove local user state and navigate to login
      Future.delayed(Duration.zero, () {
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (Route<dynamic> route) => false,
          );
        }
      });
    } catch (e) {
      debugPrint("Logout error: $e");
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              const Text("Error signing out"),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildBottomNav(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: NavigationBar(
          height: 65,
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primary.withAlpha((0.15 * 255).toInt()),
          destinations: [
            _buildNavDestination(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              theme: theme,
            ),
            _buildNavDestination(
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              label: 'Chat',
              index: 1,
              theme: theme,
            ),
            _buildNavDestination(
              icon: Icons.inbox_outlined,
              selectedIcon: Icons.inbox_rounded,
              label: 'Requests',
              index: 2,
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavDestination({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _selectedIndex == index;

    return NavigationDestination(
      icon: Icon(
        icon,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
      ),
      selectedIcon: Icon(
        selectedIcon,
        color: theme.colorScheme.primary,
      ),
      label: label,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}