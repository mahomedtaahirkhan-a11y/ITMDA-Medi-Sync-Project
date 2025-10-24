import 'package:cloud_firestore/cloud_firestore.dart';

class AppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime dateTime;
  final String status;
  final String? reason;
  final DateTime createdAt;

  AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.dateTime,
    required this.status,
    this.reason,
    required this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      } else {
        return DateTime.now();
      }
    }

    return AppointmentModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      dateTime: parseTimestamp(data['dateTime']),
      status: data['status'] ?? 'scheduled',
      reason: data['reason'],
      createdAt: parseTimestamp(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'patientId': patientId,
      'doctorId': doctorId,
      'dateTime': Timestamp.fromDate(dateTime),
      'status': status,
      if (reason != null) 'reason': reason,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
