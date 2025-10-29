import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medisync/models/appointment_model.dart';
import 'package:medisync/providers/auth_provider.dart';
import 'package:medisync/services/appointment_service.dart';
import 'package:provider/provider.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  AppointmentsScreenState createState() => AppointmentsScreenState();
}

class AppointmentsScreenState extends State<AppointmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppointmentService _appointmentService = AppointmentService();

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
            Container(
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
                        'My Appointments',
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
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Completed'),
                      Tab(text: 'Cancelled'),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAppointmentsList('upcoming'),
                  _buildAppointmentsList('completed'),
                  _buildAppointmentsList('cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/book_appointment'),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Book Appointment',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(String type) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Center(child: Text('Please log in to see your appointments.'));
    }

    // Correctly map tab types to appointment statuses
    String status = type;
    if (type == 'upcoming') {
      status = 'scheduled'; // 'upcoming' in UI is 'scheduled' in the database
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _appointmentService.getPatientAppointments(user.uid, status),
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
                Icon(Icons.event_busy, size: 80, color: const Color(0xFFBFDBFE)),
                const SizedBox(height: 16),
                Text(
                  'No $type appointments',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          );
        }

        final appointments = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointmentDetails = appointments[index];
            return _buildAppointmentCard(appointmentDetails, type);
          },
        );
      },
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointmentDetails, String type) {
    final AppointmentModel appointment = appointmentDetails['appointment'];
    final String doctorName = appointmentDetails['doctorName'] ?? 'N/A';
    final String specialty = appointmentDetails['doctorSpecialty'] ?? 'N/A';
    final String clinicName = appointmentDetails['clinicName'] ?? 'N/A';
    final String doctorRole = appointmentDetails['doctorRole'] ?? 'doctor';

    Color statusColor;
    String statusText = appointment.status.toUpperCase();

    switch (appointment.status) {
      case 'scheduled':
        statusColor = const Color(0xFF059669);
        statusText = 'CONFIRMED';
        break;
      case 'pending':
        statusColor = const Color(0xFFCA8A04);
        break;
      case 'completed':
        statusColor = const Color(0xFF3B82F6);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFDC2626);
        break;
      default:
        statusColor = Colors.grey;
    }

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        specialty,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat.yMMMd().format(appointment.dateTime)}, ${DateFormat.jm().format(appointment.dateTime)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    clinicName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
            if (type == 'upcoming' && doctorRole == 'doctor') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Implement reschedule
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF93C5FD)),
                        foregroundColor: const Color(0xFF1D4ED8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reschedule'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/checkin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Check In'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
