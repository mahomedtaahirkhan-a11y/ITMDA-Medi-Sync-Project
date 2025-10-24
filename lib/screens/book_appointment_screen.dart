import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medisync/models/user_model.dart';
import 'package:medisync/providers/auth_provider.dart';
import 'package:medisync/services/appointment_service.dart';
import 'package:medisync/services/doctor_service.dart';
import 'package:provider/provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final DoctorService _doctorService = DoctorService();
  final AppointmentService _appointmentService = AppointmentService();

  String? _selectedDoctorId;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E3A8A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
       builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E3A8A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedTime != null && pickedTime != _selectedTime) {
      setState(() {
        _selectedTime = pickedTime;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date and time.')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final patientId = authProvider.user!.uid;

      final finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      try {
        await _appointmentService.createAppointment(
          patientId: patientId,
          doctorId: _selectedDoctorId!,
          dateTime: finalDateTime,
          reason: _reasonController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment booked successfully!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to book appointment: $e'), backgroundColor: Colors.red),
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
             crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildDoctorSelector(),
                        const SizedBox(height: 24),
                        _buildDateTimePicker(),
                        const SizedBox(height: 24),
                        _buildReasonField(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
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
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Text(
            'Book an Appointment',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorSelector() {
    return StreamBuilder<List<UserModel>>(
      stream: _doctorService.getDoctors(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final doctors = snapshot.data!;
        return DropdownButtonFormField<String>(
          value: _selectedDoctorId,
          hint: const Text('Select a Doctor'),
          decoration: InputDecoration(
            labelText: 'Doctor',
            labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: doctors.map((doctor) {
            return DropdownMenuItem(value: doctor.uid, child: Text(doctor.name));
          }).toList(),
          onChanged: (value) => setState(() => _selectedDoctorId = value),
          validator: (value) => value == null ? 'Please select a doctor' : null,
        );
      },
    );
  }

  Widget _buildDateTimePicker() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date',
                labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Text(
                _selectedDate != null ? DateFormat.yMMMd().format(_selectedDate!) : 'Select Date',
                style: const TextStyle(color: Color(0xFF1E3A8A)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: _pickTime,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Time',
                labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              child: Text(
                _selectedTime != null ? _selectedTime!.format(context) : 'Select Time',
                 style: const TextStyle(color: Color(0xFF1E3A8A)),
                ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      decoration: InputDecoration(
        labelText: 'Reason for Visit',
        hintText: 'Briefly describe your symptoms',
        labelStyle: const TextStyle(color: Color(0xFF1E3A8A)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      maxLines: 3,
      validator: (value) => (value == null || value.isEmpty) ? 'Please enter a reason' : null,
    );
  }

  Widget _buildSubmitButton() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )
            ),
            child: const Text('Book Appointment'),
          );
  }
}
