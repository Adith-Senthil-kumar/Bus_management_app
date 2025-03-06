import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Fetch assigned buses
  Stream<QuerySnapshot> _fetchAssignedBuses() {
    return _firestore.collection('assignedbus').snapshots();
  }

  Future<void> _deleteAssignedBus(String documentId) async {
    try {
      await _firestore.collection('assignedbus').doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bus assignment deleted successfully.')),
      );
    } catch (e) {
      print('Error deleting bus assignment: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Fixed Search Bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: double.infinity,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by Bus Number or Route',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                ),
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchAssignedBuses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No buses assigned yet.'));
                }

                // Filter the list based on the search query
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  var busNumber = doc['busNumber'].toString().toLowerCase();
                  var routeName = doc['routeName'].toString().toLowerCase();
                  return busNumber.contains(_searchQuery) ||
                      routeName.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    var assignedBus = filteredDocs[index];
                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue, width: 2),
                      ),
                      child: Stack(
                        children: [
                          // Bus details
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bus Number: ${assignedBus['busNumber']}',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text('Route: ${assignedBus['routeName']}'),
                              SizedBox(height: 8),
                              Text('Driver: ${assignedBus['driverName']}'),
                              SizedBox(height: 8),
                              Text('Capacity: ${assignedBus['capacity']}'),
                              SizedBox(height: 8),
                              Text('Stops: ${assignedBus['stops'] is List ? assignedBus['stops'].join(', ') : 'No stops available'}'),
                              SizedBox(height: 8),
                              Text('Driver Phone: ${assignedBus['driverPhone']}'),
                            ],
                          ),
                          // Delete icon
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _deleteAssignedBus(assignedBus.id);
                              },
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 95, right: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Prevents unnecessary space
          children: [
            FloatingActionButton(
              onPressed: () => _showAssignBusDialog(),
              backgroundColor: Color.fromRGBO(62, 142, 205, 1),
              child: Icon(Icons.add, color: Colors.white),
            ),
            SizedBox(height: 10), // Spacing between buttons
            FloatingActionButton(
  onPressed: () async {
    await _clearCollection('assignedbus'); 
    await _clearCollection('stops_status'); // Call again for another collection
  },
  backgroundColor: Colors.red, 
  child: Icon(Icons.delete, color: Colors.white),
),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCollection(String collectionName) async {
    try {
      var collectionRef = FirebaseFirestore.instance.collection(collectionName);
      var snapshots = await collectionRef.get();

      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("All documents deleted successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting documents: $e")),
      );
    }
  }

  Future<void> _showAssignBusDialog() async {
    String? selectedBusId;
    String? selectedRouteId;
    String? selectedDriverId;

    final buses = await _fetchBusNumbers();
    final routes = await _fetchRoutes();
    final drivers = await _fetchDrivers();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Assign Bus'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bus dropdown
                    DropdownButtonFormField<String>(
                      value: selectedBusId,
                      hint: Text('Select Bus'),
                      items: buses
                          .map((bus) => DropdownMenuItem<String>(
                                value: bus['busId'],
                                child: Text(bus['busNumber'] ?? 'Unknown'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedBusId = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    // Route dropdown
                    DropdownButtonFormField<String>(
                      value: selectedRouteId,
                      hint: Text('Select Route'),
                      items: routes
                          .map((route) => DropdownMenuItem<String>(
                                value: route['routeId'],
                                child: Text(route['routeName'] ?? 'Unknown'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedRouteId = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    // Driver dropdown
                    DropdownButtonFormField<String>(
                      value: selectedDriverId,
                      hint: Text('Select Driver'),
                      items: drivers
                          .map((driver) => DropdownMenuItem<String>(
                                value: driver['driverId'],
                                child: Text(driver['driverName'] ?? 'Unknown'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedDriverId = value;
                        });
                      },
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
                    if (selectedBusId != null &&
                        selectedRouteId != null &&
                        selectedDriverId != null) {
                      try {
                        final busDetails = await _getBusDetails(selectedBusId!);
                        final routeDetails = await _getRouteDetails(selectedRouteId!);
                        final driverDetails = await _getDriverDetails(selectedDriverId!);

                        await _assignBusToFirestore(
                          busDetails['busNumber']!,
                          busDetails['capacity']!,
                          routeDetails['routeName']!,
                          selectedRouteId!,
                          driverDetails['driverName']!,
                          selectedDriverId!,
                          driverDetails['driverEmail']??'',
                          routeDetails['stops'] ?? [],
                          driverDetails['driverPhone']!,
                          driverDetails['profilePic'] ?? '',
                          
                        );

                        Navigator.of(context).pop();
                      } catch (e) {
                        print('Error assigning bus: $e');
                      }
                    }
                  },
                  child: Text('Assign Bus'),
                ),
              ],
            );
          },
        );
      },
    );
  }

Future<List<Map<String, String>>> _fetchBusNumbers() async {
  try {
    // Try reading from cache first
    final snapshot = await _firestore
        .collection('buses')
        .get(const GetOptions(source: Source.cache));

    if (snapshot.docs.isNotEmpty) {
      print("Fetched from cache");
      return snapshot.docs.map((doc) {
        return {
          'busId': doc.id,
          'busNumber': doc['busNumber']?.toString() ?? '',
        };
      }).toList();
    }
  } catch (e) {
    print('Cache miss, fetching from server...');
  }

  // If cache fails, fetch fresh data
  final snapshot = await _firestore.collection('buses').get();
  print("Fetched from Firestore");

  return snapshot.docs.map((doc) {
    return {
      'busId': doc.id,
      'busNumber': doc['busNumber']?.toString() ?? '',
    };
  }).toList();
}
  // Updated to work with the new route structure
  Future<List<Map<String, dynamic>>> _fetchRoutes() async {
  try {
    // Try reading from cache first
    final snapshot = await _firestore
        .collection('routes')
        .get(const GetOptions(source: Source.cache));

    if (snapshot.docs.isNotEmpty) {
      print("Fetched from cache");
      return _parseRoutes(snapshot);
    }
  } catch (e) {
    print('Cache miss, fetching from server...');
  }

  // If cache fails, fetch fresh data
  final snapshot = await _firestore.collection('routes').get();
  print("Fetched from Firestore");

  return _parseRoutes(snapshot);
}

// Helper function to parse Firestore data
List<Map<String, dynamic>> _parseRoutes(QuerySnapshot snapshot) {
  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    List<String> stopNames = [];

    // Extract stop names from stopsWithLocations
    if (data.containsKey('stopsWithLocations') && data['stopsWithLocations'] is List) {
      List<dynamic> stopsWithLocations = data['stopsWithLocations'];
      stopNames = stopsWithLocations
          .map((stop) => stop['name']?.toString() ?? '')
          .toList()
          .cast<String>();
    }

    return {
      'routeId': doc.id,
      'routeName': data['routeName']?.toString() ?? '',
      'stops': stopNames,
    };
  }).toList();
}

  Future<Map<String, dynamic>> _getRouteDetails(String routeId) async {
  try {
    // Try reading from cache first
    final doc = await _firestore
        .collection('routes')
        .doc(routeId)
        .get(const GetOptions(source: Source.cache));

    if (doc.exists) {
      print("Fetched from cache");
      return _parseRouteDetails(doc);
    }
  } catch (e) {
    print('Cache miss, fetching from server...');
  }

  // If cache fails, fetch fresh data
  final doc = await _firestore.collection('routes').doc(routeId).get();
  print("Fetched from Firestore");

  return _parseRouteDetails(doc);
}

