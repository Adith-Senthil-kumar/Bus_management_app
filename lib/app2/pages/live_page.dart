import 'package:busbuddy/app2/blocs/navigation_event.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  LatLng? driverLocation;
  MapController mapController = MapController();  // Add MapController to control the map

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
          var studentData = studentSnapshot.docs.first.data() as Map<String, dynamic>;
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
                DocumentSnapshot driverSnapshot = await FirebaseFirestore.instance
                    .collection('drivers')
                    .doc(driverId)
                    .get();

                if (driverSnapshot.exists) {
                  var driverData = driverSnapshot.data() as Map<String, dynamic>;
                  GeoPoint? location = driverData['location'];
                  if (location != null) {
                    setState(() {
                      initialLocation = LatLng(location.latitude, location.longitude);
                      driverLocation = LatLng(location.latitude, location.longitude); // Initial location
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
                  .snapshots(),  // Listen for real-time updates
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.hasData) {
                  var driverData = snapshot.data!.data() as Map<String, dynamic>;
                  GeoPoint? location = driverData['location'];

                  if (location != null) {
                    LatLng newDriverLocation = LatLng(location.latitude, location.longitude);

                    // If the location has changed, update the driverLocation and map center
                    if (driverLocation != newDriverLocation) {
                      // Use addPostFrameCallback to ensure setState is called after build
                      WidgetsBinding.instance!.addPostFrameCallback((_) {
                        setState(() {
                          driverLocation = newDriverLocation;
                        });

                        // Update the map center to the new driver location
                        mapController.move(newDriverLocation, 18.0); // 18.0 is the zoom level
                      });
                    }
                  }
                }

                return FlutterMap(
                  mapController: mapController,  // Pass the map controller here
                  options: MapOptions(
                    initialCenter: driverLocation ?? LatLng(0.0, 0.0),  // Fallback if null
                    initialZoom: 18.0,  // Set zoom level
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: driverLocation ?? LatLng(0.0, 0.0),  // Fallback if null
                          child: TweenAnimationBuilder<LatLng>(
                            tween: LatLngTween(
                                begin: initialLocation ?? LatLng(0.0, 0.0),
                                end: driverLocation ?? LatLng(0.0, 0.0)),
                            duration: Duration(seconds: 3), // Duration of the animation
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
                );
              },
            ),
    );
  }
}

