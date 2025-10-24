import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/appointment_model.dart';
import '../models/user_model.dart'; // Import the UserModel
import '../providers/auth_provider.dart'; 
import '../services/appointment_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    String formattedDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
    
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
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
              // Header
              _buildHeader(user, formattedDate),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Actions
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildQuickActions(context),
                      
                      const SizedBox(height: 32),
                      
                      // Upcoming Appointments
                      _buildUpcomingAppointmentsHeader(context),
                      const SizedBox(height: 12),
                      
                      _buildAppointmentsStream(user.uid),
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

  Widget _buildHeader(UserModel user, String formattedDate) {
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
                  const Text(
                    'Welcome back,',
                    style: TextStyle(fontSize: 14, color: Color(0xFFBFDBFE)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51), // FIX: withOpacity -> withAlpha
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
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 14, color: Color(0xFFBFDBFE)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.medical_services,
                title: 'Check In',
                color: const Color(0xFF2563EB),
                onTap: () => Navigator.pushNamed(context, '/checkin'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.calendar_month,
                title: 'Appointments',
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.pushNamed(context, '/appointments'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.description,
                title: 'Referrals',
                color: const Color(0xFFDC2626),
                onTap: () => Navigator.pushNamed(context, '/referrals'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(), // Empty container
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointmentsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Upcoming Appointments',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3A8A),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/appointments'),
          child: const Text('See All'),
        ),
      ],
    );
  }

  Widget _buildAppointmentsStream(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _appointmentService.getPatientAppointments(userId, 'scheduled'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text('No upcoming appointments', style: TextStyle(color: Colors.grey[600])),
              ),
            ),
          );
        }
        
        final appointments = snapshot.data!.take(2).toList();
        return Column(
          children: appointments.map((aptDetails) {
            final apt = aptDetails['appointment'] as AppointmentModel; // Explicit cast
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAppointmentCard(
                doctorName: aptDetails['doctorName'] ?? 'N/A',
                specialty: aptDetails['doctorSpecialty'] ?? 'N/A',
                date: DateFormat('MMM dd, yyyy').format(apt.dateTime),
                time: DateFormat('hh:mm a').format(apt.dateTime),
                clinic: aptDetails['clinicName'] ?? 'N/A',
              ),
            );
          }).toList(),
        );
      },
    );
  }
  
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(26), // FIX: withOpacity -> withAlpha
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppointmentCard({
    required String doctorName,
    required String specialty,
    required String date,
    required String time,
    required String clinic,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withAlpha(26), // FIX: withOpacity -> withAlpha
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.person, color: Color(0xFF2563EB), size: 32),
            ),
            const SizedBox(width: 16),
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
                    style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Text(
                        '$date, $time',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clinic,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
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
              _buildNavItem(Icons.home, 'Home', true, () {}),
              _buildNavItem(Icons.person, 'Profile', false, () {
                Navigator.pushNamed(context, '/profile');
              }),
              _buildNavItem(Icons.notifications, 'Alerts', false, () {}),
              _buildNavItem(Icons.settings, 'Settings', false, () {}),
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
              color: isActive ? const Color(0xFF2563EB) : const Color(0xFFBFDBFE),
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
