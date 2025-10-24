import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/queue_status_model.dart';
import '../providers/auth_provider.dart';
import '../services/queue_service.dart';

class QueueStatusScreen extends StatefulWidget {
  const QueueStatusScreen({super.key});

  @override
  State<QueueStatusScreen> createState() => QueueStatusScreenState();
}

class QueueStatusScreenState extends State<QueueStatusScreen> {
  final QueueService _queueService = QueueService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userId = authProvider.user?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      body: StreamBuilder<QueueStatusModel?>(
        stream: _queueService.getPatientQueueStatus(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 80, color: Color(0xFFBFDBFE)),
                  const SizedBox(height: 16),
                  const Text('You are not in any queue'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/checkin'),
                    child: const Text('Check In Again'),
                  ),
                ],
              ),
            );
          }

          final queueStatus = snapshot.data!;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE3F2FD), Colors.white],
              ),
            ),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _buildPositionCard(queueStatus.position),
                        const SizedBox(height: 24),
                        _buildWaitTimeCard(queueStatus.estimatedWaitMinutes),
                        const SizedBox(height: 24),
                        _buildCancelButton(queueStatus.queueId),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF2563EB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
            IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Queue Status',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCard(int position) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Text(
                  'Your Position',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '#$position',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              'in queue',
              style: TextStyle(fontSize: 18, color: Color(0xFFBFDBFE)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitTimeCard(int estimatedWaitMinutes) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  'Estimated Wait Time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '~$estimatedWaitMinutes mins',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelButton(String queueId) {
    return OutlinedButton(
      onPressed: () async {
        await _queueService.cancelCheckIn(queueId);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      },
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        side: const BorderSide(color: Color(0xFFFCA5A5)),
        foregroundColor: const Color(0xFFDC2626),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('Cancel Check-In'),
    );
  }
}
