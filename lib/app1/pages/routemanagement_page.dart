import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class RoutemanagementPage extends StatefulWidget {
  @override
  _RoutemanagementPageState createState() => _RoutemanagementPageState();
}

class _RoutemanagementPageState extends State<RoutemanagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers for text fields
  final TextEditingController routeNameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  // Lists to store stop controllers and location data
  List<TextEditingController> stopControllers = [];
  List<GeoPoint?> stopLocations = []; // Store location data as GeoPoints
  List<String> locationNames = []; // Store human-readable location names

  // Method to fetch route details from Firestore with search filtering
  Stream<QuerySnapshot> _fetchRouteDetails() {
    if (searchQuery.isEmpty) {
      return _firestore.collection('routes').snapshots(); // No filter
    } else {
      return _firestore.collection('routes')
          .where('routeName', isGreaterThanOrEqualTo: searchQuery)
          .where('routeName', isLessThanOrEqualTo: searchQuery + '\uf8ff')
          .snapshots();
    }
  }

  // Method to add or update route details in Firestore
  Future<void> _addOrUpdateRoute({String? documentId}) async {
    // Create a list of stop data with both name and location
    List<Map<String, dynamic>> stopsWithLocations = [];
    
    for (int i = 0; i < stopControllers.length; i++) {
      if (stopControllers[i].text.isNotEmpty) {
        Map<String, dynamic> stopData = {
          'name': stopControllers[i].text,
        };
        
        // Add location if available
        if (i < stopLocations.length && stopLocations[i] != null) {
          stopData['location'] = stopLocations[i];
          
          // Add location name if available
          if (i < locationNames.length && locationNames[i].isNotEmpty) {
            stopData['locationName'] = locationNames[i];
          }
        }
        
        stopsWithLocations.add(stopData);
      }
    }
    
    final Map<String, dynamic> routeData = {
      'routeName': routeNameController.text,
      'stopsWithLocations': stopsWithLocations,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (documentId == null) {
        // Add new route
        await _firestore.collection('routes').add(routeData);
      } else {
        // Update existing route
        await _firestore.collection('routes').doc(documentId).update(routeData);
      }
      print('Route details successfully added/updated');
    } catch (e) {
      print('Error adding/updating route: $e');
    }
  }

  // Method to delete a route detail
  Future<void> _deleteRoute(String documentId) async {
    try {
      await _firestore.collection('routes').doc(documentId).delete();
      print('Route successfully deleted');
    } catch (e) {
      print('Error deleting route: $e');
    }
  }

  /// First, let's modify the _openGoogleMapsSelection method

void _openGoogleMapsSelection(int stopIndex) async {
  // Check if a location is already selected, use it as starting point
  double initialLat = 0.0;
  double initialLng = 0.0;
  
  // Try to get current position if no location is selected
  if (stopIndex >= stopLocations.length || stopLocations[stopIndex] == null) {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition();
        initialLat = position.latitude;
        initialLng = position.longitude;
      }
    } catch (e) {
      print('Error getting current location: $e');
      // Use default coordinates if couldn't get current location
    }
  } else {
    // Use existing location
    initialLat = stopLocations[stopIndex]!.latitude;
    initialLng = stopLocations[stopIndex]!.longitude;
  }

  // Show the map dialog with the initial location
  _showMapDialog(stopIndex, initialLat, initialLng);
}

