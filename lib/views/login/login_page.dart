import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_scaffold.dart';
import '../register_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // Add loading state
  String? _errorMessage; // Add error message state

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
    });

    // Also show snackbar for immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );

    // Clear error message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  void _login() async {
    // Validate input fields
    if (_emailController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your email.');
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your password.');
      return;
    }

    // Clear previous error message
    setState(() {
      _errorMessage = null;
    });

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.loginUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Only navigate if login was successful AND user is not null
      if (user != null && user.isNotEmpty) {
        if (!mounted) return; // Check if widget is still mounted
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AppScaffold()),
        );
      } else {
        // Login failed - stay on login screen and show error
        if (!mounted) return;
        _showErrorMessage('Wrong username or password. Please try again.');
      }
    } catch (e) {
      // Login failed with exception - stay on login screen
      if (!mounted) return;

      // Parse specific Firebase Auth errors
      String errorMessage = 'Login failed. Please try again.';

      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account found with this email address.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Wrong password. Please try again.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (e.toString().contains('user-disabled')) {
        errorMessage = 'This account has been disabled.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many failed attempts. Please try again later.';
      } else if (e.toString().contains('network-request-failed')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('invalid-credential')) {
        errorMessage = 'Wrong username or password. Please try again.';
      }

      _showErrorMessage(errorMessage);
    } finally {
      // Stop loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 219, 189, 0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/splash/splash.png', width: 100, height: 100),
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Login to AutoCare',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Show error message if exists
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isLoading, // Disable during loading
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        enabled: !_isLoading, // Disable during loading
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            _isLoading ? null : _login, // Disable when loading
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('Login'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                onPressed:
                    _isLoading
                        ? null
                        : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        },
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
