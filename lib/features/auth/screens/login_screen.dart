import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../../dashboard/screens/main_layout.dart';
import 'shop_registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    _fadeController.forward();
    _slideController.forward();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      if (event == AuthChangeEvent.signedIn && session != null) {
        final shopRes = await Supabase.instance.client
            .from('shops')
            .select()
            .eq('owner_id', session.user.id)
            .maybeSingle();
        if (mounted) {
          if (shopRes != null) {
            Navigator.pushReplacement(context, _pageRoute(const MainLayout()));
          } else {
            Navigator.pushReplacement(context, _pageRoute(const ShopRegistrationScreen()));
          }
        }
      }
    });
  }

  PageRoute _pageRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      );

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.merchantapp://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        _showError('Google Sign-In failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showError('Please enter a valid phone number.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final email = '$phone@nolato.com';
      const password = 'password123';
      AuthResponse res;
      try {
        res = await Supabase.instance.client.auth.signInWithPassword(email: email, password: password);
      } catch (_) {
        res = await Supabase.instance.client.auth.signUp(email: email, password: password);
      }
      final user = res.user;
      if (user != null && mounted) {
        final shopRes = await Supabase.instance.client.from('shops').select().eq('owner_id', user.id).maybeSingle();
        if (mounted) {
          Navigator.pushReplacement(context, _pageRoute(shopRes != null ? const MainLayout() : const ShopRegistrationScreen()));
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient blobs
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.electricBlue.withValues(alpha: 0.18), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.purpleAccent.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 70),
                      // Logo
                      Center(
                        child: Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.electricBlue, AppColors.purpleAccent],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.electricBlue.withValues(alpha: 0.5),
                                blurRadius: 30,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 44),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Sign in to manage your store and\ngrow your business with Nolate.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
                      ),
                      const SizedBox(height: 52),

                      // Google Sign-In Button
                      GlassContainer(
                        padding: EdgeInsets.zero,
                        borderRadius: 18,
                        glow: true,
                        glowColor: Colors.white,
                        child: InkWell(
                          onTap: _isLoading ? null : _signInWithGoogle,
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Text('G', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w900, fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Continue with Google',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.glassBorder, thickness: 1)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('or continue with phone', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ),
                          const Expanded(child: Divider(color: AppColors.glassBorder, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Phone Input
                      GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              decoration: const InputDecoration(
                                hintText: 'Phone Number',
                                prefixIcon: Icon(Icons.phone_rounded, color: AppColors.electricBlue),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _isLoading
                                ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue, strokeWidth: 2.5))
                                : Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppColors.electricBlue, AppColors.blueGlow],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.electricBlue.withValues(alpha: 0.45),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _signInWithPhone,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        padding: const EdgeInsets.symmetric(vertical: 18),
                                      ),
                                      child: const Text('Get Started →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'By signing in, you agree to our Terms of Service\nand Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.7),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
