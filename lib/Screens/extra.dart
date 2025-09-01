//
//
// import 'package:flutter/material.dart';
// import 'package:skill_buddy/Screens/Chatlist.dart';
// import 'package:skill_buddy/Screens/profile.dart';
// import 'package:skill_buddy/Screens/settings.dart';
// import 'login.dart';
// import 'theme.dart';
// import 'ViewRequest.dart';
// import 'Homecontent.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
//
// class StudentHomePage extends StatefulWidget {
//   const StudentHomePage({super.key});
//
//   @override
//   State<StudentHomePage> createState() => _StudentHomePageState();
// }
//
// class _StudentHomePageState extends State<StudentHomePage> {
//   int _selectedIndex = 0;
//
//   static const List<Widget> _pages = <Widget>[
//     HomeScreenContent(),
//     ChatListPage(),
//     ViewRequestsPage(role: "Student"),
//     ProfilePage(),
//   ];
//
//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: PreferredSize(
//         preferredSize: const Size.fromHeight(68),
//         child: AppBar(
//           elevation: 0,
//           backgroundColor: Colors.transparent,
//           flexibleSpace: Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF6C63FF),
//                   Color(0xFF4F5EE2),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           shape: const RoundedRectangleBorder(
//             borderRadius: BorderRadius.vertical(
//               bottom: Radius.circular(24),
//             ),
//           ),
//           title: const Text(
//             "Skill Buddy",
//             style: TextStyle(
//               fontSize: 23,
//               fontWeight: FontWeight.bold,
//               color: Colors.white,
//               letterSpacing: 0.7,
//             ),
//           ),
//           centerTitle: true,
//           leading: Builder(
//             builder: (context) => IconButton(
//               icon: const Icon(Icons.menu, color: Colors.white),
//               onPressed: () => Scaffold.of(context).openDrawer(),
//               tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
//             ),
//           ),
//         ),
//       ),
//       drawer: Drawer(
//         backgroundColor: Colors.white,
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.only(
//             topRight: Radius.circular(24),
//             bottomRight: Radius.circular(24),
//           ),
//         ),
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             Container(
//               height: 150,
//               padding: const EdgeInsets.all(28),
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     Color(0xFF6C63FF),
//                     Color(0xFF4F5EE2),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: BorderRadius.only(
//                   topRight: Radius.circular(24),
//                 ),
//               ),
//               child: const Align(
//                 alignment: Alignment.bottomLeft,
//                 child: Text(
//                   'Skill Buddy Menu',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 25,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 10),
//             ListTile(
//               leading: const Icon(Icons.account_circle, color: Color(0xFF6C63FF)),
//               title: const Text(
//                 'My Profile',
//                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (_) => const ProfilePage()));
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.settings, color: Color(0xFF6C63FF)),
//               title: const Text(
//                 'Settings',
//                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(context,
//                     MaterialPageRoute(builder: (_) => const SettingsPage()));
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout, color: Colors.redAccent),
//               title: const Text(
//                 'Logout',
//                 style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
//               ),
//               onTap: () async {
//                 try {
//                   final GoogleSignIn googleSignIn = GoogleSignIn();
//
//                   if (await googleSignIn.isSignedIn()) {
//                     await googleSignIn.disconnect();
//                     await googleSignIn.signOut();
//                   }
//
//                   await FirebaseAuth.instance.signOut();
//
//                   Navigator.pushAndRemoveUntil(
//                     context,
//                     MaterialPageRoute(builder: (_) => const LoginPage()),
//                         (route) => false,
//                   );
//                 } catch (e) {
//                   debugPrint("Logout error: $e");
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text("Error signing out")),
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//       body: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 300),
//         child: _pages[_selectedIndex],
//       ),
//       bottomNavigationBar: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF6C63FF),
//               Color(0xFF4F5EE2),
//             ],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
//           boxShadow: [
//             BoxShadow(
//               color: Color(0x22000000),
//               blurRadius: 20,
//               offset: Offset(0, -2),
//             ),
//           ],
//         ),
//         child: SizedBox(
//           height: 68,
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _navBarIcon(
//                 icon: Icons.home,
//                 index: 0,
//                 selected: _selectedIndex == 0,
//                 onTap: () => _onItemTapped(0),
//               ),
//               _navBarIcon(
//                 icon: Icons.chat,
//                 index: 1,
//                 selected: _selectedIndex == 1,
//                 onTap: () => _onItemTapped(1),
//               ),
//               _navBarIcon(
//                 icon: Icons.inbox,
//                 index: 2,
//                 selected: _selectedIndex == 2,
//                 onTap: () => _onItemTapped(2),
//               ),
//               _navBarIcon(
//                 icon: Icons.person,
//                 index: 3,
//                 selected: _selectedIndex == 3,
//                 onTap: () => _onItemTapped(3),
//               ),
//             ],
//           ),
//         ),
//       ),
//   );
//   }
//
//   Widget _navBarIcon({
//     required IconData icon,
//     required int index,
//     required bool selected,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 180),
//         padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
//         decoration: BoxDecoration(
//           color: selected
//               ? Colors.white.withOpacity(0.18)
//               : Colors.transparent,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         child: Icon(
//           icon,
//           color: selected ? Colors.white : Colors.white70,
//           size: 28,
//         ),
//       ),
//     );
//   }
// }