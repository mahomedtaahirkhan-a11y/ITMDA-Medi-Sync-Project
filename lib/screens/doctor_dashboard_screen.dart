import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medisync/models/user_model.dart';
import 'package:medisync/providers/auth_provider.dart';
import 'package:medisync/services/queue_service.dart';
import 'package:provider/provider.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  DoctorDashboardScreenState createState() => DoctorDashboardScreenState();
}

class DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final QueueService _queueService = QueueService();

  Future<void> _callNextPatient(String doctorId) async {
    // Show a confirmation dialog before calling the next patient
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Next Patient?'),
        content: const Text('This will mark the current patient as completed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Call Next'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _queueService.callNextPatient(doctorId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final doctor = authProvider.user;
    final String formattedDate = DateFormat('EEEE, MMMM d').format(DateTime.now());

    if (doctor == null) {
      return const Scaffold(body: Center(child: Text('Authentication Error')));
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(doctor, formattedDate),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatsSection(doctor.uid),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Current Queue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _callNextPatient(doctor.uid),
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('Call Next'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildQueueList(doctor.uid),
                      const SizedBox(height: 80), // For bottom nav spacing
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildHeader(UserModel doctor, String formattedDate) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Good Morning,', style: TextStyle(fontSize: 14, color: Color(0xFFBFDBFE))),
                  const SizedBox(height: 4),
                  Text(doctor.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Color(0xFFBFDBFE), size: 16),
              const SizedBox(width: 8),
              Text(formattedDate, style: const TextStyle(fontSize: 14, color: Color(0xFFBFDBFE))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(String doctorId) {
    return StreamBuilder<List<UserModel>>(
      stream: _queueService.getDoctorQueue(doctorId),
      builder: (context, snapshot) {
        final waitingCount = snapshot.data?.length ?? 0;
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Waiting',
                value: waitingCount.toString(),
                icon: Icons.hourglass_empty,
                color: const Color(0xFFCA8A04),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Referrals Sent',
                value: '0', // Placeholder for now
                icon: Icons.send,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQueueList(String doctorId) {
    return StreamBuilder<List<UserModel>>(
      stream: _queueService.getDoctorQueue(doctorId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Could not load queue. Please ensure the Firestore index for queries has been created.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text('No patients in the queue.')));
        }
        final patients = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: patients.length,
          itemBuilder: (context, index) {
            final patient = patients[index];
            return _buildPatientCard(patient: patient, position: index + 1);
          },
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard({required UserModel patient, required int position}) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withAlpha(26),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('#$position', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A))),
                  const SizedBox(height: 4),
                  const Text('Checked-in for consultation', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard, 'Dashboard', true, () {}),
              _buildNavItem(Icons.people, 'Patients', false, () {
                Navigator.pushNamed(context, '/seen_patients');
              }),
              _buildNavItem(Icons.message, 'Messages', false, () {}),
              _buildNavItem(Icons.person, 'Profile', false, () {
                Navigator.pushNamed(context, '/profile');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFF93C5FD),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isActive ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
