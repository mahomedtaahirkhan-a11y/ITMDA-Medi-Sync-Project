import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medisync/models/referral_model.dart';
import 'package:medisync/models/user_model.dart';

class ReferralService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _referralsCollection = FirebaseFirestore.instance.collection('referrals');
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  /// Creates a new referral in Firestore.
  Future<void> createReferral({
    required String patientId,
    required String fromDoctorId,
    required String toSpecialistId,
    required String reason,
    required String priority,
  }) async {
    await _referralsCollection.add({
      'patientId': patientId,
      'fromDoctorId': fromDoctorId,
      'toSpecialistId': toSpecialistId,
      'reason': reason,
      'priority': priority,
      'status': 'pending', // Referrals are always pending when created.
      'createdAt': FieldValue.serverTimestamp(),
    });
    // In a production app, you would also trigger a notification here.
  }

  /// Updates the status of an existing referral.
  Future<void> updateReferralStatus(String referralId, String newStatus) async {
    await _referralsCollection.doc(referralId).update({'status': newStatus});
    // In a production app, you would also trigger a notification here.
  }

  /// Fetches a stream of referrals for a given patient, specified by status.
  Stream<List<Map<String, dynamic>>> getPatientReferrals(String patientId, String status) {
    return _referralsCollection
        .where('patientId', isEqualTo: patientId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap(_processReferralList);
  }

  /// Fetches a stream of referrals for a given specialist, specified by status.
  Stream<List<Map<String, dynamic>>> getSpecialistReferrals(String specialistId, String status) {
    return _referralsCollection
        .where('toSpecialistId', isEqualTo: specialistId)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap(_processReferralList);
  }

  /// Helper function to process a snapshot of referrals and fetch related details.
  Future<List<Map<String, dynamic>>> _processReferralList(QuerySnapshot snapshot) async {
    final referrals = snapshot.docs.map((doc) => ReferralModel.fromFirestore(doc)).toList();
    final detailedReferrals = <Map<String, dynamic>>[];

    for (var referral in referrals) {
      try {
        final details = await _getReferralDetails(referral);
        detailedReferrals.add(details);
      } catch (e) {
        print('Error processing referral ${referral.id}: $e');
      }
    }
    return detailedReferrals;
  }

  /// Fetches the full details for a single referral, including related user names.
  Future<Map<String, dynamic>> _getReferralDetails(ReferralModel referral) async {
    // Fetch the referring doctor's details.
    final fromDoctorDoc = await _usersCollection.doc(referral.fromDoctorId).get();
    final fromDoctorName = fromDoctorDoc.exists ? (fromDoctorDoc.data() as Map<String, dynamic>)['name'] : 'Unknown Doctor';

    // Fetch the specialist's details.
    final toSpecialistDoc = await _usersCollection.doc(referral.toSpecialistId).get();
    final toSpecialistName = toSpecialistDoc.exists ? (toSpecialistDoc.data() as Map<String, dynamic>)['name'] : 'Unknown Specialist';

    // Fetch the patient's details.
    final patientDoc = await _usersCollection.doc(referral.patientId).get();
    final patientName = patientDoc.exists ? (patientDoc.data() as Map<String, dynamic>)['name'] : 'Unknown Patient';

    return {
      'referral': referral,
      'fromDoctorName': fromDoctorName,
      'toSpecialistName': toSpecialistName,
      'patientName': patientName,
    };
  }
}
