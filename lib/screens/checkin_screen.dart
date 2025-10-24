import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medisync/models/appointment_model.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/queue_service.dart';
import '../services/appointment_service.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  CheckInScreenState createState() => CheckInScreenState();
}

class CheckInScreenState extends State<CheckInScreen> {
  final QueueService _queueService = QueueService();
  final AppointmentService _appointmentService = AppointmentService();
  bool _isLoading = false;

  Future<void> _checkIn(String patientId, String doctorId) async {
    setState(() => _isLoading = true);

    try {
      await _queueService.checkIn(patientId, doctorId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully checked in!'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/queue_status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final String formattedDate = DateFormat('EEEE, MMMM d, y').format(DateTime.now());

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to check in.')));
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
            _buildHeader(formattedDate),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _appointmentService.getPatientAppointments(user.uid, 'scheduled'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'You have no upcoming appointments today to check in for.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    );
                  }

                  final appointments = snapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(24.0),
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final details = appointments[index];
                      final AppointmentModel appointment = details['appointment'];
                      return _buildCheckInCard(user.uid, appointment, details);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String formattedDate) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
      decoration: const BoxDecoration(color: Color(0xFF2563EB)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                'Check-In to Clinic',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
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

  Widget _buildCheckInCard(String userId, AppointmentModel appointment, Map<String, dynamic> details) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: Colors.white,
      shadowColor: const Color(0xFFDBEAFE),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Appointment with ${details['doctorName']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('at ${details['clinicName']}'),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () => _checkIn(userId, appointment.doctorId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Check In Now'),
                  ),
          ],
        ),
      ),
    );
  }
}
