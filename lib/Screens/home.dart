import 'package:flutter/material.dart';
import 'package:skill_buddy_fyp/Screens/payment_screen.dart';
import 'package:skill_buddy_fyp/Screens/profile.dart';
import 'package:skill_buddy_fyp/Screens/settings.dart';
import 'Addskill.dart';
import 'Chatlist.dart';
import 'login.dart';
import "Homecontent.dart";
import 'theme.dart';
import 'Myskills.dart';
import 'ViewRequest.dart';
import '../Service/api_service.dart';
import '../config.dart';


class HomePage extends StatefulWidget {
  final String userId;
  final int initialIndex;
  final Map<String, dynamic>? existingData;
  final String? skillId;

  const HomePage({super.key, required this.userId, this.initialIndex = 0, this.existingData, this.skillId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String get currentUserId => widget.userId;
  String userRole = "both";
  Map<String, dynamic>? userProfileData;

  List<Widget> _pages = [];

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
    _selectedIndex = widget.initialIndex;
    _pages = [
      HomeScreenContent(),
      MySkillsPage(userId: currentUserId),
      AddSkillPage(
        existingData: widget.existingData,
        skillId: widget.skillId,
        userId: currentUserId,
      ),
      ChatListPage(currentUserId: currentUserId, baseUrl: baseUrl),
      ViewRequestsPage(role: userRole),
    ];
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    if (currentUserId.isEmpty) return;
    final data = await ApiService.getUserProfile(currentUserId);
    setState(() {
      userRole = (data?['role'] ?? 'both').toString().toLowerCase();
      userProfileData = data;
    });
  }

  Widget _profileAvatar({double radius = 20, bool showBorder = true}) {
    if (userProfileData == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withAlpha((0.12 * 255).toInt()),
        child: Icon(Icons.person_outline, color: AppColors.primary, size: radius),
      );
    }
    String? photoUrl = userProfileData?['photoUrl'];
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withAlpha((0.12 * 255).toInt()),
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
        color: AppColors.primary.withAlpha((0.08 * 255).toInt()),
      ),
      child: avatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isWeb = width >= 900;

    final appBar = PreferredSize(
      preferredSize: const Size.fromHeight(70),
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

    Widget mainContent;
    if (!isWeb) {
      mainContent = IndexedStack(
        index: _selectedIndex,
        children: _pages,
      );
    } else {
      mainContent = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 210,
            height: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.04 * 255).toInt()),
                  blurRadius: 12,
                  offset: const Offset(1, 0),
                ),
              ],
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withAlpha((0.08 * 255).toInt()),
                  width: 1.5,
                ),
              ),
            ),
            child: _buildWebNav(theme),
          ),
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
      bottomNavigationBar: !isWeb
          ? Container(
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
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            indicatorColor: theme.colorScheme.primary.withAlpha((0.15 * 255).toInt()),
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: _selectedIndex == 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
                  color: _selectedIndex == 1
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
                  color: _selectedIndex == 2
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
                  color: _selectedIndex == 3
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
                  color: _selectedIndex == 4
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
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
      )
          : null,
    );
  }

  Widget _buildWebNav(ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () => _showProfileCard(context),
          child: _profileAvatar(radius: 36),
        ),
        const SizedBox(height: 36),
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
          color: isSelected ? theme.colorScheme.primary.withAlpha((0.10 * 255).toInt()) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected ? theme.colorScheme.primary : theme.iconTheme.color?.withAlpha((0.65 * 255).toInt()),
              size: 26,
            ),
            const SizedBox(width: 15),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.textTheme.titleMedium?.color?.withAlpha((0.8 * 255).toInt()),
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
    final displayName = userProfileData?['Fullname'] ?? userProfileData?['fullName'] ?? 'User';
    final email = userProfileData?['email'] ?? '';
    final photoUrl = userProfileData?['photoUrl'] ?? '';
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: 320,
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
                      theme.colorScheme.primary.withAlpha((0.85 * 255).toInt()),
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
              _buildProfileMenuItem(
                icon: Icons.person_outline,
                title: 'My Profile',
                subtitle: 'View and edit your profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: currentUserId)));
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
              // --- Payment Option ---
              _buildProfileMenuItem(
                icon: Icons.payment,
                title: 'Payment',
                subtitle: 'Make a payment',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        onOrderSuccess: () {
                          // You can add your order saving logic here or show a snackbar
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment successful!')),
                          );
                        },
                      ),
                    ),
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
      ),);
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
                      color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).toInt()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),);
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
}
