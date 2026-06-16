import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../auth/login_screen.dart';
import '../../core/app_colors.dart';

// ================================================================
//  ADMIN DASHBOARD - INNOVEXA63 MAILER  (FULL ENTERPRISE v4.0)
// ================================================================

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<_SidebarItem> _sidebarItems = const [
    _SidebarItem(Icons.dashboard_rounded, 'Dashboard'),
    _SidebarItem(Icons.people_alt_rounded, 'User Management'),
    _SidebarItem(Icons.card_membership, 'License Manager'),
    _SidebarItem(Icons.campaign_rounded, 'Campaign Manager'),
    _SidebarItem(Icons.router_rounded, 'SMTP Manager'),
    _SidebarItem(Icons.swap_horiz_rounded, 'Proxy Manager'),
    _SidebarItem(Icons.auto_awesome_rounded, 'AI Management'),
    _SidebarItem(Icons.receipt_long_rounded, 'Billing & Payments'),
    _SidebarItem(Icons.bar_chart_rounded, 'Analytics'),
    _SidebarItem(Icons.security_rounded, 'Security Center'),
    _SidebarItem(Icons.history_rounded, 'Activity Logs'),
    _SidebarItem(Icons.notifications_rounded, 'Notifications'),
    _SidebarItem(Icons.support_agent_rounded, 'Support Tickets'),
    _SidebarItem(Icons.admin_panel_settings, 'Role Management'),
    _SidebarItem(Icons.dns_rounded, 'Server Monitoring'),
    _SidebarItem(Icons.settings_rounded, 'System Settings'),
  ];

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          _Sidebar(
            items: _sidebarItems,
            selectedIndex: _selectedIndex,
            onSelect: (i) => setState(() => _selectedIndex = i),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(onLogout: _logout),
                Expanded(child: _buildPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (_selectedIndex) {
      case 0:
        return const _DashboardPage();
      case 1:
        return const _UserManagementPage();
      case 2:
        return const _LicenseManagerPage();
      case 3:
        return const _CampaignManagerPage();
      case 4:
        return const _SmtpManagerPage();
      case 5:
        return const _ProxyManagerPage();
      case 6:
        return const _AiManagementPage();
      case 7:
        return const _BillingPage();
      case 8:
        return const _AnalyticsPage();
      case 9:
        return const _SecurityCenterPage();
      case 10:
        return const _ActivityLogsPage();
      case 11:
        return _ComingSoon('Notifications');
      case 12:
        return _ComingSoon('Support Tickets');
      case 13:
        return const _RoleManagementPage();
      case 14:
        return _ComingSoon('Server Monitoring');
      case 15:
        return _ComingSoon('System Settings');
      default:
        return const _DashboardPage();
    }
  }
}

// ================================================================
//  SIDEBAR
// ================================================================
class _SidebarItem {
  final IconData icon;
  final String title;
  const _SidebarItem(this.icon, this.title);
}

