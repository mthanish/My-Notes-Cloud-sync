import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final session = await auth.signInWithGoogle();
      if (session != null && mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        if (e is GoogleSignInException) {
          if (e.code == GoogleSignInExceptionCode.canceled) {
            setState(() => _errorMessage = null);
          } else {
            setState(() {
              _errorMessage = e.description ?? 'Google Sign-In failed: ${e.code.name}';
            });
          }
        } else if (e is FirebaseNotConfiguredException) {
          _showFirebaseSetupDialog(e.toString());
        } else {
          setState(() {
            _errorMessage = 'Google Sign-In failed: $e';
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFirebaseSetupDialog(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.dialogBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Google Sign-In Setup',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Google Sign-In requires connecting this app to your Firebase project:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('1. Place google-services.json in android/app/', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                  SizedBox(height: 6),
                  Text('2. Enable Google Sign-In in Firebase Console', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                  SizedBox(height: 6),
                  Text('3. Add your Android SHA-1 fingerprint', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.5)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'You can continue in Offline / Guest Mode immediately! All notes, tasks, search, and AES-256 password vault work 100% locally.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textTertiary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _handleGuestSignIn();
            },
            child: const Text('Use Offline Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGuestSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.continueAsGuest();
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // MI Notes Icon (Stylized yellow squircle notepad)
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CustomPaint(
                      size: const Size(48, 48),
                      painter: _AppIconPainter(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'My Notes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Capture ideas, tasks & encrypted notes across all your devices in real-time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 48),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Google Sign In Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cardBackground,
                      foregroundColor: AppColors.textPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border, width: 0.8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google G logo representation
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: const Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      color: Color(0xFF4285F4),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Continue with Google',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 14),

                // Guest / Offline Mode Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleGuestSignIn,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Use Offline / Guest Mode',
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined, size: 14, color: AppColors.textTertiary),
                    SizedBox(width: 6),
                    Text(
                      'End-to-End Local Persistence & AES-256 Vault',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
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

class _AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Horizontal notepad lines
    final linePaint = Paint()
      ..color = const Color(0x66B06C00)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = const Color(0x66B06C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset(w * 0.15, h * 0.32), 2.2, dotPaint);
    canvas.drawLine(Offset(w * 0.28, h * 0.32), Offset(w * 0.85, h * 0.32), linePaint);

    canvas.drawCircle(Offset(w * 0.15, h * 0.50), 2.2, dotPaint);
    canvas.drawLine(Offset(w * 0.28, h * 0.50), Offset(w * 0.85, h * 0.50), linePaint);

    canvas.drawCircle(Offset(w * 0.15, h * 0.68), 2.2, dotPaint);
    canvas.drawLine(Offset(w * 0.28, h * 0.68), Offset(w * 0.85, h * 0.68), linePaint);

    // Diagonal white pen stylus
    final penPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.78, h * 0.22), Offset(w * 0.26, h * 0.74), penPaint);
  }

  @override
  bool shouldRepaint(covariant _AppIconPainter oldDelegate) => false;
}
