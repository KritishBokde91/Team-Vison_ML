import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  GoogleSignInAccount? _currentUser;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.ease),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: "268069475714-df41ma7nrk8cp4sfp3nj9bj84u9a857b.apps.googleusercontent.com",
      );

      GoogleSignIn.instance.authenticationEvents.listen((event) {
        debugPrint('Auth event type: ${event.runtimeType}');
        final eventString = event.runtimeType.toString();

        if (eventString.contains('SignIn') && !eventString.contains('Failed')) {
          try {
            final userProperty = (event as dynamic).user as GoogleSignInAccount?;
            if (userProperty != null) {
              _handleAuthenticationSuccess(userProperty);
            }
          } catch (e) {
            debugPrint('Error extracting user from event: $e');
          }
        } else if (eventString.contains('SignOut')) {
          setState(() => _currentUser = null);
        } else if (eventString.contains('Failed')) {
          _handleAuthenticationError('Authentication failed');
        }
      }, onError: (error) {
        debugPrint('Authentication stream error: $error');
        _handleAuthenticationError('Authentication error: $error');
      });

      await GoogleSignIn.instance.attemptLightweightAuthentication();
    } catch (e) {
      debugPrint('Google Sign-In initialization error: $e');
    }
  }

  Future<void> _handleAuthenticationSuccess(GoogleSignInAccount user) async {
    try {
      setState(() => _currentUser = user);

      // Get the authentication tokens
      final GoogleSignInAuthentication googleAuth = user.authentication;

      if (googleAuth.idToken == null) {
        _showSnackBar('Failed to get ID token', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      debugPrint('Got ID Token, signing in to Supabase...');

      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );

      if (mounted) {
        _showSnackBar('Signed in with Google!', Colors.green);
        _navigateToHome();
      }
    } on AuthException catch (e) {
      debugPrint('Supabase auth error: ${e.message}');
      _showSnackBar('Supabase auth error: ${e.message}', Colors.red);
    } catch (e) {
      debugPrint('Google login failed: $e');
      _showSnackBar('Google login failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthenticationError(String error) {
    debugPrint('Authentication error: $error');
    if (mounted) {
      _showSnackBar(error, Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startGoogleSignIn() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (GoogleSignIn.instance.supportsAuthenticate()) {
        await GoogleSignIn.instance.authenticate();
      } else {
        _showSnackBar(
          'Platform does not support authentication',
          Colors.orange,
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _showSnackBar('Google Sign-In failed: $e', Colors.red);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (response.user != null && mounted) {
        _showSnackBar('Welcome back!', Colors.green);
        _navigateToHome();
      }
    } on AuthException catch (e) {
      String message = e.message;

      if (e.statusCode == '400') {
        message = 'Invalid email or password';
      } else if (e.statusCode == '422') {
        message = 'Please verify your email first';
      } else if (message.toLowerCase().contains('invalid')) {
        message = 'Invalid login credentials';
      }

      _showSnackBar(message, Colors.red);
    } catch (e) {
      debugPrint('Email login error: $e');
      _showSnackBar('Login failed. Please try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePlaceholder(currentUser: _currentUser),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2DC8CC), Color(0xFFC7F497)],
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: GlassContainer(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: Icon(
                                Icons.flutter_dash,
                                size: 50,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 32),

                            _buildTextField(
                              controller: _emailController,
                              hint: 'Email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 24),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _signInWithEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade700,
                                  elevation: 8,
                                  disabledBackgroundColor: Colors.white
                                      .withValues(alpha: 0.7),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SpinKitThreeBounce(
                                        color: Colors.blue,
                                        size: 24,
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            const Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white38)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'OR',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.white38)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _startGoogleSignIn,
                                icon: SvgPicture.asset(
                                  'assets/icons/google.svg',
                                  width: 24,
                                  height: 24,
                                ),
                                label: const Text(
                                  'Continue with Google',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  disabledForegroundColor: Colors.white54,
                                  side: const BorderSide(color: Colors.white38),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () {},
                              child: Text.rich(
                                TextSpan(
                                  text: "Don't have an account? ",
                                  style: const TextStyle(color: Colors.white70),
                                  children: const [
                                    TextSpan(
                                      text: 'Sign Up',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white70,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.yellowAccent),
      ),
      validator: validator,
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class HomePlaceholder extends StatelessWidget {
  final GoogleSignInAccount? currentUser;

  const HomePlaceholder({super.key, this.currentUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await Supabase.instance.client.auth.signOut();
                if (currentUser != null) {
                  await GoogleSignIn.instance.disconnect();
                }

                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              } catch (e) {
                debugPrint('Sign out error: $e');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Logged In Successfully!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (currentUser != null) ...[
              Text(
                'Hello, ${currentUser?.displayName ?? "User"}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                currentUser?.email ?? '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ] else if (Supabase.instance.client.auth.currentUser != null) ...[
              Text(
                'Email: ${Supabase.instance.client.auth.currentUser?.email ?? ""}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
