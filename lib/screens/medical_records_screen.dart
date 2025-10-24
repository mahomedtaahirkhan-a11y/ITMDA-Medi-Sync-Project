import 'package:flutter/material.dart';
import 'package:medisync/providers/auth_provider.dart';
import 'package:medisync/services/medical_record_service.dart';
import 'package:provider/provider.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  MedicalRecordsScreenState createState() => MedicalRecordsScreenState();
}

class MedicalRecordsScreenState extends State<MedicalRecordsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MedicalRecordService _medicalRecordService = MedicalRecordService();

  Stream<List<Map<String, dynamic>>>? _visitsStream;
  Stream<List<Map<String, dynamic>>>? _medicationsStream;
  Stream<List<Map<String, dynamic>>>? _labResultsStream;
  Stream<List<Map<String, dynamic>>>? _documentsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_visitsStream == null) {
      final authProvider = Provider.of<AuthProvider>(context);
      final user = authProvider.user;
      if (user != null) {
        _visitsStream = _medicalRecordService.getVisits(user.uid).asBroadcastStream();
        _medicationsStream = _medicalRecordService.getMedications(user.uid).asBroadcastStream();
        _labResultsStream = _medicalRecordService.getLabResults(user.uid).asBroadcastStream();
        _documentsStream = _medicalRecordService.getDocuments(user.uid).asBroadcastStream();
      }
    }
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
                        'Medical Records',
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
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Visits'),
                      Tab(text: 'Medications'),
                      Tab(text: 'Lab Results'),
                      Tab(text: 'Documents'),
                    ],
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildVisitsTab(),
                  _buildMedicationsTab(),
                  _buildLabResultsTab(),
                  _buildDocumentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _visitsStream,
      builder: (context, snapshot) {
        if (Provider.of<AuthProvider>(context).user == null) {
          return const Center(child: Text('Please log in to see your medical records.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No visits found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final visits = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: visits.length,
          itemBuilder: (context, index) {
            final visit = visits[index];
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
                        Text(
                          visit['date'] ?? 'No Date',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF6B7280)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 18, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(
                          visit['doctor'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      visit['specialty'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Diagnosis',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            visit['diagnosis'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      visit['notes'] ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMedicationsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _medicationsStream,
      builder: (context, snapshot) {
        if (Provider.of<AuthProvider>(context).user == null) {
          return const Center(child: Text('Please log in to see your medical records.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No medications found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final medications = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: medications.length,
          itemBuilder: (context, index) {
            final medication = medications[index];
            bool isActive = medication['status'] == 'Active';
            
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
                          child: Text(
                            medication['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFF059669).withAlpha(26) : const Color(0xFF6B7280).withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            medication['status'] ?? 'N/A',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isActive ? const Color(0xFF059669) : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.medication, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(
                          '${medication['dosage'] ?? 'N/A'} - ${medication['frequency'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(
                          'Prescribed by ${medication['prescribedBy'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(
                          'Started: ${medication['startDate'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLabResultsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _labResultsStream,
      builder: (context, snapshot) {
        if (Provider.of<AuthProvider>(context).user == null) {
          return const Center(child: Text('Please log in to see your medical records.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No lab results found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final labResults = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: labResults.length,
          itemBuilder: (context, index) {
            final result = labResults[index];
            Color statusColor = result['status'] == 'Normal'
                ? const Color(0xFF059669)
                : result['status'] == 'Borderline High'
                    ? const Color(0xFFCA8A04)
                    : const Color(0xFFDC2626);
            
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
                          child: Text(
                            result['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            result['status'] ?? 'N/A',
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
                          result['date'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        Text(
                          'Ordered by ${result['orderedBy'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // TODO: View detailed results
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _documentsStream,
      builder: (context, snapshot) {
        if (Provider.of<AuthProvider>(context).user == null) {
          return const Center(child: Text('Please log in to see your medical records.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No documents found.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final documents = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final document = documents[index];
            
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description, color: Color(0xFF2563EB), size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            document['name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            document['type'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                document['date'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              Text(
                                ' • ${document['size'] ?? 'N/A'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download, color: Color(0xFF2563EB)),
                      onPressed: () {
                        // TODO: Download document
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Downloading ${document['name'] ?? 'document'}')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
