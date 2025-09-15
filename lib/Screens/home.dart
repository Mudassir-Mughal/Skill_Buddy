import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_buddy_fyp/Screens/profile.dart';
import 'package:skill_buddy_fyp/Screens/settings.dart';
import 'Addskill.dart';
import 'Chatlist.dart';
import 'login.dart';
import "Homecontent.dart";
import 'theme.dart';
import 'Myskills.dart';
import 'ViewRequest.dart';
import 'package:animations/animations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  late final List<Widget> _pages;

  static const List<String> _pageTitles = [
    'Home',
    'My Skills',
    'Add Skill',
    "Chat",
    'Requests',
  ];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreenContent(),
      MySkillsPage(),
      AddSkillPage(),
      if (currentUserId != null)
        ChatListPage(currentUserId: currentUserId!)
      else
        const Center(child: Text('User not logged in')),
      ViewRequestsPage(role: "Both"),
    ];
  }

  // Helper widget that listens to the current user's Firestore document
  // and returns a CircleAvatar (with image if available) and an optional name.
  Widget _profileAvatar({double radius = 20, bool showBorder = true}) {
    if (currentUserId == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        child: Icon(Icons.person_outline, color: AppColors.primary, size: radius),
      );
    }

    final docStream = FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots();

    return StreamBuilder<DocumentSnapshot>(
      stream: docStream,
      builder: (context, snapshot) {
        String? photoUrl;
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          photoUrl = (data != null ? (data['photoUrl'] as String?) : null);
        }

        final avatar = CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
          child: (photoUrl == null || photoUrl.isEmpty)
              ? Icon(Icons.person_outline, color: AppColors.primary, size: radius)
              : null,
        );

        if (!showBorder) return avatar;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.08),
          ),
          child: avatar,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= 900;

    // --- AppBar ---
    final appBar = PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: isWeb
                ? const EdgeInsets.symmetric(horizontal: 48, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    child: _profileAvatar(radius: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // --- Main Content ---
    Widget mainContent;
    if (!isWeb) {
      mainContent = PageTransitionSwitcher(
        transitionBuilder: (child, animation, secondaryAnimation) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: _pages[_selectedIndex],
      );
    } else {
      // Responsive web layout: horizontally arranges navigation and content
      mainContent = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Vertical Navigation
          Container(
            width: 210,
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(1, 0),
                ),
              ],
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withOpacity(0.08),
                  width: 1.5,
                ),
              ),
            ),
            child: _buildWebNav(theme),
          ),
          // Center: Main Section
          Expanded(
            child: Container(
              alignment: Alignment.topCenter,
              color: theme.colorScheme.background,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 950),
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: theme.cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _pages[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.background,
      appBar: isWeb ? appBar : appBar,
      body: mainContent,
      bottomNavigationBar: isWeb ? null : _buildBottomNav(theme),
    );
  }

  // --- Web Navigation ---
  Widget _buildWebNav(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 28),
        // App logo or profile (now dynamic)
        GestureDetector(
          onTap: () => _showProfileCard(context),
          child: _profileAvatar(radius: 36),
        ),
        const SizedBox(height: 36),
        // Navigation Items
        for (var i = 0; i < _pageTitles.length; i++)
          _buildWebNavItem(
            icon: _getNavIcon(i, false),
            selectedIcon: _getNavIcon(i, true),
            label: _pageTitles[i],
            index: i,
            theme: theme,
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: IconButton(
            icon: const Icon(Icons.settings, size: 28),
            color: theme.colorScheme.primary,
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
            tooltip: "Settings",
          ),
        ),
      ],
    );
  }

  Widget _buildWebNavItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required ThemeData theme,
  }) {
    final isSelected = _selectedIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 13),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color?.withOpacity(0.65),
              size: 26,
            ),
            const SizedBox(width: 15),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.titleMedium?.color?.withOpacity(0.8),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNavIcon(int index, bool selected) {
    switch (index) {
      case 0:
        return selected ? Icons.home_rounded : Icons.home_outlined;
      case 1:
        return selected ? Icons.workspace_premium_rounded : Icons.workspace_premium_outlined;
      case 2:
        return selected ? Icons.add_circle_rounded : Icons.add_circle_outline;
      case 3:
        return selected ? Icons.chat_bubble : Icons.chat_bubble_outline;
      case 4:
        return selected ? Icons.inbox_rounded : Icons.inbox_outlined;
      default:
        return Icons.home_outlined;
    }
  }

  void _showProfileCard(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: StreamBuilder<DocumentSnapshot>(
          stream: currentUserId != null
              ? FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots()
              : const Stream.empty(),
          builder: (context, snapshot) {
            // build default values first
            String displayName = 'User';
            String email = '';
            String? photoUrl;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>?;
              if (data != null) {
                displayName = (data['Fullname'] ?? data['fullName'] ?? FirebaseAuth.instance.currentUser?.displayName ?? 'User').toString();
                email = (data['email'] ?? FirebaseAuth.instance.currentUser?.email ?? '').toString();
                photoUrl = (data['photoUrl'] as String?) ?? '';
              }
            }

            return Container(
              width: 320,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile Header with Gradient and image/name
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.85),
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
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.white,
                            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Icon(Icons.person, size: 44, color: theme.colorScheme.primary)
                                : null,
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
                        const SizedBox(height: 6),
                        Text(
                          email,
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // Menu Items
                  _buildProfileMenuItem(
                    icon: Icons.person_outline,
                    title: 'My Profile',
                    subtitle: 'View and edit your profile',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                    },
                    theme: theme,
                  ),
                  _buildProfileMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    subtitle: 'App preferences and more',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
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
            );
          },
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
                    ? theme.colorScheme.error.withOpacity(0.1)
                    : theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
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
                      color: isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
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
      final GoogleSignIn googleSignIn = GoogleSignIn();

      try {
        await googleSignIn.disconnect();
      } catch (_) {}

      try {
        await googleSignIn.signOut();
      } catch (_) {}

      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Delay navigation to allow auth state to update & widget to rebuild
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
            children: const [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text("Error signing out"),
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
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.transparent,
          indicatorColor: theme.colorScheme.primary.withOpacity(0.15),
          destinations: [
            _buildNavDestination(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              theme: theme,
            ),
            _buildNavDestination(
              icon: Icons.workspace_premium_outlined,
              selectedIcon: Icons.workspace_premium_rounded,
              label: 'Skills',
              index: 1,
              theme: theme,
            ),
            _buildNavDestination(
              icon: Icons.add_circle_outline,
              selectedIcon: Icons.add_circle_rounded,
              label: 'Add',
              index: 2,
              theme: theme,
            ),
            _buildNavDestination(
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              label: 'Chat',
              index: 3,
              theme: theme,
            ),
            _buildNavDestination(
              icon: Icons.inbox_outlined,
              selectedIcon: Icons.inbox_rounded,
              label: 'Requests',
              index: 4,
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
            : theme.colorScheme.onSurface.withOpacity(0.6),
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
