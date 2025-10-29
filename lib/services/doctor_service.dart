import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medisync/models/user_model.dart';

class DoctorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  /// Fetches a stream of all doctors.
  Stream<List<UserModel>> getDoctors() {
    return _usersCollection
        .where('role', isEqualTo: 'doctor') // Fetch only doctors
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
    });
  }

  /// Gets a stream of the total number of appointments scheduled for a doctor today.
  Stream<int> getTotalAppointmentsToday(String doctorId) {
    final now = DateTime.now();
    final startOfToday = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final endOfToday = Timestamp.fromDate(DateTime(now.year, now.month, now.day, 23, 59, 59));

    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('dateTime', isGreaterThanOrEqualTo: startOfToday)
        .where('dateTime', isLessThanOrEqualTo: endOfToday)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Gets a stream of the number of completed appointments for a doctor today.
  Stream<int> getCompletedAppointmentsToday(String doctorId) {
    final now = DateTime.now();
    final startOfToday = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final endOfToday = Timestamp.fromDate(DateTime(now.year, now.month, now.day, 23, 59, 59));

    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId)
        .where('status', isEqualTo: 'completed')
        .where('dateTime', isGreaterThanOrEqualTo: startOfToday)
        .where('dateTime', isLessThanOrEqualTo: endOfToday)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
