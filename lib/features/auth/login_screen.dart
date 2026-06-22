import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <-- NEW IMPORT
import 'dart:math'; // <-- NEW IMPORT
import '../../core/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import '../admin/admin_dashboard.dart';

// ================================================================
//  LOGIN SCREEN — INNOVEXA63
//  Role-based routing:
//    admin / super_admin / sub_admin  →  AdminDashboard
//    user                             →  DashboardScreen
//
//  v4.1 — COMPACT / OVERFLOW-SAFE LAYOUT
//  • Wrapped content in SingleChildScrollView so small/resized
//    desktop windows never throw overflow errors.
//  • Reduced overall vertical paddings/margins/font sizes so the
//    whole login card fits comfortably in a smaller window.
//  • NOTHING removed — all original logic, fields, dialogs and
//    Firebase/Firestore flow kept 100% intact.
// ================================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _userIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // ── NEW: Load saved User ID when screen opens ──
    _loadSavedUserId();
  }

  // ================================================================
  //  LOAD SAVED USER ID LOGIC (NEW)
  // ================================================================
  Future<void> _loadSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('saved_user_id') ?? '';

    if (savedUserId.isNotEmpty && mounted) {
      setState(() {
        _userIdCtrl.text = savedUserId;
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _userIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ================================================================
  //  LOCAL DEVICE ID GENERATOR
  // ================================================================
  Future<String> _getLocalDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('local_device_id');

    if (deviceId == null) {
      deviceId =
          'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
      await prefs.setString('local_device_id', deviceId);
    }
    return deviceId;
  }

  // ================================================================
  //  CORE LOGIN LOGIC (UPGRADED WITH THREAD SAFETY FOR WINDOWS)
  // ================================================================
  Future<void> _login() async {
    final userId = _userIdCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text.trim();

    if (userId.isEmpty || password.isEmpty) {
      _setError('User ID and Password cannot be empty.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final email = '$userId@innovexa.com';

      // ── Step 1: Firebase Auth ──
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUid = credential.user!.uid;

      // ── Step 2: Find Firestore doc ──
      // Try by userId first (e.g. "rasel417"), then fallback to Firebase UID
      Map<String, dynamic>? data;
      String? docId;

      // Try userId as doc ID
      final docByUserId = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (docByUserId.exists) {
        data = docByUserId.data() as Map<String, dynamic>;
        docId = userId;
      } else {
        // Fallback: try Firebase UID as doc ID
        final docByUid = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUid)
            .get();

        if (docByUid.exists) {
          data = docByUid.data() as Map<String, dynamic>;
          docId = firebaseUid;
        }
      }

      // ── Step 3: Doc not found anywhere ──
      if (data == null) {
        _setError('SYSTEM ERROR: User profile not found in database.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      // ================================================================
      //  ── Step 3.5: SINGLE DEVICE LOGIN LOGIC ──
      // ================================================================
      final String localDeviceId = await _getLocalDeviceId();
      final String? activeDeviceId = data['current_device_id'];

      // Check if logged in elsewhere
      if (activeDeviceId != null &&
          activeDeviceId != localDeviceId &&
          activeDeviceId.isNotEmpty) {
        bool? forceLogin = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.sidebar,
            title: const Text(
              'Already Logged In!',
              style: TextStyle(color: AppColors.dangerRed),
            ),
            content: const Text(
              'Your account is currently active on another device. Do you want to force log out from that device and log in here?',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut(); // Cancel login
                  Navigator.pop(ctx, false);
                },
                child: const Text(
                  'CANCEL',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.dangerRed,
                ),
                onPressed: () =>
                    Navigator.pop(ctx, true), // Proceed to force login
                child: const Text(
                  'FORCE LOGIN',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        if (forceLogin != true) {
          _setError('Login cancelled. Account active on another device.');
          return; // Stop the login process
        }
      }

      // Update Firestore with the new device ID
      await FirebaseFirestore.instance.collection('users').doc(docId).set({
        'current_device_id': localDeviceId,
      }, SetOptions(merge: true));
      // ================================================================

      final role = (data['role'] ?? 'user').toString().toLowerCase();
      final status = (data['status'] ?? 'active').toString().toLowerCase();
      final isAdmin =
          role == 'admin' || role == 'super_admin' || role == 'sub_admin';

      // ── Step 4: Status checks ──
      if (status == 'blocked' || status == 'suspended') {
        _setError(
          'ACCESS DENIED: Your account has been '
          '${status == 'blocked' ? 'blocked' : 'suspended'} by Admin.',
        );
        await FirebaseAuth.instance.signOut();
        return;
      }

      if (status == 'banned') {
        _setError('ACCESS DENIED: Your account has been permanently banned.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      // ── Step 5: Expiry check (skip for admin) ──
      if (!isAdmin && data['expiryDate'] != null) {
        final expiry = (data['expiryDate'] as Timestamp).toDate();
        if (expiry.isBefore(DateTime.now())) {
          _setError('LICENSE EXPIRED: Contact Admin to renew your access.');
          await FirebaseAuth.instance.signOut();
          return;
        }
      }

      // ── Step 6: forceLogout check (skip for admin) ──
      if (!isAdmin && data['forceLogout'] == true) {
        _setError('SESSION TERMINATED: Please contact Admin.');
        await FirebaseAuth.instance.signOut();
        return;
      }

      // ── Step 7: Clear forceLogout flag if it was set ──
      if (data['forceLogout'] == true && isAdmin) {
        await FirebaseFirestore.instance.collection('users').doc(docId).update({
          'forceLogout': false,
        });
      }

      // ── Step 8: Write activity log ──
      await FirebaseFirestore.instance.collection('activity_logs').add({
        'action': 'User logged in: $userId',
        'type': 'login',
        'targetUser': userId,
        'performedBy': userId,
        'device': 'App',
        'platform': 'Flutter',
        'ipAddress': '',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // ── NEW: Save User ID on successful login ──
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_user_id', userId);
      // ───────────────────────────────────────────

      if (!mounted) return;

      // ── Step 9: Navigate by role (Forced on Main Thread for Safety) ──
      final Widget destination = isAdmin
          ? const AdminDashboard()
          : const DashboardScreen();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => destination,
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 300),
            ),
            (route) => false,
          );
        }
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        _setError('Invalid User ID or Password.');
      } else {
        _setError('Auth error: ${e.message}');
      }
    } catch (e) {
      _setError('Error: $e');
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  void _setError(String msg) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _errorMessage = msg);
    });
  }

  // ================================================================
  //  BUILD
  //  NOTE: Everything is now wrapped in a SingleChildScrollView
  //  inside a LayoutBuilder, so the screen scales down cleanly on
  //  smaller / resized desktop windows instead of overflowing.
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              return Stack(
                children: [
                  Positioned(
                    top: -120,
                    left: -120,
                    child: _GlowCircle(
                      color: AppColors.primaryCyan,
                      size: w * 0.5,
                      opacity: 0.06,
                    ),
                  ),
                  Positioned(
                    bottom: -100,
                    right: -100,
                    child: _GlowCircle(
                      color: AppColors.secondaryPurple,
                      size: w * 0.42,
                      opacity: 0.07,
                    ),
                  ),

                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: h - 32, // keeps it centered when tall
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 380),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _buildLogo(),
                                  const SizedBox(height: 18),
                                  _buildCard(),
                                  const SizedBox(height: 14),
                                  _buildFooter(),
                                  const SizedBox(height: 10),
                                  _buildStatusBar(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.sidebar,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryCyan.withOpacity(0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryCyan.withOpacity(0.16),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: AppColors.primaryCyan,
            size: 22,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'VEXA',
                style: TextStyle(
                  color: AppColors.primaryCyan,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.2,
                ),
              ),
              TextSpan(
                text: '63 ULTRA',
                style: TextStyle(
                  color: AppColors.secondaryPurple,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Smart Delivery. Intelligent Automation.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryCyan.withOpacity(0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.05),
            blurRadius: 28,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'SYSTEM AUTHENTICATION',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text(
              'Enter your credentials to access the platform.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 9.5),
            ),
          ),
          const SizedBox(height: 16),

          _FieldLabel('SYSTEM USER ID'),
          const SizedBox(height: 5),
          _buildTextField(
            controller: _userIdCtrl,
            hint: 'e.g. demo123',
            icon: Icons.person_outline_rounded,
            obscure: false,
          ),
          const SizedBox(height: 12),

          _FieldLabel('ACCESS PASSWORD'),
          const SizedBox(height: 5),
          _buildTextField(
            controller: _passwordCtrl,
            hint: '••••••••',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            isPassword: true,
            onToggle: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onSubmit: (_) => _login(),
          ),

          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.dangerRed.withOpacity(0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.dangerRed,
                      size: 13,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: AppColors.dangerRed,
                        fontSize: 9.5,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryCyan,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.primaryCyan.withOpacity(
                  0.35,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.login_rounded, size: 16),
                        SizedBox(width: 7),
                        Text(
                          'INITIALIZE LOGIN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
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
    required bool obscure,
    bool isPassword = false,
    VoidCallback? onToggle,
    ValueChanged<String>? onSubmit,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white, fontSize: 12.5),
      onSubmitted: onSubmit,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textMuted.withOpacity(0.45),
          fontSize: 11.5,
        ),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 17),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.textMuted,
                  size: 17,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: AppColors.background,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide(color: AppColors.border.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: AppColors.primaryCyan,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.sidebar.withOpacity(0.7),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryCyan.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primaryCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'RESTRICTED SYSTEM ACCESS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'To request a new license, account access, or technical support, please contact your System Administrator.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: AppColors.successGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'ALL SYSTEMS OPERATIONAL  •  INNOVEXA63 v2.0',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 8.5,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

// ================================================================
//  HELPER WIDGETS
// ================================================================

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 9.5,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.7,
    ),
  );
}

class _ContactChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ContactChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  final Color color;
  final double size;
  final double opacity;
  const _GlowCircle({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryCyan.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