// Helper function to parse route details
Map<String, dynamic> _parseRouteDetails(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>? ?? {};
  List<String> stopNames = [];

  if (data.containsKey('stopsWithLocations') && data['stopsWithLocations'] is List) {
    List<dynamic> stopsWithLocations = data['stopsWithLocations'];
    stopNames = stopsWithLocations
        .map((stop) => stop['name']?.toString() ?? '')
        .toList()
        .cast<String>();
  }

  return {
    'routeName': data['routeName']?.toString() ?? '',
    'stops': stopNames,
  };
}
Future<List<Map<String, String>>> _fetchDrivers() async {
  try {
    final snapshot = await _firestore
        .collection('drivers')
        .get(const GetOptions(source: Source.cache));

    if (snapshot.docs.isNotEmpty) {
      print("Fetched from cache");
      return _parseDrivers(snapshot);
    }
  } catch (e) {
    print('Cache miss, fetching from server...');
  }

  final snapshot = await _firestore.collection('drivers').get();
  print("Fetched from Firestore");

  return _parseDrivers(snapshot);
}

// Helper function to parse drivers
List<Map<String, String>> _parseDrivers(QuerySnapshot snapshot) {
  return snapshot.docs.map((doc) {
    return {
      'driverId': doc.id,
      'driverName': doc['driverName']?.toString() ?? '',
      'profilePic': doc['profile_pic']?.toString() ?? '',
      'driverEmail':doc['driverEmail']?.toString()??'',
    };
  }).toList();
}
Future<Map<String, String>> _getBusDetails(String busId) async {
  try {
    final doc = await _firestore
        .collection('buses')
        .doc(busId)
        .get(const GetOptions(source: Source.cache));

    if (doc.exists) {
      print("Fetched from cache");
      return _parseBusDetails(doc);
    }
  } catch (e) {
    print('Cache miss, fetching from server...');
  }

  final doc = await _firestore.collection('buses').doc(busId).get();
  print("Fetched from Firestore");

  return _parseBusDetails(doc);
}

