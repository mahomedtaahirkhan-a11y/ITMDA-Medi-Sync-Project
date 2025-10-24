import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medisync/models/user_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<int> getUserCount() async {
    final snapshot = await _firestore.collection('users').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getActiveQueueCount() async {
    final snapshot = await _firestore.collection('queues').where('status', isEqualTo: 'waiting').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getReferralCount() async {
    final snapshot = await _firestore.collection('referrals').where('status', isEqualTo: 'pending').count().get();
    return snapshot.count ?? 0;
  }

  Future<int> getAppointmentsTodayCount() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    final snapshot = await _firestore
        .collection('appointments')
        .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
        .where('dateTime', isLessThan: Timestamp.fromDate(endOfToday))
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<Map<String, int>> getUserDistribution() async {
    final snapshot = await _firestore.collection('users').get();
    final distribution = <String, int>{
      'patient': 0,
      'doctor': 0,
      'specialist': 0,
      'admin': 0,
    };

    for (var doc in snapshot.docs) {
      final role = doc.data()['role'] as String? ?? 'patient';
      distribution.update(role, (value) => value + 1, ifAbsent: () => 1);
    }
    return distribution;
  }

  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromFirestore(data, doc.id);
      }).toList();
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}
