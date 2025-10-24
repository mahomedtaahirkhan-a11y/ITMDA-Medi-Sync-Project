import 'package:flutter/material.dart';
import 'package:medisync/models/user_model.dart';
import 'package:medisync/providers/auth_provider.dart';
import 'package:medisync/services/doctor_service.dart';
import 'package:medisync/services/referral_service.dart';
import 'package:provider/provider.dart';

class CreateReferralScreen extends StatefulWidget {
  const CreateReferralScreen({super.key});

  @override
  State<CreateReferralScreen> createState() => _CreateReferralScreenState();
}

class _CreateReferralScreenState extends State<CreateReferralScreen> {
  final _formKey = GlobalKey<FormState>();
  final ReferralService _referralService = ReferralService();
  final DoctorService _doctorService = DoctorService();

  String? _selectedSpecialistId;
  String _priority = 'Medium';
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendReferral(String fromDoctorId, String patientId) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _referralService.createReferral(
          patientId: patientId,
          fromDoctorId: fromDoctorId,
          toSpecialistId: _selectedSpecialistId!,
          reason: _reasonController.text,
          priority: _priority,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Referral sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send referral: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final doctor = authProvider.user!;
    final patient = ModalRoute.of(context)!.settings.arguments as UserModel;

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
            _buildHeader(context, patient),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSpecialistSelector(),
                      const SizedBox(height: 24),
                      _buildPrioritySelector(),
                      const SizedBox(height: 24),
                      _buildReasonField(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(doctor.uid, patient.uid),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserModel patient) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
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
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Refer Patient: ${patient.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialistSelector() {
    return StreamBuilder<List<UserModel>>(
      stream: _doctorService.getDoctors(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final specialists = snapshot.data!.where((user) => user.role == 'specialist').toList();
        return DropdownButtonFormField<String>(
          value: _selectedSpecialistId,
          hint: const Text('Select a Specialist'),
          decoration: const InputDecoration(labelText: 'To Specialist'),
          items: specialists.map((specialist) {
            return DropdownMenuItem(
              value: specialist.uid,
              child: Text('${specialist.name} - ${specialist.specialty ?? 'Specialist'}'),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedSpecialistId = value),
          validator: (value) => value == null ? 'Please select a specialist' : null,
        );
      },
    );
  }

  Widget _buildPrioritySelector() {
    return DropdownButtonFormField<String>(
      value: _priority,
      decoration: const InputDecoration(labelText: 'Priority'),
      items: const [
        DropdownMenuItem(value: 'High', child: Text('High')),
        DropdownMenuItem(value: 'Medium', child: Text('Medium')),
        DropdownMenuItem(value: 'Low', child: Text('Low')),
      ],
      onChanged: (value) => setState(() => _priority = value!),
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      decoration: const InputDecoration(
        labelText: 'Reason for Referral',
        hintText: 'Enter clinical details...',
      ),
      maxLines: 5,
      validator: (value) => (value == null || value.isEmpty) ? 'Please provide a reason' : null,
    );
  }

  Widget _buildSubmitButton(String fromDoctorId, String patientId) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: () => _sendReferral(fromDoctorId, patientId),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send Referral'),
          );
  }
}