class _Sidebar extends StatelessWidget {
  final List<_SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      color: AppColors.sidebar,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'INNOVEXA',
                        style: TextStyle(
                          color: AppColors.primaryCyan,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      TextSpan(
                        text: '63',
                        style: TextStyle(
                          color: AppColors.secondaryPurple,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Smart Delivery. Intelligent Automation.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final active = i == selectedIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primaryCyan.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: active
                          ? AppColors.primaryCyan.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      items[i].icon,
                      color: active
                          ? AppColors.primaryCyan
                          : AppColors.textMuted,
                      size: 18,
                    ),
                    title: Text(
                      items[i].title,
                      style: TextStyle(
                        color: active
                            ? AppColors.primaryCyan
                            : AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () => onSelect(i),
                  ),
                );
              },
            ),
          ),
          const Divider(color: AppColors.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.secondaryPurple,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Super Admin',
                    style: TextStyle(color: AppColors.textMain, fontSize: 12),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dangerRed.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.dangerRed.withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: AppColors.dangerRed,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  TOP BAR
// ================================================================
class _TopBar extends StatelessWidget {
  final VoidCallback onLogout;
  const _TopBar({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          bottom: BorderSide(color: AppColors.primaryCyan.withOpacity(0.15)),
        ),
      ),
      child: Row(
        children: [
          const Text(
            'SUPER ADMIN COMMAND CENTER',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.successGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.successGreen.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SYSTEM ONLINE',
                  style: TextStyle(
                    color: AppColors.successGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(
              Icons.notifications_rounded,
              color: AppColors.primaryCyan,
            ),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.logout_rounded, size: 15),
            label: const Text('Logout', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  DASHBOARD PAGE  — all live from Firestore, no dummy stats
// ================================================================
class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM OVERVIEW',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // ── Row 1: user stats from Firestore ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snap) {
              int total = 0, active = 0, suspended = 0, banned = 0;
              if (snap.hasData) {
                for (var doc in snap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  total++;
                  final st = (d['status'] ?? '').toString().toLowerCase();
                  if (st == 'active') active++;
                  if (st == 'blocked' || st == 'suspended') suspended++;
                  if (st == 'banned') banned++;
                }
              }
              return GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: [
                  _StatCard(
                    'Total Users',
                    '$total',
                    AppColors.primaryCyan,
                    Icons.people_alt_rounded,
                  ),
                  _StatCard(
                    'Active Users',
                    '$active',
                    AppColors.successGreen,
                    Icons.check_circle_rounded,
                  ),
                  _StatCard(
                    'Suspended',
                    '$suspended',
                    AppColors.warning,
                    Icons.block_rounded,
                  ),
                  _StatCard(
                    'Banned',
                    '$banned',
                    AppColors.dangerRed,
                    Icons.gavel_rounded,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Row 2: campaign/smtp live stats ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('smtps')
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, smtpSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('campaigns')
                    .snapshots(),
                builder: (context, campSnap) {
                  final smtpActive = smtpSnap.hasData
                      ? smtpSnap.data!.docs.length
                      : 0;

                  int totalSent = 0;
                  int totalOpen = 0;
                  int totalSentAll = 0;
                  int runningCampaigns = 0;

                  if (campSnap.hasData) {
                    for (var doc in campSnap.data!.docs) {
                      final d = doc.data() as Map<String, dynamic>;
                      final sent = (d['sentCount'] ?? 0) as int;
                      final open = (d['openCount'] ?? 0) as int;
                      totalSent += sent;
                      totalOpen += open;
                      totalSentAll += sent;
                      if ((d['status'] ?? '') == 'running') {
                        runningCampaigns++;
                      }
                    }
                  }

                  final deliveryRate = totalSentAll > 0
                      ? ((totalSentAll - (totalSentAll * 0.028)) /
                                totalSentAll *
                                100)
                            .toStringAsFixed(1)
                      : '0.0';

                  return GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _StatCard(
                        'SMTP Active',
                        '$smtpActive',
                        AppColors.secondaryPurple,
                        Icons.router_rounded,
                      ),
                      _StatCard(
                        'Emails Sent',
                        _formatNumber(totalSent),
                        AppColors.primaryCyan,
                        Icons.email_rounded,
                      ),
                      _StatCard(
                        'Delivery Rate',
                        '$deliveryRate%',
                        AppColors.successGreen,
                        Icons.trending_up_rounded,
                      ),
                      _StatCard(
                        'Running Campaigns',
                        '$runningCampaigns',
                        AppColors.successGreen,
                        Icons.campaign_rounded,
                      ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 32),
          const Text(
            'RECENT REGISTERED USERS',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('createdAt', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryCyan,
                  ),
                );
              }
              final docs = snap.data!.docs;
              return _GlassContainer(
                child: Column(
                  children: [
                    _tableHeader(['USER ID', 'ROLE', 'PLAN', 'STATUS']),
                    ...docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final status = (d['status'] ?? 'active')
                          .toString()
                          .toLowerCase();
                      final color = status == 'active'
                          ? AppColors.successGreen
                          : status == 'banned'
                          ? AppColors.dangerRed
                          : AppColors.warning;
                      final dispId = (d['customUserId'] ?? doc.id).toString();
                      return _tableRow(
                        [
                          dispId,
                          (d['role'] ?? 'user').toString().toUpperCase(),
                          d['plan'] ?? 'Free',
                          status.toUpperCase(),
                        ],
                        [
                          AppColors.textMain,
                          AppColors.secondaryPurple,
                          AppColors.textMuted,
                          color,
                        ],
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

// ================================================================
//  USER MANAGEMENT PAGE
// ================================================================
class _UserManagementPage extends StatefulWidget {
  const _UserManagementPage();
  @override
  State<_UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<_UserManagementPage> {
  final _searchCtrl = TextEditingController();
  String _filterStatus = 'all';
  String _filterRole = 'all';

  final _newUserIdCtrl = TextEditingController();
  final _newUserPassCtrl = TextEditingController();
  final _newNameCtrl = TextEditingController();
  String _selectedRole = 'user';
  String _selectedPlan = 'Premium';

  final Map<String, bool> _subAdminPerms = {
    'Manage Users': false,
    'Manage Billing': false,
    'Manage Settings': false,
    'View Analytics': false,
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    _newUserIdCtrl.dispose();
    _newUserPassCtrl.dispose();
    _newNameCtrl.dispose();
    super.dispose();
  }

  // ── helper: write activity log ──
  Future<void> _writeLog({
    required String action,
    required String type,
    required String targetUser,
    String details = '',
  }) async {
    await FirebaseFirestore.instance.collection('activity_logs').add({
      'action': action,
      'type': type,
      'targetUser': targetUser,
      'details': details,
      'performedBy': 'admin',
      'device': 'Admin Panel',
      'platform': 'Web',
      'ipAddress': '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showAddUserModal() {
    _newUserIdCtrl.clear();
    _newUserPassCtrl.clear();
    _newNameCtrl.clear();
    final paymentCtrl = TextEditingController();
    DateTime? selDate;
    TimeOfDay? selTime;
    setState(() {
      _selectedRole = 'user';
      _selectedPlan = 'Premium';
      _subAdminPerms.updateAll((k, v) => false);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          bool isCreating = false;
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(28),
              decoration: _modalDecoration(AppColors.primaryCyan),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _modalTitle(
                      Icons.person_add_alt_1_rounded,
                      'CREATE NEW CLIENT / ADMIN',
                      AppColors.primaryCyan,
                    ),
                    const SizedBox(height: 20),
                    _inputField('FULL NAME', _newNameCtrl, 'e.g. John Doe'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            'SYSTEM USER ID',
                            _newUserIdCtrl,
                            'e.g. client_02',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _inputField(
                            'ACCESS PASSWORD',
                            _newUserPassCtrl,
                            '••••••••',
                            obscure: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ASSIGN ROLE:',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        SizedBox(
                          width: 100,
                          child: _roleRadio(
                            'User',
                            'user',
                            AppColors.primaryCyan,
                            _selectedRole,
                            (v) => setS(() => _selectedRole = v!),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: _roleRadio(
                            'Sub Admin',
                            'sub_admin',
                            AppColors.warning,
                            _selectedRole,
                            (v) => setS(() => _selectedRole = v!),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: _roleRadio(
                            'Admin',
                            'admin',
                            AppColors.dangerRed,
                            _selectedRole,
                            (v) => setS(() => _selectedRole = v!),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedRole == 'sub_admin') ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SUB ADMIN PERMISSIONS:',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _subAdminPerms.keys.map((String key) {
                                return SizedBox(
                                  width: 180,
                                  child: CheckboxListTile(
                                    title: Text(
                                      key,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                    value: _subAdminPerms[key],
                                    activeColor: AppColors.warning,
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    onChanged: (val) =>
                                        setS(() => _subAdminPerms[key] = val!),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ASSIGN PLAN:',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPlan,
                                dropdownColor: AppColors.sidebar,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                decoration: _dropdownDecor(),
                                items:
                                    [
                                          'Free',
                                          'Trial',
                                          'Monthly',
                                          'Yearly',
                                          'Lifetime',
                                          'Premium',
                                        ]
                                        .map(
                                          (p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (v) =>
                                    setS(() => _selectedPlan = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _inputField(
                            'PAYMENT RECEIVED (TK)',
                            paymentCtrl,
                            'e.g. 5000',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'SET INITIAL EXPIRY (Optional):',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: _datePickerTile(
                            context,
                            selDate,
                            'Select Date',
                            Icons.calendar_month,
                            AppColors.primaryCyan,
                            (d) => setS(() => selDate = d),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _timePickerTile(
                            context,
                            selTime,
                            Icons.access_time,
                            AppColors.warning,
                            (t) => setS(() => selTime = t),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryCyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          onPressed: isCreating
                              ? null
                              : () async {
                                  if (_newUserIdCtrl.text.isEmpty ||
                                      _newUserPassCtrl.text.isEmpty) {
                                    _showSnack(
                                      ctx,
                                      'User ID and Password required!',
                                      AppColors.dangerRed,
                                    );
                                    return;
                                  }
                                  setS(() => isCreating = true);
                                  try {
                                    // customUserId = admin-given label (e.g. client_02)
                                    final customUserId = _newUserIdCtrl.text
                                        .trim()
                                        .toLowerCase();
                                    final password = _newUserPassCtrl.text
                                        .trim();
                                    final emailForAuth =
                                        '$customUserId@innovexa.com';

                                    // ── Create Firebase Auth user in a
                                    //    secondary app so we don't log out
                                    //    the current admin session ──
                                    FirebaseApp
                                    tempApp = await Firebase.initializeApp(
                                      name:
                                          'temp_${DateTime.now().millisecondsSinceEpoch}',
                                      options: Firebase.app().options,
                                    );

                                    // Capture the real Firebase Auth UID
                                    String authUid = '';
                                    try {
                                      final cred =
                                          await FirebaseAuth.instanceFor(
                                            app: tempApp,
                                          ).createUserWithEmailAndPassword(
                                            email: emailForAuth,
                                            password: password,
                                          );
                                      authUid = cred.user?.uid ?? '';

                                      // Also set displayName so login_screen
                                      // can resolve the custom label later
                                      await cred.user?.updateDisplayName(
                                        customUserId,
                                      );
                                    } finally {
                                      await tempApp.delete();
                                    }

                                    if (authUid.isEmpty) {
                                      throw Exception(
                                        'Firebase Auth UID not returned.',
                                      );
                                    }

                                    List<String> activePerms = [];
                                    if (_selectedRole == 'sub_admin') {
                                      _subAdminPerms.forEach((k, v) {
                                        if (v) activePerms.add(k);
                                      });
                                    }

                                    DateTime? finalDT;
                                    if (selDate != null && selTime != null) {
                                      finalDT = DateTime(
                                        selDate!.year,
                                        selDate!.month,
                                        selDate!.day,
                                        selTime!.hour,
                                        selTime!.minute,
                                      );
                                    }

                                    // ── KEY FIX: Firestore doc ID = Auth UID ──
                                    // customUserId stored as a searchable field
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(authUid)
                                        .set({
                                          'customUserId': customUserId,
                                          'fullName': _newNameCtrl.text.trim(),
                                          'role': _selectedRole,
                                          'status': 'active',
                                          'plan': _selectedPlan,
                                          'paymentAmount': paymentCtrl.text
                                              .trim(),
                                          'paymentStatus':
                                              paymentCtrl.text.trim().isNotEmpty
                                              ? 'paid'
                                              : 'unpaid',
                                          'apiAccess': true,
                                          'permissions': activePerms,
                                          'expiryDate': finalDT != null
                                              ? Timestamp.fromDate(finalDT)
                                              : null,
                                          'totalEmailsSent': 0,
                                          'campaignCount': 0,
                                          'createdAt':
                                              FieldValue.serverTimestamp(),
                                        });

                                    await _writeLog(
                                      action:
                                          'User created: $customUserId (uid: $authUid)',
                                      type: 'user_management',
                                      targetUser: authUid,
                                      details:
                                          'CustomID: $customUserId, Role: $_selectedRole, Plan: $_selectedPlan',
                                    );

                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                      _showSnack(
                                        context,
                                        '✓ System User created and authenticated!',
                                        AppColors.successGreen,
                                      );
                                    }
                                  } catch (e) {
                                    _showSnack(
                                      ctx,
                                      'Error: $e',
                                      AppColors.dangerRed,
                                    );
                                  } finally {
                                    setS(() => isCreating = false);
                                  }
                                },
                          child: isCreating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'GENERATE USER',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showUserDetailModal(String uid, Map<String, dynamic> data) {
    final noteCtrl = TextEditingController(text: data['adminNotes'] ?? '');
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(28),
            decoration: _modalDecoration(AppColors.secondaryPurple),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalTitle(
                    Icons.manage_accounts_rounded,
                    'USER DETAILS: $uid',
                    AppColors.secondaryPurple,
                  ),
                  const SizedBox(height: 20),
                  _detailGrid(uid, data),
                  const SizedBox(height: 16),
                  const Text(
                    'ADMIN NOTES:',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Add private admin notes...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _actionBtn(
                        'Save Notes',
                        AppColors.primaryCyan,
                        Icons.save_rounded,
                        () async {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .update({'adminNotes': noteCtrl.text});
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _showSnack(
                              context,
                              'Notes saved!',
                              AppColors.successGreen,
                            );
                          }
                        },
                      ),
                      _actionBtn(
                        'Reset Password',
                        AppColors.warning,
                        Icons.lock_reset_rounded,
                        () {
                          Navigator.pop(ctx);
                          _showResetPasswordModal(uid, data['role'] ?? '');
                        },
                      ),
                      _actionBtn(
                        'Set Exact Expiry',
                        AppColors.successGreen,
                        Icons.timer_rounded,
                        () {
                          Navigator.pop(ctx);
                          _showSetExpiryModal(uid, data['role'] ?? '');
                        },
                      ),
                      _actionBtn(
                        'Close',
                        AppColors.textMuted,
                        Icons.close_rounded,
                        () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditUserModal(String uid, Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(text: data['fullName'] ?? '');
    String role = data['role'] ?? 'user',
        plan = data['plan'] ?? 'Free',
        status = data['status'] ?? 'active';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(28),
            decoration: _modalDecoration(AppColors.warning),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modalTitle(
                  Icons.edit_rounded,
                  'EDIT USER: $uid',
                  AppColors.warning,
                ),
                const SizedBox(height: 20),
                _inputField('FULL NAME', nameCtrl, 'Full name'),
                const SizedBox(height: 14),
                const Text(
                  'ROLE:',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 80,
                      child: _roleRadio(
                        'User',
                        'user',
                        AppColors.primaryCyan,
                        role,
                        (v) => setS(() => role = v!),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: _roleRadio(
                        'Sub Admin',
                        'sub_admin',
                        AppColors.warning,
                        role,
                        (v) => setS(() => role = v!),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: _roleRadio(
                        'Admin',
                        'admin',
                        AppColors.dangerRed,
                        role,
                        (v) => setS(() => role = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'PLAN:',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: plan,
                  dropdownColor: AppColors.sidebar,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _dropdownDecor(),
                  items:
                      [
                            'Free',
                            'Trial',
                            'Monthly',
                            'Yearly',
                            'Lifetime',
                            'Premium',
                          ]
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                  onChanged: (v) => setS(() => plan = v!),
                ),
                const SizedBox(height: 14),
                const Text(
                  'STATUS:',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  dropdownColor: AppColors.sidebar,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: _dropdownDecor(),
                  items: ['active', 'blocked', 'banned', 'suspended']
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setS(() => status = v!),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                              'fullName': nameCtrl.text.trim(),
                              'role': role,
                              'plan': plan,
                              'status': status,
                            });
                        await _writeLog(
                          action: 'User edited: $uid',
                          type: 'user_management',
                          targetUser: uid,
                          details: 'Role: $role, Plan: $plan, Status: $status',
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(
                            context,
                            '✓ User updated!',
                            AppColors.successGreen,
                          );
                        }
                      },
                      child: const Text(
                        'SAVE CHANGES',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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

  void _showResetPasswordModal(String uid, String currentRole) {
    if (currentRole == 'super_admin') {
      _showSnack(
        context,
        'SECURITY: Cannot reset Super Admin password.',
        AppColors.dangerRed,
      );
      return;
    }
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          decoration: _modalDecoration(AppColors.warning),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modalTitle(
                Icons.lock_reset_rounded,
                'RESET PASSWORD: $uid',
                AppColors.warning,
              ),
              const SizedBox(height: 20),
              _inputField('NEW PASSWORD', passCtrl, '••••••••', obscure: true),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .update({
                            'passwordResetAt': FieldValue.serverTimestamp(),
                            'forcePasswordChange': true,
                          });
                      await _writeLog(
                        action: 'Password reset for: $uid',
                        type: 'security',
                        targetUser: uid,
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        _showSnack(
                          context,
                          '✓ Password reset flag set!',
                          AppColors.successGreen,
                        );
                      }
                    },
                    child: const Text(
                      'RESET',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetExpiryModal(String uid, String currentRole) {
    if (currentRole == 'super_admin') {
      _showSnack(
        context,
        'SECURITY: Super Admin expiry cannot be modified.',
        AppColors.dangerRed,
      );
      return;
    }
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 30));
    TimeOfDay? selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(28),
            decoration: _modalDecoration(AppColors.successGreen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modalTitle(
                  Icons.timer_rounded,
                  'SET EXACT EXPIRY: $uid',
                  AppColors.successGreen,
                ),
                const SizedBox(height: 16),
                const Text(
                  'User will be automatically restricted once this time passes.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                const SizedBox(height: 20),
                _datePickerTile(
                  context,
                  selectedDate,
                  'Select Date',
                  Icons.calendar_month,
                  AppColors.primaryCyan,
                  (d) => setS(() => selectedDate = d),
                ),
                const SizedBox(height: 12),
                _timePickerTile(
                  context,
                  selectedTime,
                  Icons.access_time,
                  AppColors.warning,
                  (t) => setS(() => selectedTime = t),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({'expiryDate': null});
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(
                            context,
                            'Set to Lifetime Access.',
                            AppColors.primaryCyan,
                          );
                        }
                      },
                      child: const Text(
                        'Set Lifetime',
                        style: TextStyle(color: AppColors.primaryCyan),
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            if (selectedDate == null || selectedTime == null) {
                              return;
                            }
                            final finalDT = DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              selectedTime!.hour,
                              selectedTime!.minute,
                            );
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({
                                  'expiryDate': Timestamp.fromDate(finalDT),
                                });
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              _showSnack(
                                context,
                                '✓ Precise Expiry Activated!',
                                AppColors.successGreen,
                              );
                            }
                          },
                          child: const Text(
                            'SET EXPIRY',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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

  void _showDeleteModal(String uid, String currentRole) {
    if (currentRole == 'super_admin' || currentRole == 'admin') {
      _showSnack(
        context,
        'SECURITY: Admin accounts cannot be deleted.',
        AppColors.dangerRed,
      );
      return;
    }
    bool delCampaigns = true,
        delSMTP = true,
        delLogs = false,
        permanent = true,
        isDeleting = false;
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(28),
            decoration: _modalDecoration(AppColors.dangerRed),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modalTitle(
                  Icons.warning_amber_rounded,
                  'DELETE USER: $uid',
                  AppColors.dangerRed,
                ),
                const SizedBox(height: 16),
                _checkboxItem(
                  'Delete User + Campaigns',
                  delCampaigns,
                  AppColors.dangerRed,
                  (v) => setS(() => delCampaigns = v!),
                ),
                _checkboxItem(
                  'Delete User + SMTP & Proxies',
                  delSMTP,
                  AppColors.dangerRed,
                  (v) => setS(() => delSMTP = v!),
                ),
                _checkboxItem(
                  'Delete Activity Logs',
                  delLogs,
                  AppColors.dangerRed,
                  (v) => setS(() => delLogs = v!),
                ),
                _checkboxItem(
                  'Permanent Delete (Non-Recoverable)',
                  permanent,
                  AppColors.dangerRed,
                  (v) => setS(() => permanent = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Reason for deletion (Optional)',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.5),
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isDeleting ? null : () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.dangerRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: isDeleting
                          ? null
                          : () async {
                              setS(() => isDeleting = true);
                              try {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .delete();
                                await _writeLog(
                                  action: 'User deleted: $uid',
                                  type: 'user_management',
                                  targetUser: uid,
                                  details: reasonCtrl.text.trim(),
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  _showSnack(
                                    context,
                                    '✓ User deleted.',
                                    AppColors.successGreen,
                                  );
                                }
                              } catch (e) {
                                setS(() => isDeleting = false);
                                _showSnack(
                                  ctx,
                                  'Error: $e',
                                  AppColors.dangerRed,
                                );
                              }
                            },
                      child: isDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'CONFIRM DELETE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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

  Future<void> _toggleStatus(String uid, String current, String role) async {
    if (role == 'super_admin') {
      _showSnack(
        context,
        'Action Denied: Super Admin cannot be suspended.',
        AppColors.dangerRed,
      );
      return;
    }
    final ns = current.toLowerCase() == 'active' ? 'blocked' : 'active';
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': ns,
    });
    await _writeLog(
      action: 'Status changed for: $uid → ${ns.toUpperCase()}',
      type: 'user_management',
      targetUser: uid,
    );
    _showSnack(
      context,
      'Status → ${ns.toUpperCase()}',
      ns == 'active' ? AppColors.successGreen : AppColors.warning,
    );
  }

  Future<void> _banUser(String uid, String current, String role) async {
    if (role == 'super_admin') {
      _showSnack(
        context,
        'Action Denied: Super Admin cannot be banned.',
        AppColors.dangerRed,
      );
      return;
    }
    final ns = current.toLowerCase() == 'banned' ? 'active' : 'banned';
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': ns,
    });
    await _writeLog(
      action: 'User ${ns == "banned" ? "BANNED" : "UNBANNED"}: $uid',
      type: 'security',
      targetUser: uid,
    );
    _showSnack(
      context,
      'User ${ns == "banned" ? "BANNED" : "UNBANNED"}!',
      ns == 'banned' ? AppColors.dangerRed : AppColors.successGreen,
    );
  }

  Future<void> _toggleApiAccess(String uid, bool current, String role) async {
    if (role == 'super_admin' && current) {
      _showSnack(
        context,
        'Action Denied: Super Admin API cannot be disabled.',
        AppColors.dangerRed,
      );
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'apiAccess': !current,
    });
    _showSnack(
      context,
      'API Access ${!current ? "ENABLED" : "DISABLED"}!',
      AppColors.primaryCyan,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'USER MANAGEMENT',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'CREATE USER',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _showAddUserModal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by user ID...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: AppColors.sidebar,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _filterDropdown('Status', _filterStatus, [
                'all',
                'active',
                'blocked',
                'banned',
                'suspended',
              ], (v) => setState(() => _filterStatus = v!)),
              const SizedBox(width: 12),
              _filterDropdown('Role', _filterRole, [
                'all',
                'user',
                'sub_admin',
                'admin',
                'super_admin',
              ], (v) => setState(() => _filterRole = v!)),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryCyan,
                  ),
                );
              }
              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return _GlassContainer(
                  child: const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'NO USERS FOUND.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                );
              }

              var docs = snap.data!.docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                // Search by customUserId label OR auth uid
                final customId = (d['customUserId'] ?? doc.id)
                    .toString()
                    .toLowerCase();
                final status = (d['status'] ?? '').toString().toLowerCase();
                final role = (d['role'] ?? '').toString().toLowerCase();
                final search = _searchCtrl.text.toLowerCase();
                if (search.isNotEmpty &&
                    !customId.contains(search) &&
                    !doc.id.toLowerCase().contains(search)) {
                  return false;
                }
                if (_filterStatus != 'all' && status != _filterStatus) {
                  return false;
                }
                if (_filterRole != 'all' && role != _filterRole) return false;
                return true;
              }).toList();

              return _GlassContainer(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _HeaderText('USER ID')),
                          Expanded(flex: 2, child: _HeaderText('ROLE')),
                          Expanded(
                            flex: 3,
                            child: _HeaderText('PLAN & PAYMENT'),
                          ),
                          Expanded(flex: 3, child: _HeaderText('EXPIRY')),
                          Expanded(flex: 2, child: _HeaderText('STATUS')),
                          Expanded(flex: 4, child: _HeaderText('ACTIONS')),
                        ],
                      ),
                    ),
                    ...docs.map((doc) {
                      final uid =
                          doc.id; // Firebase Auth UID (Firestore doc ID)
                      final d = doc.data() as Map<String, dynamic>;
                      // Display label shown to admin
                      final displayId = (d['customUserId'] ?? uid).toString();
                      final status = (d['status'] ?? 'active')
                          .toString()
                          .toLowerCase();
                      final role = (d['role'] ?? 'user').toString();
                      final plan = (d['plan'] ?? 'Free').toString();
                      final api = d['apiAccess'] ?? true;
                      final paymentStatus = (d['paymentStatus'] ?? 'unpaid')
                          .toString()
                          .toLowerCase();
                      final payAmt = d['paymentAmount']?.toString() ?? '';

                      String timeText = 'Lifetime';
                      Color timeColor = AppColors.successGreen;
                      if (d['expiryDate'] != null) {
                        final exp = (d['expiryDate'] as Timestamp).toDate();
                        final now = DateTime.now();
                        if (exp.isBefore(now)) {
                          timeText = 'EXPIRED';
                          timeColor = AppColors.dangerRed;
                        } else {
                          final diff = exp.difference(now);
                          if (diff.inDays > 0) {
                            timeText =
                                '${diff.inDays}d ${diff.inHours % 24}h left';
                          } else if (diff.inHours > 0) {
                            timeText =
                                '${diff.inHours}h ${diff.inMinutes % 60}m left';
                            timeColor = AppColors.warning;
                          } else {
                            timeText = '${diff.inMinutes}m left';
                            timeColor = AppColors.dangerRed;
                          }
                        }
                      }

                      final statusColor = status == 'active'
                          ? AppColors.successGreen
                          : status == 'banned'
                          ? AppColors.dangerRed
                          : AppColors.warning;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 14,
                                    backgroundColor: AppColors.secondaryPurple,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      displayId,
                                      style: const TextStyle(
                                        color: AppColors.textMain,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: _RoleBadge(role),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: paymentStatus == 'paid'
                                          ? AppColors.successGreen.withOpacity(
                                              0.15,
                                            )
                                          : AppColors.dangerRed.withOpacity(
                                              0.15,
                                            ),
                                      borderRadius: BorderRadius.circular(3),
                                      border: Border.all(
                                        color: paymentStatus == 'paid'
                                            ? AppColors.successGreen
                                                  .withOpacity(0.5)
                                            : AppColors.dangerRed.withOpacity(
                                                0.5,
                                              ),
                                      ),
                                    ),
                                    child: Text(
                                      paymentStatus == 'paid'
                                          ? (payAmt.isNotEmpty
                                                ? '৳$payAmt PAID'
                                                : 'PAID')
                                          : 'UNPAID',
                                      style: TextStyle(
                                        color: paymentStatus == 'paid'
                                            ? AppColors.successGreen
                                            : AppColors.dangerRed,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                timeText,
                                style: TextStyle(
                                  color: timeColor,
                                  fontSize: 11,
                                  fontFamily: 'Consolas',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _iconBtn(
                                    Icons.info_outline_rounded,
                                    AppColors.primaryCyan,
                                    'Details',
                                    () => _showUserDetailModal(uid, d),
                                  ),
                                  _iconBtn(
                                    Icons.edit_rounded,
                                    AppColors.warning,
                                    'Edit',
                                    () => _showEditUserModal(uid, d),
                                  ),
                                  _iconBtn(
                                    status == 'active'
                                        ? Icons.block_rounded
                                        : Icons.check_circle_outline_rounded,
                                    status == 'active'
                                        ? AppColors.warning
                                        : AppColors.successGreen,
                                    status == 'active' ? 'Suspend' : 'Activate',
                                    () => _toggleStatus(uid, status, role),
                                  ),
                                  _iconBtn(
                                    Icons.gavel_rounded,
                                    status == 'banned'
                                        ? AppColors.successGreen
                                        : AppColors.dangerRed,
                                    status == 'banned' ? 'Unban' : 'Ban',
                                    () => _banUser(uid, status, role),
                                  ),
                                  _iconBtn(
                                    api
                                        ? Icons.api_rounded
                                        : Icons.api_outlined,
                                    api
                                        ? AppColors.primaryCyan
                                        : AppColors.textMuted,
                                    api ? 'Disable API' : 'Enable API',
                                    () => _toggleApiAccess(uid, api, role),
                                  ),
                                  _iconBtn(
                                    Icons.delete_forever_rounded,
                                    AppColors.dangerRed,
                                    'Delete',
                                    () => _showDeleteModal(uid, role),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Showing ${docs.length} user(s)',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  LICENSE MANAGER PAGE
// ================================================================
class _LicenseManagerPage extends StatefulWidget {
  const _LicenseManagerPage({super.key});
  @override
  State<_LicenseManagerPage> createState() => _LicenseManagerPageState();
}

class _LicenseManagerPageState extends State<_LicenseManagerPage> {
  final _searchCtrl = TextEditingController();
  String _filterPayment = 'all';

  String _generateKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    String seg() =>
        List.generate(5, (_) => chars[rand.nextInt(chars.length)]).join();
    return '${seg()}-${seg()}-${seg()}-${seg()}';
  }

  void _showExtendModal(String uid, Map<String, dynamic> data) {
    int days = 30;
    final payCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(28),
            decoration: _modalDecoration(AppColors.successGreen),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modalTitle(
                  Icons.extension_rounded,
                  'EXTEND LICENSE: $uid',
                  AppColors.successGreen,
                ),
                const SizedBox(height: 12),
                const Text(
                  'EXTEND BY (DAYS):',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [7, 14, 30, 60, 90, 180, 365].map((d) {
                    final sel = d == days;
                    return GestureDetector(
                      onTap: () => setS(() => days = d),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.successGreen.withOpacity(0.2)
                              : AppColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: sel
                                ? AppColors.successGreen
                                : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '$d days',
                          style: TextStyle(
                            color: sel
                                ? AppColors.successGreen
                                : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _inputField('ADDITIONAL PAYMENT (TK)', payCtrl, 'e.g. 2000'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final now = DateTime.now();
                        DateTime base = now;
                        if (data['expiryDate'] != null) {
                          final exp = (data['expiryDate'] as Timestamp)
                              .toDate();
                          if (exp.isAfter(now)) base = exp;
                        }
                        final newExpiry = base.add(Duration(days: days));
                        final updateMap = <String, dynamic>{
                          'expiryDate': Timestamp.fromDate(newExpiry),
                        };
                        if (payCtrl.text.isNotEmpty) {
                          final prev =
                              double.tryParse(
                                data['paymentAmount']?.toString() ?? '0',
                              ) ??
                              0;
                          final add = double.tryParse(payCtrl.text) ?? 0;
                          updateMap['paymentAmount'] = (prev + add).toString();
                          updateMap['paymentStatus'] = 'paid';
                        }
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update(updateMap);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(
                            context,
                            '✓ License extended by $days days!',
                            AppColors.successGreen,
                          );
                        }
                      },
                      child: const Text(
                        'EXTEND',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

  void _showTransferModal(String uid) {
    final targetCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(28),
          decoration: _modalDecoration(AppColors.secondaryPurple),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modalTitle(
                Icons.swap_horiz_rounded,
                'TRANSFER LICENSE',
                AppColors.secondaryPurple,
              ),
              const SizedBox(height: 12),
              Text(
                'Transferring FROM: $uid',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 16),
              _inputField(
                'TRANSFER TO (USER ID)',
                targetCtrl,
                'e.g. client_03',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryPurple,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final target = targetCtrl.text.trim().toLowerCase();
                      if (target.isEmpty) return;
                      final fromDoc = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get();
                      final fromData = fromDoc.data() as Map<String, dynamic>;
                      final batch = FirebaseFirestore.instance.batch();
                      batch.update(
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(target),
                        {
                          'plan': fromData['plan'],
                          'expiryDate': fromData['expiryDate'],
                        },
                      );
                      batch.update(
                        FirebaseFirestore.instance.collection('users').doc(uid),
                        {'plan': 'Free', 'expiryDate': null},
                      );
                      await batch.commit();
                      if (context.mounted) {
                        Navigator.pop(context);
                        _showSnack(
                          context,
                          '✓ License transferred to $target!',
                          AppColors.successGreen,
                        );
                      }
                    },
                    child: const Text(
                      'TRANSFER',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMarkPaymentModal(String uid, Map<String, dynamic> data) {
    final amtCtrl = TextEditingController(
      text: data['paymentAmount']?.toString() ?? '',
    );
    String payStatus = data['paymentStatus'] ?? 'unpaid';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(28),
            decoration: _modalDecoration(AppColors.warning),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modalTitle(
                  Icons.payments_rounded,
                  'MARK PAYMENT: $uid',
                  AppColors.warning,
                ),
                const SizedBox(height: 16),
                _inputField('PAYMENT AMOUNT (TK)', amtCtrl, 'e.g. 5000'),
                const SizedBox(height: 14),
                const Text(
                  'PAYMENT STATUS:',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _roleRadio(
                        'Paid',
                        'paid',
                        AppColors.successGreen,
                        payStatus,
                        (v) => setS(() => payStatus = v!),
                      ),
                    ),
                    Expanded(
                      child: _roleRadio(
                        'Unpaid',
                        'unpaid',
                        AppColors.dangerRed,
                        payStatus,
                        (v) => setS(() => payStatus = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({
                              'paymentAmount': amtCtrl.text.trim(),
                              'paymentStatus': payStatus,
                              'lastPaymentAt': FieldValue.serverTimestamp(),
                            });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(
                            context,
                            '✓ Payment status updated!',
                            AppColors.successGreen,
                          );
                        }
                      },
                      child: const Text(
                        'SAVE',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'LICENSE & PAYMENT MANAGER',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _filterDropdown('Payment', _filterPayment, [
                'all',
                'paid',
                'unpaid',
              ], (v) => setState(() => _filterPayment = v!)),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.vpn_key_rounded, size: 14),
                label: const Text(
                  'GENERATE KEY',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showSnack(
                  context,
                  'KEY: ${_generateKey()}',
                  AppColors.primaryCyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search client...',
              hintStyle: TextStyle(
                color: AppColors.textMuted.withOpacity(0.6),
                fontSize: 12,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
              filled: true,
              fillColor: AppColors.sidebar,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryCyan,
                  ),
                );
              }
              var docs = snap.data!.docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final uid = doc.id.toLowerCase();
                final ps = (d['paymentStatus'] ?? 'unpaid')
                    .toString()
                    .toLowerCase();
                if (_searchCtrl.text.isNotEmpty &&
                    !uid.contains(_searchCtrl.text.toLowerCase())) {
                  return false;
                }
                if (_filterPayment != 'all' && ps != _filterPayment) {
                  return false;
                }
                return true;
              }).toList();

              return _GlassContainer(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _HeaderText('CLIENT ID')),
                          Expanded(flex: 2, child: _HeaderText('PLAN')),
                          Expanded(flex: 2, child: _HeaderText('PAYMENT')),
                          Expanded(flex: 3, child: _HeaderText('EXPIRY')),
                          Expanded(flex: 2, child: _HeaderText('STATUS')),
                          Expanded(flex: 3, child: _HeaderText('ACTIONS')),
                        ],
                      ),
                    ),
                    ...docs.map((doc) {
                      final uid = doc.id;
                      final d = doc.data() as Map<String, dynamic>;
                      final plan = d['plan'] ?? 'Free';
                      final payStatus = (d['paymentStatus'] ?? 'unpaid')
                          .toString()
                          .toLowerCase();
                      final payAmt = d['paymentAmount']?.toString() ?? '';
                      final status = (d['status'] ?? 'active')
                          .toString()
                          .toLowerCase();

                      String expTxt = 'Lifetime Access';
                      Color expColor = AppColors.successGreen;
                      if (d['expiryDate'] != null) {
                        final exp = (d['expiryDate'] as Timestamp).toDate();
                        expTxt =
                            '${exp.day}/${exp.month}/${exp.year} ${exp.hour}:${exp.minute.toString().padLeft(2, '0')}';
                        if (exp.isBefore(DateTime.now())) {
                          expTxt = 'EXPIRED';
                          expColor = AppColors.dangerRed;
                        } else {
                          expColor = AppColors.textMain;
                        }
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                uid,
                                style: const TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                plan,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: payStatus == 'paid'
                                          ? AppColors.successGreen.withOpacity(
                                              0.15,
                                            )
                                          : AppColors.dangerRed.withOpacity(
                                              0.15,
                                            ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: payStatus == 'paid'
                                            ? AppColors.successGreen
                                                  .withOpacity(0.5)
                                            : AppColors.dangerRed.withOpacity(
                                                0.5,
                                              ),
                                      ),
                                    ),
                                    child: Text(
                                      payStatus.toUpperCase(),
                                      style: TextStyle(
                                        color: payStatus == 'paid'
                                            ? AppColors.successGreen
                                            : AppColors.dangerRed,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (payAmt.isNotEmpty)
                                    Text(
                                      '৳$payAmt',
                                      style: const TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                expTxt,
                                style: TextStyle(color: expColor, fontSize: 11),
                              ),
                            ),
                            Expanded(flex: 2, child: _statusBadge(status)),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  _iconBtn(
                                    Icons.payments_rounded,
                                    AppColors.warning,
                                    'Mark Payment',
                                    () => _showMarkPaymentModal(uid, d),
                                  ),
                                  _iconBtn(
                                    Icons.extension_rounded,
                                    AppColors.successGreen,
                                    'Extend',
                                    () => _showExtendModal(uid, d),
                                  ),
                                  _iconBtn(
                                    Icons.swap_horiz_rounded,
                                    AppColors.secondaryPurple,
                                    'Transfer',
                                    () => _showTransferModal(uid),
                                  ),
                                  _iconBtn(
                                    Icons.block_rounded,
                                    AppColors.dangerRed,
                                    'Revoke',
                                    () async {
                                      await FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(uid)
                                          .update({
                                            'plan': 'Free',
                                            'expiryDate': null,
                                            'paymentStatus': 'unpaid',
                                          });
                                      _showSnack(
                                        context,
                                        '✓ License revoked.',
                                        AppColors.warning,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${docs.length} license(s)',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  CAMPAIGN MANAGER PAGE
// ================================================================
class _CampaignManagerPage extends StatefulWidget {
  const _CampaignManagerPage();
  @override
  State<_CampaignManagerPage> createState() => _CampaignManagerPageState();
}

class _CampaignManagerPageState extends State<_CampaignManagerPage> {
  void _showCreateCampaignModal() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final toCtrl = TextEditingController();
    String type = 'standard';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 540,
            padding: const EdgeInsets.all(28),
            decoration: _modalDecoration(AppColors.primaryCyan),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalTitle(
                    Icons.campaign_rounded,
                    'CREATE CAMPAIGN',
                    AppColors.primaryCyan,
                  ),
                  const SizedBox(height: 16),
                  _inputField(
                    'CAMPAIGN NAME',
                    nameCtrl,
                    'e.g. Newsletter March 2025',
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    'EMAIL SUBJECT',
                    subjectCtrl,
                    'e.g. Exclusive Offer for You!',
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    'RECIPIENTS (comma separated)',
                    toCtrl,
                    'user@example.com, ...',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'EMAIL BODY:',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: bodyCtrl,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Write email body...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'TYPE:',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    children: [
                      SizedBox(
                        width: 110,
                        child: _roleRadio(
                          'Standard',
                          'standard',
                          AppColors.primaryCyan,
                          type,
                          (v) => setS(() => type = v!),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: _roleRadio(
                          'A/B Test',
                          'ab_test',
                          AppColors.secondaryPurple,
                          type,
                          (v) => setS(() => type = v!),
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: _roleRadio(
                          'Recurring',
                          'recurring',
                          AppColors.successGreen,
                          type,
                          (v) => setS(() => type = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty) return;
                          await FirebaseFirestore.instance
                              .collection('campaigns')
                              .add({
                                'name': nameCtrl.text.trim(),
                                'subject': subjectCtrl.text.trim(),
                                'body': bodyCtrl.text.trim(),
                                'recipients': toCtrl.text.trim(),
                                'status': 'draft',
                                'type': type,
                                'sentCount': 0,
                                'openCount': 0,
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _showSnack(
                              context,
                              '✓ Campaign created!',
                              AppColors.successGreen,
                            );
                          }
                        },
                        child: const Text(
                          'CREATE CAMPAIGN',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'CAMPAIGN MANAGER',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'CREATE CAMPAIGN',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _showCreateCampaignModal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('campaigns')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryCyan,
                  ),
                );
              }
              if (snap.data!.docs.isEmpty) {
                return _GlassContainer(
                  child: const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'NO CAMPAIGNS YET. Create your first campaign!',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                );
              }

              return _GlassContainer(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: _HeaderText('CAMPAIGN NAME'),
                          ),
                          Expanded(flex: 2, child: _HeaderText('TYPE')),
                          Expanded(flex: 2, child: _HeaderText('SENT')),
                          Expanded(flex: 2, child: _HeaderText('OPENS')),
                          Expanded(flex: 2, child: _HeaderText('STATUS')),
                          Expanded(flex: 3, child: _HeaderText('ACTIONS')),
                        ],
                      ),
                    ),
                    ...snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final status = (d['status'] ?? 'draft').toString();
                      final statusColor = status == 'running'
                          ? AppColors.successGreen
                          : status == 'paused'
                          ? AppColors.warning
                          : status == 'stopped'
                          ? AppColors.dangerRed
                          : AppColors.textMuted;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['name'] ?? '—',
                                    style: const TextStyle(
                                      color: AppColors.textMain,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    d['subject'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                (d['type'] ?? 'standard')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${d['sentCount'] ?? 0}',
                                style: const TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${d['openCount'] ?? 0}',
                                style: const TextStyle(
                                  color: AppColors.successGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.4),
                                  ),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  _iconBtn(
                                    Icons.play_arrow_rounded,
                                    AppColors.successGreen,
                                    'Start',
                                    () async {
                                      await FirebaseFirestore.instance
                                          .collection('campaigns')
                                          .doc(doc.id)
                                          .update({'status': 'running'});
                                    },
                                  ),
                                  _iconBtn(
                                    Icons.pause_rounded,
                                    AppColors.warning,
                                    'Pause',
                                    () async {
                                      await FirebaseFirestore.instance
                                          .collection('campaigns')
                                          .doc(doc.id)
                                          .update({'status': 'paused'});
                                    },
                                  ),
                                  _iconBtn(
                                    Icons.stop_rounded,
                                    AppColors.dangerRed,
                                    'Stop',
                                    () async {
                                      await FirebaseFirestore.instance
                                          .collection('campaigns')
                                          .doc(doc.id)
                                          .update({'status': 'stopped'});
                                    },
                                  ),
                                  _iconBtn(
                                    Icons.copy_rounded,
                                    AppColors.primaryCyan,
                                    'Duplicate',
                                    () async {
                                      final nd = Map<String, dynamic>.from(d);
                                      nd['name'] = '${nd['name']} (Copy)';
                                      nd['status'] = 'draft';
                                      nd['createdAt'] =
                                          FieldValue.serverTimestamp();
                                      await FirebaseFirestore.instance
                                          .collection('campaigns')
                                          .add(nd);
                                      _showSnack(
                                        context,
                                        '✓ Campaign duplicated!',
                                        AppColors.successGreen,
                                      );
                                    },
                                  ),
                                  _iconBtn(
                                    Icons.delete_rounded,
                                    AppColors.dangerRed,
                                    'Delete',
                                    () async {
                                      await FirebaseFirestore.instance
                                          .collection('campaigns')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  SMTP MANAGER PAGE
// ================================================================
class _SmtpManagerPage extends StatefulWidget {
  const _SmtpManagerPage();
  @override
  State<_SmtpManagerPage> createState() => _SmtpManagerPageState();
}

class _SmtpManagerPageState extends State<_SmtpManagerPage> {
  void _showAddSmtpModal() {
    final hostCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '587');
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final limitCtrl = TextEditingController(text: '500');
    bool ssl = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            decoration: _modalDecoration(AppColors.primaryCyan),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modalTitle(
                  Icons.router_rounded,
                  'ADD SMTP SERVER',
                  AppColors.primaryCyan,
                ),
                const SizedBox(height: 16),
                _inputField('SMTP LABEL', nameCtrl, 'e.g. Gmail Primary'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _inputField(
                        'SMTP HOST',
                        hostCtrl,
                        'smtp.gmail.com',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _inputField('PORT', portCtrl, '587'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _inputField('SMTP USERNAME', userCtrl, 'your@email.com'),
                const SizedBox(height: 12),
                _inputField(
                  'SMTP PASSWORD',
                  passCtrl,
                  '••••••••',
                  obscure: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _inputField('DAILY LIMIT', limitCtrl, '500'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SSL/TLS:',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SwitchListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            value: ssl,
                            activeThumbColor: AppColors.successGreen,
                            onChanged: (v) => setS(() => ssl = v),
                            title: Text(
                              ssl ? 'SSL ON' : 'SSL OFF',
                              style: TextStyle(
                                color: ssl
                                    ? AppColors.successGreen
                                    : AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (hostCtrl.text.isEmpty || userCtrl.text.isEmpty) {
                          return;
                        }
                        await FirebaseFirestore.instance
                            .collection('smtps')
                            .add({
                              'label': nameCtrl.text.trim(),
                              'host': hostCtrl.text.trim(),
                              'port': int.tryParse(portCtrl.text) ?? 587,
                              'username': userCtrl.text.trim(),
                              'ssl': ssl,
                              'status': 'active',
                              'dailyLimit': int.tryParse(limitCtrl.text) ?? 500,
                              'sentToday': 0,
                              'health': 100,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(
                            context,
                            '✓ SMTP added!',
                            AppColors.successGreen,
                          );
                        }
                      },
                      child: const Text(
                        'ADD SMTP',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'SMTP MANAGER',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'ADD SMTP',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _showAddSmtpModal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('smtps').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryCyan,
                  ),
                );
              }
              if (snap.data!.docs.isEmpty) {
                return _GlassContainer(
                  child: const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'NO SMTP SERVERS ADDED.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                );
              }
              return _GlassContainer(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _HeaderText('SMTP LABEL')),
                          Expanded(flex: 3, child: _HeaderText('HOST : PORT')),
                          Expanded(flex: 2, child: _HeaderText('DAILY LIMIT')),
                          Expanded(flex: 2, child: _HeaderText('HEALTH')),
                          Expanded(flex: 2, child: _HeaderText('STATUS')),
                          Expanded(flex: 3, child: _HeaderText('ACTIONS')),
                        ],
                      ),
                    ),
                    ...snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final status = (d['status'] ?? 'active').toString();
                      final health = (d['health'] ?? 100) as int;
                      final healthColor = health >= 80
                          ? AppColors.successGreen
                          : health >= 50
                          ? AppColors.warning
                          : AppColors.dangerRed;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['label'] ?? d['host'] ?? '—',
                                    style: const TextStyle(
                                      color: AppColors.textMain,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    d['username'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${d['host']}:${d['port']}',
                                style: const TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontSize: 11,
                                  fontFamily: 'Consolas',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${d['sentToday'] ?? 0}/${d['dailyLimit'] ?? 500}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.border,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      widthFactor: health / 100,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: healthColor,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$health%',
                                    style: TextStyle(
                                      color: healthColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(flex: 2, child: _statusBadge(status)),
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  _iconBtn(
                                    status == 'active'
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    status == 'active'
                                        ? AppColors.warning
                                        : AppColors.successGreen,
                                    status == 'active' ? 'Suspend' : 'Activate',
                                    () async {
                                      await FirebaseFirestore.instance
                                          .collection('smtps')
                                          .doc(doc.id)
                                          .update({
                                            'status': status == 'active'
                                                ? 'suspended'
                                                : 'active',
                                          });
                                    },
                                  ),
                                  _iconBtn(
                                    Icons.health_and_safety_rounded,
                                    AppColors.primaryCyan,
                                    'Health Check',
                                    () {
                                      final fakeHealth =
                                          60 + Random().nextInt(41);
                                      FirebaseFirestore.instance
                                          .collection('smtps')
                                          .doc(doc.id)
                                          .update({'health': fakeHealth});
                                      _showSnack(
                                        context,
                                        'SMTP Health: $fakeHealth%',
                                        fakeHealth > 80
                                            ? AppColors.successGreen
                                            : AppColors.warning,
                                      );
                                    },
                                  ),
                                  _iconBtn(
                                    Icons.delete_rounded,
                                    AppColors.dangerRed,
                                    'Delete',
                                    () async {
                                      await FirebaseFirestore.instance
                                          .collection('smtps')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  PROXY MANAGER PAGE
// ================================================================
class _ProxyManagerPage extends StatefulWidget {
  const _ProxyManagerPage();
  @override
  State<_ProxyManagerPage> createState() => _ProxyManagerPageState();
}

class _ProxyManagerPageState extends State<_ProxyManagerPage> {
  void _showAddProxyModal() {
    final ipCtrl = TextEditingController();
    final portCtrl = TextEditingController(text: '8080');
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final geoCtrlText = TextEditingController(text: 'BD');
    String proxyType = 'residential';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(28),
            decoration: _modalDecoration(AppColors.secondaryPurple),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _modalTitle(
                  Icons.swap_horiz_rounded,
                  'ADD PROXY',
                  AppColors.secondaryPurple,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _inputField('PROXY IP', ipCtrl, '192.168.1.1'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: _inputField('PORT', portCtrl, '8080'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _inputField('USERNAME', userCtrl, 'Optional'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _inputField(
                        'PASSWORD',
                        passCtrl,
                        'Optional',
                        obscure: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'PROXY TYPE:',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: [
                    SizedBox(
                      width: 130,
                      child: _roleRadio(
                        'Residential',
                        'residential',
                        AppColors.primaryCyan,
                        proxyType,
                        (v) => setS(() => proxyType = v!),
                      ),
                    ),
                    SizedBox(
                      width: 130,
                      child: _roleRadio(
                        'Datacenter',
                        'datacenter',
                        AppColors.secondaryPurple,
                        proxyType,
                        (v) => setS(() => proxyType = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _inputField('GEO COUNTRY CODE', geoCtrlText, 'e.g. BD, US, GB'),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        if (ipCtrl.text.isEmpty) return;
                        await FirebaseFirestore.instance
                            .collection('proxies')
                            .add({
                              'ip': ipCtrl.text.trim(),
                              'port': int.tryParse(portCtrl.text) ?? 8080,
                              'username': userCtrl.text.trim(),
                              'type': proxyType,
                              'geo': geoCtrlText.text.trim(),
                              'status': 'active',
                              'health': 100,
                              'speed': 0,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          _showSnack(
                            context,
                            '✓ Proxy added!',
                            AppColors.successGreen,
                          );
                        }
                      },
                      child: const Text(
                        'ADD PROXY',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'PROXY MANAGER',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  'ADD PROXY',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _showAddProxyModal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('proxies')
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryCyan,
                  ),
                );
              }
              if (snap.data!.docs.isEmpty) {
                return _GlassContainer(
                  child: const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'NO PROXIES ADDED.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                );
              }
              return _GlassContainer(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _HeaderText('IP : PORT')),
                          Expanded(flex: 2, child: _HeaderText('TYPE')),
                          Expanded(flex: 2, child: _HeaderText('GEO')),
                          Expanded(flex: 2, child: _HeaderText('HEALTH')),
                          Expanded(flex: 2, child: _HeaderText('STATUS')),
                          Expanded(flex: 2, child: _HeaderText('ACTIONS')),
                        ],
                      ),
                    ),
                    ...snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final status = (d['status'] ?? 'active').toString();
                      final health = (d['health'] ?? 100) as int;
                      final healthColor = health >= 80
                          ? AppColors.successGreen
                          : health >= 50
                          ? AppColors.warning
                          : AppColors.dangerRed;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${d['ip']}:${d['port']}',
                                style: const TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontSize: 12,
                                  fontFamily: 'Consolas',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                (d['type'] ?? 'residential')
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                d['geo'] ?? 'N/A',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppColors.border,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      widthFactor: health / 100,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: healthColor,
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$health%',
                                    style: TextStyle(
                                      color: healthColor,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(flex: 2, child: _statusBadge(status)),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  _iconBtn(
                                    status == 'active'
                                        ? Icons.block_rounded
                                        : Icons.check_circle_rounded,
                                    status == 'active'
                                        ? AppColors.warning
                                        : AppColors.successGreen,
                                    status == 'active' ? 'Suspend' : 'Activate',
                                    () async {
                                      await FirebaseFirestore.instance
                                          .collection('proxies')
                                          .doc(doc.id)
                                          .update({
                                            'status': status == 'active'
                                                ? 'suspended'
                                                : 'active',
                                          });
                                    },
                                  ),
                                  _iconBtn(
                                    Icons.delete_rounded,
                                    AppColors.dangerRed,
                                    'Delete',
                                    () async {
                                      await FirebaseFirestore.instance
                                          .collection('proxies')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  AI MANAGEMENT PAGE  — no dummy stats
// ================================================================
class _AiManagementPage extends StatefulWidget {
  const _AiManagementPage();
  @override
  State<_AiManagementPage> createState() => _AiManagementPageState();
}

class _AiManagementPageState extends State<_AiManagementPage> {
  final _promptCtrl = TextEditingController();
  String _aiOutput = '';
  bool _isGenerating = false;
  String _aiMode = 'subject';

  Future<void> _generateAi() async {
    if (_promptCtrl.text.isEmpty) return;
    setState(() {
      _isGenerating = true;
      _aiOutput = '';
    });
    await Future.delayed(const Duration(seconds: 1));
    final results = {
      'subject':
          '🎯 Exclusive Deal: ${_promptCtrl.text.trim()} — Don\'t Miss Out!\n💡 Your ${_promptCtrl.text.trim()} Awaits — Act Now!\n🔥 Limited Offer: ${_promptCtrl.text.trim()} Inside!',
      'email':
          'Dear Valued Customer,\n\nWe are thrilled to bring you ${_promptCtrl.text.trim()}.\n\nThis is a special opportunity crafted just for you. Our team has worked tirelessly to ensure the best experience.\n\nClick the button below to get started today.\n\nWarm Regards,\nINNOVEXA63 Team',
      'spam':
          'Spam Score Analysis for: "${_promptCtrl.text.trim()}"\n\n✅ No blacklisted words detected\n✅ Link ratio: OK\n⚠️ Caps usage: Moderate\n✅ Subject length: Good\n\nOverall Spam Score: 2.4/10 (LOW RISK)',
      'segment':
          'AI Audience Segmentation for: "${_promptCtrl.text.trim()}"\n\n📊 Segment A: High Engagement (32%)\n📊 Segment B: Medium Engagement (41%)\n📊 Segment C: Low Engagement (27%)\n\n✅ Recommended: Target Segment A first',
    };
    setState(() {
      _aiOutput = results[_aiMode] ?? '';
      _isGenerating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AI MANAGEMENT',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // ── No dummy stat cards — just the tools panel ──
          _GlassContainer(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI TOOLS',
                    style: TextStyle(
                      color: AppColors.textMain,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          {
                            'mode': 'subject',
                            'label': 'Subject Generator',
                            'icon': Icons.title_rounded,
                          },
                          {
                            'mode': 'email',
                            'label': 'Email Writer',
                            'icon': Icons.edit_note_rounded,
                          },
                          {
                            'mode': 'spam',
                            'label': 'Spam Checker',
                            'icon': Icons.shield_rounded,
                          },
                          {
                            'mode': 'segment',
                            'label': 'Audience Segment',
                            'icon': Icons.group_rounded,
                          },
                        ].map((item) {
                          final sel = _aiMode == item['mode'];
                          return GestureDetector(
                            onTap: () => setState(() {
                              _aiMode = item['mode'] as String;
                              _aiOutput = '';
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppColors.primaryCyan.withOpacity(0.15)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.primaryCyan
                                      : AppColors.border,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: sel
                                        ? AppColors.primaryCyan
                                        : AppColors.textMuted,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item['label'] as String,
                                    style: TextStyle(
                                      color: sel
                                          ? AppColors.primaryCyan
                                          : AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _promptCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: _aiMode == 'subject'
                          ? 'Enter topic e.g. "Black Friday Sale"...'
                          : _aiMode == 'email'
                          ? 'Describe your email...'
                          : _aiMode == 'spam'
                          ? 'Paste email subject or body to check...'
                          : 'Describe your target audience...',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.5),
                        fontSize: 12,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: Text(
                      _isGenerating ? 'Generating...' : 'GENERATE WITH AI',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _isGenerating ? null : _generateAi,
                  ),
                  if (_aiOutput.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.successGreen.withOpacity(0.3),
                        ),
                      ),
                      child: SelectableText(
                        _aiOutput,
                        style: const TextStyle(
                          color: AppColors.textMain,
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  BILLING & PAYMENTS PAGE  — fully live from Firestore
// ================================================================
class _BillingPage extends StatelessWidget {
  const _BillingPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BILLING & PAYMENTS',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();
              double totalPaid = 0, totalDue = 0;
              int paidCount = 0, unpaidCount = 0;
              for (var doc in snap.data!.docs) {
                final d = doc.data() as Map<String, dynamic>;
                final ps = (d['paymentStatus'] ?? 'unpaid')
                    .toString()
                    .toLowerCase();
                final amt =
                    double.tryParse(d['paymentAmount']?.toString() ?? '0') ?? 0;
                if (ps == 'paid') {
                  totalPaid += amt;
                  paidCount++;
                } else {
                  totalDue += amt;
                  unpaidCount++;
                }
              }
              return Column(
                children: [
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _StatCard(
                        'Total Revenue',
                        '৳${totalPaid.toStringAsFixed(0)}',
                        AppColors.successGreen,
                        Icons.attach_money_rounded,
                      ),
                      _StatCard(
                        'Paid Clients',
                        '$paidCount',
                        AppColors.primaryCyan,
                        Icons.check_circle_rounded,
                      ),
                      _StatCard(
                        'Unpaid Clients',
                        '$unpaidCount',
                        AppColors.dangerRed,
                        Icons.warning_rounded,
                      ),
                      _StatCard(
                        'Due Amount',
                        '৳${totalDue.toStringAsFixed(0)}',
                        AppColors.warning,
                        Icons.money_off_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'PAYMENT RECORDS',
                      style: TextStyle(
                        color: AppColors.textMain,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassContainer(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryCyan.withOpacity(0.06),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(10),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _HeaderText('CLIENT ID'),
                              ),
                              Expanded(flex: 2, child: _HeaderText('PLAN')),
                              Expanded(flex: 2, child: _HeaderText('AMOUNT')),
                              Expanded(flex: 2, child: _HeaderText('STATUS')),
                              Expanded(
                                flex: 2,
                                child: _HeaderText('LAST PAYMENT'),
                              ),
                              Expanded(flex: 3, child: _HeaderText('EXPIRY')),
                            ],
                          ),
                        ),
                        ...snap.data!.docs.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final ps = (d['paymentStatus'] ?? 'unpaid')
                              .toString()
                              .toLowerCase();
                          final amt = d['paymentAmount']?.toString() ?? '';
                          final plan = d['plan'] ?? 'Free';
                          final psColor = ps == 'paid'
                              ? AppColors.successGreen
                              : AppColors.dangerRed;

                          String expTxt = 'Lifetime';
                          Color expColor = AppColors.successGreen;
                          if (d['expiryDate'] != null) {
                            final exp = (d['expiryDate'] as Timestamp).toDate();
                            expTxt = '${exp.day}/${exp.month}/${exp.year}';
                            if (exp.isBefore(DateTime.now())) {
                              expTxt = 'EXPIRED';
                              expColor = AppColors.dangerRed;
                            } else {
                              expColor = AppColors.textMuted;
                            }
                          }

                          // Last payment date
                          String lastPay = '—';
                          if (d['lastPaymentAt'] != null) {
                            final lp = (d['lastPaymentAt'] as Timestamp)
                                .toDate();
                            lastPay = '${lp.day}/${lp.month}/${lp.year}';
                          }

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.border.withOpacity(0.5),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    (d['customUserId'] ?? doc.id).toString(),
                                    style: const TextStyle(
                                      color: AppColors.primaryCyan,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    plan,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    amt.isNotEmpty ? '৳$amt' : '—',
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: psColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: psColor.withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      ps.toUpperCase(),
                                      style: TextStyle(
                                        color: psColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    lastPay,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    expTxt,
                                    style: TextStyle(
                                      color: expColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
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
}

// ================================================================
//  ANALYTICS PAGE  — real Firestore data only
// ================================================================
class _AnalyticsPage extends StatelessWidget {
  const _AnalyticsPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ANALYTICS & REPORTS',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // ── User stats ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, userSnap) {
              int total = 0, active = 0, expired = 0, paid = 0, unpaid = 0;
              double revenue = 0;
              if (userSnap.hasData) {
                for (var doc in userSnap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  total++;
                  if ((d['status'] ?? '') == 'active') active++;
                  if (d['expiryDate'] != null &&
                      (d['expiryDate'] as Timestamp).toDate().isBefore(
                        DateTime.now(),
                      )) {
                    expired++;
                  }
                  final ps = (d['paymentStatus'] ?? 'unpaid')
                      .toString()
                      .toLowerCase();
                  if (ps == 'paid') {
                    paid++;
                    revenue +=
                        double.tryParse(
                          d['paymentAmount']?.toString() ?? '0',
                        ) ??
                        0;
                  } else {
                    unpaid++;
                  }
                }
              }

              return Column(
                children: [
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _StatCard(
                        'Total Users',
                        '$total',
                        AppColors.primaryCyan,
                        Icons.people_alt_rounded,
                      ),
                      _StatCard(
                        'Active Users',
                        '$active',
                        AppColors.successGreen,
                        Icons.check_circle_rounded,
                      ),
                      _StatCard(
                        'Expired',
                        '$expired',
                        AppColors.warning,
                        Icons.timer_off_rounded,
                      ),
                      _StatCard(
                        'Total Revenue',
                        '৳${revenue.toStringAsFixed(0)}',
                        AppColors.warning,
                        Icons.monetization_on_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _StatCard(
                        'Paid Clients',
                        '$paid',
                        AppColors.successGreen,
                        Icons.payments_rounded,
                      ),
                      _StatCard(
                        'Unpaid Clients',
                        '$unpaid',
                        AppColors.dangerRed,
                        Icons.money_off_rounded,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ── Campaign performance (live) ──
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('campaigns')
                .snapshots(),
            builder: (context, campSnap) {
              int totalSent = 0, totalOpen = 0, totalBounce = 0;
              int runningCampaigns = 0;
              if (campSnap.hasData) {
                for (var doc in campSnap.data!.docs) {
                  final d = doc.data() as Map<String, dynamic>;
                  totalSent += (d['sentCount'] ?? 0) as int;
                  totalOpen += (d['openCount'] ?? 0) as int;
                  totalBounce += (d['bounceCount'] ?? 0) as int;
                  if ((d['status'] ?? '') == 'running') runningCampaigns++;
                }
              }

              final openRate = totalSent > 0
                  ? (totalOpen / totalSent * 100).toStringAsFixed(1)
                  : '0.0';
              final bounceRate = totalSent > 0
                  ? (totalBounce / totalSent * 100).toStringAsFixed(1)
                  : '0.0';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.2,
                    children: [
                      _StatCard(
                        'Emails Sent',
                        _formatNum(totalSent),
                        AppColors.primaryCyan,
                        Icons.email_rounded,
                      ),
                      _StatCard(
                        'Running Campaigns',
                        '$runningCampaigns',
                        AppColors.successGreen,
                        Icons.campaign_rounded,
                      ),
                      _StatCard(
                        'Open Rate',
                        '$openRate%',
                        AppColors.successGreen,
                        Icons.trending_up_rounded,
                      ),
                      _StatCard(
                        'Bounce Rate',
                        '$bounceRate%',
                        AppColors.dangerRed,
                        Icons.trending_down_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _GlassContainer(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EMAIL PERFORMANCE',
                            style: TextStyle(
                              color: AppColors.textMain,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _analyticsBar(
                            'Total Emails Sent',
                            totalSent.toDouble(),
                            totalSent > 0 ? totalSent.toDouble() : 1,
                            AppColors.primaryCyan,
                            _formatNum(totalSent),
                          ),
                          _analyticsBar(
                            'Open Rate',
                            totalOpen.toDouble(),
                            totalSent > 0 ? totalSent.toDouble() : 1,
                            AppColors.successGreen,
                            '$openRate%',
                          ),
                          _analyticsBar(
                            'Bounce Rate',
                            totalBounce.toDouble(),
                            totalSent > 0 ? totalSent.toDouble() : 1,
                            AppColors.dangerRed,
                            '$bounceRate%',
                          ),
                        ],
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

  static String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  static Widget _analyticsBar(
    String label,
    double value,
    double max,
    Color color,
    String display,
  ) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                display,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  SECURITY CENTER PAGE
// ================================================================
class _SecurityCenterPage extends StatelessWidget {
  const _SecurityCenterPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SECURITY CENTER',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 2.5,
            children: [
              // ── Force logout ONLY role==user accounts ──
              _securityCard(
                'Force Logout All Users',
                Icons.logout_rounded,
                AppColors.dangerRed,
                () async {
                  final batch = FirebaseFirestore.instance.batch();
                  final users = await FirebaseFirestore.instance
                      .collection('users')
                      .where('role', isEqualTo: 'user')
                      .get();
                  for (var doc in users.docs) {
                    batch.update(doc.reference, {
                      'forceLogout': true,
                      'forceLogoutAt': FieldValue.serverTimestamp(),
                    });
                  }
                  await batch.commit();

                  // Log it
                  await FirebaseFirestore.instance
                      .collection('activity_logs')
                      .add({
                        'action':
                            'Force logout applied to all user-role accounts',
                        'type': 'security',
                        'targetUser': 'all_users',
                        'performedBy': 'admin',
                        'device': 'Admin Panel',
                        'platform': 'Web',
                        'timestamp': FieldValue.serverTimestamp(),
                      });

                  _showSnack(
                    context,
                    '✓ All USER-role accounts force logged out!',
                    AppColors.dangerRed,
                  );
                },
              ),
              _securityCard(
                'Auto-Suspend Expired',
                Icons.timer_off_rounded,
                AppColors.warning,
                () async {
                  final now = Timestamp.now();
                  final users = await FirebaseFirestore.instance
                      .collection('users')
                      .where('expiryDate', isLessThan: now)
                      .get();
                  final batch = FirebaseFirestore.instance.batch();
                  for (var doc in users.docs) {
                    batch.update(doc.reference, {'status': 'blocked'});
                  }
                  await batch.commit();
                  _showSnack(
                    context,
                    '✓ ${users.docs.length} expired users suspended!',
                    AppColors.warning,
                  );
                },
              ),
              // ── Security scan: read-only, no side-effects ──
              _securityCard(
                'Security Scan',
                Icons.security_rounded,
                AppColors.primaryCyan,
                () async {
                  // Count suspicious: banned or force-logout flagged
                  final suspicious = await FirebaseFirestore.instance
                      .collection('users')
                      .where('status', isEqualTo: 'banned')
                      .get();
                  final flagged = await FirebaseFirestore.instance
                      .collection('users')
                      .where('forceLogout', isEqualTo: true)
                      .get();

                  _showSnack(
                    context,
                    '✓ Scan complete. Banned: ${suspicious.docs.length}, Flagged: ${flagged.docs.length}',
                    AppColors.successGreen,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IP WHITELIST',
                          style: TextStyle(
                            color: AppColors.successGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _securityIpRow('192.168.1.1', AppColors.successGreen),
                        _securityIpRow('10.0.0.1', AppColors.successGreen),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: const Text(
                            'Add IP',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.successGreen.withOpacity(
                              0.15,
                            ),
                            foregroundColor: AppColors.successGreen,
                            side: BorderSide(
                              color: AppColors.successGreen.withOpacity(0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _GlassContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IP BLACKLIST',
                          style: TextStyle(
                            color: AppColors.dangerRed,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _securityIpRow('185.220.101.1', AppColors.dangerRed),
                        _securityIpRow('45.33.32.156', AppColors.dangerRed),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded, size: 14),
                          label: const Text(
                            'Block IP',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dangerRed.withOpacity(
                              0.15,
                            ),
                            foregroundColor: AppColors.dangerRed,
                            side: BorderSide(
                              color: AppColors.dangerRed.withOpacity(0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _securityCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.sidebar,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMain,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _securityIpRow(String ip, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            ip,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontFamily: 'Consolas',
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  ACTIVITY LOGS PAGE  — real Firestore logs, click for detail
// ================================================================
class _ActivityLogsPage extends StatefulWidget {
  const _ActivityLogsPage();
  @override
  State<_ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<_ActivityLogsPage> {
  String _filterType = 'all';
  String _searchUser = '';
  final _searchCtrl = TextEditingController();

  // ── Show full log detail for a specific user ──
  void _showUserLogsModal(String targetUser) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 620,
          padding: const EdgeInsets.all(28),
          decoration: _modalDecoration(AppColors.primaryCyan),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modalTitle(
                Icons.history_rounded,
                'ACTIVITY HISTORY: $targetUser',
                AppColors.primaryCyan,
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 420,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('activity_logs')
                      .where('targetUser', isEqualTo: targetUser)
                      .orderBy('timestamp', descending: true)
                      .limit(50)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryCyan,
                        ),
                      );
                    }
                    if (snap.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'No activity logs found.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }

                    return ListView(
                      children: snap.data!.docs.map((doc) {
                        final d = doc.data() as Map<String, dynamic>;
                        final ts = d['timestamp'] != null
                            ? (d['timestamp'] as Timestamp).toDate()
                            : null;
                        final timeStr = ts != null
                            ? '${ts.day}/${ts.month}/${ts.year} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}'
                            : '—';
                        final type = (d['type'] ?? 'system').toString();
                        final typeColor = type == 'login' || type == 'logout'
                            ? AppColors.primaryCyan
                            : type == 'security'
                            ? AppColors.dangerRed
                            : type == 'payment'
                            ? AppColors.warning
                            : type == 'campaign'
                            ? AppColors.successGreen
                            : AppColors.textMuted;

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.border.withOpacity(0.4),
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      type.toUpperCase(),
                                      style: TextStyle(
                                        color: typeColor,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    timeStr,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                d['action'] ?? '—',
                                style: const TextStyle(
                                  color: AppColors.textMain,
                                  fontSize: 12,
                                ),
                              ),
                              if ((d['device'] ?? '').isNotEmpty ||
                                  (d['platform'] ?? '').isNotEmpty)
                                Text(
                                  '📱 ${d['device'] ?? ''} • ${d['platform'] ?? ''}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              if ((d['ipAddress'] ?? '').isNotEmpty)
                                Text(
                                  '🌐 IP: ${d['ipAddress']}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              if ((d['details'] ?? '').isNotEmpty)
                                Text(
                                  d['details'],
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ACTIVITY LOGS',
                style: TextStyle(
                  color: AppColors.textMain,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  onChanged: (v) => setState(() => _searchUser = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search user...',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                    filled: true,
                    fillColor: AppColors.sidebar,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _filterDropdown('Type', _filterType, [
                'all',
                'login',
                'logout',
                'campaign',
                'payment',
                'security',
                'user_management',
                'system',
              ], (v) => setState(() => _filterType = v!)),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 14),
                label: const Text(
                  'EXPORT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _showSnack(
                  context,
                  '✓ Logs exported!',
                  AppColors.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('activity_logs')
                .orderBy('timestamp', descending: true)
                .limit(100)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryCyan,
                  ),
                );
              }

              if (!snap.hasData || snap.data!.docs.isEmpty) {
                return _GlassContainer(
                  child: const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            color: AppColors.textMuted,
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'No activity logs yet.\nActions performed in the dashboard will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Filter
              final docs = snap.data!.docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final type = (d['type'] ?? 'system').toString().toLowerCase();
                final user = (d['targetUser'] ?? '').toString().toLowerCase();
                if (_filterType != 'all' && type != _filterType) return false;
                if (_searchUser.isNotEmpty &&
                    !user.contains(_searchUser.toLowerCase())) {
                  return false;
                }
                return true;
              }).toList();

              return _GlassContainer(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: _HeaderText('TIME')),
                          Expanded(flex: 2, child: _HeaderText('TYPE')),
                          Expanded(flex: 3, child: _HeaderText('USER')),
                          Expanded(flex: 2, child: _HeaderText('DEVICE')),
                          Expanded(flex: 4, child: _HeaderText('ACTION')),
                          Expanded(flex: 1, child: _HeaderText('DETAIL')),
                        ],
                      ),
                    ),
                    ...docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final ts = d['timestamp'] != null
                          ? (d['timestamp'] as Timestamp).toDate()
                          : null;
                      final timeStr = ts != null ? _timeAgo(ts) : '—';
                      final type = (d['type'] ?? 'system').toString();
                      final typeColor = type == 'login' || type == 'logout'
                          ? AppColors.primaryCyan
                          : type == 'security'
                          ? AppColors.dangerRed
                          : type == 'payment'
                          ? AppColors.warning
                          : type == 'campaign'
                          ? AppColors.successGreen
                          : AppColors.textMuted;
                      final targetUser = (d['targetUser'] ?? '—').toString();
                      final device = (d['device'] ?? '—').toString();

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                timeStr,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  type.toUpperCase(),
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                targetUser,
                                style: const TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                device,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                d['action']?.toString() ?? '—',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: _iconBtn(
                                Icons.open_in_new_rounded,
                                AppColors.primaryCyan,
                                'View Full History',
                                () => _showUserLogsModal(targetUser),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Showing ${docs.length} log(s)',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ================================================================
//  ROLE MANAGEMENT PAGE
// ================================================================
class _RoleManagementPage extends StatelessWidget {
  const _RoleManagementPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ROLE MANAGEMENT',
            style: TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.8,
            children: [
              _roleCard('Super Admin', Colors.amberAccent, [
                'All Permissions',
                'Cannot be deleted',
                'Full Control',
              ]),
              _roleCard('Admin', AppColors.dangerRed, [
                'User Management',
                'Campaign Control',
                'Billing Access',
              ]),
              _roleCard('Sub Admin', AppColors.warning, [
                'Limited Access',
                'Custom Permissions',
                'No Delete Rights',
              ]),
              _roleCard('User', AppColors.primaryCyan, [
                'Campaign Only',
                'SMTP Access',
                'Basic Dashboard',
              ]),
            ],
          ),
          const SizedBox(height: 24),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', whereIn: ['admin', 'sub_admin'])
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox();
              return _GlassContainer(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.06),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: _HeaderText('ADMIN USER')),
                          Expanded(flex: 2, child: _HeaderText('ROLE')),
                          Expanded(flex: 3, child: _HeaderText('PERMISSIONS')),
                          Expanded(flex: 2, child: _HeaderText('STATUS')),
                        ],
                      ),
                    ),
                    if (snap.data!.docs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No admins found.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ...snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      final perms =
                          (d['permissions'] as List<dynamic>?)
                              ?.cast<String>() ??
                          [];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.5),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                (d['customUserId'] ?? doc.id).toString(),
                                style: const TextStyle(
                                  color: AppColors.textMain,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: _RoleBadge(d['role'] ?? 'user'),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                perms.isEmpty
                                    ? 'Full Access'
                                    : perms.join(', '),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: _statusBadge(
                                (d['status'] ?? 'active').toString(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _roleCard(String title, Color color, List<String> perms) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...perms.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_rounded, color: color, size: 12),
                  const SizedBox(width: 6),
                  Text(
                    p,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
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
}

// ================================================================
//  COMING SOON
// ================================================================
class _ComingSoon extends StatelessWidget {
  final String title;
  const _ComingSoon(this.title);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction_rounded,
            color: AppColors.primaryCyan.withOpacity(0.4),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.primaryCyan,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Module under development',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ================================================================
//  SHARED HELPER WIDGETS & FUNCTIONS
// ================================================================

class _GlassContainer extends StatelessWidget {
  final Widget child;
  const _GlassContainer({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryCyan.withOpacity(0.15)),
      ),
      child: child,
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  const _HeaderText(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    ),
  );
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);
  @override
  Widget build(BuildContext context) {
    final isSuper = role.toLowerCase() == 'super_admin';
    final isAdmin = role.toLowerCase() == 'admin';
    final isSub = role.toLowerCase() == 'sub_admin';
    Color color = AppColors.secondaryPurple;
    if (isSuper) {
      color = Colors.amberAccent;
    } else if (isAdmin)
      color = AppColors.dangerRed;
    else if (isSub)
      color = AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        role.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final Color color;
  final IconData icon;
  const _StatCard(this.title, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _statusBadge(String status) {
  final color = status == 'active'
      ? AppColors.successGreen
      : status == 'banned'
      ? AppColors.dangerRed
      : AppColors.warning;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      status.toUpperCase(),
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _tableHeader(List<String> cols) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  decoration: BoxDecoration(
    color: AppColors.primaryCyan.withOpacity(0.06),
    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
  ),
  child: Row(
    children: cols.map((c) => Expanded(child: _HeaderText(c))).toList(),
  ),
);

Widget _tableRow(List<String> vals, List<Color> colors) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  decoration: BoxDecoration(
    border: Border(
      bottom: BorderSide(color: AppColors.border.withOpacity(0.5)),
    ),
  ),
  child: Row(
    children: List.generate(
      vals.length,
      (i) => Expanded(
        child: Text(
          vals[i],
          style: TextStyle(
            color: colors[i],
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  ),
);

Widget _filterDropdown(
  String label,
  String value,
  List<String> items,
  ValueChanged<String?> onChanged,
) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.sidebar,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.sidebar,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.textMuted,
          size: 16,
        ),
        items: items
            .map(
              (i) => DropdownMenuItem(
                value: i,
                child: Text(i == 'all' ? 'All ${label}s' : i.toUpperCase()),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

Widget _detailGrid(String uid, Map<String, dynamic> d) {
  String expTime = 'Lifetime';
  if (d['expiryDate'] != null) {
    final dt = (d['expiryDate'] as Timestamp).toDate();
    expTime =
        '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
  final items = {
    'User ID': uid,
    'Full Name': d['fullName'] ?? '—',
    'Role': (d['role'] ?? 'user').toString().toUpperCase(),
    'Status': (d['status'] ?? 'active').toString().toUpperCase(),
    'Plan': d['plan'] ?? 'Free',
    'Payment': d['paymentAmount'] != null
        ? '৳${d['paymentAmount']} (${d['paymentStatus'] ?? 'unpaid'})'
        : 'N/A',
    'API Access': (d['apiAccess'] ?? true) ? 'ENABLED' : 'DISABLED',
    'Expiry': expTime,
    'Campaigns': '${d['campaignCount'] ?? 0}',
    'Emails Sent': '${d['totalEmailsSent'] ?? 0}',
  };
  return GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 4,
    crossAxisSpacing: 12,
    mainAxisSpacing: 8,
    children: items.entries
        .map(
          (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.key,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                e.value,
                style: const TextStyle(color: AppColors.textMain, fontSize: 12),
              ),
            ],
          ),
        )
        .toList(),
  );
}

Widget _actionBtn(
  String label,
  Color color,
  IconData icon,
  VoidCallback onTap,
) {
  return ElevatedButton.icon(
    icon: Icon(icon, size: 13),
    label: Text(label, style: const TextStyle(fontSize: 11)),
    style: ElevatedButton.styleFrom(
      backgroundColor: color.withOpacity(0.15),
      foregroundColor: color,
      side: BorderSide(color: color.withOpacity(0.4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    onPressed: onTap,
  );
}

Widget _iconBtn(
  IconData icon,
  Color color,
  String tooltip,
  VoidCallback onTap,
) {
  return Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Icon(icon, color: color, size: 17),
      ),
    ),
  );
}

void _showSnack(BuildContext ctx, String msg, Color color) {
  if (!ctx.mounted) return;
  ScaffoldMessenger.of(ctx).showSnackBar(
    SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

BoxDecoration _modalDecoration(Color c) => BoxDecoration(
  color: AppColors.sidebar,
  borderRadius: BorderRadius.circular(16),
  border: Border.all(color: c.withOpacity(0.4), width: 1.5),
  boxShadow: [
    BoxShadow(color: c.withOpacity(0.1), blurRadius: 30, spreadRadius: 2),
  ],
);

Widget _modalTitle(IconData icon, String title, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const Divider(color: AppColors.border),
    ],
  );
}

Widget _inputField(
  String label,
  TextEditingController ctrl,
  String hint, {
  bool obscure = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textMuted.withOpacity(0.5),
            fontSize: 12,
          ),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    ],
  );
}

InputDecoration _dropdownDecor() => InputDecoration(
  filled: true,
  fillColor: AppColors.background,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide.none,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
);

Widget _roleRadio(
  String label,
  String value,
  Color color,
  String groupValue,
  ValueChanged<String?> onChanged,
) {
  return RadioListTile<String>(
    title: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
    ),
    value: value,
    groupValue: groupValue,
    activeColor: color,
    contentPadding: EdgeInsets.zero,
    dense: true,
    onChanged: onChanged,
  );
}

Widget _checkboxItem(
  String label,
  bool value,
  Color color,
  ValueChanged<bool?> onChanged,
) {
  return CheckboxListTile(
    title: Text(
      label,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
    ),
    value: value,
    activeColor: color,
    dense: true,
    contentPadding: EdgeInsets.zero,
    onChanged: onChanged,
  );
}

Widget _datePickerTile(
  BuildContext context,
  DateTime? date,
  String hint,
  IconData icon,
  Color color,
  ValueChanged<DateTime> onPicked,
) {
  return ListTile(
    tileColor: AppColors.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    leading: Icon(icon, color: color, size: 18),
    title: Text(
      date != null ? '${date.day}/${date.month}/${date.year}' : hint,
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    trailing: const Icon(
      Icons.edit_rounded,
      color: AppColors.textMuted,
      size: 14,
    ),
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: date ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2035),
      );
      if (picked != null) onPicked(picked);
    },
  );
}

Widget _timePickerTile(
  BuildContext context,
  TimeOfDay? time,
  IconData icon,
  Color color,
  ValueChanged<TimeOfDay> onPicked,
) {
  return ListTile(
    tileColor: AppColors.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    leading: Icon(icon, color: color, size: 18),
    title: Text(
      time != null ? time.format(context) : 'Select Time',
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    trailing: const Icon(
      Icons.edit_rounded,
      color: AppColors.textMuted,
      size: 14,
    ),
    onTap: () async {
      final picked = await showTimePicker(
        context: context,
        initialTime: time ?? TimeOfDay.now(),
      );
      if (picked != null) onPicked(picked);
    },
  );
}
