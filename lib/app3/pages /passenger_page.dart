import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PassengerPage extends StatefulWidget {
  @override
  _PassengerPageState createState() => _PassengerPageState();
}

class _PassengerPageState extends State<PassengerPage> {
  // Get Driver ID from Firebase Authentication
  Future<String?> getDriverId() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      final String? email = user?.email;

      if (email == null) {
        throw Exception("User email is null");
      }

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('driverEmail', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id; // Return the driver document ID
      } else {
        throw Exception("No matching driver found");
      }
    } catch (e) {
      print("Error fetching driver ID: $e");
      return null;
    }
  }

  // Stream to get the assigned bus ID for the driver
  Stream<String?> getAssignedBusIdStream(String driverId) {
    return FirebaseFirestore.instance
        .collection('assignedbus')
        .where('driverId', isEqualTo: driverId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id; // Return the assigned bus ID
      } else {
        return null;
      }
    });
  }

  // Stream to fetch all students with the same assignedBusId as the driver
  Stream<List<Map<String, dynamic>>> getStudentsByAssignedBusStream(
      String assignedBusId) {
    return FirebaseFirestore.instance
        .collection('students')
        .where('assignedBusId', isEqualTo: assignedBusId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<String?>(
        future: getDriverId(),
        builder: (context, driverIdSnapshot) {
          if (driverIdSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (driverIdSnapshot.hasError) {
            return Center(child: Text('Error: ${driverIdSnapshot.error}'));
          } else if (!driverIdSnapshot.hasData ||
              driverIdSnapshot.data == null) {
            return const Center(child: Text('No driver ID found'));
          }

          final String driverId = driverIdSnapshot.data!;
          return StreamBuilder<String?>(
            stream: getAssignedBusIdStream(driverId),
            builder: (context, assignedBusIdSnapshot) {
              if (assignedBusIdSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (assignedBusIdSnapshot.hasError) {
                return Center(
                    child: Text('Error: ${assignedBusIdSnapshot.error}'));
              } else if (!assignedBusIdSnapshot.hasData ||
                  assignedBusIdSnapshot.data == null) {
                return const Center(child: Text('No assigned bus ID found'));
              }

              final String assignedBusId = assignedBusIdSnapshot.data!;
              return StreamBuilder<List<Map<String, dynamic>>>(
                stream: getStudentsByAssignedBusStream(assignedBusId),
                builder: (context, studentsSnapshot) {
                  if (studentsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (studentsSnapshot.hasError) {
                    return Center(
                        child: Text('Error: ${studentsSnapshot.error}'));
                  } else if (!studentsSnapshot.hasData ||
                      studentsSnapshot.data!.isEmpty) {
                    return const Center(child: Text('No students found'));
                  }

                  final List<Map<String, dynamic>> students =
                      studentsSnapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final studentName = student['name'] ?? 'N/A';
                      final bool isPresent = student['present'] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 4.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            isPresent ? 'Present' : 'Absent',
                            style: TextStyle(
                              color: isPresent ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}