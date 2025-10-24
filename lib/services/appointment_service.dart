import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medisync/models/appointment_model.dart';
import 'package:medisync/models/user_model.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _appointmentsCollection = FirebaseFirestore.instance.collection('appointments');

  /// Creates a new appointment without a clinicId.
  Future<void> createAppointment({
    required String patientId,
    required String doctorId,
    required DateTime dateTime,
    required String reason,
  }) async {
    await _appointmentsCollection.add({
      'patientId': patientId,
      'doctorId': doctorId,
      'dateTime': Timestamp.fromDate(dateTime),
      'reason': reason,
      'status': 'scheduled',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getPatientAppointments(
    String patientId,
    String status,
  ) {
    Query query = _appointmentsCollection
        .where('patientId', isEqualTo: patientId)
        .where('status', isEqualTo: status);

    if (status == 'scheduled') {
      query = query.orderBy('dateTime', descending: false);
    } else {
      query = query.orderBy('dateTime', descending: true);
    }

    return query.snapshots().asyncMap((snapshot) async {
      final appointments = snapshot.docs.map((doc) => AppointmentModel.fromFirestore(doc)).toList();
      final detailedAppointments = <Map<String, dynamic>>[];

      for (var apt in appointments) {
        try {
          final details = await getAppointmentDetails(apt);
          detailedAppointments.add(details);
        } catch (e) {
          print('Error fetching details for appointment ${apt.id}: $e');
        }
      }
      
      return detailedAppointments;
    });
  }

  Future<Map<String, dynamic>> getAppointmentDetails(AppointmentModel appointment) async {
    final doctorDoc = await _usersCollection.doc(appointment.doctorId).get();
    if (!doctorDoc.exists) {
      throw Exception('Doctor not found for ID: ${appointment.doctorId}');
    }
    final doctor = UserModel.fromFirestore(doctorDoc.data() as Map<String, dynamic>, doctorDoc.id);

    return {
      'appointment': appointment,
      'doctorName': doctor.name,
      'doctorSpecialty': doctor.specialty ?? 'General Practice',
    };
  }
}
