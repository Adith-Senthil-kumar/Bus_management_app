import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Add student to Firestore
  Future<void> addStudent({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String rollNo,
    required String department,
    required String yearOfStudy,
    required String address,
    String? assignedBusId, // Optional assigned bus field
  }) async {
    try {
      await _db.collection('students').add({
        'user_id': _db.doc('users/$userId'),
        'name': name,
        'email': email,
        'phone': phone,
        'roll_no': rollNo,
        'department': department,
        'year_of_study': yearOfStudy,
        'address': address,
        'assignedBusId': assignedBusId ?? '', // Default to empty if not provided
      });
    } catch (e) {
      print('Error adding student: $e');
      rethrow;
    }
  }

  // Fetch all students
  Stream<List<Map<String, dynamic>>> getStudents() {
    return _db.collection('students').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Include document ID for future operations
        return data;
      }).toList();
    });
  }

  // Update student
  Future<void> updateStudent(String studentId, Map<String, dynamic> updatedData) async {
    try {
      await _db.collection('students').doc(studentId).update(updatedData);
    } catch (e) {
      print('Error updating student: $e');
      rethrow;
    }
  }

  // Delete student
  Future<void> deleteStudent(String studentId) async {
    try {
      await _db.collection('students').doc(studentId).delete();
    } catch (e) {
      print('Error deleting student: $e');
      rethrow;
    }
  }

  // Assign a bus to a student
  Future<void> assignBusToStudent(String studentId, String busId) async {
    try {
      await _db.collection('students').doc(studentId).update({
        'assignedBusId': busId,
      });
    } catch (e) {
      print('Error assigning bus: $e');
      rethrow;
    }
  }
}