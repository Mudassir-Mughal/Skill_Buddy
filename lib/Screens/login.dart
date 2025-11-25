import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_buddy_fyp/Screens/setprofile.dart';
import 'StudentHome.dart';
import 'home.dart';
import 'signup.dart';
import 'theme.dart';
import '../Service/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w]{2,4}").hasMatch(email);
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _otpController = TextEditingController();
    final TextEditingController _newPasswordController = TextEditingController();
    String? dialogError;
    String step = 'email'; // email -> otp -> password
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> sendOtp() async {
            setState(() { isLoading = true; dialogError = null; });
            final email = _emailController.text.trim();
            if (email.isEmpty) {
              setState(() { dialogError = "Please enter your email."; isLoading = false; });
              return;
            }
            // Improved email regex
            final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}");
            if (!emailRegex.hasMatch(email)) {
              setState(() { dialogError = "Please enter a valid email address."; isLoading = false; });
              return;
            }
            final sent = await ApiService.sendForgotPasswordOtp(email);
            if (sent) {
              setState(() { step = 'otp'; isLoading = false; });
            } else {
              setState(() { dialogError = "Failed to send OTP. Please try again."; isLoading = false; });
            }
          }

          Future<void> verifyOtp() async {
            setState(() { isLoading = true; dialogError = null; });
            final email = _emailController.text.trim();
            final otp = _otpController.text.trim();
            if (otp.isEmpty) {
              setState(() { dialogError = "Please enter the OTP."; isLoading = false; });
              return;
            }
            final verified = await ApiService.verifyOtp(email, otp);
            if (verified) {
              setState(() { step = 'password'; isLoading = false; });
            } else {
              setState(() { dialogError = "Invalid or expired OTP."; isLoading = false; });
            }
          }

          Future<void> resetPassword() async {
            setState(() { isLoading = true; dialogError = null; });
            final email = _emailController.text.trim();
            final newPassword = _newPasswordController.text.trim();
            if (newPassword.length < 6) {
              setState(() { dialogError = "Password must be at least 6 characters."; isLoading = false; });
              return;
            }
            final reset = await ApiService.resetPassword(email, newPassword);
            if (reset) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Password updated. You can now log in.")),
              );
            } else {
              setState(() { dialogError = "Failed to reset password. Try again."; isLoading = false; });
            }
          }

          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              step == 'email' ? "Reset Password" : step == 'otp' ? "Enter OTP" : "Set New Password",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (step == 'email') ...[
                  const Text("Enter your email to reset your password", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: "Email Address",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      errorText: dialogError,
                    ),
                  ),
                ] else if (step == 'otp') ...[
                  const Text("Enter the OTP sent to your email", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "6-digit OTP",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      errorText: dialogError,
                    ),
                  ),
                ] else ...[
                  const Text("Enter your new password", style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: "New Password",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      errorText: dialogError,
                    ),
                  ),
                ],
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isLoading
                    ? null
                    : () {
                        if (step == 'email') {
                          sendOtp();
                        } else if (step == 'otp') {
                          verifyOtp();
                        } else {
                          resetPassword();
                        }
                      },
                child: Text(
                  step == 'email'
                      ? "Send OTP"
                      : step == 'otp'
                          ? "Verify OTP"
                          : "Reset Password",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> loginUser() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final result = await ApiService.login(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
        if (result == null || result['userId'] == null) {
          setState(() => _generalError = "Login failed. Please enter correct email and password.");
        } else {
          final userId = result['userId'];
          // Save userId to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', userId);
          final profile = await ApiService.getUserProfile(userId);
          final profileSet = profile?['profileSet'] == true;
          final role = (profile?['role'] ?? '').toString().toLowerCase();
          if (!profileSet) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => SetProfilePage(userId: userId),
              ),
            );
          } else if (role == 'student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => StudentHomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage(userId: userId)),
            );
          }
        }
      } catch (e) {
        setState(() => _generalError = "Login failed. Please enter correct email and password.");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> signInWithGoogle({required BuildContext context, required bool isFromSignUp}) async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      await googleSignIn.signOut();
      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account == null) {
        setState(() {
          _generalError = "Google sign-in cancelled.";
          _isLoading = false;
        });
        return;
      }
      final email = account.email;
      // Always fetch latest user profile by email (to get updated profileSet)
      Map<String, dynamic>? userProfile = await ApiService.getUserByEmail(email);
      // DEBUG: Print userProfile for troubleshooting
      print('Google sign-in userProfile:');
      print(userProfile);
      if (userProfile == null) {
        // If user does not exist, create user in backend
        final createRes = await ApiService.createUserWithGoogle(email);
        print('Google sign-in createUserWithGoogle response:');
        print(createRes);
        // Fetch again after creation
        userProfile = await ApiService.getUserByEmail(email);
        print('Google sign-in userProfile after create:');
        print(userProfile);
      }
      if (userProfile != null) {
        final profileSet = userProfile['profileSet'] == true;
        final role = (userProfile['role'] ?? '').toString().toLowerCase();
        final userId = userProfile['userId'] ?? userProfile['_id'] ?? '';
        // Save userId to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        if (profileSet) {
          if (role == 'student') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => StudentHomePage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage(userId: userId)),
            );
          }
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => SetProfilePage(userId: userId, hideBackButton: true),
            ),
          );
        }
      } else {
        setState(() {
          _generalError = "Google sign-in failed. Could not create user.";
        });
      }
    } catch (e) {
      setState(() {
        _generalError = "Google sign-in failed. Please try again.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration inputStyle(String label, IconData icon, {String? errorText}) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: AppColors.primary),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white,
      errorText: errorText,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Logo and App Name Section: visually matches splash screen
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6C63FF),
                        Color(0xFF4F5EE2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6C63FF).withOpacity(0.15),
                        blurRadius: 24,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C63FF).withOpacity(0.11),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.handshake_rounded,
                          size: 40,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF6C63FF),
                      Color(0xFF4F5EE2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    "Skill Buddy",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Login to continue",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),

                // Login Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Email Field with error
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: emailController,
                          decoration: inputStyle("Email", Icons.email, errorText: _emailError)
                              .copyWith(
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value!.isEmpty) return "Please enter your email";
                            if (!isValidEmail(value)) return "Invalid email format";
                            return null;
                          },
                          onChanged: (_) {
                            if (_emailError != null) {
                              setState(() => _emailError = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Show email error below field (if any)
                      if (_emailError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _emailError!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ),

                      const SizedBox(height: 6),
                      // Password Field with error
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: inputStyle("Password", Icons.lock, errorText: _passwordError)
                              .copyWith(
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) =>
                          value!.isEmpty ? "Please enter your password" : null,
                          onChanged: (_) {
                            if (_passwordError != null) {
                              setState(() => _passwordError = null);
                            }
                          },
                        ),
                      ),
                      if (_passwordError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _passwordError!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ),

                      // Forgot Password Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPasswordDialog(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                          ),
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      if (_generalError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
                          child: Text(
                            _generalError!,
                            style: const TextStyle(color: Colors.red, fontSize: 13),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                        Column(
                          children: [
                            // Login Button
                            Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF4F5EE2),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: loginUser,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // OR Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    "OR",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Google Sign In Button
                            Container(
                              width: double.infinity,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: OutlinedButton(
                                onPressed: () => signInWithGoogle(
                                  context: context,
                                  isFromSignUp: false,
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero, // we’ll handle padding ourselves
                                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'images/google_icon.png',
                                        height: 24,
                                        width: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      // THIS is the trick:
                                      Flexible(
                                        child: Text(
                                          "Continue with Google",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black87,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          ],
                        ),
                      const SizedBox(height: 20),
                      // Sign Up Link
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SignUpPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Sign up",
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
