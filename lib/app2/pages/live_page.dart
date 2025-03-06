import 'dart:async';

import 'package:busbuddy/app2/blocs/navigation_event.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:provider/provider.dart';
import '../../app2/blocs/navigation_bloc.dart';
import '../../app2/blocs/navigation_event.dart';

class LivePage extends StatefulWidget {
  @override
  _LivePageState createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  String? busDetails;
  String? driverId;
  LatLng? initialLocation;
  LatLng driverLocation = LatLng(0, 0);

  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  void _focusOnPin() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: driverLocation,
        zoom: 17.0, // Adjust for closer or wider zoom
        
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    _fetchAssignedBusDetails();
  }

  // Fetch bus and driver details
  Future<void> _fetchAssignedBusDetails() async {
    try {
      String userEmail = FirebaseAuth.instance.currentUser?.email ?? "";

      if (userEmail.isNotEmpty) {
        QuerySnapshot studentSnapshot = await FirebaseFirestore.instance
            .collection('students')
            .where('email', isEqualTo: userEmail)
            .get();

        if (studentSnapshot.docs.isNotEmpty) {
          var studentData =
              studentSnapshot.docs.first.data() as Map<String, dynamic>;
          String assignedBusId = studentData['assignedBusId'] ?? "";

          if (assignedBusId.isNotEmpty) {
            DocumentSnapshot busSnapshot = await FirebaseFirestore.instance
                .collection('assignedbus')
                .doc(assignedBusId)
                .get();

            if (busSnapshot.exists) {
              var busData = busSnapshot.data() as Map<String, dynamic>;
              setState(() {
                busDetails = busData['busDetails'] ?? "No details available";
                driverId = busData['driverId'] ?? "No driver assigned";
              });

              if (driverId != null && driverId!.isNotEmpty) {
                DocumentSnapshot driverSnapshot = await FirebaseFirestore
                    .instance
                    .collection('drivers')
                    .doc(driverId)
                    .get();

                if (driverSnapshot.exists) {
                  var driverData =
                      driverSnapshot.data() as Map<String, dynamic>;
                  GeoPoint? location = driverData['location'];
                  if (location != null) {
                    setState(() {
                      initialLocation =
                          LatLng(location.latitude, location.longitude);
                      driverLocation = LatLng(location.latitude,
                          location.longitude); // Initial location
                    });
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      setState(() {
        busDetails = "Error fetching bus details";
        driverId = "Error fetching driver details";
      });
    }
  }

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(right: 55.0),
          child: Center(
            child: Text(
              'Location',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: gradient,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.read<NavigationBloc>().add(NavigateToLocation());
            Navigator.pop(context);
          },
        ),
      ),
      body: initialLocation == null
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('drivers')
                  .doc(driverId)
                  .snapshots(), // Listen for real-time updates
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.hasData) {
                  var driverData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  GeoPoint? location = driverData['location'];

                  if (location != null) {
                    LatLng newDriverLocation =
                        LatLng(location.latitude, location.longitude);

                    // If the location has changed, update the driverLocation and map center
                    if (driverLocation != newDriverLocation) {
                      // Use addPostFrameCallback to ensure setState is called after build
                      driverLocation = newDriverLocation;
                    }
                  }
                }
                return Stack(
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      },
    ),

    // Floating Button Positioned on Map
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
);
              },
            ),
    );
  }
}
