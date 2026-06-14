import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart'; // same folder: lib/shared/
import '../core/app_colors.dart'; // lib/core/
import '../features/auth/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/admin/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PremiumMailerApp());
}

class PremiumMailerApp extends StatelessWidget {
  const PremiumMailerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'INNOVEXA63',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Segoe UI',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SplashLoader();
          }

          if (snapshot.hasData && snapshot.data != null) {
            return _RoleRouter(firebaseUser: snapshot.data!);
          }

          return const LoginScreen();
        },
      ),
    );
  }
}

// ================================================================
//  ROLE ROUTER
// ================================================================
class _RoleRouter extends StatelessWidget {
  final User firebaseUser;
  const _RoleRouter({required this.firebaseUser});

  Future<Map<String, dynamic>?> _fetchUserData() async {
    // Extract userId from email: "rasel417@innovexa.com" → "rasel417"
    final email = firebaseUser.email ?? '';
    final userId = email.contains('@innovexa.com')
        ? email.replaceAll('@innovexa.com', '')
        : '';

    // Try 1: doc by userId (e.g. "rasel417", "muktadir417")
    if (userId.isNotEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        final d = doc.data() as Map<String, dynamic>;
        d['_docId'] = userId;
        return d;
      }
    }

    // Try 2: doc by Firebase UID (admin accounts created with UID as doc ID)
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();
    if (doc.exists) {
      final d = doc.data() as Map<String, dynamic>;
      d['_docId'] = firebaseUser.uid;
      return d;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchUserData(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _SplashLoader();
        }

        // No doc found → logout
        if (!snap.hasData || snap.data == null) {
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }

        final data = snap.data!;
        final role = (data['role'] ?? 'user').toString().toLowerCase();
        final status = (data['status'] ?? 'active').toString().toLowerCase();
        final forceLogout = data['forceLogout'] ?? false;
        final isAdmin =
            role == 'admin' || role == 'super_admin' || role == 'sub_admin';

        // Blocked / banned / suspended → logout
        if (status == 'blocked' ||
            status == 'banned' ||
            status == 'suspended') {
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }

        // forceLogout → only apply to regular users, NOT admin
        if (!isAdmin && forceLogout == true) {
          FirebaseAuth.instance.signOut();
          return const LoginScreen();
        }

        // Expiry → only check for regular users
        if (!isAdmin && data['expiryDate'] != null) {
          final expiry = (data['expiryDate'] as Timestamp).toDate();
          if (expiry.isBefore(DateTime.now())) {
            FirebaseAuth.instance.signOut();
            return const LoginScreen();
          }
        }

        // Route by role
        if (isAdmin) return const AdminDashboard();
        return const DashboardScreen();
      },
    );
  }
}

// ================================================================
//  SPLASH LOADER
// ================================================================
class _SplashLoader extends StatelessWidget {
  const _SplashLoader();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.sidebar,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryCyan.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.14),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.primaryCyan,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'INNOVEXA',
                    style: TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  TextSpan(
                    text: '63',
                    style: TextStyle(
                      color: AppColors.secondaryPurple,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Smart Delivery. Intelligent Automation.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: AppColors.primaryCyan,
                strokeWidth: 2.5,
                backgroundColor: AppColors.primaryCyan.withOpacity(0.1),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Authenticating...',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
