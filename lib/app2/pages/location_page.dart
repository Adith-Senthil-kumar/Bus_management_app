import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:busbuddy/app2/pages/live_page.dart'; // Ensure you import LivePage

class LocationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'No user is logged in.',
            style: TextStyle(fontSize: 18, color: Colors.black),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: userEmail)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No details found for this user.'));
          }

          final student = snapshot.data!.docs.first;
          final data = student.data() as Map<String, dynamic>;
          final assignedBusId = data['assignedBusId'] ?? 'Not assigned';

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('assignedbus')
                .doc(assignedBusId)
                .snapshots(),
            builder: (context, busSnapshot) {
              if (busSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (busSnapshot.hasError) {
                return Center(child: Text('Error: ${busSnapshot.error}'));
              }
              if (!busSnapshot.hasData || !busSnapshot.data!.exists) {
                return Center(child: Text('No bus details found.'));
              }

              final busData = busSnapshot.data!.data() as Map<String, dynamic>;
              final driverEmail = busData['driverEmail'] ?? 'No driver assigned';

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('stops_status')
                    .where('driverEmail', isEqualTo: driverEmail)
                    .snapshots(),
                builder: (context, stopsStatusSnapshot) {
                  if (stopsStatusSnapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (stopsStatusSnapshot.hasError) {
                    return Center(child: Text('Error: ${stopsStatusSnapshot.error}'));
                  }
                  if (!stopsStatusSnapshot.hasData || stopsStatusSnapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No stops status found for this driver.'));
                  }

                  final stopsStatusDoc = stopsStatusSnapshot.data!.docs.first;
                  final stopsStatusData = stopsStatusDoc.data() as Map<String, dynamic>;

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      itemCount: stopsStatusData['stopsWithLocations'].length,
                      itemBuilder: (context, index) {
                        final stop = stopsStatusData['stopsWithLocations'][index];
                        String stopName = stop['name'] ?? 'Unknown Stop';
                        String status = stop['status'] ?? 'on the way';
                        Color statusColor;

                        switch (status) {
                          case 'reached':
                            statusColor = Colors.green;
                            break;
                          case 'next':
                            statusColor = Colors.yellow;
                            break;
                          default:
                            statusColor = Colors.blue;
                            status = 'on the way';
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Status Circle (Left)
                              Container(
                                width: 20,
                                height: 20,
                                margin: EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusColor,
                                ),
                              ),

                              // Stop Name and Status (Centered)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      stopName,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      
    
  

      // Floating Action Button with location icon
      floatingActionButton: Container(
        alignment: Alignment.bottomRight, // Control the position here
        padding: EdgeInsets.only(bottom: 80, right: 20), // Adjust padding for control
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to LivePage when button is pressed
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LivePage()), // Navigate to LivePage
            );
          },
          backgroundColor: const Color.fromRGBO(62, 142, 205, 1),
          child: Icon(
            Icons.location_on,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}