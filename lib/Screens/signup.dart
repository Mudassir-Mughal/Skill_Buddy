import 'package:flutter/material.dart';
import 'theme.dart';
import 'login.dart';
import 'setprofile.dart';
import '../Service/api_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nameController = TextEditingController();

  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _nameError;
  String? _generalError;

  bool isValidEmail(String email) {
    return RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w]{2,4}").hasMatch(email);
  }

  Future<void> signUpUser() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _nameError = null;
      _generalError = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final email = emailController.text.trim();
        final password = passwordController.text;
        final name = nameController.text.trim();

        // Call backend API for signup and get userId from response
        final response = await ApiService.signupWithId(email, password);
        if (response != null && response['userId'] != null) {
          final userId = response['userId'];
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "✅ Account created! Please set up your profile.",
              ),
              duration: Duration(seconds: 4),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SetProfilePage(userId: userId)),
          );
        } else {
          setState(() {
            _generalError = "Sign up failed. Email may already be registered.";
          });
        }
      } catch (e) {
        setState(() {
          _generalError = "Unexpected error. Please try again.";
        });
      } finally {
        setState(() => _isLoading = false);
      }
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
                const SizedBox(height: 32),
                // Logo and App Name Section
                Container(
                  width: 100,
                  height: 100,
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
                        color: Color(0xFF6C63FF).withOpacity(0.16),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF6C63FF).withOpacity(0.12),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.handshake_rounded,
                          size: 36,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
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
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Create a new account",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),
                // SignUp Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Name
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: nameController,
                          decoration: inputStyle("Full Name", Icons.person, errorText: _nameError),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return "Please enter your name";
                            if (value.trim().length < 3) return "Name too short";
                            return null;
                          },
                          onChanged: (_) {
                            if (_nameError != null) setState(() => _nameError = null);
                          },
                        ),
                      ),
                      if (_nameError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_nameError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ),
                        ),
                      const SizedBox(height: 14),
                      // Email
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: emailController,
                          decoration: inputStyle("Email", Icons.email, errorText: _emailError),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return "Please enter your email";
                            if (!isValidEmail(value.trim())) return "Invalid email format";
                            return null;
                          },
                          onChanged: (_) {
                            if (_emailError != null) setState(() => _emailError = null);
                          },
                        ),
                      ),
                      if (_emailError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_emailError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ),
                        ),
                      const SizedBox(height: 14),
                      // Password
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: inputStyle("Password", Icons.lock, errorText: _passwordError),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Please enter a password";
                            if (value.length < 6) return "Password should be at least 6 characters";
                            return null;
                          },
                          onChanged: (_) {
                            if (_passwordError != null) setState(() => _passwordError = null);
                          },
                        ),
                      ),
                      if (_passwordError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_passwordError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ),
                        ),
                      const SizedBox(height: 14),
                      // Confirm Password
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: inputStyle("Confirm Password", Icons.lock_outline, errorText: _confirmPasswordError),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Please confirm your password";
                            if (value != passwordController.text) return "Passwords do not match";
                            return null;
                          },
                          onChanged: (_) {
                            if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                          },
                        ),
                      ),
                      if (_confirmPasswordError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_confirmPasswordError!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                          ),
                        ),
                      if (_generalError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 2),
                          child: Text(_generalError!,
                              style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ),
                      const SizedBox(height: 22),
                      if (_isLoading)
                        const CircularProgressIndicator()
                      else
                      // Sign Up Button
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
                                color: AppColors.primary.withOpacity(0.22),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: signUpUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 18),
                      // Already have account link
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: "Already have an account? ",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: "Login",
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
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
