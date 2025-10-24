import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:medisync/models/user_model.dart';
import 'package:medisync/providers/auth_provider.dart';
import 'package:medisync/services/admin_service.dart';
import 'package:provider/provider.dart';

// Matching the color palette from the React example
const Color primaryColor = Color(0xFF2563EB); // blue-600
const Color doctorColor = Color(0xFF7C3AED); // purple-600
const Color specialistColor = Color(0xFF059669); // green-600
const Color orangeColor = Color(0xFFF59E0B); // orange-500 (lucide orange is usually amber/orange)
const Color backgroundColor = Color(0xFFF9FAFB); // gray-50
const Color cardColor = Colors.white;
const Color textColor = Color(0xFF1F2937); // gray-800
const Color subTextColor = Color(0xFF6B7280); // gray-500

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();

  // State variables for data
  int _userCount = 0;
  int _activeQueueCount = 0;
  int _referralCount = 0;
  int _appointmentsToday = 0;
  Map<String, int> _userDistribution = {};

  // State for Users Tab
  String _searchTerm = '';
  String _filterRole = 'all';
  final TextEditingController _searchController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _loadDashboardData();
     _searchController.addListener(() {
      setState(() {
        _searchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      final results = await Future.wait([
        _adminService.getUserCount(),
        _adminService.getActiveQueueCount(),
        _adminService.getReferralCount(),
        _adminService.getUserDistribution(),
        _adminService.getAppointmentsTodayCount(),
      ]);

      if (mounted) {
        setState(() {
          _userCount = results[0] as int;
          _activeQueueCount = results[1] as int;
          _referralCount = results[2] as int;
          _userDistribution = results[3] as Map<String, int>;
          _appointmentsToday = results[4] as int;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Changed from 3 to 2
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Dashboard',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                'MedSync System Administration',
                style: TextStyle(fontSize: 12, color: Color(0xFFDBEAFE)),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                if (mounted) {
                  // Navigate to login screen and remove all previous routes
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: const Color(0xFF93C5FD),
            indicatorColor: Colors.white,
            indicatorWeight: 3.0,
            tabs: const [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.dashboard_rounded), SizedBox(width: 8), Text('Overview')])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people_alt_rounded), SizedBox(width: 8), Text('Users')])),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            _buildUsersTab(),
          ],
        ),
      ),
    );
  }

  // Overview Tab
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildStatsGrid(),
          const SizedBox(height: 24),
          _buildUserDistributionChart(),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return LayoutBuilder(builder: (context, constraints) {
      final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
      return GridView.count(
        crossAxisCount: crossAxisCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.8, // Adjust aspect ratio for better look
        children: [
          _buildStatCard(icon: Icons.people_outline, title: 'Total Users', value: _userCount.toString(), color: primaryColor),
          _buildStatCard(icon: Icons.hourglass_bottom_rounded, title: 'Active Queues', value: _activeQueueCount.toString(), color: specialistColor),
          _buildStatCard(icon: Icons.calendar_today_rounded, title: 'Appointments Today', value: _appointmentsToday.toString(), color: doctorColor),
          _buildStatCard(icon: Icons.assignment_turned_in_outlined, title: 'Pending Referrals', value: _referralCount.toString(), color: orangeColor),
        ],
      );
    });
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Color color}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(title, style: TextStyle(fontSize: 14, color: subTextColor), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: textColor)),
                ],
              ),
            ),
             const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDistributionChart() {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Distribution', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: _userDistribution.entries.map((entry) {
                    return PieChartSectionData(
                      color: _getColorForRole(entry.key),
                      value: entry.value.toDouble(),
                      title: '${entry.key}\n${entry.value}',
                      radius: 100,
                      titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForRole(String role) {
    switch (role) {
      case 'patient':
        return primaryColor;
      case 'doctor':
        return doctorColor;
      case 'specialist':
        return specialistColor;
      default:
        return Colors.grey;
    }
  }

  // Users Tab
  Widget _buildUsersTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _adminService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No users found."));
        }
        
        var users = snapshot.data!;
        
        // Filtering logic
        final filteredUsers = users.where((user) {
          final name = user.name.toLowerCase();
          final email = user.email.toLowerCase();
          final search = _searchTerm.toLowerCase();
          final role = user.role;

          final matchesSearch = name.contains(search) || email.contains(search);
          final matchesRole = _filterRole == 'all' || role == _filterRole;

          return matchesSearch && matchesRole;
        }).toList();

        return Column(
          children: [
            _buildUserFilters(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];
                  return _buildUserCard(user);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              prefixIcon: Icon(Icons.search, color: subTextColor),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _filterRole,
            onChanged: (value) {
              setState(() {
                _filterRole = value!;
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Roles')),
              DropdownMenuItem(value: 'patient', child: Text('Patients')),
              DropdownMenuItem(value: 'doctor', child: Text('Doctors')),
              DropdownMenuItem(value: 'specialist', child: Text('Specialists')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1.5,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getColorForRole(user.role).withAlpha(38),
                  child: Icon(Icons.person, color: _getColorForRole(user.role)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 16)),
                      Text(user.email, style: TextStyle(color: subTextColor, fontSize: 14)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorForRole(user.role).withAlpha(38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role,
                    style: TextStyle(color: _getColorForRole(user.role), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                )
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${DateFormat.yMMMd().format(user.createdAt)}',
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      onPressed: () => _showEditUserDialog(user),
                      style: TextButton.styleFrom(foregroundColor: primaryColor),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                      onPressed: () => _adminService.deleteUser(user.uid),
                      style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }


  void _showEditUserDialog(UserModel user) {
    final nameController = TextEditingController(text: user.name);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: const Text('Edit User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'patient', child: Text('Patient')),
                      DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                      DropdownMenuItem(value: 'specialist', child: Text('Specialist')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                           selectedRole = value;
                        });
                      }
                    },
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _adminService.updateUser(user.uid, {
                      'name': nameController.text,
                      'role': selectedRole,
                    });
                    Navigator.of(context).pop();
                    _loadDashboardData(); // Refresh data
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