// Add this new method to show the map dialog
void _showMapDialog(int stopIndex, double initialLat, double initialLng) {
  GoogleMapController? mapController;
  LatLng selectedLocation = LatLng(initialLat, initialLng);
  final TextEditingController locationNameController = TextEditingController();
  
  // Pre-fill with existing location name if available
  if (stopIndex < locationNames.length && locationNames[stopIndex].isNotEmpty) {
    locationNameController.text = locationNames[stopIndex];
  }
  
  // Create a marker at the initial location
  Set<Marker> markers = {
    Marker(
      markerId: MarkerId('selectedLocation'),
      position: selectedLocation,
      draggable: true,
      onDragEnd: (newPosition) {
        selectedLocation = newPosition;
      },
    ),
  };

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Select Location'),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(initialLat, initialLng),
                        zoom: 15,
                      ),
                      markers: markers,
                      onMapCreated: (controller) {
                        mapController = controller;
                      },
                      onTap: (LatLng position) {
                        setState(() {
                          selectedLocation = position;
                          markers = {
                            Marker(
                              markerId: MarkerId('selectedLocation'),
                              position: position,
                              draggable: true,
                              onDragEnd: (newPosition) {
                                selectedLocation = newPosition;
                              },
                            ),
                          };
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: locationNameController,
                    decoration: InputDecoration(
                      labelText: 'Location Name/Address',
                      hintText: 'e.g. Main Street Station',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Save the selected location
                  setState(() {
                    // Ensure the lists have enough elements
                    while (stopLocations.length <= stopIndex) {
                      stopLocations.add(null);
                    }
                    while (locationNames.length <= stopIndex) {
                      locationNames.add('');
                    }
                    
                    // Update the location at the specified index
                    stopLocations[stopIndex] = GeoPoint(
                      selectedLocation.latitude,
                      selectedLocation.longitude
                    );
                    locationNames[stopIndex] = locationNameController.text;
                  });
                  
                  Navigator.of(context).pop();
                },
                child: Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

  // Method to show the dialog
  void _showAddRouteDialog(BuildContext context, {String? documentId, Map<String, dynamic>? routeData}) {
    if (routeData != null) {
      // Pre-fill the fields with the selected route details
      routeNameController.text = routeData['routeName'];
      stopControllers.clear();
      stopLocations.clear();
      locationNames.clear();

      // Add controllers for each existing stop and location
      if (routeData.containsKey('stopsWithLocations')) {
        for (var stopData in routeData['stopsWithLocations']) {
          stopControllers.add(TextEditingController(text: stopData['name']));
          
          // Extract location if available
          if (stopData.containsKey('location')) {
            GeoPoint geoPoint = stopData['location'];
            stopLocations.add(geoPoint);
            
            // Extract location name if available
            if (stopData.containsKey('locationName')) {
              locationNames.add(stopData['locationName']);
            } else {
              locationNames.add('');
            }
          } else {
            stopLocations.add(null);
            locationNames.add('');
          }
        }
      } else if (routeData.containsKey('stops')) {
        // Handle legacy data format
        for (String stop in routeData['stops']) {
          stopControllers.add(TextEditingController(text: stop));
          stopLocations.add(null);
          locationNames.add('');
        }
      }
    } else {
      // Clear the fields for a new route
      routeNameController.clear();
      stopControllers.clear();
      stopLocations.clear();
      locationNames.clear();
      
      // Add initial stop
      stopControllers.add(TextEditingController());
      stopLocations.add(null);
      locationNames.add('');
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(documentId == null ? 'Add Route Details' : 'Edit Route Details'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Route Name Input
                    TextField(
                      controller: routeNameController,
                      decoration: InputDecoration(
                        labelText: 'Route Name',
                      ),
                    ),
                    SizedBox(height: 20),
                    // Section header for stops
                    Text(
                      'Stops and Locations',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 10),
                    // Dynamically display the stop fields with location buttons
                    Column(
                      children: [
                        for (int i = 0; i < stopControllers.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextField(
                                        controller: stopControllers[i],
                                        decoration: InputDecoration(
                                          labelText: 'Stop ${i + 1}',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    // Button to open Google Maps
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _openGoogleMapsSelection(i);
                                      },
                                      icon: Icon(Icons.location_on),
                                      label: Text('Set'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () {
                                        setStateDialog(() {
                                          // Remove the selected stop and its location
                                          stopControllers.removeAt(i);
                                          if (i < stopLocations.length) {
                                            stopLocations.removeAt(i);
                                          }
                                          if (i < locationNames.length) {
                                            locationNames.removeAt(i);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                // Display location info if available
                                if (i < stopLocations.length && stopLocations[i] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: Text(
                                      i < locationNames.length && locationNames[i].isNotEmpty
                                          ? 'Location: ${locationNames[i]}'
                                          : 'Location: (${stopLocations[i]!.latitude.toStringAsFixed(6)}, ${stopLocations[i]!.longitude.toStringAsFixed(6)})',
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        color: Colors.blue[700],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Button to add another stop
                    ElevatedButton.icon(
                      onPressed: () {
                        setStateDialog(() {
                          // Add new stop controller and empty location
                          stopControllers.add(TextEditingController());
                          stopLocations.add(null);
                          locationNames.add('');
                        });
                      },
                      icon: Icon(Icons.add),
                      label: Text('Add Another Stop'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    // Save or edit the route details
                    await _addOrUpdateRoute(documentId: documentId);

                    // Clear data
                    routeNameController.clear();
                    for (var controller in stopControllers) {
                      controller.clear();
                    }
                    stopControllers.clear();
                    stopLocations.clear();
                    locationNames.clear();

                    Navigator.of(context).pop();
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Dispose controllers properly
    routeNameController.dispose();
    searchController.dispose();
    for (var controller in stopControllers) {
      controller.dispose();
    }
    stopControllers.clear();
    stopLocations.clear();
    locationNames.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: screenHeight * 0.80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by Route Name',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _fetchRouteDetails(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No routes added yet.'));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final document = snapshot.data!.docs[index];
                          final data = document.data() as Map<String, dynamic>;
                          
                          // Handle both data formats (new with locations and old without)
                          List<Widget> stopsWidgets = [];
                          
                          if (data.containsKey('stopsWithLocations')) {
                            // New format with locations
                            List<dynamic> stopsWithLocs = data['stopsWithLocations'];
                            for (var stopData in stopsWithLocs) {
                              String locationText = '';
                              
                              // Check if location data exists
                              if (stopData.containsKey('location')) {
                                GeoPoint geoPoint = stopData['location'];
                                
                                // Use location name if available, otherwise use coordinates
                                if (stopData.containsKey('locationName') && 
                                    stopData['locationName'] != null && 
                                    stopData['locationName'].isNotEmpty) {
                                  locationText = stopData['locationName'];
                                } else {
                                  locationText = '(${geoPoint.latitude.toStringAsFixed(6)}, ${geoPoint.longitude.toStringAsFixed(6)})';
                                }
                              }
                              
                              stopsWidgets.add(
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(color: Colors.black, fontSize: 14),
                                      children: [
                                        TextSpan(
                                          text: '• ${stopData['name']}',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        if (locationText.isNotEmpty)
                                          TextSpan(
                                            text: ' - $locationText',
                                            style: TextStyle(fontStyle: FontStyle.italic),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          } else if (data.containsKey('stops')) {
                            // Old format without locations
                            List<dynamic> stops = data['stops'];
                            stopsWidgets.add(
                              Text(
                                'Stops: ${stops.join(', ')}',
                                style: TextStyle(fontSize: 14),
                              ),
                            );
                          }

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Route Name: ${data['routeName']}',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 8),
                                    if (stopsWidgets.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Stops:',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                          SizedBox(height: 4),
                                          ...stopsWidgets,
                                        ],
                                      ),
                                  ],
                                ),
                                Positioned(
                                  top: -10,
                                  right: -10,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          // Open the dialog to edit route details
                                          _showAddRouteDialog(context, documentId: document.id, routeData: data);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          // Delete the route
                                          _deleteRoute(document.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
          
          Positioned(
            bottom: 25,
            right: 21,
            child: FloatingActionButton(
              onPressed: () {
                _showAddRouteDialog(context);
              },
              backgroundColor: const Color.fromRGBO(62, 142, 205, 1),
              child: Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}