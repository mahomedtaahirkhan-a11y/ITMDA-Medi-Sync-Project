import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a referral document in the Firestore database.
class ReferralModel {
  final String id;
  final String fromDoctorId;
  final String toSpecialistId;
  final String patientId;
  final String reason;
  final String priority;
  final String status;
  final DateTime createdAt;

  ReferralModel({
    required this.id,
    required this.fromDoctorId,
    required this.toSpecialistId,
    required this.patientId,
    required this.reason,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  /// Creates a ReferralModel from a Firestore document snapshot.
  factory ReferralModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReferralModel(
      id: doc.id,
      fromDoctorId: data['fromDoctorId'] ?? '',
      toSpecialistId: data['toSpecialistId'] ?? '',
      patientId: data['patientId'] ?? '',
      reason: data['reason'] ?? 'No reason provided.',
      priority: data['priority'] ?? 'Medium',
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  /// Converts a ReferralModel instance to a map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'fromDoctorId': fromDoctorId,
      'toSpecialistId': toSpecialistId,
      'patientId': patientId,
      'reason': reason,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