// Helper function to parse bus details
Map<String, String> _parseBusDetails(DocumentSnapshot doc) {
  return {
    'busNumber': doc['busNumber']?.toString() ?? '',
    'capacity': doc['capacity']?.toString() ?? '',
  };
}
Future<Map<String, String>> _getDriverDetails(String driverId) async {
  try {
    final doc = await _firestore
        .collection('drivers')
        .doc(driverId)
        .get(const GetOptions(source: Source.cache));

    if (doc.exists) {
      print("Fetched from cache");
      return _parseDriverDetails(doc);
    }
  } catch (e) {
    print('Cache miss, fetching from server...');
  }

  final doc = await _firestore.collection('drivers').doc(driverId).get();
  print("Fetched from Firestore");

  return _parseDriverDetails(doc);
}

// Helper function to parse driver details
Map<String, String> _parseDriverDetails(DocumentSnapshot doc) {
  return {
    'driverName': doc['driverName']?.toString() ?? '',
    'driverPhone': doc['driverPhone']?.toString() ?? 'Not available',
    'profilePic': doc['profile_pic']?.toString() ?? '',
    'driverEmail': doc['driverEmail']?.toString() ?? 'Not available',

  };
}
  
  Future<void> _assignBusToFirestore(
  String busNumber,
  String capacity,
  String routeName,
  String routeId,
  String driverName,
  String driverId,
  String driverEmail,
  List<String> stops,
  String driverPhone,
  String profilePic,
) async {
  final busAssigned = await _isBusAssigned(busNumber);
  if (busAssigned) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('This bus has already been assigned to a route.')),
    );
    return;
  }

  try {
    // **1. Assign Bus to Firestore**
    await _firestore.collection('assignedbus').add({
      'busNumber': busNumber,
      'capacity': capacity,
      'routeName': routeName,
      'routeId': routeId,
      'driverName': driverName,
      'driverId': driverId,
      'driverEmail':driverEmail,
      'assignedAt': Timestamp.now(),
      'stops': stops,
      'driverPhone': driverPhone,
      'profilePic': profilePic,
    });

    // **2. Fetch Route Data and Store it in stops_status**
    await _createStopStatus(driverEmail, routeId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bus successfully assigned!')),
    );
  } catch (e) {
    print('Error assigning bus: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error assigning bus: $e')),
    );
  }
}

// **New Function to Fetch Route Data and Store it in stops_status**
Future<void> _createStopStatus(String driverEmail, String routeId) async {
  try {
    DocumentSnapshot routeSnapshot;

    // Try fetching route data from cache first
    try {
      routeSnapshot = await _firestore
          .collection('routes')
          .doc(routeId)
          .get(const GetOptions(source: Source.cache));

      if (!routeSnapshot.exists) {
        throw Exception("Route not found in cache");
      }
      print("Fetched route data from cache");
    } catch (cacheError) {
      print("Cache miss, fetching from Firestore...");
      routeSnapshot = await _firestore.collection('routes').doc(routeId).get();
      
      if (!routeSnapshot.exists) {
        throw Exception("Route not found in Firestore");
      }
      print("Fetched route data from Firestore");
    }

    // Extract route data
    Map<String, dynamic> routeData = routeSnapshot.data() as Map<String, dynamic>;

    // Extract necessary fields
    String routeName = routeData['routeName'] ?? 'Unknown Route';
    Timestamp updatedAt = routeData['updatedAt'] ?? Timestamp.now();
    List<dynamic> stopsWithLocations = routeData['stopsWithLocations'] ?? [];

    // Add status to each stop
    List<Map<String, dynamic>> stopsWithStatus = stopsWithLocations.map((stop) {
      return {
        'name': stop['name'] ?? 'Unknown Stop',
        'location': stop['location'] ?? {},
        'locationName': stop['locationName'] ?? 'Unknown Location',
        'status': 'null' // Default status for each stop
      };
    }).toList();

    // Store driverId and full route data in 'stops_status'
    await _firestore.collection('stops_status').add({
      'driverEmail': driverEmail,
      'routeName': routeName,
      'updatedAt': updatedAt,
      'stopsWithLocations': stopsWithStatus, // Store stop details + status
      'lastUpdated': Timestamp.now(),
    });

    print('Stop status created successfully.');
  } catch (e) {
    print('Error creating stop status: $e');
  }
}

  Future<bool> _isBusAssigned(String busId) async {
    final snapshot = await _firestore
        .collection('assignedbus')
        .where('busNumber', isEqualTo: busId)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}