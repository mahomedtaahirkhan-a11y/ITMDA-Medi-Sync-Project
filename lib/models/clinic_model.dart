import 'package:cloud_firestore/cloud_firestore.dart';

class ClinicModel {
  final String id;
  final String name;
  final String address;

  ClinicModel({
    required this.id,
    required this.name,
    required this.address,
  });

  factory ClinicModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Handle potential null data

    return ClinicModel(
      id: doc.id,
      name: data?['name'] ?? 'Unknown Clinic',
      address: data?['address'] ?? 'No Address',
    );
  }
}
