import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:busbuddy/app1/blocs/navigation_bloc.dart';
import 'package:busbuddy/app1/blocs/navigation_event.dart';
import 'package:flutter_map/flutter_map.dart'; // Import FlutterMap
import 'package:latlong2/latlong.dart'; // Import for LatLng

class TrackingPage extends StatefulWidget {
  @override
  _TrackingPageState createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  MapController mapController = MapController();
  List<Marker> _markers = [];
  LatLng? driverLocation;

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

        if (driverId.isNotEmpty) {
          // Listen to the driver's location updates in real-time
          _getDriverLocationStream(driverId).listen((driverSnapshot) {
            if (driverSnapshot.exists) {
              var driverData = driverSnapshot.data() as Map<String, dynamic>;
              GeoPoint? location = driverData['location'];
              if (location != null) {
                setState(() {
                  driverLocation =
                      LatLng(location.latitude, location.longitude);
                });

                // Animate the map to the new location
                mapController.move(driverLocation!, 18.0);
              }
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching bus details: $e');
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
          title: Center(
            child: Padding(
              padding: EdgeInsets.only(right: 20.0), // Add padding to the right
              child: Text(
                'Live Tracking',
                style: TextStyle(
                  color: Colors.white, // Set the title color to white
                  fontWeight: FontWeight.bold, // Optional: Make the title bold
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // Map Section
            Expanded(
              child: FlutterMap(
                mapController: mapController, // Pass the map controller here
                options: MapOptions(
                  initialCenter:
                      driverLocation ?? LatLng(0.0, 0.0), // Fallback if null
                  initialZoom: 18.0, // Set zoom level
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains: ['a', 'b', 'c'],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: driverLocation ??
                            LatLng(0.0, 0.0), // Fallback if null
                        child: TweenAnimationBuilder<LatLng>(
                          tween: LatLngTween(
                              begin: LatLng(0.0, 0.0),
                              end: driverLocation ?? LatLng(0.0, 0.0)),
                          duration:
                              Duration(seconds: 3), // Duration of the animation
                          builder: (context, LatLng currentLatLng, child) {
                            return Icon(
                              Icons.location_on,
                              size: 40.0,
                              color: Colors.red,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // StreamBuilder to fetch data from Firestore
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
                    return Center(child: Text('No data available'));
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
                              'Bus Number: ${doc['busNumber']}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800]),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Driver Name: ${doc['driverName']}'),
                                Text('Route Name: ${doc['routeName']}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.location_on,
                                color: Colors
                                    .purple, // Purple color for the location icon
                              ),
                              onPressed: () {
                                _fetchAssignedBusDetails(busId,
                                    context); // Pass busId to fetch details
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
