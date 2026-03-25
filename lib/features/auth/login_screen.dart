// lib/features/auth/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _formKey      = GlobalKey<FormState>();
  bool  _showPassword = false;
  bool  _emailExpanded = false;

  // ── Animation controllers ────────────────────────────────────────────────
  late final AnimationController _bgAnim;
  late final AnimationController _fadeAnim;
  late final AnimationController _emailExpandAnim;

  late final Animation<double> _fadeCurve;
  late final Animation<double> _slideCurve;
  late final Animation<double> _emailExpandCurve;

  @override
  void initState() {
    super.initState();

    // Subtle animated background
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    // Page fade-in on load
    _fadeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeCurve = CurvedAnimation(parent: _fadeAnim, curve: Curves.easeOut);
    _slideCurve = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _fadeAnim, curve: Curves.easeOutCubic),
    );

    // Email form expand/collapse
    _emailExpandAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _emailExpandCurve = CurvedAnimation(
      parent: _emailExpandAnim,
      curve: Curves.easeInOutCubic,
    );

    _fadeAnim.forward();
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _fadeAnim.dispose();
    _emailExpandAnim.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Auth actions ─────────────────────────────────────────────────────────
  Future<void> _googleSignIn() async {
    HapticFeedback.lightImpact();
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).signInWithGoogle();
    _handleAuthResult();
  }

  Future<void> _appleSignIn() async {
    HapticFeedback.lightImpact();
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).signInWithApple();
    _handleAuthResult();
  }

  Future<void> _emailSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    ref.read(authProvider.notifier).clearError();
    await ref.read(authProvider.notifier).signInWithEmail(
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );
    _handleAuthResult();
  }

  void _handleAuthResult() {
    final auth = ref.read(authProvider);
    if (auth.isAuthenticated && mounted) {
      context.go('/home');
    } else if (auth.error != null && auth.error!.isNotEmpty && mounted) {
      _showErrorSnackbar(auth.error!);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _toggleEmailForm() {
    setState(() => _emailExpanded = !_emailExpanded);
    if (_emailExpanded) {
      _emailExpandAnim.forward();
    } else {
      _emailExpandAnim.reverse();
      FocusScope.of(context).unfocus();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth     = ref.watch(authProvider);
    final isLoading = auth.isLoading;
    final size     = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ── Animated mesh background ──────────────────────────────────────
          _AnimatedBackground(controller: _bgAnim, size: size),

          // ── Main content ──────────────────────────────────────────────────
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeCurve,
              builder: (_, child) => Opacity(
                opacity: _fadeCurve.value,
                child: Transform.translate(
                  offset: Offset(0, _slideCurve.value),
                  child: child,
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // ── Logo ────────────────────────────────────────────────
                    _Logo(),

                    const SizedBox(height: 56),

                    // ── Tagline ─────────────────────────────────────────────
                    _Tagline(),

                    const SizedBox(height: 48),

                    // ── Google Sign-In ───────────────────────────────────────
                    _SocialButton(
                      onTap: isLoading ? null : _googleSignIn,
                      isLoading: isLoading,
                      icon: _GoogleIcon(),
                      label: 'Continue with Google',
                      backgroundColor: AppColors.googleBg,
                      textColor: AppColors.googleText,
                      isPrimary: true,
                    ),

                    const SizedBox(height: 12),

                    // ── Apple Sign-In (shown only if available) ───────────────
                    if (AuthNotifier.isAppleSignInAvailable) ...[
                      _SocialButton(
                        onTap: isLoading ? null : _appleSignIn,
                        isLoading: isLoading,
                        icon: const Icon(Icons.apple,
                            color: Colors.white, size: 22),
                        label: 'Continue with Apple',
                        backgroundColor: AppColors.appleBg,
                        textColor: AppColors.appleText,
                        isPrimary: true,
                        borderColor: const Color(0xFF2A2A3A),
                      ),
                      const SizedBox(height: 28),
                    ] else ...[
                      const SizedBox(height: 28),
                    ],

                    // ── Divider with email option ────────────────────────────
                    _OrDivider(
                      onTap: _toggleEmailForm,
                      isExpanded: _emailExpanded,
                    ),

                    // ── Expandable email form ─────────────────────────────────
                    SizeTransition(
                      sizeFactor: _emailExpandCurve,
                      axisAlignment: -1,
                      child: FadeTransition(
                        opacity: _emailExpandCurve,
                        child: _EmailForm(
                          formKey: _formKey,
                          emailCtrl: _emailCtrl,
                          passCtrl: _passCtrl,
                          showPassword: _showPassword,
                          onTogglePassword: () =>
                              setState(() => _showPassword = !_showPassword),
                          onSignIn: isLoading ? null : _emailSignIn,
                          onSignUp: () => context.go('/signup'),
                          isLoading: isLoading,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Sign up link ─────────────────────────────────────────
                    if (!_emailExpanded)
                      _SignUpLink(onTap: () => context.go('/signup')),

                    const SizedBox(height: 40),

                    // ── Legal ────────────────────────────────────────────────
                    _LegalText(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ── Full-screen loading overlay ───────────────────────────────────
          if (isLoading) _LoadingOverlay(),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ANIMATED BACKGROUND
// ═════════════════════════════════════════════════════════════════════════════
class _AnimatedBackground extends StatelessWidget {
  final AnimationController controller;
  final Size size;

  const _AnimatedBackground({required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return CustomPaint(
          size: size,
          painter: _BackgroundPainter(t),
        );
      },
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double t;
  _BackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    // Deep background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.background,
    );

    // Animated radial glow — top center (primary)
    final glow1 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withOpacity(0.12 + 0.06 * math.sin(t * math.pi)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.15),
        radius: size.width * 0.7,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.15),
      size.width * 0.7,
      glow1,
    );

    // Ghost glow — bottom right
    final glow2 = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.ghost.withOpacity(0.08 + 0.04 * math.cos(t * math.pi)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.85, size.height * 0.75),
        radius: size.width * 0.5,
      ));
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.75),
      size.width * 0.5,
      glow2,
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.t != t;
}

// ═════════════════════════════════════════════════════════════════════════════
// LOGO
// ═════════════════════════════════════════════════════════════════════════════
class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Icon mark
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text('👻', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 16),
        // Wordmark
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'PACELY',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAGLINE
// ═════════════════════════════════════════════════════════════════════════════
class _Tagline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Race Your Ghost',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to start competing',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SOCIAL BUTTON (Google / Apple)
// ═════════════════════════════════════════════════════════════════════════════
class _SocialButton extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool isPrimary;
  final Color? borderColor;

  const _SocialButton({
    required this.onTap,
    required this.isLoading,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.isPrimary = false,
    this.borderColor,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: widget.borderColor != null
                ? Border.all(color: widget.borderColor!, width: 1.5)
                : null,
            boxShadow: widget.isPrimary && !_pressed
                ? [
                    BoxShadow(
                      color: widget.backgroundColor.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.icon,
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GOOGLE ICON  (coloured SVG-style)
// ═════════════════════════════════════════════════════════════════════════════
class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final center = Offset(r, r);

    // Full circle clip
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)));

    // Background
    canvas.drawCircle(center, r,
        Paint()..color = Colors.white);

    const double sr = 0.72; // scale radius
    const double cx = 0.5, cy = 0.5;

    void drawSector(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()..color = color;
      final path = Path()
        ..moveTo(size.width * cx, size.height * cy)
        ..arcTo(
          Rect.fromCircle(
              center: Offset(size.width * cx, size.height * cy),
              radius: r * sr),
          startDeg * math.pi / 180,
          sweepDeg * math.pi / 180,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);
    }

    drawSector(-30, 120, const Color(0xFF4285F4)); // blue
    drawSector(90, 120, const Color(0xFF34A853));  // green
    drawSector(210, 120, const Color(0xFFEA4335)); // red

    // Yellow sector
    drawSector(-150, 120, const Color(0xFFFBBC05));

    // White center circle
    canvas.drawCircle(center, r * 0.42, Paint()..color = Colors.white);

    canvas.restore();

    // Blue bar (right side of G)
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(r * 0.95, r * 0.67, r * 0.95, r * 0.33),
      const Radius.circular(2),
    );
    canvas.drawRRect(barRect,
        Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(_) => false;
}

// ═════════════════════════════════════════════════════════════════════════════
// OR DIVIDER  (tappable "or use email")
// ═════════════════════════════════════════════════════════════════════════════
class _OrDivider extends StatelessWidget {
  final VoidCallback onTap;
  final bool isExpanded;

  const _OrDivider({required this.onTap, required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.surfaceHigh,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'or use email',
                    style: TextStyle(
                      color: isExpanded
                          ? AppColors.primary
                          : AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: isExpanded
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: AppColors.surfaceHigh,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMAIL FORM  (expandable)
// ═════════════════════════════════════════════════════════════════════════════
class _EmailForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback? onSignIn;
  final VoidCallback onSignUp;
  final bool isLoading;

  const _EmailForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onSignIn,
    required this.onSignUp,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email field
            _PacelyTextField(
              controller: emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Password field
            _PacelyTextField(
              controller: passCtrl,
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: !showPassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSignIn?.call(),
              suffixIcon: GestureDetector(
                onTap: onTogglePassword,
                child: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'At least 6 characters';
                return null;
              },
            ),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      vertical: 4, horizontal: 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Sign in button
            _PacelyButton(
              label: 'Sign In',
              onTap: onSignIn,
              isLoading: isLoading,
            ),

            const SizedBox(height: 20),

            // Sign up link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                GestureDetector(
                  onTap: onSignUp,
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// REUSABLE TEXT FIELD
// ═════════════════════════════════════════════════════════════════════════════
class _PacelyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _PacelyTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.suffixIcon,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.surfaceHigh,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.error.withOpacity(0.7),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: TextStyle(color: AppColors.error, fontSize: 12),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PRIMARY CTA BUTTON
// ═════════════════════════════════════════════════════════════════════════════
class _PacelyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _PacelyButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<_PacelyButton> createState() => _PacelyButtonState();
}

class _PacelyButtonState extends State<_PacelyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _pressed
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SIGN UP LINK (shown when email form is collapsed)
// ═════════════════════════════════════════════════════════════════════════════
class _SignUpLink extends StatelessWidget {
  final VoidCallback onTap;
  const _SignUpLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "New to Pacely? ",
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            'Create an account',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LEGAL TEXT
// ═════════════════════════════════════════════════════════════════════════════
class _LegalText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'By continuing, you agree to our Terms of Service\nand Privacy Policy.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        height: 1.6,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LOADING OVERLAY
// ═════════════════════════════════════════════════════════════════════════════
class _LoadingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withOpacity(0.6),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Signing you in...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}