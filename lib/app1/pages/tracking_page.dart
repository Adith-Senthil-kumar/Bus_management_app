import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class TrackingPage extends StatefulWidget {
  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  // Default to a reasonable location until we get real data
  LatLng driverLocation = LatLng(0, 0);
  bool isMapReady = false;

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  @override
  void initState() {
    super.initState();
    // To ensure we have a default location for the map
    isMapReady = true;
  }

  void _focusOnPin() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: driverLocation,
        zoom: 17.0, // Adjust for closer or wider zoom
      ),
    ));
  }

  // Stream to listen for real-time updates to the driver's location
  Stream<DocumentSnapshot> _getDriverLocationStream(String driverId) {
    return FirebaseFirestore.instance
        .collection('drivers')
        .doc(driverId)
        .snapshots();
  }

  // Fetch assigned bus details and listen for updates to the driver's location
  Future<void> _fetchAssignedBusDetails(
      String busId, BuildContext context) async {
    try {
      // Fetch the bus details directly from the assignedbus collection
      DocumentSnapshot busSnapshot = await FirebaseFirestore.instance
          .collection('assignedbus')
          .doc(busId)
          .get();

      if (busSnapshot.exists) {
        var busData = busSnapshot.data() as Map<String, dynamic>;
        String driverId = busData['driverId'] ?? "No driver assigned";
        print('Bus Details: ${busData['busDetails']}');
        print('Driver ID: $driverId');

        if (driverId != null &&
            driverId.isNotEmpty &&
            driverId != "No driver assigned") {
          // Listen to the driver's location updates in real-time
          _getDriverLocationStream(driverId).listen((driverSnapshot) {
            if (driverSnapshot.exists) {
              var driverData = driverSnapshot.data() as Map<String, dynamic>;
              GeoPoint? location = driverData['location'];
              if (location != null) {
                setState(() {
                  driverLocation =
                      LatLng(location.latitude, location.longitude);
                  // Call _focusOnPin to center the map on the new location
                  _focusOnPin();
                });
              }
            }
          });
        } else {
          // Show a snackbar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No driver assigned to this bus.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error fetching bus details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading driver location: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gradient definition
    final gradient = LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFF3764A7), // Gradient Color 1
        Color(0xFF28497B), // Gradient Color 2
        Color(0xFF152741), // Gradient Color 3
      ],
      stops: [0.36, 0.69, 1.0],
    );

    return WillPopScope(
      onWillPop: () async {
        context.read<NavigationBloc>().add(NavigateToHome());
        Navigator.pop(context); // Remove this page from the navigation stack
        return Future.value(false); // Prevent the default back action
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Make the AppBar transparent
          elevation: 0, // Remove shadow
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: gradient, // Apply gradient to the AppBar
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white), // Back button
            onPressed: () {
              // Handle back navigation
              context.read<NavigationBloc>().add(NavigateToHome());
              Navigator.pop(
                  context); // Remove this page from the navigation stack
            },
          ),
          title: Text(
            'Live Tracking',
            style: TextStyle(
              color: Colors.white, // Set the title color to white
              fontWeight: FontWeight.bold, // Optional: Make the title bold
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Map Section - Give it a fixed height or flexible fraction
            Container(
              height: MediaQuery.of(context).size.height *
                  0.5, // 50% of screen height
              child: Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: CameraPosition(
                      target: driverLocation,
                      zoom: 16.0,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    markers: {
                      Marker(
                        markerId: MarkerId('driver'),
                        position: driverLocation,
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueBlue),
                      ),
                    },
                  ),
                  // Correctly positioned button inside the Stack
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: FloatingActionButton(
                      onPressed: _focusOnPin,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.my_location, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Bus List Section
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('assignedbus')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No buses available'));
                  }

                  var documents = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      var doc = documents[index];
                      String busId = doc.id; // Getting the document ID (bus ID)

                      return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue[50], // Light blue background
                            border: Border.all(
                                color: Colors.blue, width: 2), // Blue border
                            borderRadius:
                                BorderRadius.circular(10), // Rounded corners
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            title: Text(
                              'Bus Number: ${doc['busNumber'] ?? "Unknown"}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800]),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    'Driver Name: ${doc['driverName'] ?? "Not assigned"}'),
                                Text(
                                    'Route Name: ${doc['routeName'] ?? "No route"}'),
                              ],
                            ),
                            trailing: ElevatedButton.icon(
                              icon: Icon(
                                Icons.location_on,
                                color: Colors.white,
                              ),
                              label: Text('Track'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () {
                                _fetchAssignedBusDetails(busId, context);
                                // Show a snackbar to inform the user
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Tracking bus ${doc['busNumber'] ?? "Unknown"}'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
