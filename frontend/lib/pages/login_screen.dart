import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // ✅ make sure the path matches your project structure

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService().loginUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        context,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  "Travelers App",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Welcome back",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Login to continue your journey",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

                // Email field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (val) => val == null || !val.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 20),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your password' : null,
                ),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/reset_password'),
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(color: Color(0xFF4C8DFF)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C8DFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 30),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/register'),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Color(0xFF4C8DFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
            