import 'package:flutter/material.dart';
import '../utils/storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final isValid = await Storage.validateUser(
      _emailController.text,
      _passwordController.text,
    );

    if (isValid) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid credentials. Try demo:password123';
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
                          // Big "Log In" text with Rakkas font
                          const Text(
                            'Log In',
                            style: TextStyle(
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
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: Directionality(
                              // Force LTR text direction for the input fields
                              textDirection: TextDirection.ltr,
                              child: TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF96C994),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF96C994),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: Directionality(
                              // Force LTR text direction for the input fields
                              textDirection: TextDirection.ltr,
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF96C994),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: Color(0xFF96C994),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: const Color(0xFF96C994),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                              ),
                            ),
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
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                          const SizedBox(height: 18),
                          // Updated login button with new color and smaller size
                          Center(
                            child: Container(
                              width: 140, // Make the button smaller
                              height: 45,
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFF96C994), // Exact color from blueprint
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // TODO: Navigate to signup screen
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(0, 0),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Create your account',
                                  style: TextStyle(
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
}
