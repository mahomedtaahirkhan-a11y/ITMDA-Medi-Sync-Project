import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medisync/models/queue_status_model.dart';
import 'package:medisync/models/user_model.dart';

class QueueService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _queuesCollection = FirebaseFirestore.instance.collection('queues');

  /// Checks a patient into a doctor's queue.
  Future<void> checkIn(String patientId, String doctorId) async {
    final existingEntry = await _queuesCollection
        .where('patientId', isEqualTo: patientId)
        .where('status', isEqualTo: 'waiting')
        .limit(1)
        .get();

    if (existingEntry.docs.isNotEmpty) {
      throw Exception('You are already checked in to a queue.');
    }

    await _queuesCollection.add({
      'patientId': patientId,
      'doctorId': doctorId,
      'entryTime': FieldValue.serverTimestamp(),
      'status': 'waiting',
    });
  }

  /// Cancels a patient's check-in by deleting their queue entry.
  Future<void> cancelCheckIn(String queueId) async {
    await _queuesCollection.doc(queueId).delete();
  }

  /// Calls the next patient, updating their status and adding a completion timestamp.
  Future<void> callNextPatient(String doctorId) async {
    final querySnapshot = await _queuesCollection
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'waiting')
        .orderBy('entryTime')
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final patientDocId = querySnapshot.docs.first.id;
      await _queuesCollection.doc(patientDocId).update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Gets the patient's current queue status as a QueueStatusModel.
  Stream<QueueStatusModel?> getPatientQueueStatus(String patientId) {
    return _queuesCollection
        .where('status', isEqualTo: 'waiting')
        .orderBy('entryTime')
        .snapshots()
        .map((snapshot) {
      final allWaitingDocs = snapshot.docs;
      final patientDocIndex = allWaitingDocs.indexWhere((doc) => doc['patientId'] == patientId);

      if (patientDocIndex == -1) {
        return null; // Patient is not in the queue.
      }

      final patientDoc = allWaitingDocs[patientDocIndex];
      const averageConsultationTime = 15; // Assume 15 minutes per patient.

      return QueueStatusModel(
        queueId: patientDoc.id,
        position: patientDocIndex + 1,
        estimatedWaitMinutes: patientDocIndex * averageConsultationTime,
      );
    });
  }

  /// Gets the list of patients currently waiting in a doctor's queue.
  Stream<List<UserModel>> getDoctorQueue(String doctorId) {
    return _queuesCollection
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'waiting')
        .orderBy('entryTime')
        .snapshots()
        .asyncMap((snapshot) async {
      final patientIds = snapshot.docs.map((doc) => doc['patientId'] as String).toList();
      
      if (patientIds.isEmpty) {
        return [];
      }

      final usersSnapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: patientIds).get();
      final patients = usersSnapshot.docs.map((doc) => UserModel.fromFirestore(doc.data(), doc.id)).toList();

      final orderedPatients = patientIds
          .map((id) => patients.firstWhere((p) => p.uid == id, orElse: () => UserModel.fromFirestore({}, 'missing')))
          .where((p) => p.uid != 'missing')
          .toList();

      return orderedPatients;
    });
  }

  /// Gets the list of patients a doctor has already seen (completed).
  Stream<List<UserModel>> getSeenPatients(String doctorId) {
    return _queuesCollection
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'completed')
        .orderBy('completedAt', descending: true)
        .limit(20) // Limit to the 20 most recent patients
        .snapshots()
        .asyncMap((snapshot) async {
      final patientIds = snapshot.docs.map((doc) => doc['patientId'] as String).toList();

      if (patientIds.isEmpty) {
        return [];
      }

      final usersSnapshot = await _firestore.collection('users').where(FieldPath.documentId, whereIn: patientIds).get();
      final patients = usersSnapshot.docs.map((doc) => UserModel.fromFirestore(doc.data(), doc.id)).toList();
      
      final orderedPatients = patientIds
          .map((id) => patients.firstWhere((p) => p.uid == id, orElse: () => UserModel.fromFirestore({}, 'missing')))
          .where((p) => p.uid != 'missing')
          .toList();

      return orderedPatients;
    });
  }
}
