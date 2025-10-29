import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medisync/models/referral_model.dart';
import 'package:medisync/providers/auth_provider.dart';
import 'package:medisync/services/referral_service.dart';
import 'package:provider/provider.dart';

class SpecialistInboxScreen extends StatefulWidget {
  const SpecialistInboxScreen({super.key});

  @override
  SpecialistInboxScreenState createState() => SpecialistInboxScreenState();
}

class SpecialistInboxScreenState extends State<SpecialistInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReferralService _referralService = ReferralService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final specialist = authProvider.user;

    if (specialist == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Colors.white],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context, specialist.uid),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReferralsList(specialist.uid, 'pending'),
                  _buildReferralsList(specialist.uid, 'accepted'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String specialistId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      decoration: const BoxDecoration(color: Color(0xFF2563EB)),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Referral Inbox', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
              const Spacer(),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _referralService.getSpecialistReferrals(specialistId, 'pending'),
                builder: (context, snapshot) {
                  final count = snapshot.data?.length ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(12)),
                    child: Text('$count New', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Logout',
                onPressed: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.signOut();
                  if (mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFFBFDBFE),
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            tabs: const [Tab(text: 'Pending Review'), Tab(text: 'Accepted')],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralsList(String specialistId, String status) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _referralService.getSpecialistReferrals(specialistId, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inbox_outlined, size: 80, color: Color(0xFFBFDBFE)),
                const SizedBox(height: 16),
                Text('No $status referrals', style: const TextStyle(fontSize: 18, color: Color(0xFF6B7280))),
              ],
            ),
          );
        }

        final referrals = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: referrals.length,
          itemBuilder: (context, index) {
            final referralDetails = referrals[index];
            return _buildReferralCard(referralDetails);
          },
        );
      },
    );
  }

  Widget _buildReferralCard(Map<String, dynamic> referral) {
    final ReferralModel referralData = referral['referral'];
    final appointmentDate = referral['appointmentDate']?.toDate();
    Color priorityColor = referralData.priority == 'High'
        ? const Color(0xFFDC2626)
        : referralData.priority == 'Medium'
            ? const Color(0xFFCA8A04)
            : const Color(0xFF059669);

    bool isPending = referralData.status == 'pending';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF2563EB).withAlpha(26), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.person, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(referral['patientName'] ?? 'N/A', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                          Text('ID: Not Available', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))), // Patient ID is not available in the details map
                        ],
                      ),
                    ),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: priorityColor.withAlpha(26), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.priority_high, size: 12, color: priorityColor),
                    const SizedBox(width: 4),
                    Text(referralData.priority, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: priorityColor)),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(referralData.reason, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFDBEAFE)),
            const SizedBox(height: 16),
            Row(children: [
              const Icon(Icons.local_hospital, size: 16, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text('Referred by: ${referral['fromDoctorName'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today, size: 16, color: Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              Text('Received: ${DateFormat.yMMMd().format(referralData.createdAt)}', style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6))),
            ]),
            if (appointmentDate != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.check_circle, size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Text('Appointment: ${DateFormat.yMMMd().add_jm().format(appointmentDate)}', style: const TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.w500)),
              ]),
            ],
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showRejectDialog(context, referralData.id),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFCA5A5)), foregroundColor: const Color(0xFFDC2626), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/schedule_referral', arguments: referralData),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: const Text('Accept & Schedule'),
                  ),
                ),
              ]),
            ]
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, String referralId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Referral'),
          content: const Text('Are you sure you want to reject this referral?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _referralService.updateReferralStatus(referralId, 'rejected');
                Navigator.pop(context);
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Referral rejected.'), backgroundColor: Color(0xFFDC2626)),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }
}
