import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../auth/login_screen.dart';
import '../../core/app_colors.dart';
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart';

// ================================================================
//  DASHBOARD SCREEN - INNOVEXA63 MAILER ULTRA 7.0
//  NEW v7: Google API JSON send, Excel export (sent/failed sheets),
//          Format selector (Plain/HTML/Template), Random name/subject
//          pools, inline text+HTML dual, App Password optional,
//          per-task method selector, admin force-logout real-time
//  NOTHING DELETED — All v6 features kept + upgraded
// ================================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  StreamSubscription<DocumentSnapshot>? _userStatusSub;

  // ── Tasks ──
  final List<_MailTask> _tasks = [_MailTask(id: 1)];
  int _activeTask = 0;

  // ── IP & Proxy Rotation ──
  List<String> _ipList = [];
  bool _ipRotationEnabled = false;
  bool _randomIpRotation = true;
  int _ipRotateEvery = 5;
  int _currentIpIndex = 0;
  String _currentIp = 'None';

  // Global Proxy
  String _proxyHost = '';
  String _proxyPort = '';
  String _proxyUser = '';
  String _proxyPass = '';

  // ── Delivery Stats ──
  int _totalSent = 0;
  int _totalFailed = 0;
  int _totalPending = 0;
  bool _isSending = false;
  bool _isPaused = false;

  // ── Per-SMTP send limit ──
  int _maxSendPerSmtp = 0;
  int _sentFromCurrentSmtp = 0;

  // ── Logs ──
  final List<_LogEntry> _logs = [];
  bool _saveLogs = false;

  // ── License info ──
  Map<String, dynamic> _userData = {};
  String _resolvedUserId = '';
  String _displayName = '';

  // ── Countdown timer ──
  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  // ── SMTP Test ──
  String _smtpTestResult = '';
  bool _smtpTesting = false;

  final _ipInputCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startLiveSecurityCheck();
  }

  @override
  void dispose() {
    _userStatusSub?.cancel();
    _countdownTimer?.cancel();
    _ipInputCtrl.dispose();
    for (final t in _tasks) t.dispose();
    super.dispose();
  }

  // ================================================================
  //  REAL-TIME AUTO LOGOUT
  // ================================================================
  void _startLiveSecurityCheck() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String docId = user.uid;
    final email = user.email ?? '';
    if (email.contains('@innovexa.com')) {
      final fromEmail = email.replaceAll('@innovexa.com', '').trim();
      if (fromEmail.isNotEmpty) {
        try {
          final d = await FirebaseFirestore.instance
              .collection('users')
              .doc(fromEmail)
              .get();
          if (d.exists) docId = fromEmail;
        } catch (_) {}
      }
    }

    setState(() {
      _resolvedUserId = docId;
      _displayName = docId;
    });

    _userStatusSub = FirebaseFirestore.instance
        .collection('users')
        .doc(docId)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;
          final data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userData = data;
              _displayName = (data['fullName'] ?? '').toString().isNotEmpty
                  ? data['fullName']
                  : (data['customUserId'] ?? docId).toString();
            });
            _startCountdownTimer(data);
          }

          final role = (data['role'] ?? 'user').toString().toLowerCase();
          final isAdmin =
              role == 'admin' || role == 'super_admin' || role == 'sub_admin';

          if (!isAdmin && data['forceLogout'] == true) {
            _forceLogout('SECURITY ALERT: Admin force-logged you out.');
            return;
          }

          final status = (data['status'] ?? 'active').toString().toLowerCase();
          if (status == 'blocked' ||
              status == 'banned' ||
              status == 'suspended') {
            _forceLogout('ACCESS DENIED: Account $status by Administrator.');
            return;
          }

          if (!isAdmin && data['expiryDate'] != null) {
            final exp = (data['expiryDate'] as Timestamp).toDate();
            if (DateTime.now().isAfter(exp)) {
              _forceLogout('LICENSE EXPIRED: Please renew your subscription.');
              return;
            }
          }
        });
  }

  void _startCountdownTimer(Map<String, dynamic> data) {
    _countdownTimer?.cancel();
    if (data['expiryDate'] == null) {
      setState(() => _timeRemaining = Duration.zero);
      return;
    }
    final exp = (data['expiryDate'] as Timestamp).toDate();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final diff = exp.difference(DateTime.now());
      setState(() => _timeRemaining = diff.isNegative ? Duration.zero : diff);
    });
  }

  String _formatCountdown(Duration d) {
    if (d == Duration.zero && _userData['expiryDate'] == null)
      return 'Lifetime';
    if (d == Duration.zero) return 'EXPIRED';
    if (d.inDays > 0)
      return '${d.inDays}d ${d.inHours % 24}h ${d.inMinutes % 60}m';
    if (d.inHours > 0)
      return '${d.inHours}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  Future<void> _forceLogout(String reason) async {
    _userStatusSub?.cancel();
    _countdownTimer?.cancel();
    setState(() => _isSending = false);
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: AppColors.dangerRed,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (r) => false,
      );
    }
  }

  // ================================================================
  //  REAL GOOGLE API AUTHENTICATION
  // ================================================================
  void _authenticateGoogle(_MailTask task) async {
    if (task.googleJsonPath.isEmpty) {
      _showSnack(
        context,
        'Please select a Google credentials.json file!',
        AppColors.dangerRed,
      );
      return;
    }
    _showSnack(context, 'Authenticating with Google API...', AppColors.warning);

    try {
      final jsonString = await File(task.googleJsonPath).readAsString();
      final credentials = auth.ServiceAccountCredentials.fromJson(jsonString);

      final client = await auth.clientViaServiceAccount(credentials, [
        gmail.GmailApi.mailGoogleComScope,
      ]);

      setState(() {
        task.googleApiToken = 'REAL-AUTH-SUCCESS';
      });
      client.close();
      _showSnack(
        context,
        '✓ Google API Authenticated Successfully!',
        AppColors.successGreen,
      );
    } catch (e) {
      setState(() => task.googleApiToken = '');
      _showSnack(
        context,
        'Auth Failed: Ensure valid JSON file!',
        AppColors.dangerRed,
      );
    }
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

  // ================================================================
  //  LICENSE BANNER
  // ================================================================
  Widget _buildLicenseBanner() {
    final plan = _userData['plan'] ?? '—';
    final hasExpiry = _userData['expiryDate'] != null;
    final isExpired = hasExpiry && _timeRemaining == Duration.zero;
    Color bannerColor = AppColors.successGreen;
    if (isExpired)
      bannerColor = AppColors.dangerRed;
    else if (hasExpiry && _timeRemaining.inDays < 7)
      bannerColor = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(0.08),
        border: Border(
          bottom: BorderSide(color: bannerColor.withOpacity(0.25)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_rounded,
            color: AppColors.primaryCyan,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            _displayName.isNotEmpty ? _displayName : '—',
            style: const TextStyle(
              color: AppColors.primaryCyan,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 14),
          Icon(Icons.verified_rounded, color: bannerColor, size: 13),
          const SizedBox(width: 4),
          Text(
            'Plan: $plan',
            style: TextStyle(
              color: bannerColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.timer_rounded, color: bannerColor, size: 13),
          const SizedBox(width: 4),
          Text(
            _formatCountdown(_timeRemaining),
            style: TextStyle(
              color: bannerColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'Consolas',
            ),
          ),
          const Spacer(),
          _pkgChip('mailer', AppColors.successGreen),
          const SizedBox(width: 6),
          _pkgChip('firebase', AppColors.warning),
          const SizedBox(width: 6),
          _pkgChip('excel', AppColors.primaryCyan),
        ],
      ),
    );
  }

  Widget _pkgChip(String pkg, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          pkg,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  // ================================================================
  //  TASK MANAGEMENT
  // ================================================================
  void _addTask() {
    if (_tasks.length >= 5) {
      _showSnack(context, 'Maximum 5 tasks!', AppColors.warning);
      return;
    }
    setState(() {
      _tasks.add(_MailTask(id: _tasks.length + 1));
      _activeTask = _tasks.length - 1;
    });
  }

  void _deleteTask() {
    if (_tasks.length <= 1) {
      _showSnack(context, 'At least 1 task required!', AppColors.warning);
      return;
    }
    setState(() {
      _tasks[_activeTask].dispose();
      _tasks.removeAt(_activeTask);
      _activeTask = (_activeTask > 0) ? _activeTask - 1 : 0;
    });
  }

  // ================================================================
  //  IP ROTATION
  // ================================================================
  void _addIp(String ip) {
    ip = ip.trim();
    if (ip.isEmpty) return;
    setState(() {
      for (final p in ip.split('\n')) {
        final c = p.trim();
        if (c.isNotEmpty && !_ipList.contains(c)) _ipList.add(c);
      }
      if (_ipList.isNotEmpty) _currentIp = _ipList[0];
    });
    _ipInputCtrl.clear();
  }

  String _getNextIp() {
    if (_ipList.isEmpty) return 'Direct';
    _currentIpIndex = _randomIpRotation
        ? Random().nextInt(_ipList.length)
        : (_currentIpIndex + 1) % _ipList.length;
    _currentIp = _ipList[_currentIpIndex];
    return _currentIp;
  }

  // ================================================================
  //  EXCEL / CSV PARSER
  // ================================================================
  Future<void> _parseExcelOrCsv(String filePath, _MailTask task) async {
    final file = File(filePath);
    final ext = filePath.split('.').last.toLowerCase();
    final emails = <String>[];
    final parsed = <Map<String, dynamic>>[];
    int skipped = 0;

    try {
      if (ext == 'xlsx' || ext == 'xls') {
        final bytes = await file.readAsBytes();
        final xl = Excel.decodeBytes(bytes);
        for (final table in xl.tables.keys) {
          final sheet = xl.tables[table]!;
          for (int r = 0; r < sheet.maxRows; r++) {
            final row = sheet.row(r);
            if (row.isEmpty) continue;
            final emailVal = row[0]?.value?.toString().trim() ?? '';
            if (emailVal.isEmpty ||
                !emailVal.contains('@') ||
                !emailVal.contains('.')) {
              if (r > 0) skipped++;
              continue;
            }
            String name = row.length > 1
                ? (row[1]?.value?.toString().trim() ?? '')
                : '';
            if (name.isEmpty) name = _nameFromEmail(emailVal);
            emails.add(emailVal);
            parsed.add({
              'email': emailVal,
              'name': name,
              'amount': row.length > 2
                  ? (row[2]?.value?.toString().trim() ?? '')
                  : '',
              'address': row.length > 3
                  ? (row[3]?.value?.toString().trim() ?? '')
                  : '',
              'extra': row.length > 4
                  ? row
                        .sublist(4)
                        .map((c) => c?.value?.toString() ?? '')
                        .join(',')
                  : '',
            });
          }
          break;
        }
      } else {
        final content = await file.readAsString();
        _parseCsvText(content, emails, parsed, skipped);
      }

      setState(() {
        task.recipientList = emails;
        task.recipientData = parsed;
      });
      _showSnack(
        context,
        '✓ Loaded ${emails.length} emails${skipped > 0 ? ' ($skipped skipped)' : ''}',
        AppColors.successGreen,
      );
    } catch (e) {
      _showSnack(context, 'Parse error: $e', AppColors.dangerRed);
    }
  }

  void _parseCsvText(
    String rawText,
    List<String> emails,
    List<Map<String, dynamic>> parsed,
    int skipped,
  ) {
    for (final line in rawText.trim().split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final parts = trimmed.contains('\t')
          ? trimmed.split('\t')
          : trimmed.split(',');
      final email = parts[0].trim().replaceAll('"', '');
      if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
        skipped++;
        continue;
      }
      String name = parts.length > 1 ? parts[1].trim().replaceAll('"', '') : '';
      if (name.isEmpty) name = _nameFromEmail(email);
      emails.add(email);
      parsed.add({
        'email': email,
        'name': name,
        'amount': parts.length > 2 ? parts[2].trim().replaceAll('"', '') : '',
        'address': parts.length > 3 ? parts[3].trim().replaceAll('"', '') : '',
        'extra': parts.length > 4 ? parts.sublist(4).join(',').trim() : '',
      });
    }
  }

  void _parseCsvContent(String rawText, _MailTask task) {
    final emails = <String>[];
    final parsed = <Map<String, dynamic>>[];
    int sk = 0;
    _parseCsvText(rawText, emails, parsed, sk);
    setState(() {
      task.recipientList = emails;
      task.recipientData = parsed;
    });
    _showSnack(
      context,
      '✓ Loaded ${emails.length} emails',
      AppColors.successGreen,
    );
  }

  String _nameFromEmail(String email) {
    final prefix = email.split('@')[0];
    return prefix
        .replaceAll('.', ' ')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (w) => w.isNotEmpty
              ? w[0].toUpperCase() + w.substring(1).toLowerCase()
              : '',
        )
        .join(' ')
        .trim();
  }

  // ================================================================
  //  SMTP VALIDATION
  // ================================================================
  bool _validateSmtp(_MailTask task) {
    if (task.sendMethod == 'Google API JSON') {
      if (task.emailCtrl.text.trim().isEmpty) {
        _showSnack(context, 'Enter Google Email!', AppColors.dangerRed);
        return false;
      }
      if (task.googleJsonPath.isEmpty) {
        _showSnack(
          context,
          'Select Google credentials.json!',
          AppColors.dangerRed,
        );
        return false;
      }
      return true;
    }
    if (task.emailCtrl.text.trim().isEmpty) {
      _showSnack(context, 'Enter From Email!', AppColors.dangerRed);
      return false;
    }
    if (!task.emailCtrl.text.contains('@')) {
      _showSnack(context, 'Invalid email!', AppColors.dangerRed);
      return false;
    }
    if (task.sendMethod != 'No Auth (Custom SMTP)' &&
        task.appPassCtrl.text.trim().isEmpty) {
      _showSnack(
        context,
        'Enter App Password / SMTP Password!',
        AppColors.dangerRed,
      );
      return false;
    }
    if (task.smtpHostCtrl.text.trim().isEmpty) {
      _showSnack(context, 'Enter SMTP Host!', AppColors.dangerRed);
      return false;
    }
    if (task.subjectCtrl.text.trim().isEmpty && task.subjectsList.isEmpty) {
      _showSnack(context, 'Enter Email Subject!', AppColors.dangerRed);
      return false;
    }
    if (task.bodyCtrl.text.trim().isEmpty &&
        task.bodyList.isEmpty &&
        task.descType != 'HTML File') {
      _showSnack(context, 'Write email body!', AppColors.dangerRed);
      return false;
    }
    return true;
  }

  // ================================================================
  //  SMTP SERVER BUILDER (Fixed Gmail Prefix Conflict)
  // ================================================================
  SmtpServer _buildSmtpServer(_MailTask task) {
    final host = task.smtpHostCtrl.text.trim();
    final port = int.tryParse(task.smtpPortCtrl.text.trim()) ?? 587;
    final user = task.emailCtrl.text.trim();
    final pass = task.appPassCtrl.text.trim();

    // Fix: Using explicit SmtpServer instead of gmail() helper
    if (host.contains('gmail')) {
      return SmtpServer(
        'smtp.gmail.com',
        port: 465,
        username: user,
        password: pass,
        ssl: true,
      );
    }
    if (host.contains('yahoo')) return yahoo(user, pass);
    if (host.contains('hotmail') ||
        host.contains('outlook') ||
        host.contains('live')) {
      return hotmail(user, pass);
    }
    return SmtpServer(
      host,
      port: port,
      username: user.isNotEmpty ? user : null,
      password: pass.isNotEmpty ? pass : null,
      ssl: port == 465,
      allowInsecure: port == 25 || pass.isEmpty,
    );
  }

  // ================================================================
  //  SMTP TEST CONNECTION
  // ================================================================
  Future<void> _testSmtpConnection(_MailTask task) async {
    if (!_validateSmtp(task)) return;
    setState(() {
      _smtpTesting = true;
      _smtpTestResult = 'Testing...';
    });
    try {
      final server = _buildSmtpServer(task);
      final testMsg = Message()
        ..from = Address(task.emailCtrl.text.trim(), 'Test')
        ..recipients.add(task.emailCtrl.text.trim())
        ..subject = 'SMTP Test — INNOVEXA63'
        ..text = 'SMTP connection test successful!';
      final conn = PersistentConnection(server);
      await conn.send(testMsg);
      await conn.close();
      setState(() => _smtpTestResult = '✓ CONNECTED');
      _showSnack(
        context,
        '✓ SMTP Connection Successful!',
        AppColors.successGreen,
      );
    } catch (e) {
      setState(() => _smtpTestResult = '✗ FAILED');
      _showSnack(context, 'SMTP Error: $e', AppColors.dangerRed);
    } finally {
      setState(() => _smtpTesting = false);
    }
  }

  // ================================================================
  //  REAL GOOGLE API JSON SEND (100% Authentic API Call)
  // ================================================================
  Future<bool> _sendViaGoogleJson({
    required _MailTask task,
    required String toEmail,
    required String toName,
    required String subject,
    required String body,
    required String fromDisplay,
  }) async {
    try {
      // ১. JSON ফাইল রিড এবং রিয়েল অথেনটিকেশন
      final jsonStr = await File(task.googleJsonPath).readAsString();
      final credentials = auth.ServiceAccountCredentials.fromJson(jsonStr);
      final client = await auth.clientViaServiceAccount(credentials, [
        gmail.GmailApi.mailGoogleComScope,
      ]);
      final gmailApi = gmail.GmailApi(client);

      // ২. ইমেইল ফরম্যাট তৈরি (Base64 Encode)
      String rawEmail =
          "From: $fromDisplay <${task.emailCtrl.text.trim()}>\n"
          "To: $toEmail\n"
          "Subject: $subject\n"
          "Content-Type: text/html; charset=utf-8\n\n"
          "$body";

      final message = gmail.Message()
        ..raw = base64UrlEncode(utf8.encode(rawEmail));

      // ৩. Google সার্ভার দিয়ে সরাসরি মেইল ফায়ার করা
      await gmailApi.users.messages.send(message, 'me');

      client.close();
      return true; // মেইল সফলভাবে গেলে Sent ✓ দেখাবে
    } catch (e) {
      debugPrint('Google API Error: $e');
      return false; // ফেইল করলে বা বাউন্স খেলে Failed ✗ দেখাবে
    }
  }

  // ================================================================
  //  SEND ONE EMAIL (SMTP)
  // ================================================================
  Future<bool> _sendOneEmail({
    required _MailTask task,
    required String toEmail,
    required String toName,
    required String subject,
    required String body,
    required String fromDisplay,
  }) async {
    if (task.sendMethod == 'Google API JSON') {
      return _sendViaGoogleJson(
        task: task,
        toEmail: toEmail,
        toName: toName,
        subject: subject,
        body: body,
        fromDisplay: fromDisplay,
      );
    }
    try {
      final server = _buildSmtpServer(task);
      final msg = Message()
        ..from = Address(
          task.emailCtrl.text.trim(),
          fromDisplay.isNotEmpty ? fromDisplay : task.emailCtrl.text.trim(),
        )
        ..recipients.add(Address(toEmail, toName))
        ..subject = subject;

      // Load HTML file body
      String finalBody = body;
      if (task.descType == 'HTML File' && task.bodyCtrl.text.isNotEmpty) {
        try {
          finalBody = await File(task.bodyCtrl.text).readAsString();
        } catch (_) {
          finalBody = body;
        }
      }

      if (task.descType == 'HTML Code' || task.descType == 'HTML File') {
        msg.html = finalBody;
        msg.text = finalBody.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      } else {
        msg.text = finalBody;
      }

      // লিস্টে থাকা সব ফাইল একে একে মেইলের সাথে যুক্ত হবে
      if (task.attachmentPaths.isNotEmpty) {
        for (String path in task.attachmentPaths) {
          if (File(path).existsSync()) {
            msg.attachments.add(FileAttachment(File(path)));
          }
        }
      }
      if (task.headers['Priority'] ?? false) {
        msg.headers['X-Priority'] = '1';
        msg.headers['X-MSMail-Priority'] = 'High';
      }
      if (task.headers['HTML'] ?? true) msg.headers['MIME-Version'] = '1.0';

      final conn = PersistentConnection(server);
      await conn.send(msg);
      await conn.close();
      return true;
    } catch (e) {
      debugPrint('Send error for $toEmail: $e');
      return false;
    }
  }

  // ================================================================
  //  MAIN SEND LOOP
  // ================================================================
  Future<void> _startSending() async {
    final task = _tasks[_activeTask];
    if (task.recipientList.isEmpty) {
      _showSnack(
        context,
        'No recipients! Load CSV/Excel.',
        AppColors.dangerRed,
      );
      return;
    }
    if (!_validateSmtp(task)) return;

    setState(() {
      _isSending = true;
      _isPaused = false;
      _totalSent = 0;
      _totalFailed = 0;
      _totalPending = task.recipientList.length;
      _sentFromCurrentSmtp = 0;
      if (!_saveLogs) _logs.clear();
    });
    _showSnack(
      context,
      '▶ Sending started — ${task.recipientList.length} emails queued',
      AppColors.successGreen,
    );

    for (int i = 0; i < task.recipientList.length; i++) {
      if (!_isSending) break;
      while (_isPaused && _isSending)
        await Future.delayed(const Duration(milliseconds: 300));
      if (!_isSending) break;

      if (_maxSendPerSmtp > 0 && _sentFromCurrentSmtp >= _maxSendPerSmtp) {
        setState(() => _isSending = false);
        _showSnack(
          context,
          '⚡ Auto-stopped: SMTP limit $_maxSendPerSmtp reached!',
          AppColors.warning,
        );
        break;
      }

      final recipient = task.recipientList[i];
      final rData = i < task.recipientData.length
          ? task.recipientData[i]
          : <String, dynamic>{
              'email': recipient,
              'name': '',
              'amount': '',
              'address': '',
            };

      String usedIp = 'Direct';
      if (_proxyHost.isNotEmpty)
        usedIp = 'Proxy: $_proxyHost';
      else if (_ipRotationEnabled && _ipList.isNotEmpty)
        usedIp = i % _ipRotateEvery == 0 ? _getNextIp() : _currentIp;

      // Spoof name: pool or single
      String currentSpoof = task.spoofNameCtrl.text.trim().isNotEmpty
          ? task.spoofNameCtrl.text.trim()
          : task.emailCtrl.text.trim();
      if (task.spoofMultiple && task.spoofNamesList.isNotEmpty)
        currentSpoof =
            task.spoofNamesList[Random().nextInt(task.spoofNamesList.length)];

      // Subject: pool or single
      String currentSubject = task.subjectCtrl.text;
      if (task.subjectMultiple && task.subjectsList.isNotEmpty)
        currentSubject =
            task.subjectsList[Random().nextInt(task.subjectsList.length)];

      // Body: pool or single
      String currentBody = task.bodyCtrl.text;
      if (task.bodyMultiple && task.bodyList.isNotEmpty)
        currentBody = task.bodyList[Random().nextInt(task.bodyList.length)];

      // Tag replacement
      final name = rData['name'] ?? '';
      final amount = rData['amount'] ?? '';
      final address = rData['address'] ?? '';
      final now = DateTime.now();
      String rep(String s) => s
          .replaceAll('{name}', name)
          .replaceAll('{email}', recipient)
          .replaceAll('{amount}', amount)
          .replaceAll('{address}', address)
          .replaceAll('{date}', '${now.day}/${now.month}/${now.year}')
          .replaceAll(
            '{time}',
            '${now.hour}:${now.minute.toString().padLeft(2, '0')}',
          )
          .replaceAll('{tracking}', _randomString(10))
          .replaceAll('{random}', _randomString(6));

      currentSubject = rep(currentSubject);
      currentBody = rep(currentBody);

      // Delay
      if (i > 0 && task.mailDelay > 0) {
        for (double elapsed = 0; elapsed < task.mailDelay; elapsed += 0.3) {
          if (!_isSending) break;
          while (_isPaused && _isSending)
            await Future.delayed(const Duration(milliseconds: 300));
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      if (!_isSending) break;

      final success = await _sendOneEmail(
        task: task,
        toEmail: recipient,
        toName: name,
        subject: currentSubject,
        body: currentBody,
        fromDisplay: currentSpoof,
      );

      final logEntry = _LogEntry(
        sNo: _totalSent + _totalFailed + 1,
        sender: currentSpoof,
        recipient: recipient,
        mailId: currentSubject,
        status: success ? 'Sent ✓' : 'Failed ✗',
        ip: usedIp,
        timestamp: DateTime.now(),
        success: success,
        bodySnippet: currentBody.length > 40
            ? currentBody.substring(0, 40) + '...'
            : currentBody,
        attachmentName: task.attachmentNames.join(', '),
      );

      setState(() {
        if (success) {
          _totalSent++;
          _sentFromCurrentSmtp++;
        } else
          _totalFailed++;
        _totalPending--;
        _logs.insert(0, logEntry);
      });

      if (_saveLogs) {
        try {
          await FirebaseFirestore.instance.collection('send_logs').add({
            'userId': _resolvedUserId,
            'sNo': logEntry.sNo,
            'sender': logEntry.sender,
            'recipient': logEntry.recipient,
            'subject': logEntry.mailId,
            'status': logEntry.status,
            'ip': logEntry.ip,
            'timestamp': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
    }

    if (_isSending) {
      setState(() => _isSending = false);
      _showSnack(
        context,
        '✓ Complete! Sent: $_totalSent | Failed: $_totalFailed',
        AppColors.successGreen,
      );
    }
  }

  void _stopSending() {
    setState(() {
      _isSending = false;
      _isPaused = false;
    });
    _showSnack(
      context,
      '■ Stopped. Sent: $_totalSent | Failed: $_totalFailed',
      AppColors.dangerRed,
    );
  }

  void _pauseResumeSending() {
    setState(() => _isPaused = !_isPaused);
    _showSnack(
      context,
      _isPaused ? '⏸ Paused...' : '▶ Resumed!',
      _isPaused ? AppColors.warning : AppColors.successGreen,
    );
  }

  void _clearAll() {
    final task = _tasks[_activeTask];
    setState(() {
      task.bodyCtrl.clear();
      task.spoofNameCtrl.clear();
      task.subjectCtrl.clear();
      task.recipientList.clear();
      task.recipientData.clear();
      task.spoofNamesList.clear();
      task.subjectsList.clear();
      task.bodyList.clear();
      task.attachmentPaths.clear();
      task.attachmentNames.clear();
      task.spamScore = '—';
      _logs.clear();
      _totalSent = 0;
      _totalFailed = 0;
      _totalPending = 0;
      _sentFromCurrentSmtp = 0;
      _smtpTestResult = '';
    });
    _showSnack(context, '✓ All cleared!', AppColors.textMuted);
  }

  String _randomString(int len) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(
      len,
      (_) => chars[Random().nextInt(chars.length)],
    ).join();
  }

  // ================================================================
  //  EXCEL EXPORT — Sent & Failed sheets
  // ================================================================
  Future<void> _exportExcel() async {
    if (_logs.isEmpty) {
      _showSnack(context, 'No logs to export!', AppColors.warning);
      return;
    }

    try {
      final xl = Excel.createExcel();
      final sent = xl['Sent'];
      final failed = xl['Failed'];
      final all = xl['All'];

      // Headers
      final headers = [
        'S.No',
        'Email',
        'Sender',
        'Subject',
        'IP',
        'Status',
        'Time',
      ];
      for (final sheet in [sent, failed, all]) {
        for (int c = 0; c < headers.length; c++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0))
              .value = TextCellValue(
            headers[c],
          );
        }
      }

      int sentRow = 1, failedRow = 1, allRow = 1;
      for (final log in _logs.reversed) {
        final timeStr =
            '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';
        final rowData = [
          log.sNo.toString(),
          log.recipient,
          log.sender,
          log.mailId,
          log.ip,
          log.status,
          timeStr,
        ];

        void writeRow(Sheet sh, int r) {
          for (int c = 0; c < rowData.length; c++) {
            sh
                .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r))
                .value = TextCellValue(
              rowData[c],
            );
          }
        }

        writeRow(all, allRow++);
        if (log.success)
          writeRow(sent, sentRow++);
        else
          writeRow(failed, failedRow++);
      }

      // Remove default empty sheet
      xl.delete('Sheet1');

      // Save to temp directory
      final bytes = xl.encode()!;
      final now = DateTime.now();
      final taskName = 'Task${_activeTask + 1}';
      final filename =
          'INNOVEXA63_${taskName}_${now.day}-${now.month}-${now.year}_${now.hour}${now.minute}.xlsx';
      final dir = await _getDownloadsPath();
      final file = File('$dir/$filename');
      await file.writeAsBytes(bytes);
      _showSnack(
        context,
        '✓ Exported: $filename\nLocation: $dir',
        AppColors.successGreen,
      );
    } catch (e) {
      _showSnack(context, 'Export error: $e', AppColors.dangerRed);
    }
  }

  Future<String> _getDownloadsPath() async {
    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'] ?? 'C:/Users/Public';
      return '$home/Downloads';
    }
    if (Platform.isMacOS) return '${Platform.environment['HOME']}/Downloads';
    return '/tmp';
  }

  // ================================================================
  //  RECIPIENT UPLOAD MODAL
  // ================================================================
  void _showRecipientUploadModal(int taskIndex) {
    final pasteCtrl = TextEditingController();
    bool isLoading = false;
    int previewCount = 0;
    String loadedFileName = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 680,
            padding: const EdgeInsets.all(26),
            decoration: _modalDecoration(AppColors.primaryCyan),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalTitle(
                    Icons.upload_file_rounded,
                    'LOAD RECIPIENTS — Excel / CSV / Paste',
                    AppColors.primaryCyan,
                  ),

                  // Instructions
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryCyan.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📋  FORMAT GUIDE',
                          style: TextStyle(
                            color: AppColors.primaryCyan,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _fmtRow(
                          'Column A',
                          'Email',
                          'REQUIRED — must have @ and domain',
                          AppColors.dangerRed,
                        ),
                        _fmtRow(
                          'Column B',
                          'Name',
                          'Optional — auto-extracted from email if empty',
                          AppColors.warning,
                        ),
                        _fmtRow(
                          'Column C',
                          'Amount',
                          'Optional — use {amount} tag in body',
                          AppColors.textMuted,
                        ),
                        _fmtRow(
                          'Column D',
                          'Address',
                          'Optional — use {address} tag in body',
                          AppColors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'john@gmail.com, John Doe, 5000, New York\nalex@yahoo.com,,2000,Texas   ← name auto "Alex"\nsara.smith@outlook.com         ← name auto "Sara Smith"',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 10,
                              fontFamily: 'Consolas',
                              height: 1.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _uploadBtn(
                          icon: Icons.grid_on_rounded,
                          label: 'Upload Excel (.xlsx / .xls)',
                          color: AppColors.warning,
                          onTap: () async {
                            setS(() => isLoading = true);
                            try {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['xlsx', 'xls'],
                                  );
                              if (result?.files.single.path != null) {
                                await _parseExcelOrCsv(
                                  result!.files.single.path!,
                                  _tasks[taskIndex],
                                );
                                setS(() {
                                  loadedFileName = result.files.single.name;
                                  previewCount =
                                      _tasks[taskIndex].recipientList.length;
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                              }
                            } catch (e) {
                              _showSnack(ctx, 'Error: $e', AppColors.dangerRed);
                            }
                            setS(() => isLoading = false);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _uploadBtn(
                          icon: Icons.table_chart_rounded,
                          label: 'Upload CSV / TXT',
                          color: AppColors.successGreen,
                          onTap: () async {
                            setS(() => isLoading = true);
                            try {
                              final result = await FilePicker.platform
                                  .pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['csv', 'txt'],
                                  );
                              if (result?.files.single.path != null) {
                                await _parseExcelOrCsv(
                                  result!.files.single.path!,
                                  _tasks[taskIndex],
                                );
                                setS(() {
                                  loadedFileName = result.files.single.name;
                                  previewCount =
                                      _tasks[taskIndex].recipientList.length;
                                });
                                if (ctx.mounted) Navigator.pop(ctx);
                              }
                            } catch (e) {
                              _showSnack(ctx, 'Error: $e', AppColors.dangerRed);
                            }
                            setS(() => isLoading = false);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR PASTE CSV TEXT DIRECTLY',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: pasteCtrl,
                    maxLines: 8,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Consolas',
                    ),
                    onChanged: (v) => setS(() {
                      previewCount = v
                          .trim()
                          .split('\n')
                          .where((l) => l.isNotEmpty)
                          .length;
                    }),
                    decoration: InputDecoration(
                      hintText:
                          'john@gmail.com, John, 5000, NY\nalex@yahoo.com',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withOpacity(0.4),
                        fontSize: 11,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: AppColors.border.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  if (previewCount > 0 || loadedFileName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.list_alt_rounded,
                          color: AppColors.primaryCyan,
                          size: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loadedFileName.isNotEmpty
                              ? '$previewCount emails from "$loadedFileName"'
                              : '$previewCount rows detected',
                          style: const TextStyle(
                            color: AppColors.primaryCyan,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
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
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryCyan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () {
                                if (pasteCtrl.text.trim().isEmpty) {
                                  _showSnack(
                                    ctx,
                                    'No data!',
                                    AppColors.dangerRed,
                                  );
                                  return;
                                }
                                _parseCsvContent(
                                  pasteCtrl.text,
                                  _tasks[taskIndex],
                                );
                                Navigator.pop(ctx);
                              },
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'PROCESS PASTED DATA',
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
      ),
    );
  }

  Widget _fmtRow(String col, String field, String note, Color noteColor) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 65,
              child: Text(
                col,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                  fontFamily: 'Consolas',
                ),
              ),
            ),
            SizedBox(
              width: 65,
              child: Text(
                field,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Text(
                note,
                style: TextStyle(color: noteColor, fontSize: 9),
              ),
            ),
          ],
        ),
      );

  Widget _uploadBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  );

  // ================================================================
  //  DATA PREVIEW MODAL
  // ================================================================
  void _showDataPreview(_MailTask task) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 720,
          height: 520,
          padding: const EdgeInsets.all(24),
          decoration: _modalDecoration(AppColors.primaryCyan),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modalTitle(
                Icons.table_view_rounded,
                'DATA PREVIEW  —  ${task.recipientData.length} records',
                AppColors.primaryCyan,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: AppColors.primaryCyan.withOpacity(0.08),
                child: const Row(
                  children: [
                    Expanded(flex: 3, child: _Th('EMAIL')),
                    Expanded(flex: 2, child: _Th('NAME')),
                    Expanded(flex: 2, child: _Th('AMOUNT')),
                    Expanded(flex: 2, child: _Th('ADDRESS')),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: task.recipientData.length,
                  itemBuilder: (context, i) {
                    final map = task.recipientData[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border.withOpacity(0.4),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              map['email'] ?? '',
                              style: const TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              map['name'] ?? '—',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              map['amount']?.isNotEmpty == true
                                  ? map['amount']
                                  : '—',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              map['address']?.isNotEmpty == true
                                  ? map['address']
                                  : '—',
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
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
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

  /// ================================================================
  //  MULTIPLE CSV / EXCEL MODAL (subjects, names, bodies)
  // ================================================================
  void _showGenericCsvModal(String title, ValueChanged<List<String>> onSaved) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 540,
          padding: const EdgeInsets.all(24),
          decoration: _modalDecoration(AppColors.secondaryPurple),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modalTitle(
                Icons.list_alt_rounded,
                'LOAD MULTIPLE $title',
                AppColors.secondaryPurple,
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondaryPurple.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.secondaryPurple.withOpacity(0.2),
                  ),
                ),
                child: const Text(
                  '💡 Instructions:\n• One item per line (Column A if Excel)\n• Items will be selected RANDOMLY for each email\n• Supports 100+ items (upload CSV/Excel for large lists)',
                  style: TextStyle(
                    color: AppColors.secondaryPurple,
                    fontSize: 10,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: textCtrl,
                maxLines: 10,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'Consolas',
                ),
                decoration: InputDecoration(
                  hintText: 'Item 1\nItem 2\nItem 3...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.file_upload, size: 14),
                    label: const Text('UPLOAD CSV/EXCEL'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      try {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['csv', 'txt', 'xlsx', 'xls'],
                        );
                        if (result?.files.single.path != null) {
                          final filePath = result!.files.single.path!;
                          final ext = filePath.split('.').last.toLowerCase();
                          String fileContent = '';

                          if (ext == 'xlsx' || ext == 'xls') {
                            // Excel ফাইল হলে রিড করে শুধু প্রথম কলামটা (Column A) নিবে
                            final bytes = await File(filePath).readAsBytes();
                            final xl = Excel.decodeBytes(bytes);
                            List<String> items = [];
                            for (final table in xl.tables.keys) {
                              final sheet = xl.tables[table]!;
                              for (int r = 0; r < sheet.maxRows; r++) {
                                final row = sheet.row(r);
                                if (row.isNotEmpty && row[0]?.value != null) {
                                  items.add(row[0]!.value.toString().trim());
                                }
                              }
                              break; // শুধু প্রথম শিট রিড করবে
                            }
                            fileContent = items.join('\n');
                          } else {
                            // CSV বা TXT হলে সরাসরি রিড করবে
                            fileContent = await File(filePath).readAsString();
                          }

                          textCtrl.text = fileContent;
                          _showSnack(
                            ctx,
                            '✓ File loaded successfully!',
                            AppColors.successGreen,
                          );
                        }
                      } catch (e) {
                        _showSnack(
                          ctx,
                          'Error reading file: $e',
                          AppColors.dangerRed,
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      final list = textCtrl.text
                          .split('\n')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      onSaved(list);
                      Navigator.pop(ctx);
                      _showSnack(
                        ctx,
                        '✓ Saved ${list.length} items!',
                        AppColors.successGreen,
                      );
                    },
                    child: const Text(
                      'SAVE LIST',
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

  // ================================================================
  //  IP / PROXY MODAL
  // ================================================================
  void _showIpRotationModal() {
    final phCtrl = TextEditingController(text: _proxyHost);
    final ppCtrl = TextEditingController(text: _proxyPort);
    final puCtrl = TextEditingController(text: _proxyUser);
    final pwCtrl = TextEditingController(text: _proxyPass);

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 600,
            padding: const EdgeInsets.all(24),
            decoration: _modalDecoration(AppColors.secondaryPurple),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalTitle(
                    Icons.swap_horiz_rounded,
                    'SERVER, IP & PROXY MANAGER',
                    AppColors.secondaryPurple,
                  ),
                  _inboxSection(
                    'IP & DOMAIN ROTATION',
                    AppColors.secondaryPurple,
                    [
                      Row(
                        children: [
                          const Text(
                            'Enable Rotation:',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          Switch(
                            value: _ipRotationEnabled,
                            activeColor: AppColors.successGreen,
                            onChanged: (v) => setS(
                              () => setState(() => _ipRotationEnabled = v),
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Mode:',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          Radio<bool>(
                            value: true,
                            groupValue: _randomIpRotation,
                            activeColor: AppColors.primaryCyan,
                            onChanged: (v) => setS(
                              () => setState(() => _randomIpRotation = v!),
                            ),
                          ),
                          const Text(
                            'Random',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                          Radio<bool>(
                            value: false,
                            groupValue: _randomIpRotation,
                            activeColor: AppColors.primaryCyan,
                            onChanged: (v) => setS(
                              () => setState(() => _randomIpRotation = v!),
                            ),
                          ),
                          const Text(
                            'Sequential',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Text(
                            'Rotate every:',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setS(
                              () => setState(() {
                                if (_ipRotateEvery > 1) _ipRotateEvery--;
                              }),
                            ),
                            icon: const Icon(
                              Icons.remove,
                              color: AppColors.textMuted,
                              size: 16,
                            ),
                          ),
                          Text(
                            '$_ipRotateEvery emails',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setS(() => setState(() => _ipRotateEvery++)),
                            icon: const Icon(
                              Icons.add,
                              color: AppColors.textMuted,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _ipInputCtrl,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'Consolas',
                              ),
                              decoration: InputDecoration(
                                hintText: 'Add IPs/Domains (one per line)',
                                hintStyle: TextStyle(
                                  color: AppColors.textMuted.withOpacity(0.5),
                                  fontSize: 10,
                                ),
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryPurple,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              _addIp(_ipInputCtrl.text);
                              setS(() {});
                            },
                            child: const Text(
                              'ADD',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (_ipList.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: _ipList.length,
                            itemBuilder: (_, i) => ListTile(
                              dense: true,
                              leading: Icon(
                                Icons.circle,
                                color: i == _currentIpIndex
                                    ? AppColors.successGreen
                                    : AppColors.textMuted,
                                size: 8,
                              ),
                              title: Text(
                                _ipList[i],
                                style: TextStyle(
                                  color: i == _currentIpIndex
                                      ? AppColors.successGreen
                                      : AppColors.textMain,
                                  fontSize: 11,
                                  fontFamily: 'Consolas',
                                ),
                              ),
                              trailing: IconButton(
                                onPressed: () => setS(
                                  () => setState(() {
                                    _ipList.removeAt(i);
                                    if (_currentIpIndex >= _ipList.length)
                                      _currentIpIndex = 0;
                                  }),
                                ),
                                icon: const Icon(
                                  Icons.delete,
                                  color: AppColors.dangerRed,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _inboxSection(
                    'GLOBAL PROXY SETUP (OPTIONAL)',
                    AppColors.warning,
                    [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _labelInput(
                              'Proxy Host',
                              phCtrl,
                              '127.0.0.1',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: _labelInput('Port', ppCtrl, '8080'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _labelInput('Username', puCtrl, 'user'),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _labelInput(
                              'Password',
                              pwCtrl,
                              '••••••',
                              obscure: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _proxyHost = phCtrl.text;
                          _proxyPort = ppCtrl.text;
                          _proxyUser = puCtrl.text;
                          _proxyPass = pwCtrl.text;
                        });
                        Navigator.pop(ctx);
                        _showSnack(
                          context,
                          'Server & Proxy settings saved!',
                          AppColors.successGreen,
                        );
                      },
                      child: const Text(
                        'SAVE & CLOSE',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  //  INBOX TOOLS MODAL
  // ================================================================
  void _showInboxToolsModal() {
    final t = _tasks[_activeTask];
    bool macSpoof = t.macSpoofEnabled;
    bool domainMix = t.domainMixEnabled;
    bool pcBypass = t.pcProtectionBypass;
    String macAddr = t.macAddress;
    final domainCtrl = TextEditingController(text: t.mixedDomains.join(', '));

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 560,
            padding: const EdgeInsets.all(24),
            decoration: _modalDecoration(AppColors.successGreen),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalTitle(
                    Icons.inbox_rounded,
                    'INBOX DELIVERY & ANTI-SPAM TOOLS',
                    AppColors.successGreen,
                  ),
                  _inboxSection('ANTI-SPAM EVASION', AppColors.dangerRed, [
                    Row(
                      children: [
                        const Text(
                          'Bypass Defender/Antivirus:',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: pcBypass,
                          activeColor: AppColors.dangerRed,
                          onChanged: (v) => setS(() => pcBypass = v),
                        ),
                      ],
                    ),
                    if (pcBypass)
                      const Text(
                        '⚠️ Obfuscating payloads to bypass firewall.',
                        style: TextStyle(
                          color: AppColors.dangerRed,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  _inboxSection(
                    'DOMAIN MIX (Multi-domain sending)',
                    AppColors.primaryCyan,
                    [
                      Row(
                        children: [
                          const Text(
                            'Enable Domain Mix:',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: domainMix,
                            activeColor: AppColors.primaryCyan,
                            onChanged: (v) => setS(() => domainMix = v),
                          ),
                        ],
                      ),
                      if (domainMix) ...[
                        const SizedBox(height: 8),
                        TextField(
                          controller: domainCtrl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                          decoration: InputDecoration(
                            hintText: 'gmail.com, yahoo.com, outlook.com',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted.withOpacity(0.5),
                              fontSize: 10,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  _inboxSection('MAC ADDRESS SPOOFER', AppColors.warning, [
                    Row(
                      children: [
                        const Text(
                          'Enable MAC Spoofing:',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: macSpoof,
                          activeColor: AppColors.warning,
                          onChanged: (v) => setS(() => macSpoof = v),
                        ),
                      ],
                    ),
                    if (macSpoof) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                macAddr,
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontSize: 12,
                                  fontFamily: 'Consolas',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () =>
                                setS(() => macAddr = _generateMacAddress()),
                            child: const Text(
                              'GENERATE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ]),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          t.macSpoofEnabled = macSpoof;
                          t.domainMixEnabled = domainMix;
                          t.pcProtectionBypass = pcBypass;
                          t.macAddress = macAddr;
                          t.mixedDomains = domainCtrl.text
                              .split(',')
                              .map((d) => d.trim())
                              .where((d) => d.isNotEmpty)
                              .toList();
                        });
                        Navigator.pop(ctx);
                        _showSnack(
                          context,
                          '✓ Inbox & Anti-Spam tools updated!',
                          AppColors.successGreen,
                        );
                      },
                      child: const Text(
                        'APPLY SETTINGS',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _generateMacAddress() {
    final rand = Random();
    return List.generate(
      6,
      (_) => rand.nextInt(256).toRadixString(16).padLeft(2, '0').toUpperCase(),
    ).join(':');
  }

  Future<void> _realFileUpload(TextEditingController ctrl, String ext) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [ext, 'txt'],
      );
      if (result != null) {
        setState(() => ctrl.text = result.files.single.path ?? '');
        _showSnack(context, '✓ File selected!', AppColors.successGreen);
      }
    } catch (e) {
      _showSnack(context, 'Error: $e', AppColors.dangerRed);
    }
  }

  Future<void> _pickAttachment(_MailTask task) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple:
            true, // এখানে true করে দেওয়া হলো যেন একসাথে অনেক ফাইল নেওয়া যায়
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
          'html',
          'doc',
          'docx',
          'xlsx',
          'csv',
          'txt',
          'zip',
        ],
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          // সব ফাইলের পাথ এবং নাম লিস্টে সেভ হবে
          task.attachmentPaths = result.paths.whereType<String>().toList();
          task.attachmentNames = result.files.map((f) => f.name).toList();
        });
        _showSnack(
          context,
          '✓ ${task.attachmentNames.length} Attachments Selected!',
          AppColors.successGreen,
        );
      }
    } catch (e) {
      _showSnack(context, 'Error picking files: $e', AppColors.dangerRed);
    }
  }

  Future<void> _pickGoogleJson(_MailTask task) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          task.googleJsonPath = result.files.single.path!;
          task.googleJsonName = result.files.single.name;
        });
        _showSnack(
          context,
          '✓ Credentials loaded: ${result.files.single.name}',
          AppColors.successGreen,
        );
      }
    } catch (e) {
      _showSnack(context, 'Error: $e', AppColors.dangerRed);
    }
  }

  // ================================================================
  //  SPAM CHECKER
  // ================================================================
  void _showSpamChecker(_MailTask task) {
    final body = task.bodyCtrl.text;
    final subject = task.subjectCtrl.text;
    int score = 0;
    final warnings = <String>[];
    const spamWords = [
      'free',
      'winner',
      'prize',
      'click now',
      'limited offer',
      'act now',
      'urgent',
      'guaranteed',
      'cash',
      '100%',
    ];
    for (final w in spamWords) {
      if (body.toLowerCase().contains(w) || subject.toLowerCase().contains(w)) {
        score += 2;
        warnings.add('⚠️ Spam word: "$w"');
      }
    }
    if (subject.toUpperCase() == subject && subject.isNotEmpty) {
      score += 3;
      warnings.add('⚠️ Subject is ALL CAPS');
    }
    if (body.contains('!!!')) {
      score += 2;
      warnings.add('⚠️ Excessive exclamation marks');
    }
    if (body.toLowerCase().contains('click here')) {
      score += 1;
      warnings.add('⚠️ "click here" detected');
    }
    if (body.toLowerCase().contains('unsubscribe')) {
      score -= 2;
      warnings.add('✅ Unsubscribe link found');
    }
    if (task.headers['HTML'] ?? false) {
      score -= 1;
      warnings.add('✅ HTML headers enabled');
    }
    if (task.headers['Priority'] ?? false) {
      score += 1;
      warnings.add('⚠️ Priority header increases risk');
    }
    if (body.contains('{name}')) {
      score -= 1;
      warnings.add('✅ Personalization {name} reduces score');
    }
    if (score < 0) score = 0;
    setState(() => task.spamScore = '$score/10');
    final col = score <= 3
        ? AppColors.successGreen
        : score <= 6
        ? AppColors.warning
        : AppColors.dangerRed;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: _modalDecoration(col),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modalTitle(Icons.shield_rounded, 'SPAM ANALYSIS', col),
              Row(
                children: [
                  const Text(
                    'Score: ',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  Text(
                    '$score/10',
                    style: TextStyle(
                      color: col,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    score <= 3
                        ? '🟢 LOW RISK'
                        : score <= 6
                        ? '🟡 MODERATE'
                        : '🔴 HIGH RISK',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: col,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...warnings.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    w,
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 11,
                    ),
                  ),
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

  // ================================================================
  //  TAG GUIDE MODAL (Fixed Overflow Issue)
  // ================================================================
  void _showTagGuide() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 560,
          // BoxConstraints অ্যাড করা হয়েছে যেন স্ক্রিনের বাইরে না যায়
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
          decoration: _modalDecoration(AppColors.secondaryPurple),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modalTitle(
                Icons.help_outline_rounded,
                'DYNAMIC TAG GUIDE',
                AppColors.secondaryPurple,
              ),
              // Flexible এবং SingleChildScrollView অ্যাড করা হয়েছে স্ক্রল করার জন্য
              Flexible(
                child: SingleChildScrollView(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _tagGuideRow(
                          '{name}',
                          'Recipient name',
                          'Auto-extracted from email if CSV col B empty',
                          AppColors.primaryCyan,
                        ),
                        _tagGuideRow(
                          '{email}',
                          'Recipient email',
                          'Full email from CSV column A',
                          AppColors.primaryCyan,
                        ),
                        _tagGuideRow(
                          '{amount}',
                          'Amount col C',
                          'Ex: 5000, \$99.99',
                          AppColors.warning,
                        ),
                        _tagGuideRow(
                          '{address}',
                          'Address col D',
                          'Ex: New York, TX',
                          AppColors.warning,
                        ),
                        _tagGuideRow(
                          '{date}',
                          'Today\'s date',
                          'Format: DD/MM/YYYY',
                          AppColors.successGreen,
                        ),
                        _tagGuideRow(
                          '{time}',
                          'Current time',
                          'Format: HH:MM',
                          AppColors.successGreen,
                        ),
                        _tagGuideRow(
                          '{tracking}',
                          'Random tracking ID',
                          '10-char — changes per recipient',
                          AppColors.textMuted,
                        ),
                        _tagGuideRow(
                          '{random}',
                          'Random string',
                          '6-char — randomized per email',
                          AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondaryPurple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.secondaryPurple.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  '💡 TIP: Use {name} in subject line for better inbox delivery.\n   "Dear {name}, Your order #{tracking} is ready!"\n   "Invoice #{random} from {date} — Amount: {amount}"',
                  style: TextStyle(
                    color: AppColors.secondaryPurple,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
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

  Widget _tagGuideRow(String tag, String title, String desc, Color color) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border.withOpacity(0.4)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(
                tag,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontFamily: 'Consolas',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  // ================================================================
  //  SEND REPORT MODAL
  // ================================================================
  void _showSendReport() {
    if (_logs.isEmpty) {
      _showSnack(context, 'No logs yet!', AppColors.warning);
      return;
    }
    final sent = _logs.where((l) => l.success).toList();
    final failed = _logs.where((l) => !l.success).toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 760,
          height: 580,
          padding: const EdgeInsets.all(24),
          decoration: _modalDecoration(AppColors.successGreen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _modalTitle(
                Icons.summarize_rounded,
                'SEND REPORT SHEET',
                AppColors.successGreen,
              ),
              Row(
                children: [
                  _reportStat(
                    'Total',
                    '${_logs.length}',
                    AppColors.primaryCyan,
                  ),
                  const SizedBox(width: 12),
                  _reportStat(
                    'Sent ✓',
                    '${sent.length}',
                    AppColors.successGreen,
                  ),
                  const SizedBox(width: 12),
                  _reportStat(
                    'Failed ✗',
                    '${failed.length}',
                    AppColors.dangerRed,
                  ),
                  const SizedBox(width: 12),
                  _reportStat(
                    'Success Rate',
                    _logs.isNotEmpty
                        ? '${(sent.length / _logs.length * 100).toStringAsFixed(1)}%'
                        : '0%',
                    AppColors.warning,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 14),
                    label: const Text(
                      'Export Excel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _exportExcel();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                color: AppColors.primaryCyan.withOpacity(0.08),
                child: const Row(
                  children: [
                    Expanded(flex: 1, child: _Th('#')),
                    Expanded(flex: 3, child: _Th('EMAIL')),
                    Expanded(flex: 2, child: _Th('SENDER')),
                    Expanded(flex: 3, child: _Th('SUBJECT')),
                    Expanded(flex: 1, child: _Th('STATUS')),
                    Expanded(flex: 2, child: _Th('TIME')),
                    Expanded(flex: 2, child: _Th('IP')),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, i) {
                    final log = _logs[i];
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: log.success
                            ? Colors.transparent
                            : AppColors.dangerRed.withOpacity(0.05),
                        border: Border(
                          bottom: BorderSide(
                            color: AppColors.border.withOpacity(0.4),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              '${log.sNo}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              log.recipient,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              log.sender,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              log.mailId,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              log.success ? '✓' : '✗',
                              style: TextStyle(
                                color: log.success
                                    ? AppColors.successGreen
                                    : AppColors.dangerRed,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              log.ip,
                              style: const TextStyle(
                                color: AppColors.secondaryPurple,
                                fontSize: 9,
                                fontFamily: 'Consolas',
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
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

  Widget _reportStat(String label, String value, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
        ),
      ],
    ),
  );

  // ================================================================
  //  TEMPLATE LOADER
  // ================================================================
  void _loadRandomTemplate(_MailTask task) {
    const templates = [
      'Dear {name},\n\nWe noticed a pending invoice of {amount} on your account ({email}).\n\nBilling address: {address}\n\nPlease verify your payment within 24 hours to avoid service interruption.\n\nCase ID: #{tracking}\nDate: {date}\n\nBest regards,\nBilling Team',
      'Hello {name},\n\nYour package #{tracking} has been shipped to {address}!\n\nExpected delivery: {date} at {time}\n\nPlease have your ID ready for delivery verification.\n\nThank you for your purchase!\nCustomer Support Team',
      'Dear {name},\n\nYou have an exclusive offer! Get {amount} bonus credits today.\n\nThis offer expires on {date}.\n\nYour Ref: #{random}\n\nDo not reply to this email.\n\nBest regards,\nMarketing Team',
      '<html><body style="font-family:Arial;background:#f5f5f5;padding:20px">\n<div style="max-width:600px;margin:auto;background:#fff;padding:30px;border-radius:8px">\n<h2 style="color:#1a73e8">Hello {name}!</h2>\n<p>Your account balance shows <strong>{amount}</strong>.</p>\n<p>Address on file: {address}</p>\n<p>Tracking: <code>{tracking}</code></p>\n<a href="#" style="background:#1a73e8;color:#fff;padding:10px 20px;text-decoration:none;border-radius:4px">Verify Account</a>\n</div></body></html>',
    ];
    setState(
      () => task.bodyCtrl.text = templates[Random().nextInt(templates.length)],
    );
    if (task.bodyCtrl.text.startsWith('<html>')) {
      setState(() => task.descType = 'HTML Code');
    }
  }

  // ================================================================
  //  MAIN BUILD
  // ================================================================
  @override
  Widget build(BuildContext context) {
    final task = _tasks[_activeTask];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          _buildLicenseBanner(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 300, child: _buildLeftPanel(task)),
                Expanded(
                  child: Column(
                    children: [
                      _buildTaskTabs(),
                      Expanded(child: _buildCenterPanel(task)),
                    ],
                  ),
                ),
                SizedBox(width: 240, child: _buildRightPanel(task)),
              ],
            ),
          ),
          _buildLogTable(),
        ],
      ),
    );
  }

  // ── TOP BAR ──
  Widget _buildTopBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          bottom: BorderSide(color: AppColors.primaryCyan.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'INNOVEXA',
                  style: TextStyle(
                    color: AppColors.primaryCyan,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                TextSpan(
                  text: '63',
                  style: TextStyle(
                    color: AppColors.secondaryPurple,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' MAILER ULTRA 7.0',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _statusPill('SECURE', AppColors.successGreen),
          if (_ipRotationEnabled || _proxyHost.isNotEmpty) ...[
            const SizedBox(width: 8),
            _statusPill(
              _proxyHost.isNotEmpty ? 'PROXY ACTIVE' : 'IP ROTATION',
              AppColors.secondaryPurple,
            ),
          ],
          if (_isSending) ...[
            const SizedBox(width: 8),
            _statusPill(
              _isPaused ? 'PAUSED' : 'SENDING...',
              _isPaused ? AppColors.warning : AppColors.successGreen,
            ),
          ],
          const Spacer(),
          _topIconBtn(
            Icons.dns_rounded,
            'Server & Proxies',
            AppColors.secondaryPurple,
            _showIpRotationModal,
          ),
          _topIconBtn(
            Icons.inbox_rounded,
            'Inbox & Anti-Spam',
            AppColors.warning,
            _showInboxToolsModal,
          ),
          if (_logs.isNotEmpty)
            _topIconBtn(
              Icons.summarize_rounded,
              'Send Report',
              AppColors.primaryCyan,
              _showSendReport,
            ),
          if (_logs.isNotEmpty)
            _topIconBtn(
              Icons.download_rounded,
              'Export Excel',
              AppColors.successGreen,
              _exportExcel,
            ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.power_settings_new, size: 12),
            label: const Text('Logout', style: TextStyle(fontSize: 10)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
            ),
            onPressed: () => _forceLogout('Logged out securely.'),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Row(
      children: [
        Icon(Icons.circle, color: color, size: 6),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _topIconBtn(
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onTap,
  ) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    ),
  );

  // ── TASK TABS ──
  Widget _buildTaskTabs() {
    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          ..._tasks.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            final active = i == _activeTask;
            return GestureDetector(
              onTap: () => setState(() => _activeTask = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primaryCyan.withOpacity(0.15)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: active ? AppColors.primaryCyan : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    if (_isSending && i == _activeTask)
                      const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          color: AppColors.successGreen,
                          strokeWidth: 1.5,
                        ),
                      )
                    else
                      Icon(
                        Icons.task_rounded,
                        color: active
                            ? AppColors.primaryCyan
                            : AppColors.textMuted,
                        size: 11,
                      ),
                    const SizedBox(width: 4),
                    Text(
                      'Task ${t.id}${_isSending && i == _activeTask ? (_isPaused ? ' (PAUSED)' : ' (ACTIVE)') : ''}',
                      style: TextStyle(
                        color: active
                            ? AppColors.primaryCyan
                            : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: active
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          _tabBtn(
            Icons.add_rounded,
            AppColors.successGreen,
            'New Task',
            _addTask,
          ),
          const SizedBox(width: 2),
          _tabBtn(
            Icons.remove_rounded,
            AppColors.dangerRed,
            'Delete Task',
            _deleteTask,
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(
    IconData icon,
    Color color,
    String tooltip,
    VoidCallback onTap,
  ) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Icon(icon, color: color, size: 12),
      ),
    ),
  );

  // ── LEFT PANEL ──
  Widget _buildLeftPanel(_MailTask task) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          _panelHeader('ACCOUNT & SMTP SETTINGS'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // ── SEND METHOD ───────────────────────────────────────────
                  _sectionBox('SEND METHOD', AppColors.primaryCyan, [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        _methodBtn('SMTP (Gmail)', task),
                        _methodBtn('Custom SMTP', task),
                        _methodBtn('No Auth (Custom SMTP)', task),
                        _methodBtn('Google API JSON', task),
                      ],
                    ),
                  ]),
                  const SizedBox(height: 6),

                  // ── CREDENTIALS (changes based on method) ─────────────────
                  if (task.sendMethod == 'Google API JSON') ...[
                    _sectionBox('GOOGLE API CREDENTIALS', AppColors.warning, [
                      _labelInput(
                        'Your Gmail Address',
                        task.emailCtrl,
                        'you@gmail.com',
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                task.googleJsonName.isNotEmpty
                                    ? '✓ ${task.googleJsonName}'
                                    : 'No JSON file selected',
                                style: TextStyle(
                                  color: task.googleJsonName.isNotEmpty
                                      ? AppColors.successGreen
                                      : AppColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.file_open_rounded, size: 10),
                            label: const Text(
                              'SELECT JSON',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(0, 28),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            onPressed: () => _pickGoogleJson(task),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.2),
                          ),
                        ),
                        child: const Text(
                          '💡 Google Cloud Console → APIs & Services → Credentials → Service Account → Download JSON',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 9,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // ── AUTHENTICATE & RESET BUTTONS ──
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.verified_user_rounded,
                                size: 12,
                              ),
                              label: const Text(
                                'AUTHENTICATE JSON',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.successGreen,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () => _authenticateGoogle(task),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 12),
                              label: const Text(
                                'RESET',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.dangerRed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  task.emailCtrl
                                      .clear(); // ইমেইল অ্যাড্রেস ক্লিয়ার করবে
                                  task.googleJsonPath =
                                      ''; // JSON ফাইল ক্লিয়ার করবে
                                  task.googleJsonName = '';
                                  task.googleApiToken =
                                      ''; // টোকেন ক্লিয়ার করবে
                                });
                                _showSnack(
                                  context,
                                  '✓ Credentials Cleared!',
                                  AppColors.warning,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ]),
                  ] else ...[
                    _sectionBox('SMTP CREDENTIALS', AppColors.primaryCyan, [
                      _labelInput(
                        'From Email (Sender)',
                        task.emailCtrl,
                        'sender@gmail.com',
                      ),
                      const SizedBox(height: 4),
                      if (task.sendMethod != 'No Auth (Custom SMTP)')
                        _labelInput(
                          'App Password / SMTP Password',
                          task.appPassCtrl,
                          '•••• •••• •••• ••••',
                          obscure: true,
                        ),
                      if (task.sendMethod == 'No Auth (Custom SMTP)')
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.textMuted.withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            'No-auth mode: password not required',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: _labelInput(
                              'SMTP Host',
                              task.smtpHostCtrl,
                              'smtp.gmail.com',
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 60,
                            child: _labelInput(
                              'Port',
                              task.smtpPortCtrl,
                              '587',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          _smtpPresetBtn(
                            'Gmail',
                            'smtp.gmail.com',
                            '587',
                            task,
                          ),
                          _smtpPresetBtn(
                            'Yahoo',
                            'smtp.mail.yahoo.com',
                            '587',
                            task,
                          ),
                          _smtpPresetBtn(
                            'Outlook',
                            'smtp.office365.com',
                            '587',
                            task,
                          ),
                          _smtpPresetBtn(
                            'Hotmail',
                            'smtp.live.com',
                            '587',
                            task,
                          ),
                          _smtpPresetBtn('Custom', '', '', task),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: _smtpTesting
                                  ? const SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.wifi_tethering_rounded,
                                      size: 12,
                                    ),
                              label: Text(
                                _smtpTesting ? 'Testing...' : 'TEST CONNECTION',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryCyan,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                              ),
                              onPressed: _smtpTesting
                                  ? null
                                  : () => _testSmtpConnection(task),
                            ),
                          ),
                          if (_smtpTestResult.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _smtpTestResult.contains('✓')
                                    ? AppColors.successGreen.withOpacity(0.15)
                                    : AppColors.dangerRed.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _smtpTestResult.contains('✓')
                                      ? AppColors.successGreen
                                      : AppColors.dangerRed,
                                ),
                              ),
                              child: Text(
                                _smtpTestResult,
                                style: TextStyle(
                                  color: _smtpTestResult.contains('✓')
                                      ? AppColors.successGreen
                                      : AppColors.dangerRed,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.warning.withOpacity(0.2),
                          ),
                        ),
                        child: const Text(
                          '💡 Gmail: Use App Password (not your main password)\nGoogle Account → Security → 2-Step → App Passwords',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 9,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 6),
                  _sectionBox('PER-SMTP SEND LIMIT', AppColors.warning, [
                    Row(
                      children: [
                        const Text(
                          'Limit:',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _maxSendPerSmtp.toDouble(),
                            min: 0,
                            max: 500,
                            divisions: 50,
                            activeColor: AppColors.warning,
                            onChanged: (v) =>
                                setState(() => _maxSendPerSmtp = v.toInt()),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            _maxSendPerSmtp == 0
                                ? '∞ Unlimited'
                                : '$_maxSendPerSmtp',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Auto-stops when limit reached',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 6),
                  _sectionBox(
                    'RECIPIENTS (Excel .xlsx / CSV / Paste)',
                    AppColors.successGreen,
                    [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Loaded: ${task.recipientList.length} emails',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                if (task.recipientList.isNotEmpty)
                                  Text(
                                    'First: ${task.recipientList.first}',
                                    style: const TextStyle(
                                      color: AppColors.primaryCyan,
                                      fontSize: 9,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (task.recipientList.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.visibility,
                                color: AppColors.warning,
                                size: 14,
                              ),
                              tooltip: 'Preview Data',
                              onPressed: () => _showDataPreview(task),
                            ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.upload_file_rounded,
                              size: 10,
                            ),
                            label: const Text(
                              'LOAD',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.successGreen,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(60, 26),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                            onPressed: () =>
                                _showRecipientUploadModal(_activeTask),
                          ),
                        ],
                      ),
                      if (task.recipientList.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: _totalPending > 0
                              ? 1 - (_totalPending / task.recipientList.length)
                              : (_totalSent + _totalFailed > 0 ? 1.0 : 0.0),
                          backgroundColor: AppColors.border,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.successGreen,
                          ),
                          minHeight: 3,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 6),
                  _sectionBox(
                    'ATTACHMENTS (PDF, Image, HTML, Doc...)',
                    AppColors.secondaryPurple,
                    [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.attachmentNames.isNotEmpty
                                  ? '📎 Selected: ${task.attachmentNames.length} files'
                                  : 'No attachment',
                              style: TextStyle(
                                color: task.attachmentNames.isNotEmpty
                                    ? AppColors.primaryCyan
                                    : AppColors.textMuted,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (task.attachmentNames.isNotEmpty)
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.dangerRed,
                                size: 14,
                              ),
                              onPressed: () => setState(() {
                                task.attachmentPaths.clear(); // সব ক্লিয়ার হবে
                                task.attachmentNames.clear();
                              }),
                            ),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.attach_file_rounded,
                              size: 10,
                            ),
                            label: const Text(
                              'ATTACH',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondaryPurple,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(70, 26),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                            onPressed: () => _pickAttachment(task),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),
                  _sectionBox('TIMING & EMAIL HEADERS', AppColors.warning, [
                    Row(
                      children: [
                        const Text(
                          'Delay(s):',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: task.mailDelay,
                            min: 0,
                            max: 30,
                            divisions: 30,
                            activeColor: AppColors.warning,
                            onChanged: (v) =>
                                setState(() => task.mailDelay = v),
                          ),
                        ),
                        Text(
                          '${task.mailDelay.toInt()}s',
                          style: const TextStyle(
                            color: AppColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Text(
                      'Wait between each email (0 = no delay)',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: task.headers.keys
                          .map(
                            (h) => _smallSwitch(
                              h,
                              task.headers[h]!,
                              (v) => setState(() => task.headers[h] = v),
                              AppColors.primaryCyan,
                            ),
                          )
                          .toList(),
                    ),
                  ]),

                  const SizedBox(height: 6),
                  _sectionBox('LOG SETTINGS', AppColors.secondaryPurple, [
                    Row(
                      children: [
                        const Text(
                          'Save logs to Firestore:',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _saveLogs,
                          activeColor: AppColors.secondaryPurple,
                          onChanged: (v) => setState(() => _saveLogs = v),
                        ),
                      ],
                    ),
                    if (_saveLogs)
                      const Text(
                        'All send activities saved to Firebase',
                        style: TextStyle(
                          color: AppColors.secondaryPurple,
                          fontSize: 9,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodBtn(String method, _MailTask task) {
    final active = task.sendMethod == method;
    Color color = AppColors.primaryCyan;
    if (method == 'Google API JSON') color = AppColors.warning;
    if (method == 'No Auth (Custom SMTP)') color = AppColors.textMuted;
    return GestureDetector(
      onTap: () => setState(() => task.sendMethod = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: active ? color : AppColors.border),
        ),
        child: Text(
          method,
          style: TextStyle(
            color: active ? color : AppColors.textMuted,
            fontSize: 9,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _smtpPresetBtn(
    String label,
    String host,
    String port,
    _MailTask task,
  ) {
    final isCustom = label == 'Custom';
    final isActive = !isCustom && task.smtpHostCtrl.text == host;
    return GestureDetector(
      onTap: () {
        if (!isCustom)
          setState(() {
            task.smtpHostCtrl.text = host;
            task.smtpPortCtrl.text = port;
          });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primaryCyan.withOpacity(0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive ? AppColors.primaryCyan : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryCyan : AppColors.textMuted,
            fontSize: 9,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ── CENTER PANEL ──
  Widget _buildCenterPanel(_MailTask task) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          _panelHeader('EMAIL COMPOSER & TEMPLATE ENGINE'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _inputWithCheckbox(
                          'Spoof Name / From Display Name',
                          task.spoofNameCtrl,
                          'e.g. PayPal Support',
                          'Multiple',
                          task.spoofMultiple,
                          (v) {
                            setState(() => task.spoofMultiple = v!);
                            if (v == true)
                              _showGenericCsvModal(
                                'Spoof Names',
                                (list) =>
                                    setState(() => task.spoofNamesList = list),
                              );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _inputWithCheckbox(
                          'Email Subject',
                          task.subjectCtrl,
                          'e.g. Your Invoice #{tracking}',
                          'Multiple',
                          task.subjectMultiple,
                          (v) {
                            setState(() => task.subjectMultiple = v!);
                            if (v == true)
                              _showGenericCsvModal(
                                'Subjects',
                                (list) =>
                                    setState(() => task.subjectsList = list),
                              );
                          },
                        ),
                      ),
                    ],
                  ),

                  if (task.subjectMultiple && task.subjectsList.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shuffle_rounded,
                            color: AppColors.successGreen,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.subjectsList.length} subjects — picked randomly per email',
                            style: const TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 9,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _radioMini(
                        ['Single Text', 'Multiple from CSV'],
                        task.bodyFormat,
                        (v) {
                          setState(() => task.bodyFormat = v!);
                          if (v == 'Multiple from CSV')
                            _showGenericCsvModal(
                              'Email Bodies',
                              (list) => setState(() => task.bodyList = list),
                            );
                        },
                      ),
                      const Spacer(),
                      const Text(
                        'Type:',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 9,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _radioMini(
                        ['Plain Text', 'HTML Code', 'HTML File'],
                        task.descType,
                        (v) => setState(() => task.descType = v!),
                      ),
                    ],
                  ),

                  if (task.descType == 'HTML Code') ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primaryCyan.withOpacity(0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primaryCyan,
                            size: 12,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'HTML mode: Write full HTML. Plain text fallback auto-generated.',
                              style: TextStyle(
                                color: AppColors.primaryCyan,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _composeBtn(
                        'Load Template',
                        AppColors.secondaryPurple,
                        () => _loadRandomTemplate(task),
                      ),
                      const SizedBox(width: 4),
                      _composeBtn(
                        'Check Spam',
                        AppColors.warning,
                        () => _showSpamChecker(task),
                      ),
                      const SizedBox(width: 4),
                      _composeBtn(
                        'Tag Guide 📖',
                        AppColors.primaryCyan,
                        _showTagGuide,
                      ),
                      if (task.spamScore != '—') ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.successGreen.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            'Spam: ${task.spamScore}',
                            style: const TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      if (_logs.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        _composeBtn(
                          '📊 Report (${_logs.length})',
                          AppColors.successGreen,
                          _showSendReport,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Body editor
                  if (task.descType == 'HTML File') ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.sidebar,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.html,
                              color: AppColors.primaryCyan,
                              size: 30,
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.file_upload, size: 12),
                              label: const Text(
                                'Browse HTML File',
                                style: TextStyle(fontSize: 10),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryCyan,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () =>
                                  _realFileUpload(task.bodyCtrl, 'html'),
                            ),
                            if (task.bodyCtrl.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'Loaded: ${task.bodyCtrl.text.split('/').last}',
                                  style: const TextStyle(
                                    color: AppColors.successGreen,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.sidebar,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          // Mini toolbar for HTML mode
                          if (task.descType == 'HTML Code')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryCyan.withOpacity(0.05),
                                border: Border(
                                  bottom: BorderSide(color: AppColors.border),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'HTML',
                                    style: TextStyle(
                                      color: AppColors.primaryCyan,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _htmlToolBtn('<b></b>', 'Bold', task),
                                  const SizedBox(width: 4),
                                  _htmlToolBtn('<i></i>', 'Italic', task),
                                  const SizedBox(width: 4),
                                  _htmlToolBtn('<a href=""></a>', 'Link', task),
                                  const SizedBox(width: 4),
                                  _htmlToolBtn('<br>', 'Line Break', task),
                                  const SizedBox(width: 4),
                                  _htmlToolBtn('<p></p>', 'Paragraph', task),
                                ],
                              ),
                            ),
                          TextField(
                            controller: task.bodyCtrl,
                            maxLines: 9,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontFamily: 'Consolas',
                            ),
                            decoration: InputDecoration(
                              hintText: task.descType == 'HTML Code'
                                  ? '<html><body>Hi {name}, your amount is {amount}...</body></html>'
                                  : 'Dear {name},\n\nYour amount: {amount}\nAddress: {address}\n\nTracking: {tracking}',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted.withOpacity(0.4),
                                fontSize: 10,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (task.bodyFormat == 'Multiple from CSV' &&
                        task.bodyList.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shuffle_rounded,
                              color: AppColors.successGreen,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.bodyList.length} body templates — picked randomly per email',
                              style: const TextStyle(
                                color: AppColors.successGreen,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  const SizedBox(height: 8),
                  // Dynamic Tags
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryPurple.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.secondaryPurple.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'DYNAMIC TAGS — Click to insert:',
                              style: TextStyle(
                                color: AppColors.secondaryPurple,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _showTagGuide,
                              child: const Text(
                                '📖 Full Guide',
                                style: TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            _tagChip(
                              '{name}',
                              'Recipient name (auto-filled)',
                              task,
                            ),
                            _tagChip(
                              '{email}',
                              'Recipient email address',
                              task,
                            ),
                            _tagChip(
                              '{amount}',
                              'Amount from CSV column C',
                              task,
                            ),
                            _tagChip(
                              '{address}',
                              'Address from CSV column D',
                              task,
                            ),
                            _tagChip('{date}', 'Current date DD/MM/YYYY', task),
                            _tagChip('{time}', 'Current time HH:MM', task),
                            _tagChip(
                              '{tracking}',
                              'Random 10-char tracking ID',
                              task,
                            ),
                            _tagChip('{random}', 'Random 6-char string', task),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _actionBtn2(
                          _isSending
                              ? 'SENDING... ($_totalSent/${_tasks[_activeTask].recipientList.length})'
                              : 'SEND EMAILS',
                          _isSending
                              ? AppColors.textMuted
                              : AppColors.successGreen,
                          Colors.black,
                          _isSending
                              ? Icons.hourglass_top_rounded
                              : Icons.send_rounded,
                          _isSending ? null : _startSending,
                        ),
                      ),
                      if (_isSending) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: _actionBtn2(
                            _isPaused ? '▶ RESUME' : '⏸ PAUSE',
                            _isPaused
                                ? AppColors.successGreen
                                : AppColors.warning,
                            Colors.black,
                            _isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                            _pauseResumeSending,
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Expanded(
                        child: _actionBtn2(
                          'STOP',
                          AppColors.dangerRed,
                          Colors.white,
                          Icons.stop_rounded,
                          _isSending ? _stopSending : null,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _actionBtn2(
                          'CLEAR ALL',
                          AppColors.textMuted,
                          Colors.white,
                          Icons.clear_all,
                          _clearAll,
                        ),
                      ),
                      if (_logs.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: _actionBtn2(
                            'EXPORT EXCEL',
                            AppColors.primaryCyan,
                            Colors.black,
                            Icons.download_rounded,
                            _exportExcel,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _htmlToolBtn(String tag, String tooltip, _MailTask task) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: () {
        final ctrl = task.bodyCtrl;
        final sel = ctrl.selection;
        final text = ctrl.text;
        final pos = sel.end >= 0 ? sel.end : text.length;
        ctrl.text = text.substring(0, pos) + tag + text.substring(pos);
        ctrl.selection = TextSelection.collapsed(offset: pos + tag.length);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primaryCyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            color: AppColors.primaryCyan,
            fontSize: 8,
            fontFamily: 'Consolas',
          ),
        ),
      ),
    ),
  );

  Widget _tagChip(String tag, String tooltip, _MailTask task) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: () {
        if (task.descType == 'HTML File') return;
        final ctrl = task.bodyCtrl;
        final sel = ctrl.selection;
        final text = ctrl.text;
        final pos = sel.end >= 0 ? sel.end : text.length;
        ctrl.text = text.substring(0, pos) + tag + text.substring(pos);
        ctrl.selection = TextSelection.collapsed(offset: pos + tag.length);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondaryPurple.withOpacity(0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.secondaryPurple.withOpacity(0.4)),
        ),
        child: Text(
          tag,
          style: const TextStyle(
            color: AppColors.secondaryPurple,
            fontSize: 9,
            fontFamily: 'Consolas',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );

  Widget _composeBtn(String label, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

  Widget _actionBtn2(
    String label,
    Color bgColor,
    Color textColor,
    IconData icon,
    VoidCallback? onTap,
  ) => ElevatedButton.icon(
    icon: Icon(icon, size: 12),
    label: Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: bgColor,
      foregroundColor: textColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    onPressed: onTap,
  );

  // ── RIGHT PANEL ──
  Widget _buildRightPanel(_MailTask task) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(left: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          _panelHeader('LIVE MONITORING'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  _statMini(
                    'Sent',
                    '$_totalSent',
                    AppColors.successGreen,
                    Icons.check_circle_rounded,
                  ),
                  const SizedBox(height: 6),
                  _statMini(
                    'Failed',
                    '$_totalFailed',
                    AppColors.dangerRed,
                    Icons.error_rounded,
                  ),
                  const SizedBox(height: 6),
                  _statMini(
                    'Pending',
                    '$_totalPending',
                    AppColors.warning,
                    Icons.pending_rounded,
                  ),
                  const SizedBox(height: 6),
                  if (_maxSendPerSmtp > 0)
                    _statMini(
                      'SMTP Used',
                      '$_sentFromCurrentSmtp / $_maxSendPerSmtp',
                      AppColors.secondaryPurple,
                      Icons.router_rounded,
                    ),
                  if (_totalSent + _totalFailed > 0) ...[
                    const SizedBox(height: 6),
                    _statMini(
                      'Success Rate',
                      '${((_totalSent / (_totalSent + _totalFailed)) * 100).toStringAsFixed(1)}%',
                      AppColors.primaryCyan,
                      Icons.trending_up_rounded,
                    ),
                  ],
                  const SizedBox(height: 10),

                  if (_isSending)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            (_isPaused
                                    ? AppColors.warning
                                    : AppColors.successGreen)
                                .withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              (_isPaused
                                      ? AppColors.warning
                                      : AppColors.successGreen)
                                  .withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!_isPaused)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    color: AppColors.successGreen,
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.pause_rounded,
                                  color: AppColors.warning,
                                  size: 12,
                                ),
                              const SizedBox(width: 6),
                              Text(
                                _isPaused ? 'PAUSED' : 'SENDING...',
                                style: TextStyle(
                                  color: _isPaused
                                      ? AppColors.warning
                                      : AppColors.successGreen,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_ipRotationEnabled && !_isPaused) ...[
                            const SizedBox(height: 6),
                            Text(
                              'IP: $_currentIp',
                              style: const TextStyle(
                                color: AppColors.secondaryPurple,
                                fontSize: 9,
                                fontFamily: 'Consolas',
                              ),
                            ),
                          ],
                          if (task.mailDelay > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Delay: ${task.mailDelay.toInt()}s between emails',
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REQUIRED PACKAGES',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _pkgRow('mailer', '^6.1.0', true),
                        _pkgRow('excel', '^4.0.6', true),
                        _pkgRow('file_picker', '^8.1.2', true),
                        _pkgRow('firebase_auth', '^4.x', true),
                        _pkgRow('cloud_firestore', '4.x', true),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'pubspec.yaml:\nmailer: ^6.1.0\nexcel: ^4.0.6\nfile_picker: ^8.1.2',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontSize: 9,
                              fontFamily: 'Consolas',
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
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

  Widget _pkgRow(String name, String ver, bool ok) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.error_rounded,
          color: ok ? AppColors.successGreen : AppColors.dangerRed,
          size: 11,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
        Text(
          ver,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 9,
            fontFamily: 'Consolas',
          ),
        ),
      ],
    ),
  );

  // ── LOG TABLE ──
  Widget _buildLogTable() {
    return Container(
      height: 140,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            color: AppColors.background,
            child: const Row(
              children: [
                Expanded(flex: 1, child: _HeaderTxt('S.NO')),
                Expanded(flex: 2, child: _HeaderTxt('SENDER')),
                Expanded(flex: 2, child: _HeaderTxt('SUBJECT')),
                Expanded(flex: 3, child: _HeaderTxt('SENT TO')),
                Expanded(flex: 2, child: _HeaderTxt('IP USED')),
                Expanded(flex: 1, child: _HeaderTxt('STATUS')),
                Expanded(flex: 2, child: _HeaderTxt('TIME')),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? const Center(
                    child: Text(
                      'Awaiting task execution...',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (_, i) {
                      final log = _logs[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: log.success
                              ? Colors.transparent
                              : AppColors.dangerRed.withOpacity(0.05),
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.border.withOpacity(0.4),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${log.sNo}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                log.sender,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                log.mailId,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                log.recipient,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primaryCyan,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                log.ip,
                                style: const TextStyle(
                                  color: AppColors.secondaryPurple,
                                  fontSize: 9,
                                  fontFamily: 'Consolas',
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                log.status,
                                style: TextStyle(
                                  color: log.success
                                      ? AppColors.successGreen
                                      : AppColors.dangerRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  //  HELPER WIDGETS
  // ================================================================
  Widget _panelHeader(String title) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: const BoxDecoration(
      color: AppColors.sidebar,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    ),
    child: Text(
      title,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 9,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _sectionBox(String title, Color color, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      );

  Widget _labelInput(
    String label,
    TextEditingController ctrl,
    String hint, {
    bool obscure = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
      ),
      const SizedBox(height: 2),
      SizedBox(
        height: 28,
        child: TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textMuted.withOpacity(0.4),
              fontSize: 10,
            ),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: AppColors.primaryCyan),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _inputWithCheckbox(
    String label,
    TextEditingController ctrl,
    String hint,
    String cbLabel,
    bool cbVal,
    ValueChanged<bool?> cbOnChange,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
      ),
      const SizedBox(height: 2),
      Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 28,
              child: TextField(
                controller: ctrl,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.4),
                    fontSize: 10,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _checkItem(cbLabel, cbVal, cbOnChange),
        ],
      ),
    ],
  );

  Widget _radioMini(
    List<String> options,
    String groupVal,
    ValueChanged<String?> onChange,
  ) => Wrap(
    children: options
        .map(
          (o) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<String>(
                value: o,
                groupValue: groupVal,
                onChanged: onChange,
                activeColor: AppColors.primaryCyan,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              Text(
                o,
                style: const TextStyle(color: AppColors.textMain, fontSize: 9),
              ),
              const SizedBox(width: 4),
            ],
          ),
        )
        .toList(),
  );

  Widget _smallSwitch(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    Color color,
  ) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Switch(
        value: value,
        activeColor: color,
        onChanged: onChanged,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      Text(
        label,
        style: TextStyle(
          color: value ? color : AppColors.textMuted,
          fontSize: 9,
          fontWeight: value ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      const SizedBox(width: 8),
    ],
  );

  Widget _checkItem(String label, bool value, ValueChanged<bool?> onChange) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChange,
              activeColor: AppColors.primaryCyan,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
          ),
        ],
      );

  Widget _statMini(String label, String value, Color color, IconData icon) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _inboxSection(String title, Color color, List<Widget> children) =>
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      );
}

// ================================================================
//  DATA MODELS
// ================================================================
class _MailTask {
  final int id;
  String sendMethod = 'SMTP (Gmail)';
  String descType = 'Plain Text';
  String bodyFormat = 'Single Text';
  double mailDelay = 3.0;

  bool spoofMultiple = false;
  bool subjectMultiple = false;
  bool bodyMultiple = false;
  List<String> spoofNamesList = [];
  List<String> subjectsList = [];
  List<String> bodyList = [];

  bool macSpoofEnabled = false;
  bool domainMixEnabled = false;
  bool pcProtectionBypass = false;
  String googleApiToken = '';
  String googleJsonPath = '';
  String googleJsonName = '';
  String macAddress = 'AA:BB:CC:DD:EE:FF';
  List<String> mixedDomains = [];
  String spamScore = '—';

  List<String> attachmentPaths = []; // একাধিক ফাইলের পাথ রাখার জন্য
  List<String> attachmentNames = []; // একাধিক ফাইলের নাম রাখার জন্য

  List<String> recipientList = [];
  List<Map<String, dynamic>> recipientData = [];

  Map<String, bool> headers = {
    'MGR': false,
    'HTML': true,
    'I-HTML': true,
    'Priority': false,
    'UNSUB': false,
    'OLE': false,
    'Magic': false,
  };

  final emailCtrl = TextEditingController();
  final appPassCtrl = TextEditingController();
  final smtpHostCtrl = TextEditingController(text: 'smtp.gmail.com');
  final smtpPortCtrl = TextEditingController(text: '587');
  final spoofNameCtrl = TextEditingController();
  final subjectCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  final attachmentCtrl = TextEditingController();
  final googleJsonCtrl = TextEditingController();
  final recipientFileCtrl = TextEditingController();

  _MailTask({required this.id});

  void dispose() {
    emailCtrl.dispose();
    appPassCtrl.dispose();
    smtpHostCtrl.dispose();
    smtpPortCtrl.dispose();
    spoofNameCtrl.dispose();
    subjectCtrl.dispose();
    bodyCtrl.dispose();
    attachmentCtrl.dispose();
    googleJsonCtrl.dispose();
    recipientFileCtrl.dispose();
  }
}

class _LogEntry {
  final int sNo;
  final String sender, recipient, mailId, status, ip;
  final DateTime timestamp;
  final bool success;
  final String bodySnippet;
  final String attachmentName;

  _LogEntry({
    required this.sNo,
    required this.sender,
    required this.recipient,
    required this.mailId,
    required this.status,
    required this.ip,
    required this.timestamp,
    required this.success,
    this.bodySnippet = '',
    this.attachmentName = '',
  });
}

// ================================================================
//  FILE-LEVEL HELPERS
// ================================================================
class _HeaderTxt extends StatelessWidget {
  final String text;
  const _HeaderTxt(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 9,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
    ),
  );
}

class _Th extends StatelessWidget {
  final String text;
  const _Th(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textMuted,
      fontSize: 9,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.8,
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

Widget _modalTitle(IconData icon, String title, Color color) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    const SizedBox(height: 8),
    const Divider(color: AppColors.border),
  ],
);
