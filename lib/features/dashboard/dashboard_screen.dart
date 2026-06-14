import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ================= ফাংশনাল কন্ট্রোলার =================
  final TextEditingController _senderNameCtrl = TextEditingController(
    text: 'Tabitha Kemmer',
  );
  final TextEditingController _senderEmailCtrl = TextEditingController(
    text: 'bryan.sharon@domain.com',
  );
  final TextEditingController _subjectCtrl = TextEditingController(
    text: 'Thank You for Your Order #RANDOM#',
  );

  // টার্মিনাল লগের জন্য রিয়েল-টাইম লিস্ট
  List<String> terminalLogs = [
    '[ SYSTEM ] INITIALIZING V-63 CORE PROTOCOL...',
    '[ CORE ] WAITING FOR USER CONFIGURATION...',
  ];

  // স্টার্ট বাটনের ফাংশন
  void _startCampaign() {
    setState(() {
      terminalLogs.add(
        '[ EXEC ] CONNECTING TO SMTP... SENDER: ${_senderEmailCtrl.text}',
      );
      terminalLogs.add('[ SUCCESS ] SMTP HANDSHAKE SUCCESSFUL [NODE_04]');
      // পরবর্তীতে এখানে ফায়ারবেসের কোড এবং আসল ইমেইল সেন্ডিং লজিক বসবে
    });
  }

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _senderEmailCtrl.dispose();
    _subjectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // পুরোটা এক স্ক্রিনে رکھنےর জন্য Row ব্যবহার করা হলো
      body: Row(
        children: [
          // ================= ছোট সাইডবার =================
          Container(
            width: 200, // ছোট স্ক্রিনের জন্য সাইডবার চিকন করা হয়েছে
            color: AppColors.sidebar,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 24, bottom: 24),
                  child: Text(
                    'INNOVEXA63',
                    style: TextStyle(
                      color: AppColors.primaryCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _buildMenuItem(Icons.campaign, 'Campaigns', isActive: true),
                _buildMenuItem(Icons.dashboard_customize, 'Dashboard'),
                _buildMenuItem(Icons.auto_awesome, 'AI Orchestrator'),
                _buildMenuItem(Icons.router, 'SMTP Relay'),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 40),
                    ),
                    onPressed: () {
                      setState(() {
                        terminalLogs.clear();
                        terminalLogs.add(
                          '[ SYSTEM ] NEW CAMPAIGN INITIATED...',
                        );
                      });
                    },
                    child: const Text(
                      'New Campaign',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= মেইন ক্যানভাস =================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // টাস্ক স্ট্যাটাস কার্ড (স্ক্রলএবল)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTaskCard(
                          'Task 01',
                          'Sent-204',
                          Icons.check_circle,
                          AppColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        _buildTaskCard(
                          'Task 03 (ACTIVE)',
                          'Sent-448',
                          Icons.autorenew,
                          AppColors.successGreen,
                          isActive: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Configuration Canvas (ফাংশনাল ইনপুট ফিল্ড)
                  const Text(
                    'Configuration Canvas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          'SENDER IDENTITY',
                          _senderNameCtrl,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInputField(
                          'SENDER MAIL',
                          _senderEmailCtrl,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInputField('SUBJECT LINE', _subjectCtrl),

                  const SizedBox(height: 16),

                  // ================= লাইভ টার্মিনাল =================
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black, // হ্যাকার টার্মিনালের মতো কালো
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryCyan.withOpacity(0.3),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: terminalLogs.length,
                        itemBuilder: (context, index) {
                          return Text(
                            terminalLogs[index],
                            style: const TextStyle(
                              color: AppColors.successGreen,
                              fontFamily: 'Consolas',
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // অ্যাকশন বাটন (Start / Stop)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(
                          Icons.play_arrow,
                          color: Colors.black,
                          size: 16,
                        ),
                        label: const Text(
                          'START',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                        ),
                        onPressed: _startCampaign, // ফাংশন কল
                      ),
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

  // Helper Widget: Input Field
  Widget _buildInputField(String label, TextEditingController controller) {
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
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.sidebar,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widget: Sidebar Menu
  Widget _buildMenuItem(IconData icon, String title, {bool isActive = false}) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      leading: Icon(
        icon,
        color: isActive ? AppColors.primaryCyan : AppColors.textMuted,
        size: 18,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isActive ? AppColors.primaryCyan : AppColors.textMuted,
          fontSize: 13,
        ),
      ),
      tileColor: isActive
          ? AppColors.primaryCyan.withOpacity(0.1)
          : Colors.transparent,
      onTap: () {},
    );
  }

  // Helper Widget: Task Card
  Widget _buildTaskCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor, {
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isActive
              ? AppColors.successGreen
              : AppColors.textMuted.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isActive
                      ? AppColors.successGreen
                      : AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Icon(icon, color: iconColor, size: 20),
        ],
      ),
    );
  }
}
