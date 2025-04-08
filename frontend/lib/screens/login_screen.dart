import 'package:flutter/material.dart';
import '../utils/storage.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for login fields
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

  // Controllers for registration fields
  final _registerUsernameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureRegisterPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _isLoading = false;

  // Flag to toggle between login and registration
  bool _isRegistering = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _registerUsernameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_loginController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Username and password are required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Try API login first
      final response = await ApiService.login(
        _loginController.text,
        _passwordController.text,
      );

      if (response.success) {
        // Also save the user locally for offline login
        await Storage.saveUser(
          _loginController.text,
          _passwordController.text,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        // Check if it's a connection error (which typically starts with "Could not connect")
        if (response.errorMessage?.startsWith('Could not connect') == true) {
          // If there's a connection error, fall back to local authentication
          final isValidLocal = await Storage.validateUser(
            _loginController.text,
            _passwordController.text,
          );

          if (isValidLocal && mounted) {
            // Show a snackbar about offline mode
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Logged in offline mode. Some features may be limited.'),
                duration: Duration(seconds: 3),
              ),
            );

            Navigator.pushReplacementNamed(context, '/');
          } else {
            setState(() {
              _errorMessage =
                  'Cannot connect to server and offline login failed. Try demo:123';
            });
          }
        } else {
          // Standard error message for other failures
          setState(() {
            _errorMessage =
                response.errorMessage ?? 'Invalid credentials. Try demo:123';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    // Basic form validation
    if (_registerUsernameController.text.isEmpty ||
        _registerEmailController.text.isEmpty ||
        _registerPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
      });
      return;
    }

    // Password confirmation check
    if (_registerPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    // Simple email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_registerEmailController.text)) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.register(
        _registerUsernameController.text,
        _registerEmailController.text,
        _registerPasswordController.text,
        _confirmPasswordController.text,
      );

      if (response.success) {
        // Save user locally as well
        await Storage.saveUser(
          _registerUsernameController.text,
          _registerPasswordController.text,
        );

        if (mounted) {
          // Show success message and switch back to login
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! You can now log in.'),
              backgroundColor: Colors.green,
            ),
          );

          // Clear fields and switch to login mode
          _registerUsernameController.clear();
          _registerEmailController.clear();
          _registerPasswordController.clear();
          _confirmPasswordController.clear();

          setState(() {
            _isRegistering = false;
          });
        }
      } else {
        // Check if it's a connection error
        if (response.errorMessage?.startsWith('Could not connect') == true) {
          // Create account locally only with a warning
          await Storage.saveUser(
            _registerUsernameController.text,
            _registerPasswordController.text,
          );

          if (mounted) {
            // Show warning about local-only account
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Created local account only. You\'ll need to register online when connectivity is restored.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );

            // Clear fields and switch to login mode
            _registerUsernameController.clear();
            _registerEmailController.clear();
            _registerPasswordController.clear();
            _confirmPasswordController.clear();

            setState(() {
              _isRegistering = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = response.errorMessage;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/login-bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white.withOpacity(0.9),
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.3, 0.6, 0.9],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    Image.asset(
                      'assets/images/login-logo.png',
                      height: 290,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text('Error loading logo');
                      },
                    ),

                    // Wrap the entire login section in Transform.translate
                    Transform.translate(
                      offset: const Offset(0, -70), // Move everything upward
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Big "Log In" or "Register" text with Rakkas font
                          Text(
                            _isRegistering ? 'Register' : 'Log In',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF96C994),
                              fontFamily: 'Rakkas',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 25),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Show different fields based on mode
                          if (_isRegistering) ...[
                            // Username field
                            _buildInputField(
                              controller: _registerUsernameController,
                              hintText: 'Username',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),

                            // Email field
                            _buildInputField(
                              controller: _registerEmailController,
                              hintText: 'Email',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 16),

                            // Password field
                            _buildInputField(
                              controller: _registerPasswordController,
                              hintText: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: _obscureRegisterPassword,
                              onTogglePassword: () {
                                setState(() {
                                  _obscureRegisterPassword =
                                      !_obscureRegisterPassword;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password field
                            _buildInputField(
                              controller: _confirmPasswordController,
                              hintText: 'Confirm Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: _obscureConfirmPassword,
                              onTogglePassword: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ] else ...[
                            // Username/Email field for login
                            _buildInputField(
                              controller: _loginController,
                              hintText: 'Username or Email',
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),

                            // Password field for login
                            _buildInputField(
                              controller: _passwordController,
                              hintText: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              obscureText: _obscurePassword,
                              onTogglePassword: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),

                            // Forgot Password link aligned to the right
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Implement forgot password logic
                                },
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          // Login or Register button
                          Center(
                            child: Container(
                              width: 140,
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(0xFF96C994),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : (_isRegistering
                                        ? _handleRegister
                                        : _handleLogin),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        _isRegistering ? 'Register' : 'Log In',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Toggle between login and register
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isRegistering
                                    ? "Already have an account? "
                                    : "Don't have an account? ",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        setState(() {
                                          _isRegistering = !_isRegistering;
                                          _errorMessage =
                                              null; // Clear error messages
                                        });
                                      },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _isRegistering
                                      ? 'Log in'
                                      : 'Create your account',
                                  style: const TextStyle(
                                    color: Color(0xFF96C994),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    Function()? onTogglePassword,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Directionality(
        // Force LTR text direction for the input fields
        textDirection: TextDirection.ltr,
        child: TextField(
          controller: controller,
          obscureText: isPassword && obscureText,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF96C994),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF96C994),
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF96C994),
                    ),
                    onPressed: onTogglePassword,
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }
}
