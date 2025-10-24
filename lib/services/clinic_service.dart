import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medisync/models/clinic_model.dart';

class ClinicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _clinicsCollection = FirebaseFirestore.instance.collection('clinics');

  /// Fetches a stream of all clinics.
  Stream<List<ClinicModel>> getClinics() {
    return _clinicsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ClinicModel.fromFirestore(doc)).toList();
    });
  }
}
