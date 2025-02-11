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
                              Text('Stops: ${assignedBus['stops'].join(', ')}'),
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
        child: FloatingActionButton(
          onPressed: () => _showAssignBusDialog(),
          backgroundColor: Color.fromRGBO(62, 142, 205, 1),
          child: Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
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
                  final busDetails = await _getBusDetails(selectedBusId!);
                  final routeDetails = await _getRouteDetails(selectedRouteId!);
                  final driverDetails =
                      await _getDriverDetails(selectedDriverId!);

                  await _assignBusToFirestore(
                    busDetails['busNumber']!,
                    busDetails['capacity']!,
                    routeDetails['routeName']!,
                    selectedRouteId!,
                    driverDetails['driverName']!,
                    selectedDriverId!,
                    routeDetails['stops']!,
                    driverDetails['driverPhone']!,
                    driverDetails['profilePic'] ?? '', // Store profile pic if exists
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text('Assign Bus'),
            ),
          ],
        );
      },
    );
  }

  // Fetching methods and Firestore actions remain the same...


  Future<List<Map<String, String>>> _fetchBusNumbers() async {
    final snapshot = await _firestore.collection('buses').get();
    return snapshot.docs.map((doc) {
      return {
        'busId': doc.id,
        'busNumber': doc['busNumber']?.toString() ?? '',
      };
    }).toList();
  }

  Future<List<Map<String, String>>> _fetchRoutes() async {
    final snapshot = await _firestore.collection('routes').get();
    return snapshot.docs.map((doc) {
      return {
        'routeId': doc.id,
        'routeName': doc['routeName']?.toString() ?? '',
      };
    }).toList();
  }

  Future<Map<String, dynamic>> _getRouteDetails(String routeId) async {
    final doc = await _firestore.collection('routes').doc(routeId).get();
    return {
      'routeName': doc['routeName'] ?? '',
      'stops': List<String>.from(doc['stops'] ?? []),
    };
  }

  Future<List<Map<String, String>>> _fetchDrivers() async {
    final snapshot = await _firestore.collection('drivers').get();
    return snapshot.docs.map((doc) {
      return {
        'driverId': doc.id,
        'driverName': doc['driverName']?.toString() ?? '',
        'profilePic': doc['profile_pic']?.toString() ?? '', // Treat as string URL
      };
    }).toList();
  }

  Future<Map<String, String>> _getBusDetails(String busId) async {
    final doc = await _firestore.collection('buses').doc(busId).get();
    return {
      'busNumber': doc['busNumber'] ?? '',
      'capacity': doc['capacity'] ?? '',
    };
  }

  Future<Map<String, String>> _getDriverDetails(String driverId) async {
    final doc = await _firestore.collection('drivers').doc(driverId).get();
    return {
      'driverName': doc['driverName'] ?? '',
      'driverPhone': doc['driverPhone'] ?? 'Not available',
      'profilePic': doc['profile_pic']?.toString() ?? '', // Get profile_pic as a string
    };
  }

  Future<void> _assignBusToFirestore(
    String busNumber,
    String capacity,
    String routeName,
    String routeId,
    String driverName,
    String driverId,
    List<String> stops,
    String driverPhone,
    String profilePic,  // Now a string for profile pic
  ) async {
    final busAssigned = await _isBusAssigned(busNumber);
    if (busAssigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('This bus has already been assigned to a route.')),
      );
      return;
    }

    try {
      await _firestore.collection('assignedbus').add({
        'busNumber': busNumber,
        'capacity': capacity,
        'routeName': routeName,
        'routeId': routeId,
        'driverName': driverName,
        'driverId': driverId,
        'assignedAt': Timestamp.now(),
        'stops': stops,
        'driverPhone': driverPhone,
        'profilePic': profilePic, // Store as a string URL or base64 string
      });
      print('Bus successfully assigned!');
    } catch (e) {
      print('Error assigning bus: $e');
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