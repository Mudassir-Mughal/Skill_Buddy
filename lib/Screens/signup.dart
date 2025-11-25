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

  // Only allow emails that end with exactly '@gmail.com', '@yahoo.com', or '@outlook.com' (case-insensitive)
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    // Must match: any non-empty name, then @gmail.com, @yahoo.com, or @outlook.com (no typo, no extra char)
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@(gmail|yahoo|outlook)\.com$', caseSensitive: false);
    return regex.hasMatch(email);
  }

  // Enhanced name validation
  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your name";
    }

    String trimmed = value.trim();

    // Check minimum length
    if (trimmed.length < 2) {
      return "Name must be at least 2 characters";
    }

    // Check maximum length
    if (trimmed.length > 50) {
      return "Name must be less than 50 characters";
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    RegExp nameRegex = RegExp(r"^[a-zA-Z\s\-\'\.]+$");
    if (!nameRegex.hasMatch(trimmed)) {
      return "Name can only contain letters, spaces, hyphens, and apostrophes";
    }

    // Check for excessive spaces
    if (trimmed.contains(RegExp(r'\s{2,}'))) {
      return "Name cannot contain multiple consecutive spaces";
    }

    // Check if name starts or ends with space
    if (trimmed != value.trim()) {
      return "Name cannot start or end with spaces";
    }

    return null;
  }

  // Enhanced email validation with detailed error messages
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter your email";
    }

    String trimmed = value.trim();

    if (!isValidEmail(trimmed)) {
      return "Only valid Gmail, Yahoo, or Outlook addresses (name@gmail.com, name@yahoo.com, name@outlook.com) are allowed";
    }

    return null;
  }

  // Enhanced password validation (keeping it simple as requested - only 8 characters minimum)
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter a password";
    }

    // Only check for minimum 8 characters as requested
    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }

    // Check for maximum length for security
    if (value.length > 128) {
      return "Password must be less than 128 characters";
    }

    return null;
  }

  // Enhanced confirm password validation
  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }

    if (value != passwordController.text) {
      return "Passwords do not match";
    }

    return null;
  }

  Future<void> signUpUser() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _nameError = null;
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = emailController.text.trim().toLowerCase();
      final password = passwordController.text;
      final name = nameController.text.trim();

      if (!isValidEmail(email)) {
        setState(() {
          _emailError = "Please enter a valid email address";
          _isLoading = false;
        });
        return;
      }

      // Remove pre-check, rely on backend for true source of error
      final response = await ApiService.signupWithId(email, password);

      if (response != null && response['userId'] != null) {
        final userId = response['userId'];
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Account created successfully! Please set up your profile."),
            duration: Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SetProfilePage(userId: userId)),
        );
      } else if (response != null && response['message'] != null) {
        String message = response['message'].toString().toLowerCase();
        if (message.contains('email') && (message.contains('exists') || message.contains('taken') || message.contains('registered'))) {
          setState(() {
            _emailError = "This email is already in use. Please use a different email or try logging in.";
            _isLoading = false;
          });
        } else if (message.contains('invalid email')) {
          setState(() {
            _emailError = "Invalid email format. Please check your email address.";
            _isLoading = false;
          });
        } else if (message.contains('password')) {
          setState(() {
            _passwordError = "Password requirements not met. Please try a different password.";
            _isLoading = false;
          });
        } else {
          setState(() {
            _generalError = "Registration failed: ${response['message']}";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _generalError = "Registration failed. Please check your information and try again.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _generalError = "Network error. Please check your connection and try again.";
        _isLoading = false;
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
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
                      // Name Field
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
                          decoration: inputStyle("Full Name", Icons.person),
                          validator: validateName,
                          onChanged: (_) {
                            if (_nameError != null) setState(() => _nameError = null);
                          },
                        ),
                      ),
                      if (_nameError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                _nameError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12)
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Email Field
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
                          decoration: inputStyle("Email", Icons.email),
                          keyboardType: TextInputType.emailAddress,
                          validator: validateEmail,
                          onChanged: (_) {
                            if (_emailError != null) setState(() => _emailError = null);
                          },
                        ),
                      ),
                      if (_emailError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                _emailError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12)
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Password Field
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
                          decoration: inputStyle("Password", Icons.lock),
                          validator: validatePassword,
                          onChanged: (_) {
                            if (_passwordError != null) setState(() => _passwordError = null);
                          },
                        ),
                      ),
                      if (_passwordError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                _passwordError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12)
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
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
                          decoration: inputStyle("Confirm Password", Icons.lock_outline),
                          validator: validateConfirmPassword,
                          onChanged: (_) {
                            if (_confirmPasswordError != null) setState(() => _confirmPasswordError = null);
                          },
                        ),
                      ),
                      if (_confirmPasswordError != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                _confirmPasswordError!,
                                style: const TextStyle(color: Colors.red, fontSize: 12)
                            ),
                          ),
                        ),

                      // General Error Message
                      if (_generalError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                      _generalError!,
                                      style: TextStyle(color: Colors.red.shade700, fontSize: 13)
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Sign Up Button
                      if (_isLoading)
                        Container(
                          height: 55,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                        )
                      else
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

