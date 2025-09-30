// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'main.dart';
//
// class HomePage extends StatefulWidget {
//   const HomePage({super.key});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   bool isLoggingOut = false;
//
//   // Create GoogleSignIn instance for 6.3
//   final GoogleSignIn _googleSignIn = GoogleSignIn(
//     scopes: ['email', 'profile'],
//   );
//
//   Future<void> _logout() async {
//     setState(() => isLoggingOut = true);
//     try {
//       // Sign out from Firebase
//       await FirebaseAuth.instance.signOut();
//       // Sign out from Google
//       await _googleSignIn.signOut();
//
//       // Navigate back to AuthPage
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const AuthPage()),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text("Logout failed: $e")));
//     } finally {
//       if (mounted) setState(() => isLoggingOut = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final user = FirebaseAuth.instance.currentUser;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Home Page"),
//         actions: [
//           IconButton(
//             icon: isLoggingOut
//                 ? const CircularProgressIndicator(
//                 color: Colors.white, strokeWidth: 2)
//                 : const Icon(Icons.logout),
//             onPressed: isLoggingOut ? null : _logout,
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               "Welcome, ${user?.email ?? 'User'}!",
//               style:
//               const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               "You are now logged in successfully.",
//               style: TextStyle(fontSize: 16),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseEmailVerificationTest extends StatefulWidget {
  @override
  State<FirebaseEmailVerificationTest> createState() => _FirebaseEmailVerificationTestState();
}

class _FirebaseEmailVerificationTestState extends State<FirebaseEmailVerificationTest> {
  String status = "";
  bool loading = false;

  Future<void> sendVerificationEmail() async {
    setState(() { loading = true; status = ""; });
    try {
      UserCredential cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: "mughalmudassir33@gmail.com",
        password: "121212", // <-- put your password here!
      );
      User? user = cred.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        setState(() {
          status = "Verification email sent to ${user.email}.";
        });
      } else if (user != null && user.emailVerified) {
        setState(() {
          status = "Email already verified.";
        });
      } else {
        setState(() {
          status = "No user found.";
        });
      }
    } catch (e) {
      setState(() {
        status = "Error: $e";
      });
    } finally {
      setState(() { loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Test Firebase Verification Email",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading ? null : sendVerificationEmail,
                child: Text("Send Verification Email"),
              ),
              if (loading) ...[
                const SizedBox(height: 18),
                CircularProgressIndicator(),
              ],
              const SizedBox(height: 24),
              Text(status, style: TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }
}