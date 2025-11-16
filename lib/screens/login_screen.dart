import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'resume_builder.dart';  // ✅ make sure this path is correct

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = FirebaseAuth.instance;

  bool _loading = false;
  bool _obscure = true;

  Future<void> signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      // ✅ If successful → go to Resume Pager
      Navigator.pushReplacement(
        
        context,
        MaterialPageRoute(builder: (context) => const ResumeBuilder()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> signUp() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account created successfully')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'Sign up failed')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid email to reset password')));
      return;
    }
    try {
      await auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'Failed to send reset email')));
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Colors.teal;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.shade700, theme.shade300], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 10,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: theme.shade50,
                        child: Icon(Icons.account_circle, size: 48, color: theme.shade700),
                      ),
                      const SizedBox(height: 12),
                      Text('Welcome Back', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('Sign in to continue to Ace Interview', style: TextStyle(color: Colors.black54)),
                      const SizedBox(height: 18),

                      Form(
                        key: _formKey,
                        child: Column(children: [
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration('Email', Icons.email),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                            onFieldSubmitted: (_) => signIn(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscure,
                            decoration: _inputDecoration('Password', Icons.lock).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password required';
                              if (v.length < 6) return 'Min 6 characters';
                              return null;
                            },
                            onFieldSubmitted: (_) => signIn(),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _resetPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _loading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: CircularProgressIndicator(),
                                )
                              : Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: signIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: theme.shade700,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Login'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: signUp,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: theme.shade700),
                                          foregroundColor: theme.shade700,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        child: const Text('Sign Up'),
                                      ),
                                    ),
                                  ],
                                ),
                        ]),
                      ),

                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 12),

                      // optional quick actions
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google sign-in not configured')));
                            },
                            icon: const Icon(Icons.g_mobiledata),
                            label: const Text('Sign in with Google'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      Text('By continuing you agree to our Terms & Privacy', style: TextStyle(fontSize: 12, color: Colors.black54), textAlign: TextAlign.center),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
