import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Save User Profile
  Future<void> saveUserProfile(String uid, String firstName, String lastName,
      String email, String regNumber) async {
    await _db.collection('users').doc(uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'registrationNumber': regNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get User Profile
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // Get User Profile as a stream (real-time)
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  // Log Attendance with exact location and place name
  Future<void> logAttendance(
    String uid,
    String status, {
    double? latitude,
    double? longitude,
    String? placeName,
  }) async {
    await _db.collection('attendance_logs').add({
      'uid': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'placeName': placeName,
    });
  }

  // Get Attendance Reports for a specific user
  // Note: ordering is done client-side to avoid requiring a composite index.
  Stream<QuerySnapshot> getAttendanceReports(String uid) {
    return _db
        .collection('attendance_logs')
        .where('uid', isEqualTo: uid)
        .snapshots();
  }

  // Get attendance count summary for a user
  Future<Map<String, int>> getAttendanceSummary(String uid) async {
    final snapshot = await _db
        .collection('attendance_logs')
        .where('uid', isEqualTo: uid)
        .get();

    int present = 0;
    int failed = 0;
    int total = snapshot.docs.length;

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'Present') {
        present++;
      } else {
        failed++;
      }
    }

    return {
      'total': total,
      'present': present,
      'failed': failed,
    };
  }
}
