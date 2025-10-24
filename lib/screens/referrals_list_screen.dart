import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medisync/models/referral_model.dart';
import 'package:medisync/providers/auth_provider.dart';
import 'package:medisync/services/referral_service.dart';
import 'package:provider/provider.dart';

class ReferralsListScreen extends StatefulWidget {
  const ReferralsListScreen({super.key});

  @override
  ReferralsListScreenState createState() => ReferralsListScreenState();
}

class ReferralsListScreenState extends State<ReferralsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ReferralService _referralService = ReferralService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            // Header
            _buildHeader(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildReferralsList('pending'),
                  _buildReferralsList('accepted'),
                  _buildReferralsList('completed'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'My Referrals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
              Tab(text: 'Completed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferralsList(String status) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: Text('Please log in to see your referrals.'));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _referralService.getPatientReferrals(user.uid, status),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description_outlined, size: 80, color: Color(0xFFBFDBFE)),
                const SizedBox(height: 16),
                Text(
                  'No $status referrals',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6B7280),
                  ),
                ),
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

  Widget _buildReferralCard(Map<String, dynamic> referralDetails) {
    final ReferralModel referral = referralDetails['referral'];

    Color priorityColor = referral.priority == 'High'
        ? const Color(0xFFDC2626)
        : referral.priority == 'Medium'
            ? const Color(0xFFCA8A04)
            : const Color(0xFF059669);

    Color statusColor = referral.status == 'pending'
        ? const Color(0xFFCA8A04)
        : referral.status == 'accepted'
            ? const Color(0xFF3B82F6)
            : const Color(0xFF059669);

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
                _buildStatusTag(referral.status, statusColor),
                _buildPriorityTag(referral.priority, priorityColor),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Referral to ${referralDetails['toSpecialistName'] ?? 'a Specialist'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              referral.reason,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFDBEAFE)),
            const SizedBox(height: 16),
            _buildDoctorInfoRow('From', referralDetails['fromDoctorName'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildDoctorInfoRow('To', referralDetails['toSpecialistName'] ?? 'N/A'),
            const SizedBox(height: 8),
            _buildDateInfoRow('Referred', referral.createdAt),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPriorityTag(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInfoRow(String title, String name) {
    return Row(
      children: [
        Icon(title == 'From' ? Icons.person_outline : Icons.person, size: 16, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(
          '$title: $name',
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfoRow(String title, DateTime date) {
    return Row(
      children: [
        const Icon(Icons.calendar_today, size: 16, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(
          '$title: ${DateFormat.yMMMd().format(date)}',
          style: const TextStyle(
            fontSize: 13,
            color: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }
}
