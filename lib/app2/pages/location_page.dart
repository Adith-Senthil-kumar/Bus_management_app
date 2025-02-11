import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:busbuddy/app2/blocs/navigation_bloc.dart';
import 'package:busbuddy/app2/blocs/navigation_event.dart';
import 'package:busbuddy/app2/pages/live_page.dart'; // Ensure you import LivePage

class LocationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get the current user's email
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

          // Data is available, fetch assignedBusId
          final student = snapshot.data!.docs.first;
          final data = student.data() as Map<String, dynamic>;
          final assignedBusId = data['assignedBusId'] ?? 'Not assigned';

          // Now fetch the assigned bus details from the 'assignedbus' collection
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('assignedbus')
                .doc(assignedBusId)
                .get(),
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

              // Data from 'assignedbus' collection
              final busData = busSnapshot.data!.data() as Map<String, dynamic>;
              final stops = busData['stops'] ?? [];

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Bus Stops:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      stops.isEmpty
                          ? Text('No stops available.')
                          : Column(
                              children: stops.map<Widget>((stop) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0), // Increased vertical padding
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Circle with black border
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.transparent,
                                        child: CircleAvatar(
                                          radius: 10,
                                          backgroundColor: Colors.black,
                                        ),
                                      ),
                                      SizedBox(width: 16), // Space between the circle and text
                                      // Stop name displayed next to the circle
                                      Container(
                                        width: MediaQuery.of(context).size.width * 0.6,
                                        child: Center(
                                          child: Text(
                                            stop,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.center, // Center the text
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
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