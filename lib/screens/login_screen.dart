import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'menu_screen.dart';
import 'admin/admin_dashboard.dart';
import '../utils/constants.dart';

/// Student login domains. Admin uses only [AppConstants.adminEmail].
bool _isAdminEmail(String email) =>
    email.trim().toLowerCase() == AppConstants.adminEmail.toLowerCase();

const _allowedStudentDomains = {
  'gmail.com',
  'student.nitandhra.ac.in',
  'student.nitandra.ac.in', // common typo / alternate spelling
};

bool _isAllowedStudentDomain(String email) {
  final lower = email.trim().toLowerCase();
  final at = lower.lastIndexOf('@');
  if (at < 0 || at == lower.length - 1) return false;
  final domain = lower.substring(at + 1);
  return _allowedStudentDomains.contains(domain);
}

String? _validateEmailForAuth(String? val, {required bool isLogin}) {
  if (val == null || val.trim().isEmpty) return 'Enter your email';
  final raw = val.trim();
  if (!raw.contains('@')) return 'Invalid email';

  if (_isAdminEmail(raw)) {
    if (!isLogin) {
      return 'Admin account cannot be registered here. Use Log in.';
    }
    return null;
  }

  if (!_isAllowedStudentDomain(raw)) {
    return 'Only @gmail.com or @student.nitandhra.ac.in (or @student.nitandra.ac.in)';
  }
  return null;
}

String? _validatePasswordForAuth(String? val, {required bool isLogin}) {
  if (val == null || val.isEmpty) return 'Enter your password';
  if (isLogin) return null;

  final p = val;
  if (p.length < 8) return 'At least 8 characters';
  if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Include 1 uppercase letter';
  if (!RegExp(r'[0-9]').hasMatch(p)) return 'Include 1 number';
  if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(p)) {
    return 'Include 1 special character';
  }
  return null;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _sendingReset = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Hard gate before Firebase (covers edge cases where Form validation is skipped).
    final emailErr = _validateEmailForAuth(email, isLogin: _isLogin);
    if (emailErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(emailErr), backgroundColor: Colors.red.shade600),
      );
      return;
    }
    final passErr = _validatePasswordForAuth(password, isLogin: _isLogin);
    if (passErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passErr), backgroundColor: Colors.red.shade600),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email, password: password);
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email, password: password);
      }

      if (!mounted) return;

      if (email.toLowerCase() == AppConstants.adminEmail.toLowerCase()) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const MenuScreen()));
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = switch (e.code) {
        'user-not-found' => 'No account found with this email.',
        'wrong-password' => 'Incorrect password.',
        'email-already-in-use' => 'Email already registered.',
        'weak-password' =>
            'Password too weak for Firebase. Use 8+ chars with uppercase, number & special char.',
        'invalid-email' => 'Please enter a valid email.',
        _ => e.message ?? 'Something went wrong.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Sends Firebase password-reset link to the email in the email field.
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email address first')),
      );
      return;
    }
    final err = _validateEmailForAuth(email, isLogin: true);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: Colors.red.shade600),
      );
      return;
    }

    setState(() => _sendingReset = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reset link sent to $email. Check inbox & spam folder.',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'user-not-found' => 'No account found for this email.',
        'invalid-email' => 'Invalid email address.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        _ => e.message ?? 'Could not send reset email.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade600),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _sendingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top food image section with orange gradient overlay
            Stack(
              children: [
                // Food background image
                Container(
                  height: screenHeight * 0.45,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Orange gradient overlay
                Container(
                  height: screenHeight * 0.45,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xAAE64A19),
                        Color(0xCCFF5722),
                        Color(0xFFFF5722),
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                ),

                // App name and tagline
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'CanteenGo',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                fontFamily: 'serif',
                                letterSpacing: 1,
                              ),
                            ),
                            TextSpan(
                              text: '',
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Skip the Queue!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // White curved bottom section
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // Sign up / Log in toggle
                      Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F0F0),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            // Sign up button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _isLogin = false);
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _formKey.currentState?.validate();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  decoration: BoxDecoration(
                                    color: _isLogin
                                        ? Colors.transparent
                                        : const Color(0xFFFF5722),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Sign up',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _isLogin
                                            ? Colors.grey
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Log in button
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _isLogin = true);
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _formKey.currentState?.validate();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  decoration: BoxDecoration(
                                    color: _isLogin
                                        ? const Color(0xFFFF5722)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Log in',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _isLogin
                                            ? Colors.white
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Email field
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'name@gmail.com or @student.nitandhra.ac.in',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF5722), width: 2),
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        validator: (val) => _validateEmailForAuth(
                          val,
                          isLogin: _isLogin,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password field
                      TextFormField(
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 15),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                              size: 22,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFDDDDDD)),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF5722), width: 2),
                          ),
                          errorBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        validator: (val) => _validatePasswordForAuth(
                          val,
                          isLogin: _isLogin,
                        ),
                      ),

                      // Forgot password — sends link to the email above (Log in or Sign up)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: (_isLoading || _sendingReset)
                              ? null
                              : _resetPassword,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            _sendingReset
                                ? 'Sending link…'
                                : 'Forgot password?',
                            style: TextStyle(
                              color: (_isLoading || _sendingReset)
                                  ? Colors.grey.shade400
                                  : Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      if (!_isLogin) ...[
                        Text(
                          'Password: 8+ chars, 1 uppercase, 1 number, 1 special',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      const SizedBox(height: 8),

                      // Login / Register button
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _sendingReset) ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5722),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Log in' : 'Sign up',
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // OR divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.grey.shade300),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.grey.shade300),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Admin hint
                      Center(
                        child: Text(
                          'Students: @gmail.com or @student.nitandhra.ac.in\nAdmin only: ${AppConstants.adminEmail}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
