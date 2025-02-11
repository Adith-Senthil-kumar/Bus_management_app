import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'dart:typed_data';

class HomePage extends StatelessWidget {
  // Function to get the assignedBusId from the logged-in user's students document
  Future<String> getAssignedBusIdForLoggedInUser() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return "No user logged in.";
    }

    final userEmail = user.email;

    if (userEmail == null) {
      return "No email associated with logged-in user.";
    }

    try {
      // Query the students collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('email', isEqualTo: userEmail)
          .get();

      // Check if the document exists and fetch the assignedBusId
      if (querySnapshot.docs.isNotEmpty) {
        var studentDoc = querySnapshot.docs.first;
        var assignedBusId = studentDoc['assignedBusId'];

        if (assignedBusId != null) {
          return assignedBusId; // Return the assigned bus ID
        } else {
          return "No assigned bus found for this user.";
        }
      } else {
        return "No document found for the given email.";
      }
    } catch (e) {
      return "Error fetching document: $e";
    }
  }

  // Function to fetch the assigned bus details from the assignedbus collection

  Future<Map<String, dynamic>> getAssignedBusDetails(
    String assignedBusId) async {
  try {
    // Query the assignedbus collection using the assignedBusId
    DocumentSnapshot busDoc = await FirebaseFirestore.instance
        .collection('assignedbus')
        .doc(assignedBusId)
        .get();

    if (busDoc.exists) {
      var data = busDoc.data() as Map<String, dynamic>;

      // Decode the base64 image string for the profile picture
      Uint8List? profilePicBytes;
      if (data['profilePic'] != null) {
        profilePicBytes = base64Decode(data['profilePic']);
      }

      // Fetch driverId from assigned bus
      String driverId = data['driverId'];

      // Query the drivers collection to get the driver details using driverId
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .get();

      if (driverDoc.exists) {
        var driverData = driverDoc.data() as Map<String, dynamic>;

        // Now, query the landmark collection to match the driverEmail
        String driverEmail = driverData['driverEmail'];
        QuerySnapshot landmarkQuery = await FirebaseFirestore.instance
            .collection('landmark')
            .where('email', isEqualTo: driverEmail) // Matching email from landmark
            .get();

        if (landmarkQuery.docs.isNotEmpty) {
          var landmarkData = landmarkQuery.docs.first.data() as Map<String, dynamic>;

          // Decode the base64 landmark picture string
          Uint8List? landmarkPictureBytes;
          if (landmarkData['landmark_picture'] != null) {
            landmarkPictureBytes = base64Decode(landmarkData['landmark_picture']);
          }

          return {
            'busNumber': data['busNumber'],
            'capacity': data['capacity'],
            'routeName': data['routeName'],
            'stops': data['stops'],
            'driverName': driverData['driverName'],  // Driver name from drivers collection
            'driverPhone': driverData['driverPhone'],  // Driver phone from drivers collection
            'driverEmail': driverData['driverEmail'],  // Driver email from drivers collection
            'landmarkEmail': landmarkData['email'],  // Email from landmark collection
            'landmark': landmarkData['landmark'],  // Landmark from landmark collection
            'landmark_picture': landmarkPictureBytes,  // Decoded landmark picture
            'profilePic': profilePicBytes,
            'driverId': driverId,
          };
        } else {
          throw "No matching landmark data found for the driverEmail.";
        }
      } else {
        throw "No driver details found for the given driverId.";
      }
    } else {
      throw "No bus details found for the given assignedBusId.";
    }
  } catch (e) {
    throw "Error fetching bus details: $e";
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Align(
          alignment: Alignment.center, // Center the title
          child: Text(
            'Assigned Bus Details',
            style: TextStyle(
                color: Colors.black), // Set text color to black for contrast
          ),
        ),
        backgroundColor: Colors.white, // Set the background color to white
        elevation: 0, // Remove shadow/elevation effect to keep it flat
        iconTheme: IconThemeData(
            color: Colors.black), // Set the icon color to black if needed
      ),
      body: FutureBuilder<String>(
        future: getAssignedBusIdForLoggedInUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            if (snapshot.data == "No user logged in." ||
                snapshot.data == "No document found for the given email." ||
                snapshot.data == "No assigned bus found for this user.") {
              return Center(child: Text(snapshot.data!));
            }

            // Use the fetched assignedBusId to fetch bus details
            return FutureBuilder<Map<String, dynamic>>(
              future: getAssignedBusDetails(snapshot.data!),
              builder: (context, busSnapshot) {
                if (busSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (busSnapshot.hasError) {
                  return Center(child: Text('Error: ${busSnapshot.error}'));
                } else if (busSnapshot.hasData) {
                  // Extract bus details and display them in a styled box
                  var busDetails = busSnapshot.data!;
                  return ListView(
                    children: [
                      // Display bus details in a two-column format
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // First container (busNumber and capacity)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50, // Blue background
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue, // Blue border color
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bus Number',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    busDetails['busNumber'].toString(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Second container (capacity)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Capacity',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    busDetails['capacity'].toString(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Third container (routeName)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Route Name',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    busDetails['routeName'].toString(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Fourth container (driverName)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Driver Name',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    busDetails['driverName'].toString(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Fifth container (stops)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Stops',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    busDetails['stops'].toString(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Sixth container (driverPhone)
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Driver Phone',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade900),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    busDetails['driverPhone'].toString(),
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Profile picture container
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Driver Profile Picture',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  if (busDetails['profilePic'] != null)
                                    Image.memory(
                                      busDetails['profilePic'],
                                      height: 100, // Adjust the size as needed
                                      width: 100,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    Text(
                                      'No picture available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Profile picture container
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.all(10),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    busDetails['landmark'].toString(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  if (busDetails['landmark_picture'] != null)
                                    Image.memory(
                                      busDetails['landmark_picture'],
                                     
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    Text(
                                      'No picture available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                     
                    ],
                  );
                } else {
                  return Center(child: Text('No assigned bus found.'));
                }
              },
            );
          } else {
            return Center(child: Text('No data found.'));
          }
        },
      ),
    );
  }
}
