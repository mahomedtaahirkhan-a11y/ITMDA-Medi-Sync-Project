import 'package:cloud_firestore/cloud_firestore.dart';

class QueueModel {
  final String id;
  final String patientId;
  final String clinicId;
  final String doctorId;
  final int position;
  final String status;
  final DateTime checkInTime;
  final int estimatedWaitMinutes;
  final String? reason;

  QueueModel({
    required this.id,
    required this.patientId,
    required this.clinicId,
    required this.doctorId,
    required this.position,
    required this.status,
    required this.checkInTime,
    required this.estimatedWaitMinutes,
    this.reason,
  });

  factory QueueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Safe timestamp parsing
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is DateTime) {
        return timestamp;
      } else {
        return DateTime.now();
      }
    }

    return QueueModel(
      id: doc.id,
      patientId: data['patientId'] ?? '',
      clinicId: data['clinicId'] ?? '',
      doctorId: data['doctorId'] ?? '',
      position: data['position'] ?? 0,
      status: data['status'] ?? 'waiting',
      checkInTime: parseTimestamp(data['checkInTime']),
      estimatedWaitMinutes: data['estimatedWaitMinutes'] ?? 0,
      reason: data['reason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'patientId': patientId,
      'clinicId': clinicId,
      'doctorId': doctorId,
      'position': position,
      'status': status,
      'checkInTime': FieldValue.serverTimestamp(),
      'estimatedWaitMinutes': estimatedWaitMinutes,
      if (reason != null) 'reason': reason,
    };
  }

  // Helper method to get formatted wait time
  String get formattedWaitTime {
    if (estimatedWaitMinutes < 60) {
      return '$estimatedWaitMinutes min';
    } else {
      final hours = estimatedWaitMinutes ~/ 60;
      final minutes = estimatedWaitMinutes % 60;
      return minutes > 0 ? '$hours h $minutes min' : '$hours h';
    }
  }
}